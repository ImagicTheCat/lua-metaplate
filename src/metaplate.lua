--[[
MIT License

Copyright (c) 2022 ImagicTheCat

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local M = {}

-- Iterator: split string.
local function split(str, sep)
  local cur, done = 1, false
  return function(s, v)
    local a, b = str:find(sep, cur, true)
    if a then
      local pcur = cur
      cur = b+1
      return str:sub(pcur, a-1)
    elseif not done then
      done = true
      return str:sub(cur, #str), true
    end
  end
end

local default_config = {
  line_pattern = "^[\t ]*%!(.*)$", -- !...
  inlines = {
    { -- range statement: {! ... !}
      pattern = "%{%!(.-)%!%}",
      produce = function(source) return source end
    },
    { -- identifier expression: $...
      pattern = "%$([%w_]+)",
      produce = function(source) return " Z("..source..") " end
    }
  }
}

-- Find suitable level to embed in a long bracket literal.
local function find_suitable_level(source)
  local level = 0
  while source:find("]"..("="):rep(level).."]", 1, true) do
    level = level+1
  end
  return level
end

-- Produce meta code for verbatim source.
local function produce_verbatim(source)
  if #source > 0 then
    local equals = ("="):rep(find_suitable_level(source))
    if source:match("^\r?\n") then return " Z'\\n'Z["..equals.."["..source.."]"..equals.."] "
    else return " Z["..equals.."["..source.."]"..equals.."] " end
  else return "" end
end

local function parse_inline(out, source, config, index)
  local inline = config.inlines[index]
  if not inline then table.insert(out, produce_verbatim(source)); return end
  -- match pattern
  local cur = 1
  local a, b, match = source:find(inline.pattern)
  while a do
    parse_inline(out, source:sub(cur, a-1), config, index+1)
    table.insert(out, inline.produce(match))
    -- next
    cur = b+1
    a, b, match = source:find(inline.pattern, cur)
  end
  parse_inline(out, source:sub(cur), config, index+1) -- end
end

local function parse_line(out, line, config)
  local match = line:match(config.line_pattern)
  if match then table.insert(out, match)
  else parse_inline(out, line, config, 1) end
end

local function parse(out, source, config)
  for line, last in split(source, "\n") do
    parse_line(out, last and line or line.."\n", config)
  end
end

function M.compile(template, config)
  config = config or default_config
  local segments = {}
  parse(segments, template, config)
  return table.concat(segments)
end

M.default_config = default_config

return M
