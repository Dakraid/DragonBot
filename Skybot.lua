local config    = require('config')

_G.sqlite       = require('sqlite3')
local discordia = require('discordia')
local client    = discordia.Client()

local netlib    = require('./lua/netlib')
local logger    = netlib.Logger
local prcs      = netlib.Process

client:on('ready', function()
	logger.Log("notice","Connecting...")
	logger.Log("notice","Connected as " .. client.user.username)
end)

client:on('messageCreate', function(message)
  -- Prevent the bot from triggering itself
  if message.author == client.user then return end
  
  -- Process the message and store the results
  local out_msg, out_athr = prcs.ProcessMessage(message.content,message.author)
  
  -- Check that out_msg is not empty
  if out_msg then
    -- If the return from the process includes a matching username PM the user
    if message.author.username == out_athr then
      message.author:sendMessage(out_msg, out_athr)
    else
      message.channel:sendMessage(out_msg)
    end
  end
end)

-- Debugging Interface
--[[
  local TestUser = {username = "TestBot", id = "123456"}
  repeat
    io.write("Please enter input: ")
    io.flush()
    local input = io.read()
    local out_msg, out_athr = prcs.ProcessMessage(input,TestUser)
    print("DEBUG: ",out_msg,out_athr)
  until input == "quit"
--]]
  
client:run(GetConfig("token"))