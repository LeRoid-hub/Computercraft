local version = 1.8
 
-- >TODO<
--[[
  * add turtle.moveTo(x,y,[z]) function
]]--
 
--  +------------------------+  --
--  |-->  INITIALIZATION  <--|  --
--  +------------------------+  --
if not turtle then
  print("Error: This can only be used by a turtle!")
  return
end
 
-- UPDATE HANDLING --
if _UD and _UD.su(version, "6XL8EYXe", {...}) then return end
 
local turtle = turtle
 
-- add checkvariable to turtle
-- use the variable to check if the turtle can execute the additional functions
turtle.isBetterAPI = true
 
 
---- LOCATION DATA ----
 
local x = 0
local y = 0
local z = 0
-- facing vector
local fx = 0    -- west = -1, east = 1
local fz = -1   -- north = -1, south = 1
 
local facingVectors = {
  north = { 0,-1},
  south = { 0, 1},
  west  = {-1, 0},
  east  = { 1, 0}
}
 
function turtle.location()
  return x,y,z
end
 
function turtle.setLocation(_x,_y,_z)
  x = _x
  y = _y
  z = _z
end
 
function turtle.facing()
  if fx == 0 then
    return fz == -1 and "north" or "south"
  end
  return fx == -1 and "west" or "east"
end
 
function turtle.setFacing(facing)
  local vector = facingVectors[facing]
  if not vector then
    error("Unknown facing: "..tostring(facing).." !")
  end
  fx,fz = unpack(vector)
end
 
 
----  UPDATED MOVEMENT ----
 
local forward = turtle.forward
local back = turtle.back
local up = turtle.up
local down = turtle.down
local turnLeft = turtle.turnLeft
local turnRight = turtle.turnRight
 
function turtle.forward()
  if not forward() then
    return false
  end
  x = x + fx
  z = z + fz
  return true
end
 
function turtle.back()
  if not back() then
    return false
  end
  x = x - fx
  z = z - fz
  return true
end
 
function turtle.up()
  if not up() then
    return false
  end
  y = y + 1
  return true
end
 
function turtle.down()
  if not down() then
    return false
  end
  y = y - 1
  return true
end
 
function turtle.turnLeft()
  turnLeft()
  local oldFx = fx
  fx = fz
  fz = -oldFx
  return true
end
 
function turtle.turnRight()
  turnRight()
  local oldFx = fx
  fx = -fz
  fz = oldFx
  return true
end
 
function turtle.turnAround()
  turtle.turnLeft()
  turtle.turnLeft()
  return true
end
 
 
---- FORCE MOVEMENTS ----
 
function turtle.forceForward()
  while not turtle.forward() do
    turtle.dig()
    turtle.attack()
  end
end
 
function turtle.forceBack()
  if not turtle.back() then
    turtle.turnAround()
    turtle.forceForward()
    turtle.turnAround()
  end
end
 
function turtle.forceUp()
  while not turtle.up() do
    turtle.digUp()
    turtle.attackUp()
  end
end
 
function turtle.forceDown()
  while not turtle.down() do
    turtle.digDown()
    turtle.attackDown()
  end
end
 
function turtle.forceLeft()
  turtle.turnLeft()
  turtle.forceForward()
  turtle.turnRight()
end
 
function turtle.forceRight()
  turtle.turnRight()
  turtle.forceForward()
  turtle.turnLeft()
end
 
 
---- ADDITIONAL MOVES ----
 
function turtle.left()
  turtle.turnLeft()
  local result = turtle.forward()
  turtle.turnRight()
  return result
end
 
function turtle.right()
  turtle.turnRight()
  local result = turtle.forward()
  turtle.turnLeft()
  return result
end
 
 
---- ADDITIONAL DIGS ----
 
function turtle.digLeft()
  turtle.turnLeft()
  local result = turtle.dig()
  turtle.turnRight()
  return result
end
 
function turtle.digRight()
  turtle.turnRight()
  local result = turtle.dig()
  turtle.turnLeft()
  return result
end
 
function turtle.digBack()
  turtle.turnAround()
  local result = turtle.dig()
  turtle.turnAround()
  return result
end
 
function turtle.digDirection(face)
  if face == "top" then
    return turtle.digUp()
  elseif face == "bottom" then
    return turtle.digDown()
  elseif face == "left" then
    return turtle.digLeft()
  elseif face == "right" then
    return turtle.digRight()
  elseif face == "back" then
    return turtle.digBack()
  elseif face == "front" then
    return turtle.dig()
  else
    error("UNKNOWN DIRECTION: "..tostring(face).." !")
  end
end
 
 
---- ADDITIONAL DETECTS ----
 
function turtle.detectLeft()
  turtle.turnLeft()
  local result = turtle.detect()
  turtle.turnRight()
  return result
end
 
function turtle.detectRight()
  turtle.turnRight()
  local result = turtle.detect()
  turtle.turnLeft()
  return result
end
 
function turtle.detectBack()
  turtle.turnAround()
  local result = turtle.detect()
  turtle.turnAround()
  return result
end
 
function turtle.detectDirection(face)
  if face == "top" then
    return turtle.detectUp()
  elseif face == "bottom" then
    return turtle.detectDown()
  elseif face == "left" then
    return turtle.detectLeft()
  elseif face == "right" then
    return turtle.detectRight()
  elseif face == "back" then
    return turtle.detectBack()
  elseif face == "front" then
    return turtle.detect()
  else
    error("UNKNOWN DIRECTION: "..tostring(face).." !")
  end
end
 
 
---- ADDITIONAL COMPARES ----
 
function turtle.compareLeft()
  turtle.turnLeft()
  local result = turtle.compare()
  turtle.turnRight()
  return result
end
 
function turtle.compareRight()
  turtle.turnRight()
  local result = turtle.compare()
  turtle.turnLeft()
  return result
end
 
function turtle.compareBack()
  turtle.turnAround()
  local result = turtle.compare()
  turtle.turnAround()
  return result
end
 
function turtle.compareDirection(face)
  if face == "top" then
    return turtle.compareUp()
  elseif face == "bottom" then
    return turtle.compareDown()
  elseif face == "left" then
    return turtle.compareLeft()
  elseif face == "right" then
    return turtle.compareRight()
  elseif face == "back" then
    return turtle.compareBack()
  elseif face == "front" then
    return turtle.compare()
  else
    error("UNKNOWN DIRECTION: "..tostring(face).." !")
  end
end
 
 
---- ADDITIONAL INSPECTS ----
 
if turtle.inspect then
 
  function turtle.inspectLeft()
    turtle.turnLeft()
    local result, data = turtle.inspect()
    turtle.turnRight()
    return result, data
  end
 
  function turtle.inspectRight()
    turtle.turnRight()
    local result, data = turtle.inspect()
    turtle.turnLeft()
    return result, data
  end
 
  function turtle.inspectBack()
    turtle.turnAround()
    local result, data = turtle.inspect()
    turtle.turnAround()
    return result, data
  end
 
  function turtle.inspectDirection(face)
    if face == "top" then
      return turtle.inspectUp()
    elseif face == "bottom" then
      return turtle.inspectDown()
    elseif face == "left" then
      return turtle.inspectLeft()
    elseif face == "right" then
      return turtle.inspectRight()
    elseif face == "back" then
      return turtle.inspectBack()
    elseif face == "front" then
      return turtle.inspect()
    else
      error("UNKNOWN DIRECTION: "..tostring(face).." !")
    end
  end
 
end
 
 
---- ADDITIONAL PLACE ----
 
function turtle.placeLeft(signtext)
  turtle.turnLeft()
  local result = turtle.place(signtext)
  turtle.turnRight()
  return result
end
 
function turtle.placeRight(signtext)
  turtle.turnRight()
  local result = turtle.place(signtext)
  turtle.turnLeft()
  return result
end
 
function turtle.placeBack(signtext)
  turtle.turnAround()
  local result = turtle.place(signtext)
  turtle.turnAround()
  return result
end
 
function turtle.placeDirection(face, signtext)
  if face == "top" then
    return turtle.placeUp(signtext)
  elseif face == "bottom" then
    return turtle.placeDown(signtext)
  elseif face == "left" then
    return turtle.placeLeft(signtext)
  elseif face == "right" then
    return turtle.placeRight(signtext)
  elseif face == "back" then
    return turtle.placeBack(signtext)
  elseif face == "front" then
    return turtle.place(signtext)
  else
    error("UNKNOWN DIRECTION: "..tostring(face).." !")
  end
end
 
 
---- ADDITIONAL DROPS ----
 
function turtle.dropLeft(amount)
  turtle.turnLeft()
  local result = turtle.drop(amount)
  turtle.turnRight()
  return result
end
 
function turtle.dropRight(amount)
  turtle.turnRight()
  local result = turtle.drop(amount)
  turtle.turnLeft()
  return result
end
 
function turtle.dropBack(amount)
  turtle.turnAround()
  local result = turtle.drop(amount)
  turtle.turnAround()
  return result
end
 
function turtle.dropDirection(face, amount)
  if face == "top" then
    return turtle.dropUp(amount)
  elseif face == "bottom" then
    return turtle.dropDown(amount)
  elseif face == "left" then
    return turtle.dropLeft(amount)
  elseif face == "right" then
    return turtle.dropRight(amount)
  elseif face == "back" then
    return turtle.dropBack(amount)
  elseif face == "front" then
    return turtle.drop(amount)
  else
    error("UNKNOWN DIRECTION: "..tostring(face).." !")
  end
end
 
 
---- ADDITIONAL SUCKS ----
 
function turtle.suckLeft(amount)
  turtle.turnLeft()
  local result = turtle.suck(amount)
  turtle.turnRight()
  return result
end
 
function turtle.suckRight(amount)
  turtle.turnRight()
  local result = turtle.suck(amount)
  turtle.turnLeft()
  return result
end
 
function turtle.suckBack(amount)
  turtle.turnAround()
  local result = turtle.suck(amount)
  turtle.turnAround()
  return result
end
 
function turtle.suckDirection(face, amount)
  if face == "top" then
    return turtle.suckUp(amount)
  elseif face == "bottom" then
    return turtle.suckDown(amount)
  elseif face == "left" then
    return turtle.suckLeft(amount)
  elseif face == "right" then
    return turtle.suckRight(amount)
  elseif face == "back" then
    return turtle.suckBack(amount)
  elseif face == "front" then
    return turtle.suck(amount)
  else
    error("UNKNOWN DIRECTION: "..tostring(face).." !")
  end
end
