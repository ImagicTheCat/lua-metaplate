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

local default_config = {
  range_pattern = "%{(%=*)%!(.-)%!%1%}",
  line_pattern = "\n%s%!(.-)\n",
  expression_pattern = "%$([%w_]+)"
}

-- Transform source string to production code.
local function to_production(str)
  return "Z[["..str.."]]"
end

local function parse_expressions(out, source, config)
      table.insert(out, to_production(source:sub(cur, a+1))) -- source language
end

local function parse_lines(out, source, config)
  local cur = 1
  local a, b, lua = source:find(config.line_pattern)
  while a do
    parse_expressions(out, source:sub(cur, a+1), config) -- sub
    table.insert(out, lua) -- meta language
    -- next
    cur = b+1
    a, b, lua = source:find(config.range_pattern, cur)
  end
  parse_expressions(out, source:sub(cur), config) -- sub
end

local function parse_ranges(out, source, config)
  local cur = 1
  local a, b, levels, lua = source:find(config.range_pattern)
  while a do
    parse_lines(out, source:sub(cur, a+1), config) -- sub
    table.insert(out, lua) -- meta language
    -- next
    cur = b+1
    a, b, levels, lua = source:find(config.range_pattern, cur)
  end
  parse_lines(out, source:sub(cur), config) -- sub
end

function M.compile(template, chunkname, env, config)
  config = config or default_config
  return assert(load(source, chunkname, "t", env))
end

return M
