local public        = {}
local definition    = {commands = {"printroles","exportroles","printgroups","usergroup"}}
local permissions   = {owner = {"exportroles"}, admin = {"printroles","printgroups","usergroup"}}

local Config        = require('config')
local DefaultGroup  = GetMainConfig("defaultgroup")
local Trigger       = GetMainConfig("trigger")

local Userlist      = require('userlist')
local Blacklist     = require('blacklist')

local d_table       = discordia.extensions.table

local function CleanComponent(content)
    content = content:gsub("(%s*)$","")
    content = content:gsub("^(%s*)","")
    return content
end

local function GetComponents(content)
    local command = content:match(Trigger .. "(.-)" .. "%s")
    if not command then
        command = content:match(Trigger .. "(.*)")
    end
    if command then
        if command:find("~(%w*)") then
            command = command:gsub("~(%w*)","")
        end
        command = command:lower()
    end
    local parameter = content:match("%s" .. "(.*)$")
    if parameter then
        parameter = CleanComponent(parameter)
    end
    return command,parameter
end

local function WriteToFile(content,name)
  local file = io.open("Roles_" .. name .. ".txt", "w+")
  if not content then end
  file:write(content)
  file:close()
end

function public.CheckBlacklist(user)
  local id = user.id
  if d_table.search(Blacklist,id) then
    return true
  else
    return false
  end
end

-- MISSING: The command should automatically check if a plugin requires permissions and if so it should pull the group
function public.CheckPermission(user,group)
  local usergroup = Userlist.Users[user.id]
  if not usergroup then usergroup = DefaultGroup end
  if usergroup >= group then
    return true
  else
    return false
  end
end

function public.GetUserGroupID(command,parameter)
  if not (parameter and tonumber(parameter)) then return nil end
  local groupid = Userlist.Users[parameter]
  if not groupid then groupid = 0 end
  return groupid
end

function public.usergroup(content,user,member,guild)
  local command,parameter = GetComponents(content)
  if not parameter then parameter = user.id end
  if not tonumber(parameter) then parameter = user.id end
  local groupid = public.GetUserGroupID(command,parameter)
  if not groupid then return end
  local result = "\n```" .. guild:getMember(parameter).user.fullname .. " (ID:" .. parameter .. "): " .. Userlist.PermissionGroups[groupid] .. " (ID:" .. groupid .. ")```"
  return result
end

function public.printgroups()
  local result = "\n```"
  for id,group in pairs(Users.PermissionGroups) do
    result = result .. id .. ": " .. group .. "\n"
  end
  result = result .. "```"
  return result
end

function public.printroles(content,user,member,guild)
  local result = "\n```"
  local roles = guild.roles
  for id,role in pairs(roles) do
    result = result .. role.name .. " (ID: " .. id .. ")\n"
  end
  result = result .. "```"
  return result
end

function public.exportroles(content,user,member,guild)
  local result = ""
  local roles = guild.roles
  for id,role in pairs(roles) do
    result = result .. role.name .. " (ID: " .. id .. ")\n"
  end
  WriteToFile(result,guild.name)
  result = "Roles have been exported to Roles_" .. guild.name .. ".txt, which can be found in the bots directory"
  return result,user.username
end

function public.Init()
    return definition
end

function public.GetProperty(name)
    return definition[name]
end

return public