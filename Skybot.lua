local config    = require('config')
local debugmode = GetConfig("debugmode")

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
  local out_msg, out_athr, out_rpt = prcs.ProcessMessage(message.content,message.author,message.member,message.guild)
  
  -- Check that out_msg is not empty
  if out_msg then
    -- If the return from the process includes a matching username PM the user
    if message.author.username == out_athr then
      if out_rpt then
        local count = table.getn(out_msg[1])
        local split = math.floor(count / 2)
        message.author:sendMessage(MultiMessage(out_msg[1],1,split), out_athr)
        message.author:sendMessage(MultiMessage(out_msg[1],split,count), out_athr)
      else
        message.author:sendMessage(out_msg, out_athr)
      end
    else
      message.channel:sendMessage(out_msg)
    end
  end
end)

function MultiMessage(content,start,length)
  local split_msg = ""
  for i=start,length do
    if i == length then
      split_msg = split_msg .. content[i]
    else
      split_msg = split_msg .. content[i] .. ", "
    end
  end
  return split_msg
end

-- Debugging Interface
if debugmode == true then
  local TestUser = {username = "TestBot", id = "123456"}
  repeat
    io.write("Please enter input: ")
    io.flush()
    local input = io.read()
    local out_msg, out_athr, out_rpt = prcs.ProcessMessage(input,TestUser)
    if out_rpt then
      local count = table.getn(out_msg[1])
      local first = math.floor(count / 2)
      local split_msg = ""
      for i=1,first do
          split_msg = split_msg .. out_msg[1][i] .. ", "
      end
      print("DEBUG: ",split_msg,out_athr)
      split_msg = ""
      for i=first,count do
          split_msg = split_msg .. out_msg[1][i] .. ", "
      end
      print("DEBUG: ",split_msg,out_athr)
    else
      print("DEBUG: ",out_msg,out_athr)
    end
  until input == "quit"
end

client:run(GetConfig("token"))