# cmp-digraphs

A [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) source for completing [digraphs](https://vimhelp.org/digraph.txt.html) (both built-in and custom ones).

## Usage

```lua
local cmp = require('cmp')
cmp.setup({
  sources = {
    { name = 'digraphs' },
  },
})
```

## Configuration

### `cache_digraphs_on_start`

**Type:** `boolean`
**Default:** `true`

The code which gets a list of digraphs and formats it into completion items takes a significant amount of time (15-20 milliseconds), but digraphs don't really change at all while the editor is running, so by default this source will query the digraphs only once when it is invoked for the first time (meaning that it will see the custom digraphs defined in the vimrc). Disable this option only if you are for whatever reason adding digraphs at runtime.

### `filter`

**Type:** `function`
**Default:** `function(item) return item.charnr >= 0x20 end`

Some characters (by default: ASCII control characters) are known to cause issues with nvim-cmp or Nvim itself, so they are not shown in the completion results. This function receives a table with the following keys and must return `true` if the digraph should be shown:

- `digraph` - Two characters that the user must type to enter the digraph.
- `char` - The character that will be inserted.
- `charnr` - The index of that character in the Unicode table.
