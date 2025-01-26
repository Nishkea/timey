local M = {}
local timers = {}
local timer_file = vim.fn.stdpath('data') .. '/timers.json'

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
            timers[tag].start = os.time() - timers[tag].elapsed
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
    timer.elapsed = os.time() - timer.start
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
    local items = {}
    for tag, timer in pairs(timers) do
        local elapsed_time = timer.elapsed
        if timer.status == 'running' then
            elapsed_time = os.time() - timer.start + timer.elapsed
        end
        table.insert(items, string.format('%s: %s (%s)', tag, format_time(elapsed_time), timer.status))
    end
    if #items == 0 then
        table.insert(items, 'No timers running')
    end

    local content = table.concat(items, '\n')
    local width = 50
    local height = #items + 2

    vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
        relative = 'editor',
        width = width,
        height = height,
        col = (vim.o.columns - width),
        row = (vim.o.lines - height),
        style = 'minimal',
        border = 'rounded',
    })

    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(content, '\n'))
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
