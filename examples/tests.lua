package.path = "src/?.lua;"..package.path

local metaplate = require "metaplate"

local function test(template)
  local code = metaplate.compile(template)
  print("---- metacode ----\n"..code.."\n---- result ----")
  local segs = {}
  Z = function(v) table.insert(segs, v) end
  local f = assert(load(code))
  f();
  print(table.concat(segs))
end

test[[
! local function vec(n)
-- generated add
function vec{$ n $}_t.add(r,a,b)
!   for i=1,n do
  r[$i] = a[$i] + b[$i]
!   end
end
! end
!
! vec(2)
! vec(3)
]]

test[[
<h1>Multiplication table</h1>
<table>
! for y=0,10 do
  <tr>
    <td><strong>{$ y == 0 and 'X' or y $}</strong></td>
!   for x=1,10 do
!     if y == 0 then
    <td><strong>$x</strong></td>
!     else
    <td>{$ x*y $}</td>
!     end
!   end
  </tr>
! end
</table>
]]

test[[
! local function test()
! end
!
! for i=1,10 do
!   local a,b = i^2, i^3
$i $a $b {$ i^(1/2) $}
! end
]]

test[==[
[=[ test ]=]
[[test]]
]==]

test[[
{! for i=1,10 do if i > 1 then !}, {! end !}$i{! end !}
]]
