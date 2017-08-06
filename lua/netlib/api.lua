function LoadPlugin(plugin)
end

function UnloadPlugin(plugin)
end

function ReloadPlugin(plugin)
end

function LoadPlugins()
  local PluginCount = table.getn(plugins)
  Log("notice","Found " .. PluginCount .. " Plugins")
  if PluginCount == 0 then
    Log("notice","No Plugins found")
  elseif PluginCount > 0 then
    for i=1,PluginCount do
      Log("notice","Loading " .. plugins[i])
      assert(require("plugins." .. plugins[i]))
    end
  else
    Log("error","Invalid LoadMap")
    return
  end
end

function WriteConfig()
end

function ReadConfig()
end

function AddToLoadMap(plugin)
end

function RemoveFromLoadMap(plugin)
end

function CreateLoadMap()
  Log("notice","Creating new LoadMap")
  local file = io.open("LoadMap", "w")
  file:write("[]")
  file:close()
end

function ReadLoadMap()
  Log("notice","Reading LoadMap.lua")
  local file = io.open("LoadMap.lua", "r")
  if not file then
    Log("notice","LoadMap not found")
    CreateLoadMap()
    return
  end
  file:close()
  require("./LoadMap")
end


function Startup()
  Log("notice","Starting Plugin Routine")
  ReadLoadMap()
  LoadPlugins()
end