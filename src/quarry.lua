local version = 3.22
 
-- >TODO<
--[[
  * add more status prints
  * replace parameter 'burnfuel' with 'fuel.list' file
    for checkFuel and isInventoryFull (fuelSources)
  * allow "tag@" prefix in ignore/allow list to compare with block tags (e.g. "forge:stone")
  * switch to using position data from BetterTurtleAPI to check if we need to dig a hole:
    local function isHole(x,y)
      return (y + x * 3) % 5 == 0
    end
  * maybe check if dropoff point has/is inventory?
]]--
 
--  +------------------------+  --
--  |-->  INITIALIZATION  <--|  --
--  +------------------------+  --
if not turtle then
  print("This program can only be")
  print("  executed by a turtle!")
  return
end
 
-- UPDATE HANDLING --
if _UD and _UD.su(version, "HqXCPzCg", {...}) then return end
 
local ARGS = {...}
 
-- INITIALIZING NECESSARY FUNCTIONS
local startswith = function(text, piece)
  return string.sub(text, 1, string.len(piece)) == piece
end
 
local function isTableEmpty(tbl)
  for k,v in pairs(tbl) do
    return false
  end
  return true
end
 
local function itemName(slot)
  local details = turtle.getItemDetail(slot)
  return details and details.name
end
 
local function itemDetails(slot)
  local details = turtle.getItemDetail(slot)
  return details and details.name.."#"..tostring(details.damage)
end
 
 
local oreDictPeripheral = peripheral.find("oreDictionary")
 
 
-- possible drop-off blocks
-- (everything else with "chest" in the name will work too)
local dropSpots = {
  ["Railcraft:tile.railcraft.machine.beta"] = true,
  ["quark:pipe"] = true,
}
 
-- directions in relation to initial placement direction (which is 0, or north)
local direction = {front=0, right=1, back=2, left=3}
 
-- INITIAL VARIABLE SETUP --
local quarry = {
  -- width and length of the quarry site
  width = 16,
  length = 16,
  
  -- offsets
  offsetH = 0,
  
  -- maximum depth the turtle will dig down, starting at offsetH
  maxDepth = 0,
  
  -- table with valid fuel source items
  fuelSources = nil,
  skipHoles = 0,
  
  -- transmutation targets for known ore dictionary entries
  oreDictData = nil,
  
  -- enable logging status to log.txt
  enableLogging = false,
  -- supresses all status information (takes precedence over enableLogging)
  silent = false,
  -- use delay parameter for the status function
  statusDelay = false,
  
  -- depth in the curren colum
  depth = 0,
  -- x and y position on the specified grid. turtle starts one block in front of the lower left corner of the area
  posx = 1,
  posy = 1,
  facing = direction.front,
  
  -- >TODO< quarry offsets for x,y and depth
 
  -- list of blocks/things to ignore
  ignore = nil,
  -- list of blocks/things to allow (overrules ignore list)
  allow = nil,
  
  -- table of mined blocks
  rememberBlocks = false,
  minedBlocks = {},
}
 
local function log(text)
  if not quarry.enableLogging then
    return
  end
  local f = fs.open("log.txt","a")
  f.write(tostring(os.date()).."\n")
  f.write(text.."\n")
  f.close()
end
 
local function saveMinedBlocks()
  if not quarry.rememberBlocks then
    return
  end
  local f = fs.open("mined-blocks.txt","w")
  for name,_ in pairs(quarry.minedBlocks) do
    f.write(name.."\n")
  end
  f.close()
end
 
-- READ OUT COMMAND LINE PARAMETERS --
 
for _,par in pairs(ARGS) do
  if startswith(par, "w:") then
    quarry.width = tonumber(string.sub(par, string.len("w:")+1))
    print("Quarry width: "..tostring(quarry.width))
    
  elseif startswith(par, "l:") then
    quarry.length = tonumber(string.sub(par, string.len("l:")+1))
    print("Quarry length: "..tostring(quarry.length))
    
  elseif startswith(par, "offh:") then
    quarry.offsetH = tonumber(string.sub(par, string.len("offh:")+1))
    print("Quarry height offset: "..tostring(quarry.offsetH))
    
  elseif startswith(par, "maxd:") then
    quarry.maxDepth = tonumber(string.sub(par, string.len("maxd:")+1))
    print("Quarry maximum depth: "..tostring(quarry.maxDepth))
    
  elseif startswith(par, "skip:") then
    quarry.skipHoles = tonumber(string.sub(par, string.len("skip:")+1))
    print("Skipping the first "..tostring(quarry.skipHoles).." holes")
    
  elseif par == "burnfuel" then
    quarry.fuelSources = {["minecraft:coal"] = true}
    print("Fuel item usage activated")
  
  elseif par == "oredict" then
    local configFile = "oredict.config"
    if oreDictPeripheral and fs.exists(configFile) then
      local file = fs.open(configFile, "r")
      local content = file.readAll()
      file.close()
      local data = textutils.unserialise(content)
      if not isTableEmpty(data) then
        quarry.oreDictData = data
      end
    end
    if not oreDictPeripheral then
      print("No ore dictionary equipped")
    elseif not quarry.oreDictData then
      print("No useful '"..configFile.."' found")
    else
      print("Using ore dictionary")
    end
  
  elseif par == "enable-logging" then
    quarry.enableLogging = true
    print("Logging enabled")
    
  elseif par == "remember-blocks" then
    quarry.rememberBlocks = true
    print("Remember blocks enabled")
  
  elseif par == "silent" then
    quarry.silent = true
    print("Disabled status information")
  
elseif par == "statusdelay" then
    quarry.statusDelay = true
    print("Enabled status delay")
  end
end
 
-- read ignore file
local ignoreFile = "ignore.list"
if fs.exists(ignoreFile) and not fs.isDir(ignoreFile) then
  local file = fs.open(ignoreFile, "r")
  local ok, list = pcall(textutils.unserialize, file.readAll())
  file.close()
  if ok then
    -- convert list to lookup table
    quarry.ignore = {}
    for _,name in pairs(list) do
      quarry.ignore[name] = true
    end
    print("Ignoring blocks found in \""..ignoreFile.."\"")
  else
    print("Could not unserialize table from file content: "..ignoreFile)
    return
  end
else
  print("No \""..ignoreFile.."\" found.")
end
 
-- read allow file
local allowFile = "allow.list"
if fs.exists(allowFile) and not fs.isDir(allowFile) then
  local file = fs.open(allowFile, "r")
  local ok, list = pcall(textutils.unserialize, file.readAll())
  file.close()
  if ok then
    -- convert list to lookup table
    quarry.allow = {}
    for _,name in pairs(list) do
      quarry.allow[name] = true
    end
    print("Allowing blocks found in \""..allowFile.."\"")
  else
    print("Could not unserialize table from file content: "..allowFile)
    return
  end
else
  print("No \""..allowFile.."\" found.")
end
 
 
term.write("Starting program ")
for i=1,10 do
  term.write(".")
  sleep(1)
end
print(" go")
turtle.select(1)
 
 
-- frequently used globals as locals for performance
local turtle = turtle
local term = term
local colors = colors
local textutils = textutils
local sleep = sleep
local peripheral = peripheral
 
local tostring = tostring
local print = print
 
--  +-------------------+  --
--  |-->  FUNCTIONS  <--|  --
--  +-------------------+  --
 
local function status(text, color, delay)
  if quarry.silent then
    return
  end
  log(text)
  term.clear()
  term.setCursorPos(1,1)
  if term.isColor() then
    term.setTextColor(colors.yellow)
  end
  print(" Turtle-Quarry "..tostring(version))
  print("--------------------")
  print()
  if term.isColor() then
    term.setTextColor(colors.white)
  end
  term.write("--> ")
  if term.isColor() then
    if color == nil then
      color = colors.white
    end
    term.setTextColor(color)
  end
  print(text)
  if term.isColor() and color ~= colors.white then
    term.setTextColor(colors.white)
  end
  if delay and quarry.statusDelay then
    sleep(delay)
  end
end
 
-- selects the given slot if it isn't selected yet
local function select(slot)
  if turtle.getSelectedSlot() == slot then
    return true
  end
  return turtle.select(slot)
end
 
 
local function forward()
  while not turtle.forward() do
    select(1)
    turtle.dig()
    turtle.attack()
  end
  if quarry.facing == direction.front then
    quarry.posy = quarry.posy + 1
  elseif quarry.facing == direction.back then
    quarry.posy = quarry.posy - 1
  elseif quarry.facing == direction.right then
    quarry.posx = quarry.posx + 1
  else
    quarry.posx = quarry.posx - 1
  end
end
 
local function up()
  while not turtle.up() do
    select(1)
    turtle.digUp()
    turtle.attackUp()
  end
end
 
local function down()
  while not turtle.down() do
    select(1)
    turtle.digDown()
    turtle.attackDown()
  end
end
 
local function turnRight()
  turtle.turnRight()
  quarry.facing = quarry.facing+1
  if (quarry.facing > 3) then
    quarry.facing = 0
  end
end
 
local function turnLeft()
  turtle.turnLeft()
  quarry.facing = quarry.facing-1
  if (quarry.facing < 0) then
    quarry.facing = 3
  end
end
 
-- checks if the given item name is on the 'allow' list
local function isAllowed(itemName)
  return quarry.allow[itemName]
end
 
-- checks if the given item name is not on the 'ignore' list
local function isNotIgnored(itemName)
  return not quarry.ignore[itemName]
end
 
local function alwaysTrue()
  return true
end
 
-- checks if a given item name is of interest for the quarry
local isDesired =
    quarry.allow and isAllowed
    or quarry.ignore and isNotIgnored
    or alwaysTrue
 
 
--[[
  Burns the item in the given slot if it is a valid fuel item.
]]--
local function useFuelItem(slot)
  return quarry.fuelSources
         and quarry.fuelSources[itemName(slot)]
         and select(slot)
         and turtle.refuel()
end
 
 
--[[
  Checks if fuel level is okay
  and refuels if needed.
  Returns TRUE if fuel level is good,
  or FALSE if fuel level is low and
  nothing could get refuelled.
  Fuel check is determined by how much is needed to reach
  the given destination from the starting point (+ safety measure), times the given factor.
]]--
local function checkFuel(posx, posy, depth, factor, allowAnySource)
  -- if fuel is needed, check if we can consume something
  if turtle.getFuelLevel() <= ((depth + posx + posy + 100) * factor) then
    status("Need fuel, trying to fill up...", colors.lightBlue, 0.5)
    local refuelFn = allowAnySource and turtle.refuel or useFuelItem
    local success = false
    for i=1,16 do
      if turtle.getItemCount(i) > 0 then
        -- turtle.refuel only works on the currently selected slot
        select(i)
        -- lua will evaluate until one of the statements is true. meaning that it would not
        -- execute "turtle.refuel()" if it stood after the "or" once success is true.
        success = refuelFn() or success
      end
    end
    local color = success and colors.lime or colors.orange
    local text = "Refuel success: "..tostring(success)
    if success then
      text = text.." ("..tostring(turtle.getFuelLevel())..")"
    end
    status(text, color, 0.5)
    return success
  end
  return true
end
 
local function isInventoryEmpty()
  for i=1,16 do
    if turtle.getItemCount(i) > 0 then
      return false
    end
  end
  return true
end
 
 
--[[
  Check if the item in the specified slot
  is desired by the quarry. If it's not, tries
  to drop it down, then forward, then up.
  Returns true if waste was dropped,
  and false if it was not waste or could
  not be dropped.
]]--
local function dropWaste(slot)
  local item = turtle.getItemDetail(slot).name
  return not isDesired(item)
         and select(slot)
         and (turtle.dropDown()
              or turtle.drop()
              or turtle.dropUp())
end
 
 
local function getDropSpotName()
  local ok, data = turtle.inspectUp()
  if ok and (dropSpots[data.name] or data.name:lower():find("chest")) then
    return data.name
  end
end
 
 
local function dropItemsInChest()
  local dropSpotName = getDropSpotName()
  while not dropSpotName do
    status("No inventory to drop items into...", colors.orange)
    sleep(3)
    dropSpotName = getDropSpotName()
  end
  
  status("Dropping into \""..dropSpotName.."\"", colors.lightBlue, 0.5)
  while true do
    for i=1,16 do
      if turtle.getItemCount(i) > 0 then
        -- check if item is waste
        if not dropWaste(i) then
          -- otherwise drop
          select(i)
          turtle.dropUp()
        end
      end
    end
    if isInventoryEmpty() then
      break
    else
      sleep(3)
    end
  end
end
 
--[[
  Attempts to transmute the items in the given slot
  to a potential target item. Returns TRUE if the item
  was transmuted, otherwise FALSE.
]]--
local function transmuteItem(slot)
  select(slot)
  if not oreDictPeripheral then
    return false
  end
  for _,entry in pairs(oreDictPeripheral.getEntries()) do
    local target = quarry.oreDictData[entry]
    if target then
      local name = itemDetails()
      local seen = {name=true}
      -- transmute to target as necessary
      while name ~= target do
        oreDictPeripheral.transmute()
        name = itemDetails()
        -- check if we tried all possibilities
        if seen[name] then
          print(entry..": can't transmute '"..name.."' to target item")
          return false
        end
        seen[name] = true
      end
      return true
    end
  end
  return false
end
 
 
--[[
  Finds the first empty slot that represents a gap in the inventory
]]--
local function findInventoryGap()
  local gap = nil
  for i=1,16 do
    local empty = turtle.getItemCount(i) == 0
    if empty then
      gap = gap or i
    elseif gap then
      return gap
    end
  end
end
 
--[[
  Attempts to move the items in slot 'src' to slot 'dest'.
  Returns true if the entire stack was successfully moved,
  false otherwise.
]]--
local function moveStack(src, dest)
  return
    select(src)
    and turtle.transferTo(dest)
    and turtle.getItemCount(src) == 0
end
 
 
--[[
  Tries to merge stacks, and group all items
  at the beginning of the inventory.
]]--
local function defragInventory()
  -- first part: merge stacks and fill early empty spots
  for src=16,2,-1 do
    if turtle.getItemCount(src) > 0 then
      local srcName = itemDetails(src)
      for dest=1,src-1 do
        if (turtle.getItemCount(dest) == 0 or srcName == itemDetails(dest))
           and moveStack(src, dest) then
          break
        end
      end
    end
  end
  -- second second: fill gaps caused by merging stacks
  local gap = findInventoryGap()
  if gap then
    for src=16,gap+1,-1 do
      if turtle.getItemCount(src) > 0 then
        for dest=1,src-1 do
          if turtle.getItemCount(dest) == 0 and moveStack(src, dest) then
            break
          end
        end
      end
    end
  end
end
 
 
--[[
  merges stacks and removes gaps in the inventory
]]--
local function compressInventory()
  -- iterate through inventory
  for i=1,16 do
    if turtle.getItemCount(i) > 0 then
      local success =
          -- try to use item as fuel
          useFuelItem(i)
          -- see if it can be thrown away
          or dropWaste(i)
          -- maybe it can be transmuted
          or transmuteItem(i)
    end
  end
  -- merge stacks and remove gaps
  defragInventory()
end
 
 
--[[
  Returns if inventory is full.
  If it is full, attempts to free up
  some space first.
]]--
local function isInventoryFull()
  if turtle.getItemCount(16) == 0 then
    return false
  end
  compressInventory()
  -- ensure that some slots are free after cleaning up,
  -- otherwise cleaning up the inventory will eat up more time
  -- than just going home and dropping items
  return turtle.getItemCount(14) > 0
end
 
 
--[[
  Makes the turtle return to the
  starting position and empty
  it's inventory in a chest if
  one is available.
]]--
local function backHome( continueAfterwards )
  -- move up to depth 0
  local lastDepth = quarry.depth
  local lastFacing = quarry.facing
  while quarry.depth > 0 do
    up()
    quarry.depth = quarry.depth - 1
  end
 
  -- go home in x-direction
  local lastX = quarry.posx
  if lastX > 1 then
    while quarry.facing ~= direction.left do
      turnLeft()
    end
    while quarry.posx > 1 do
      forward()
    end
  end
 
  -- go home in y-direction
  local lastY = quarry.posy
  while quarry.facing ~= direction.back do
    turnLeft()
  end
  while quarry.posy > 1 do
    forward()
  end
  
  -- go up the offset
  if quarry.offsetH > 0 then
    for i=1,quarry.offsetH do
      up()
    end
  end
  
  -- WE ARE HOME NOW
  
  compressInventory()
 
  -- refuel if configured
  if quarry.fuelSources then
    status("Trying to use fuel...", colors.lightBlue)
    for i=1,16 do
      useFuelItem(i)
    end
  end
  
  -- drop items
  local isEmpty = isInventoryEmpty()
  if (not isEmpty) then
    dropItemsInChest() -- empty inventory guaranteed after return
    isEmpty = true
  end
    
  -- save mined blocks list
  saveMinedBlocks()
  
  -- CONTINUE WORK IF NECESSARY
  if continueAfterwards then
    while (not checkFuel(lastX, lastY, lastDepth, 2, true)) or (not isEmpty) do
      sleep(3)
      isEmpty = isInventoryEmpty()
    end
    status("Continuing work...", colors.lime)
    
    -- go down the offset
    if quarry.offsetH > 0 then
      for i=1,quarry.offsetH do
        down()
      end
    end
 
    -- back to hole in y-direction
    while quarry.facing ~= direction.front do
      turnLeft()
    end
    while quarry.posy < lastY do
      forward()
    end
 
    -- back to hole in x-direction
    if lastX > 1 then
      while quarry.facing ~= direction.right do
        turnRight()
      end
      while quarry.posx < lastX do
        forward()
      end
    end
 
    -- back down the hole
    while quarry.depth < lastDepth do
      down()
      quarry.depth = quarry.depth+1
    end
 
    while quarry.facing ~= lastFacing do
      turnLeft()
    end
  end
end
 
 
local inspectBlocks = (quarry.ignore or quarry.allow)
                      and true or false -- convert to boolean
 
--[[
  Checks the blocks on the four adjacent 
  sides for desired blocks.
  A block is mined if it does not match
  any block in the ignore table, or
  is listed in the allow table.
]]--
local function digSides()
  for i=1,4 do
    local digIt = turtle.detect()
    if digIt and inspectBlocks then
      local success, data = turtle.inspect()
      if success then
        digIt = isDesired(data.name)
        if digIt and quarry.rememberBlocks then
          quarry.minedBlocks[data.name] = true
        end
      end
    end
    if digIt then
      select(1)
      turtle.dig()
      if isInventoryFull() then
        backHome(true)
      end
    end
    turnLeft()
  end  
end
 
--[[
  Convenience function to check for a block below before digging down
]]--
local function drill()
  if turtle.detectDown() then
    select(1)
    turtle.digDown()
    if isInventoryFull() then
      backHome(true)
    end
  end
end
 
--[[
  Digs down a colum, only taking the blocks
  which are not in the compare slots.
]]--
local function digColumn()
  drill()
  while true do
    if not checkFuel(quarry.posx, quarry.posy, quarry.depth, 1, false) then
      backHome(true)
    end
    
    if not turtle.down() then
      drill()
      if not turtle.down() then
        break
      end
    end
    quarry.depth = quarry.depth + 1
    if isInventoryFull() then
      backHome(true)
    end
    digSides()
    
    -- check if maxDepth is reached
    if (quarry.maxDepth > 0) and (quarry.depth >= quarry.maxDepth) then
      break;
    end
    
    drill()
  end
 
  while quarry.depth > 0 do
    up()
    quarry.depth = quarry.depth - 1
  end
  
  status("Hole at x:"..tostring(quarry.posx).." y:"..tostring(quarry.posy).." is done.", colors.lightBlue)
end
 
-- go forward for a number of steps, and check fuel level and inventory filling on the way
local function stepsForward(count)
  if (count > 0) then
    for i=1,count do
      if not checkFuel(quarry.posx, quarry.posy, quarry.depth, 1, false)
          or isInventoryFull() then
        backHome(true)
      end
      forward()
    end
  end
end
 
 
local function calculateSkipOffset()
  local running = true
  
  local facing = direction.front
  local x = 1
  local y = 1
  
  while running do
    quarry.skipHoles = quarry.skipHoles - 1
    
    -- check for finish condition 
    if (x == quarry.width) then
      if ((facing == direction.front) and ((y + 5) > quarry.length))
          or ((facing == direction.back) and ((y-5) < 1)) then
        running = false
      end
    end
    
    if running then
      -- find path and go to next hole
      if facing == direction.front then
        if y+5 <= quarry.length then
          -- next hole in same line
          y = y+5
        elseif y+3 <= quarry.length then
          -- next hole in next column, above the current positon
          y = y+3
          x = x+1
          facing = direction.back
        else
          -- next hole in next column, below the current positon
          x = x+1
          facing = direction.back
          y = y-2
        end
      elseif facing == direction.back then
        if y-5 >= 1 then
          -- next hole in same line
          y = y-5
        elseif y-2 >= 1 then
          -- next hole in next column, below the current positon
          y = y-2
          x = x+1
          facing = direction.front
        else
          -- next hole in next column, above the current positon
          x = x+1
          facing = direction.front
          y = y+3
        end
      end
    end
    
    if (quarry.skipHoles <= 0) then
      break
    end
  end
  
  return x,y,facing,running
end
 
 
local function main()
  status("Working...", colors.lightBlue)
 
  local running = true
  
  -- check initial fuel level
  while (not checkFuel(quarry.posx, quarry.posy, quarry.offsetH, 2, true)) do
    sleep(3)
  end
  
  -- go down the offset
  if quarry.offsetH > 0 then
    for i=1,quarry.offsetH do
      down()
    end
  end
  
  -- are there holes to skip?
  if (quarry.skipHoles > 0) then
    local x,y,facing
    x,y,facing, running = calculateSkipOffset()
    status("Skip offset: x="..tostring(x).." y="..tostring(y), colors.lightBlue)
    if running then
      stepsForward(y-1)
      turnRight()
      stepsForward(x-1)
      while (quarry.facing ~= facing) do
        turnLeft()
      end
    end
  end
  
  while running do
    
    -- remember facing
    local lastFacing = quarry.facing
    digColumn()
    -- restore facing if necessary
    while quarry.facing ~= lastFacing do
      turnLeft()
    end
    
    -- check for finish condition 
    if (quarry.posx == quarry.width) then
      if ((quarry.facing == direction.front) and ((quarry.posy + 5) > quarry.length))
          or ((quarry.facing == direction.back) and ((quarry.posy-5) < 1)) then
        running = false
      end
    end
    
    if running then
      -- find path and go to next hole
      if quarry.facing == direction.front then
        if quarry.posy+5 <= quarry.length then
          -- next hole in same line
          stepsForward(5)
        elseif quarry.posy+3 <= quarry.length then
          -- next hole in next column, above the current positon
          stepsForward(3)
          turnRight()
          stepsForward(1)
          turnRight()
        else
          -- next hole in next column, below the current positon
          turnRight()
          stepsForward(1)
          turnRight()
          stepsForward(2)
        end
        
      elseif quarry.facing == direction.back then
        if quarry.posy-5 >= 1 then
          -- next hole in same line
          stepsForward(5)
        elseif quarry.posy-2 >= 1 then
          -- next hole in next column, above the current positon
          stepsForward(2)
          turnLeft()
          stepsForward(1)
          turnLeft()
        else
          -- next hole in next column, below the current positon
          turnLeft()
          stepsForward(1)
          turnLeft()
          stepsForward(3)
        end
      else
        -- this should not happen, but in case it does, we just send the turtle home.
        running = false
      end
    end    
  end
  status("Finished quarry. Returning home...", colors.lime)
  
  backHome(false)
  
  status("Done.", colors.lightBlue)
end
 
--  +-----------------------+  --
--  |-->  program start  <--| --
--  +-----------------------+  --
 
main()
