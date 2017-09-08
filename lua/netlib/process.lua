local public      = {}

local Config      = require('config')
local Trigger     = GetMainConfig("trigger")

local Commands    = require('./commands')
local Special     = require('./special')
local SysCmds     = {"help","quit"}

local Tokens      = {}
local out_message, out_author, out_repeat

local logger    = require('./logger')
local perms     = require('./permissions')
local loader    = require('./loader')

---Utility Functions---
local function CheckCommand(command)
    if table.find(Commands,command) then
        return true
    else
        return false
    end
end


local function Help(user)
    local text_commands = "Following commands are available: " .. table.concat(Commands, ", ") .. "\n"
    local text_help = "More help text coming soon."
    text = text_commands .. text_help
    print(text)
    return text, user.username
end

local function Quit()
    Factoids.Disconnect()
    os.exit()
end

---Public Functions---
function public.ProcessMessage(content,user)
    if not content then return end
    if not user then return end
    if content:find(Trigger) == 1 and content:len() > 1 then
        if not perms.CheckBlacklist(user) and perms.CheckPermission(user,0) then
            local command = content:match(Trigger .. "(%w*)")
            if CheckCommand(command) then
                if table.find(SysCmds, command) then
                    if command == "help" then
                        out_message, out_author = Help(user)
                    elseif command == "quit" then
                        Quit()
                    end
                else
                    for i,plugin in pairs(loader.GetPlugins()) do
                        if plugin[command] then
                            out_message, out_author = plugin[command](content,user)
                        end
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
        return out_message, out_author, out_repeat
    end
end

return public
