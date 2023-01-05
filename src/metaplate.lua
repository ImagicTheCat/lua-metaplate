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

-- production functions
local p_identity = function(source) return source end
local p_expression = function(source) return " Z("..source..") " end

local default_config = {
  parsing_steps = {
    { -- line statement
      pattern = "^[\t ]*%!(.*)$", -- !...
      produce = p_identity
    },
    { -- range statement: {! ... !}
      pattern = "%{%!(.-)%!%}",
      produce = p_identity
    },
    { -- range expression: {$ ... $}
      pattern = "%{%$(.-)%$%}",
      produce = p_expression
    },
    { -- identifier expression: $...
      pattern = "%$([%w_]+)",
      produce = p_expression
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

local function parse_step(out, source, config, index)
  local inline = config.parsing_steps[index]
  if not inline then table.insert(out, produce_verbatim(source)); return end
  -- match pattern
  local cur = 1
  local a, b, match = source:find(inline.pattern)
  while a do
    parse_step(out, source:sub(cur, a-1), config, index+1)
    table.insert(out, inline.produce(match))
    -- next
    cur = b+1
    a, b, match = source:find(inline.pattern, cur)
  end
  parse_step(out, source:sub(cur), config, index+1) -- end
end

local function parse(out, source, config)
  for line, last in split(source, "\n") do
    parse_step(out, last and line or line.."\n", config, 1)
  end
end

-- Compile template to Lua (meta) code.
-- For each line of the template, each parsing step decomposes the line recursively;
-- unmatched strings are processed in the next step until it generates verbatim meta code.
-- Note: the first step can use pattern anchors as line anchors.
--
-- template: string
-- config: (optional) table
--- parsing_steps: list of parsing steps {.pattern, .produce}
---- pattern: Lua pattern
---- produce(capture): function which should return produced meta code (string) from the capture
-- return string
function M.compile(template, config)
  config = config or default_config
  local segments = {}
  parse(segments, template, config)
  return table.concat(segments)
end

M.default_config = default_config

return M
