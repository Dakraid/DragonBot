local public        = {}

local Config        = require('config')
local DefaultPerms  = GetMainConfig("defaultclearance")

local Users         = require('userlist')
local Blacklist     = require('blacklist')

function public.CheckBlacklist(user)
  local id = user.id
  if discordia.extensions.table.search(Blacklist,id) then
    return true
  else
    return false
  end
end

function public.CheckPermission(user,level)
  local clearance = Users[user.id]
  if not clearance then clearance = DefaultPerms end
  if clearance >= level then
    return true
  else
    return false
  end
end

return public