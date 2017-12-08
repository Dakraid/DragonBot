package.path = './?.lua;' .. package.path

_G.sqlite       = require('sqlite3')
_G.discordia    = require('discordia')
local client    = discordia.Client()

local config    = require('config')
local debugmode = GetMainConfig("debugmode")

_G.netlib       = require('./lua/netlib')
local process   = netlib.Process
local logger    = netlib.Logger
local loader    = netlib.Loader

local message, out_msg, out_athr

-- Local Functions
local function Processer()
    out_msg, out_athr = process.ProcessMessage(message.content,message.author,message.member,message.guild)
end

local function ErrorHandler(x)
    local file = io.open("error.txt", "a")
    local output
    local time = os.time()
    time = os.date('%Y-%m-%d %H:%M:%S', time)
    output = "[" .. time .. "] [ERROR]: " .. x .. "\n" .. "[" .. time .. "] [TRACE]: " .. debug.traceback()
    file:write("\n" .. output)
    file:flush()
end

client:on('ready', function()
    logger.Log("notice","Connecting...")
    logger.Log("notice","Connected as " .. client.user.username)
end)

-- Event-based Functions
client:on('messageCreate', function(msg)
    -- Prevent the bot from triggering itself
    message = msg
    if message.author == client.user then return end

    -- Process the message
    -- The current protected call is currently a dirty hack
    -- The next iteration should properly integrate the protected calls in the respective places
    xpcall(Processer, ErrorHandler)

    -- Check that out_msg is not empty
    if out_msg then
        -- If the return from the process includes a matching username PM the user
        if message.author.username == out_athr then
            message.author:send(out_msg, out_athr)
        else
            message.channel:send(out_msg)
        end
    end
    out_msg, out_athr = nil, nil
end)

-- Start of Initialization
loader.Init()
process.Init()
-- End of Initialization

-- Debugging Interface
if debugmode == true then
    local TestUser = {username = "TestBot", id = "123456"}
    repeat
        io.write("Please enter input: ")
        io.flush()
        local input = io.read()
        local out_msg, out_athr = process.ProcessMessage(input,TestUser)
        print("OUTPUT: ",out_msg,out_athr)
    until input == "quit"
end

client:run("Bot " .. GetMainConfig("token"))
