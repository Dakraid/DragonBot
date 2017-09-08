local public = {}

local Config    = require('config')
local Trigger   = GetMainConfig("trigger")

local Commands  = require('./commands')
local Special   = require('./special')

local logger    = require('./logger')

local plugins

function public.Initialize()
  logger.Log("notice","Starting Init Process")
  
  local definition
  plugins = require('../plugins/pluginlist')
  
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

function public.GetPlugins()
  return plugins
end

return public