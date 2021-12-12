local source = {}

local option_defaults = {
  cache_digraphs_on_start = true,
  filter = function(item) return item.charnr >= 0x20 end,
}

function source.new()
  local self = setmetatable({}, { __index = source })
  self._cached_items = nil
  return self
end

function source:get_keyword_pattern()
  return [[.\{1,2}]]
end

function source:complete(params, callback)
  local opts = vim.tbl_deep_extend('keep', params.option, option_defaults)
  vim.validate({
    cache_digraphs_on_start = {opts.cache_digraphs_on_start, 'boolean'},
    filter = {opts.filter, 'function'},
  })

  local items
  if opts.cache_digraphs_on_start then
    if self._cached_items == nil then
      self._cached_items = self:_get_completion_items(opts)
    end
    -- Just in case our tables are modified down the line.
    items = vim.deepcopy(self._cached_items)
  else
    items = self:_get_completion_items()
  end

  callback({ items = items })
end

function source:_get_completion_items(opts)
  local items = {}
  -- Let's not create unnecessary garbage.
  local item_for_filter = { digraph = nil, char = nil, charnr = nil }
  for _, digraph_and_char in ipairs(self._get_digraphs_list()) do
    local digraph, char = unpack(digraph_and_char, 1, 2)
    local charnr = vim.fn.char2nr(char)
    item_for_filter.digraph = digraph
    item_for_filter.char = char
    item_for_filter.charnr = charnr
    if opts.filter(item_for_filter) then
      items[#items + 1] = {
        label = digraph .. ' ' .. vim.fn.strtrans(char),
        labelDetails = { detail = string.format('U+%04X', charnr) },
        filterText = digraph,
        insertText = char,
      }
    end
  end
  return items
end

if vim.fn.exists('*digraph_getlist') ~= 0 then
  -- The digraphs API is a fairly new addition to Vim (patch 8.2.3184, commited
  -- on 2021-07-19), and, as of writing, hasn't been ported to Nvim yet.
  -- <https://github.com/vim/vim/commit/6106504e9edc8500131f7a36e59bc146f90180fa>
  function source._get_digraphs_list()
    -- The boolean flag specifies whether we want to receive built-in digraphs
    -- or just the custom ones.
    return vim.fn.digraph_getlist(true)
  end
elseif vim.fn.exists('*getdigraphlist') ~= 0 then
  -- Oh, and also its functions have been renamed (patch 8.2.3226, commited on
  -- 2021-07-26), so let's account for that, just in case.
  -- <https://github.com/vim/vim/commit/29b857150c111a455f1a38a8f748243524f692e1>
  function source._get_digraphs_list()
    return vim.fn.getdigraphlist(true)
  end
else

  -- Lastly, an implementation for the current version of Neovim (0.6.0). Based
  -- on <https://github.com/chrisbra/unicode.vim/blob/664d7b2e5cedf36ea3a85ad7e8e28e43c16f025b/autoload/unicode.vim#L935-L966>.
  function source._get_digraphs_list()
    local output = vim.api.nvim_exec('digraphs', true)
    local list = {}

    local search_idx = 0
    local regex = [[(\S\S) %(\<\x\x\>|.) +(\d+)]]
    local regex_search, regex_groups = '\\v' .. regex, '\\v^' .. regex .. '$'
    while search_idx < #output do
      local match_str, match_start, match_end = unpack(vim.fn.matchstrpos(output, regex_search, search_idx), 1, 3)
      if not (match_start >= 0 and match_end >= 0) then break end
      search_idx = match_end
      local groups = vim.fn.matchlist(match_str, regex_groups)

      local digraph = groups[2]
      local char = vim.fn.nr2char(tonumber(groups[3], 10))
      list[#list + 1] = { digraph, char }
    end

    return list
  end

end

return source
