local version = 1.1
if _UD and _UD.su(version, "fw5C7u8t", {...}) then return end
 
local IGNOREFILE = "ignore.list"
local editWhenDone = false
 
local ignore = {
  ["minecraft:stone"] = true,
  ["minecraft:cobblestone"] = true,
  ["minecraft:dirt"] = true
}
 
if fs.exists(IGNOREFILE) then
  local file = fs.open(IGNOREFILE, "r")
  local content = file.readAll()
  local list = textutils.unserialize(content)
  ignore = {}
  for _,name in pairs(list) do
    ignore[name] = true
  end
end
 
local function inspect()
  local previous = nil
  while true do
    local ok, data = turtle.inspect()
    if ok then
      local block = data.name
      if block ~= previous then
        previous = block
        if ignore[block] then
          print("Already known "..block)
        else
          print("Added "..block)
          ignore[block] = true
        end
      end
    end
    sleep(0.1)
  end
end
 
local function waitForKey()
  local event, char = os.pullEvent("char")
  if char == "e" then
    editWhenDone = true
  end
end
 
local function storeToFile()
  -- convert to list
  local list = {}
  for name,_ in pairs(ignore) do
    list[#list+1] = name
  end
  -- write to file
  local file = fs.open(IGNOREFILE,"w")
  file.write(textutils.serialize(list))
  file.close()
end
 
 
--- main part
print("Place Blocks that should be ignored by")
print("the quarry in front of the turtle.")
print("Press any alphanumeric key to stop the")
print(" program and store the ignore list.")
print("Regular stone, cobble, and dirt are")
print(" added by default.")
print("Press 'e' if you want to open the file")
print("for editing afterwards.")
print()
 
parallel.waitForAny(inspect, waitForKey)
 
storeToFile()
 
if editWhenDone then
  shell.run("edit "..IGNOREFILE)
end
