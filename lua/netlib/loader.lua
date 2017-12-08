local public    = {}

local Config    = require('config')
local Trigger   = GetMainConfig("trigger")

local Commands  = require('./commands')
local Special   = require('./special')
local Logger    = require('./logger')

local Registry  = require('../plugins/pluginlist')

function RegisterPlugins(plugins)
  for i,plugin in pairs(plugins) do
    definition = plugin["Init"]()
    
    if definition["commands"] then
      for i,command in pairs(definition["commands"]) do
        table.insert(Commands,command)
      end
    end
    
    if definition["special"] then
      table.insert(Special,definition["special"])
    end
  end
end

function public.Init()
  local definition
  
  Logger.Log("notice","Starting Init Process")
  
  Logger.Log("notice","Loading Priority Plugins...")
  local priorities = Registry.LoadPriorities()
  Logger.Log("notice","...Finished")
  
  Logger.Log("notice","Registering Priority Plugins...")
  RegisterPlugins(Registry.register)
  Logger.Log("notice","...Finished")
  
  Logger.Log("notice","Loading Normal Plugins...")
  local plugins = Registry.LoadPlugins()
  Logger.Log("notice","...Finished")
  
  Logger.Log("notice","Registering Normal Plugins...")
  RegisterPlugins(Registry.register)
  Logger.Log("notice","...Finished")
  
  Logger.Log("notice","Finished Init Process")
end

function public.GetPlugins()
  if next(Registry.register) == nil then
    return nil
  else
    return Registry.register
  end
end

function public.GetPlugin(name)
  local result = Registry.register[name] 
  if result then
    return Registry.register[name]
  else
    return nil
  end
end

return public