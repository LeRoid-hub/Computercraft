local version = 1.2
 
--  +------------------------+  --
--  |-->  INITIALIZATION  <--|  --
--  +------------------------+  --
if not turtle then
  print("This program can only be")
  print("  executed by a turtle!")
  return
end
 
-- UPDATE HANDLING --
if _UD and _UD.su(version, "5pFNPRZv", {...}) then return end
 
local requiredFiles = {
  quarryFile = {"quarry.lua", "HqXCPzCg", false},
  oreDictConfigFile = {"oredict.config", "iPPApNHk", true},
  ignoreListFile = {"ignore.list", "ymBVBbt1", true},
}
 
-- ensure all files needed are installed
for k,fileInfo in pairs(requiredFiles) do
  local name = fileInfo[1]
  local pbKey = fileInfo[2]
  local forceDownload = fileInfo[3]
  if not fs.exists(name) or forceDownload then
    fs.delete(name)
    shell.run("pastebin get "..pbKey.." "..name)
    if not fs.exists(name) then
      print("Unable to download "..name)
      return
    end
  end
end
 
shell.run("quarry l:16 w:16  offh:2 oredict remember-blocks")
