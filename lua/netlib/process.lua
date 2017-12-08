local public      = {}

local Config      = require('config')
local Trigger     = GetMainConfig("trigger")

local Commands    = require('./commands')
local Special     = require('./special')
local Defaults    = {"help","quit","debug"}

local Tokens      = {}
local out_message, out_author, out_repeat

local logger      = require('./logger')
local loader      = require('./loader')
local perms

local d_table     = discordia.extensions.table
local d_string    = discordia.extensions.string

---Utility Functions---
local function CheckCommand(command)
  if d_table.search(Commands,command) then
    return true
  else
    return false
  end
end

local function Help(user)
  local text_commands = "Following commands are available: " .. table.concat(Commands, ", ") .. "\n"
  local text_help = "More help text coming soon."
  for i,plugin in pairs(loader.GetPlugins()) do
    text_help = plugin["GetProperty"]("name") .. ": " .. plugin["GetProperty"]("help") .. "\n"
  end
  text = text_commands .. text_help
  return text, user.fullname
end

local function Quit()
  logger.Close()
  os.exit()
end

local function Debug(guild)
  return perms.PrintRoles(guild)
end

---Public Functions---
function public.GetDefaults()
  return Defaults
end

function public.ProcessMessage(content,user,member,guild)
  if not (content and user and member and guild) then return end
  
  if content:find(Trigger) == 1 and content:len() > 1 then
    if not perms.CheckBlacklist(user) and perms.CheckPermission(user,0) then
      local command = content:match(Trigger .. "(%w*)")
      if CheckCommand(command) then
        if d_table.search(Defaults,command) then
          if command == "help" then
            out_message, out_author = Help(user)
          elseif command == "quit" then
            Quit()
          elseif command == "debug" then
            out_message = Debug(guild)
          end
        else
          for i,plugin in pairs(loader.GetPlugins()) do
            if plugin[command] then
              out_message, out_author = plugin[command](content,user,member,guild)
            end
          end
        end
      else
        if d_table.count(Special) > 0 then
          for i,plugin in pairs(loader.GetPlugins()) do
            local temp = plugin["GetProperty"]("special")
            if temp then
              out_message, out_author = plugin[temp](content,user)
            end
          end
        end
      end
    end
    return out_message, out_author, out_repeat
  end
end

function public.Init()
  perms = loader.GetPlugin("permissions")
end

return public
