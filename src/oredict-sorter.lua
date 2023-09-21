local version = 1.61
--  +------------------------+  --
--  |-->  INITIALIZATION  <--|  --
--  +------------------------+  --
if not turtle then
  print("This program can only be")
  print("executed by a turtle.")
  return
end
 
-- UPDATE HANDLING --
if _UD and _UD.su(version, "94eCzump", {...}) then return end
 
local ARGS = {...}
 
 
local stackDrops = false
local config = {}
 
local CONFIG_FILE = "oredict.config"
 
local function writeConfig()
  local file = fs.open(CONFIG_FILE, "w")
  file.write(textutils.serialise(config))
  file.close()
end
 
if fs.exists(CONFIG_FILE) then
  local file = fs.open(CONFIG_FILE, "r")
  local content = file.readAll()
  config = textutils.unserialise(content)
  file.close()
else
  writeConfig()
end
 
-- check if interactive mode is desired
local interactive = false
 
for _,arg in pairs(ARGS) do
  if arg == "interactive" then
    interactive = true
    break
  end
end
 
-- find free slot
local slot = nil
for i=1,16 do
  if turtle.getItemCount(i) == 0 then
    slot = i
    break
  end
end
 
if not slot then
  print("Turtle needs a free slot to")
  print("run this program.")
  return
end
turtle.select(slot)
 
-- find ore dictionary
local od = peripheral.find("oreDictionary")
if not od then
  print("No ore dictionary attached.")
  return
end
 
local term = term
local colors = colors
 
local function statusLine(text)
  local x,y = term.getCursorPos()
  term.setCursorPos(x+2,y)
  print(text)
end
 
local function status(text, color, delay)
  term.clear()
  term.setCursorPos(1,1)
  if term.isColor() then
    term.setTextColor(colors.yellow)
  end
  print(" Ore Dict Item Sorter ")
  print("----------------------")
  print()
  
  if term.isColor() then
    if color == nil then
      color = colors.white
    end
    term.setTextColor(color)
  end
  
  if type(text) == "table" then
    for i=1,#text do
      statusLine(text[i])
    end
  else
    statusLine(text,color)
  end
  
  if term.isColor() then
    term.setTextColor(colors.white)
  end
 
  if delay then
    sleep(delay)
  end
end
 
 
local function itemDetails()
  local details = turtle.getItemDetail()
  return details.name.."#"..tostring(details.damage)
end
 
local function key()
  local event, c = os.pullEvent("char")
  return c
end
 
local function write(text)
  term.clearLine()
  local x,y = term.getCursorPos()
  term.setCursorPos(1,y)
  term.write(text)
end
 
local ignore = {}
 
local function chooseTarget()
  local statusText = {
    "Use as target item?",
    "y_es | n_ext | i_gnore"
  }
  while true do
    local name = itemDetails()
    statusText[3] = name
    status(statusText)
    k = key()
    -- save to config
    if k == "y" then
      local entries = od.getEntries()
      for _,entry in pairs(entries) do
        config[entry] = name
      end
      writeConfig()
      return true
    end
    -- add to ignore list
    if k == "i" then
      ignore[name] = true
      return false
    end
    -- transmute to next item
    if k == "n" then
      od.transmute()
    end
  end
end
 
 
local function unify()
  for _,entry in pairs(od.getEntries()) do
    local target = config[entry]
    if target then
      local name = itemDetails()
      local seen = {name=true}
      -- transmute to target as necessary
      while name ~= target do
        od.transmute()
        name = itemDetails()
        -- check if we tried all possibilities
        if seen[name] then
          -- TODO: log to file
          -- print(entry..": can't transmute '"..name.."' to target item")
          return false
        end
        seen[name] = true
      end
      return true
    end
  end
  
  if interactive then
    local name = itemDetails()
    if ignore[name] then
      return false
    end
    return chooseTarget()
  end
end
 
local function tryAction(name, fn)
  status(name, colors.lightBlue)
  local first = true
  while not fn() do
    if first then
      status("retry "..name, colors.orange)
      first = false
    end
    sleep(1)
  end
end
 
-- wraps drop function to only drop one item at once if configured
local function wrapDrop(dropFn)
  if stackDrops then
    return dropFn
  end
  return function()
    while turtle.getItemCount() > 0 do
      if not dropFn(1) then
        return false
      end
    end
    return true
  end
end
 
-- begin unification process
local suck = turtle.suckDown
local drop = wrapDrop(turtle.drop)
local dropOther = wrapDrop(turtle.dropUp)
 
local counter = 0
 
while true do
  tryAction("suck", suck)
  counter = counter + turtle.getItemCount()
  if unify() or not dropOther then
    -- drop known items
    tryAction("drop", drop)
  else
    -- drop unknown items
    tryAction("drop other", dropOther)
  end
  local monitor = peripheral.find("monitor")
  if monitor then
    monitor.clear()
    monitor.setCursorPos(2,2)
    monitor.write("Items sorted")
    monitor.setCursorPos(4,4)
    monitor.write(tostring(counter))
  end
end
