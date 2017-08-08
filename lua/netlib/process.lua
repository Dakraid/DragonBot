local public      = {}

local Config      = require('config')
local Trigger     = GetConfig("trigger")

local Commands    = require('./commands')

local Tokens      = {}
local out_message, out_author, out_repeat

local Permissions    = require('./permissions')
local Factoids    = require('./factoids')

function public.ProcessMessage(content,user,member,guild)
  if not content then return end
  if not user then return end
  if content:find(Trigger) == 1 then
    Tokens = Tokenize(content)
    if not Permissions.CheckBlacklist(user) then
      if Permissions.CheckPermission(user,0) then
        if not CheckCommand(Tokens[1]) then
          out_message, out_author, out_repeat = Factoids.Process(Tokens,user)
        else
          out_message, out_author, out_repeat = ProcessCommand(user,member,guild,Tokens)
        end
      end
    end
    return out_message, out_author, out_repeat
  end
end

function ProcessCommand(user,member,guild,Tokens)
  local command = Tokens[1]:lower()
  out_author  = user.username
  if command     == Trigger .. "help" then
    out_message = "Facts can be called by using '!key'"
  end
  if Permissions.CheckPermission(user,1) then
    if command     == Trigger .. "connect" then
      out_message   = Factoids.Connect()
    elseif command == Trigger .. "reconnect" then
      out_message   = Factoids.Reconnect()
    elseif command == Trigger .. "disconnect" then
      out_message   = Factoids.Disconnect()
    elseif command == Trigger .. "lockdb" then
      out_message   = Factoids.LockDatabase()
    elseif command == Trigger .. "unlockdb" then
      out_message   = Factoids.UnlockDatabase()
    elseif command == Trigger .. "forget" then
      out_message   = Factoids.FactRemove(Tokens,Trigger)
    elseif command == Trigger .. "no" then
      out_message   = Factoids.FactReplace(Tokens,Trigger,user)
    elseif command == Trigger .. "listkeys" then
      out_message   = Factoids.ListKeys()
      out_repeat    = true
    end
  end
  return out_message, out_author, out_repeat
end

--[[
    Utility Functions
--]]

function Tokenize(content)
  local tkns = {}
  local cnt  = 0
  for token in string.gmatch(content, "%S+") do
    cnt       = cnt + 1
    tkns[cnt] = token
  end
  return tkns
end

-- Returns true if the command has been found in the list
function CheckCommand(content)
  local tmp = content:sub(2)
  if table.find(Commands,tmp) then
    return true
  else
    return false
  end
end

return public