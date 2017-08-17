local public      = {}

local Config      = require('config')
local Trigger     = GetMainConfig("trigger")

local Commands    = require('./commands')

local Tokens      = {}
local out_message, out_author, out_repeat

local Permissions = require('./permissions')
local Factoids    = require('./factoids')

function public.ProcessMessage(content,user)
  -- Abort if either content or user is empty
  if not content then return end
  if not user then return end
  
  -- Check if the trigger is at the expected position and if there is an actual input
  if content:find(Trigger) == 1 and content:len() > 1 then
    if not Permissions.CheckBlacklist(user) and Permissions.CheckPermission(user,0) then
        out_message, out_author = Factoids.Process(content,user)
    end
    return out_message, out_author, out_repeat
  end
end

function ProcessCommand(content,user)
  return out_message, out_author, out_repeat
end

--[[
    Utility Functions
--]]

function Quit()
  Factoids.Disconnect()
  os.exit()
end

return public