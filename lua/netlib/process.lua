local public      = {}

local Config      = require('config')
local Trigger     = GetConfig("trigger")

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
  if Tokens[1]     == Trigger .. "help" then
    out_message = "Facts can be called by using '!key'"
    out_author  = user.username
  elseif Tokens[1] == Trigger .. "reconnect" and CheckPermission(user,0) then
    out_message = Factoids.Reconnect()
    out_author  = user.username
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
  local users = {netrve = 0}
  local tmp = user.username
  if users[tmp] == level then
    return true
  else
    return false
  end
end

return public