local public      = {}

local Config      = require('config')
local Trigger     = GetConfig("trigger")

local Users       = require('userlist')
local Blacklist   = require('blacklist')
local Commands    = require('./commands')

local Tokens      = {}
local out_message, out_author

local Factoids    = require('./factoids')

function public.ProcessMessage(content,user)
  if not content then return end
  if not user then return end
  
  if content:find(Trigger) == 1 then
    Tokens = Tokenize(content)
    if not CheckBlacklist(user) then
      --if CheckPermission(user) then
        if not CheckCommand(Tokens[1]) then
          out_message = Factoids.Process(Tokens)
        else
          out_message, out_author = ProcessCommand(user)
        end
      --else
      --  out_message = nil
      --  out_author  = nil
      --end
    else
      out_message = nil
      out_author  = nil
    end
    return out_message, out_author
  end
end

function ProcessCommand(user)
  local command = Tokens[1]:lower()
  if command     == Trigger .. "help" then
    out_message = "Facts can be called by using '!key'"
    out_author  = user.username
  elseif command == Trigger .. "listkeys" then
    out_message = Factoids.ListKeys()
    out_author  = user.username
  end
  if CheckPermission(user,0) then
    if command == Trigger .. "connect" then
      out_message = Factoids.Connect()
      out_author  = user.username
    elseif command == Trigger .. "reconnect" then
      out_message = Factoids.Reconnect()
      out_author  = user.username
    elseif command == Trigger .. "disconnect" then
      out_message = Factoids.Disconnect()
      out_author  = user.username
    elseif command == Trigger .. "lockdb" then
      out_message = Factoids.LockDatabase()
      out_author  = user.username
    elseif command == Trigger .. "unlockdb" then
      out_message = Factoids.UnlockDatabase()
      out_author  = user.username
    end
  end
  return out_message, out_author
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

--[[
    Privilege Check Functions
--]]

-- Returns true if the user has been found in the blacklist
function CheckBlacklist(user)
  local id = user.id
  if table.find(Blacklist,id) then
    return true
  else
    return false
  end
end

function CheckPermission(user,level)
  local tmp = user.username:lower()
  if Users[tmp] == level then
    return true
  else
    return false
  end
end

return public