package.path = "src/?.lua;"..package.path

local metaplate = require "metaplate"

Z = io.write

local function test(template)
  local code = metaplate.compile(template)
  print("---- metacode ----\n"..code.."\n---- result ----")
  local f = assert(load(code))
  f(); print()
end

test[[
! local function test()
! end
!
! for i=1,10 do
!   local a,b = i^2, i^3
$i $a $b {! Z(i^(1/2)) !}
! end
]]

test[==[
! local function vec_add(n)
!   for i=1,n do
r[$i] = a[$i] + b[$i]
!   end
! end
!
! vec_add(4)
[=[ test ]=]
[[test]]
]==]
