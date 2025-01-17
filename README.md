# ⏱️ Timey
Simple timer with added tag functionality.

### Motivation
Most timers in nvim are countdown timers, timers that can count up are often bloated with functions that have no usecase for my day-to-day workflow. This plugin is for those who just want to see how long they spend on a task; and at a later time add the entries to their timemanagement system.

### Installation:
Use your favorite package manager e.g. Packer:
`use "Nishkea/timey.nvim"`

### Usage:

- To start a timer use `TimeyStart tag` 
- To stop a timer use `TimeyStop tag`
- To show all timers use `TimeyShow`
- To delete a timer use `TimeyDelete tag`

### Demo:



### Example lualine integration:

```lua
sections = {
 lualine_c = {
        function()
          return require('timey').current()
        end,
    },
}
```
