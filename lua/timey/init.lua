local timers = {}
local timer_file = vim.fn.stdpath('data') .. '/timers.json'
local M = {}

local function save_timers()
    local file = io.open(timer_file, 'w')
    file:write(vim.fn.json_encode(timers))
    file:close()
end

local function load_timers()
    local file, err = io.open(timer_file, 'r')
    if not file then return end
    local content = file:read('*all')
    timers = vim.fn.json_decode(content)
    file:close()
end

local function format_time(seconds)
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function M.start_timer(tag)
    load_timers()
    if timers[tag] then
        if timers[tag].status == 'running' then
            print('Timer already running for tag:', tag)
            return
        else
            -- Continue where it left off
            timers[tag].start = os.time()
            timers[tag].status = 'running'
            print('Resumed timer for tag:', tag)
        end
    else
        -- Start a new timer
        timers[tag] = { start = os.time(), elapsed = 0, status = 'running' }
        print('Started new timer for tag:', tag)
    end
    save_timers()
end

function M.stop_timer(tag)
    load_timers()
    if not timers[tag] or timers[tag].status == 'stopped' then
        print('No running timer for tag:', tag)
        return
    end
    local timer = timers[tag]
    timer.elapsed = timer.elapsed + (os.time() - timer.start)
    timer.status = 'stopped'
    save_timers()
    print(string.format('Stopped timer for tag: %s, elapsed time: %s', tag, format_time(timer.elapsed)))
end

function M.delete_timer(tag)
    load_timers()
    if not timers[tag] then
        print('No timer found for tag:', tag)
        return
    end
    timers[tag] = nil
    save_timers()
    print('Deleted timer for tag:', tag)
end

function M.get_timers()
    load_timers()
    local running_timers = {}
    for tag, timer in pairs(timers) do
        if timer.status == 'running' then
            table.insert(running_timers, { tag = tag, elapsed = os.time() - timer.start + timer.elapsed })
        end
    end
    if #running_timers > 0 then
        local result = {}
        for _, timer in ipairs(running_timers) do
            table.insert(result, string.format(' %s: %s', timer.tag, format_time(timer.elapsed)))
        end
        return table.concat(result, ' | ')
    else
        return ''
    end
end

function M.current()
    return M.get_timers()
end

function M.show_timers_popup()
    load_timers()
    local items = { 'Timers Overview (beta)', '' } 
    for tag, timer in pairs(timers) do
        local elapsed_time = timer.elapsed
        if timer.status == 'running' then
            elapsed_time = os.time() - timer.start + timer.elapsed
        end
        table.insert(items, string.format('%s: %s (%s)', tag, format_time(elapsed_time), timer.status))
    end
    if #items == 2 then
      table.insert(items, 'No timers running')
    else 
      table.insert(items, '')
      table.insert(items, 'Press "d" to delete a timer')
      table.insert(items, 'Press "t" to toggle a timer')
    end

    local content = table.concat(items, '\n')
    local width = 50
    local height = #items + 2

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 2),
        style = 'minimal',
        border = 'rounded',
    })

    -- refresh buffer every second
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'delete')
    vim.api.nvim_buf_set_option(buf, 'buflisted', false)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, '\n'))
    local line = vim.fn.line('.')
    local tag = vim.fn.split(vim.fn.getline(line), ':')[1]

    if #items >= 2 then
      -- Local buffer keymaps
      vim.api.nvim_buf_set_keymap(buf, 'n', 'd', ':lua require("timey-test").delete_timer_tag()<CR>', { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, 'n', 't', ':lua require("timey-test").resume_timer_tag()<CR>', { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
    end
end

function M.resume_timer_tag()
    local line = vim.fn.line('.') - 3
    local count = 0

    for _ in pairs(timers) do count = count + 1 end
    if count == 0 then
        return
    end

    if line >= 0 and line <= (count - 1) then
        local tag = vim.fn.split(vim.fn.getline(line + 3), ':')[1]
        timers[tag] = nil

        load_timers()
        if not timers[tag] or timers[tag].status == 'stopped' then
            M.start_timer(tag)
        else
          M.stop_timer(tag)
        end

        vim.api.nvim_win_close(0, true)
        M.show_timers_popup()
        return
    end
end

function M.delete_timer_tag()
    local line = vim.fn.line('.') - 3
    local count = 0

    for _ in pairs(timers) do count = count + 1 end
    if count == 0 then
        print('No timers to delete')
        return
    end

    if line >= 0 and line <= (count - 1) then
        local tag = vim.fn.split(vim.fn.getline(line + 3), ':')[1]
        timers[tag] = nil
        M.delete_timer(tag)

        vim.api.nvim_win_close(0, true)
        M.show_timers_popup()
    end
end

-- nvim commands prefix Timey

vim.api.nvim_create_user_command('TimeyStart', function(opts)
    M.start_timer(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command('TimeyStop', function(opts)
    M.stop_timer(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command('TimeyShow', function()
    M.show_timers_popup()
end, {})

vim.api.nvim_create_user_command('TimeyDelete', function(opts)
    M.delete_timer(opts.args)
end, { nargs = 1 })

load_timers()

return M
