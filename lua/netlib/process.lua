local public      = {}

local Config      = require('config')
local Trigger     = GetMainConfig("trigger")

local Commands    = require('./commands')
local Special     = require('./special')

local Tokens      = {}
local out_message, out_author, out_repeat

local logger    = require('./logger')
local perms     = require('./permissions')
local loader    = require('./loader')

local function CheckCommand(command)
  if table.find(Commands,command) then 
    return true
  else
    return false
  end
end

function public.ProcessMessage(content,user)
  -- Abort if either content or user is empty
  if not content then return end
  if not user then return end
  
  -- Check if the trigger is at the expected position and if there is an actual input
  if content:find(Trigger) == 1 and content:len() > 1 then
    if not perms.CheckBlacklist(user) and perms.CheckPermission(user,0) then
      local command = content:match(Trigger .. "(%w*)")
      if CheckCommand(command) then
        for i,plugin in pairs(loader.GetPlugins()) do
          if plugin[command] then
            out_message, out_author = plugin[command](content,user)
          end
        end
      else
        if table.count(Special) > 0 then 
          for i,plugin in pairs(loader.GetPlugins()) do
            local temp = plugin["GetProperty"]("special")
            if temp then
              out_message, out_author = plugin[temp](content,user)
            end
          end
        end
      end
    end
    --out_message, out_author = Special[1](content,user)
    return out_message, out_author, out_repeat
  end
end

--[[
    Utility Functions
--]]
function public.Test()
  print(table.tostring(Commands))
  print(table.tostring(Special))
  --for i,plugin in pairs(loader.GetPlugins()) do
  --end
end

function Quit()
  Factoids.Disconnect()
  os.exit()
end

return public