local logger    = require('./logger')

local public    = {}

local database
local db_conn   = false

local max_split = 4

--[[
Code Dump
        local locator = table.find(Tokens,"is")
        if locator then
          if locator <= 4 and Tokens[locator+1] ~= "also" then
            --FactAdd(locator)
            out_message = "This function is not implemented"
            out_author = nil
          end
        else
        end
        local key = ConcatKey()
        out_message = FactGet(key)
        out_author = nil
--]]

function public.Process(tokens)
  local output
  logger.Log("notice","Entered Factoids.lua")
  -- Open connection to the SQLite database
  database = ConnectDB()
  if db_conn then
    if KeepAlive() then
      local key = ConcatKey(tokens)
      logger.Log("notice","Compiled key is '" .. key .."'")
      output = FactGet(key)
    else
      logger.Log("warning","Database connection failed, reconnect was unsuccessful.")
    end
  end
  return output
end

function public.Reconnect()
  if db_conn then
    local output = ""
    if KeepAlive() then
      output = "Database reconnected!"
    else
      output = "Database reconnection failed!"
    end
  else
    ConnectDB()
    output = "Database connected!"
  end
  return output
end

function ConnectDB()
  local name = "Factoids.db"
  local conn = sqlite.open(name)
  conn:exec[[
  create table if not exists factoids(
    key TEXT PRIMARY KEY,
    created_by TEXT,
    created_at TIMESTAMP,
    modified_by TEXT,
    modified_at TIMESTAMP,
    locked_at TIMESTAMP,
    locked_by TEXT,
    fact TEXT,
    requested_count INTEGER
  );
  create table if not exists validator(
    validKey TEXT PRIMARY KEY,
    validValue BOOL
  );
  insert or replace into validator (validKey,validValue) values ("Valid","true");
  ]]
  db_conn = true
  logger.Log("notice","Database connected/created")
  return conn
end

function KeepAlive()
  local validator = database:rowexec("SELECT validValue FROM validator WHERE validKey=='Valid'")
  if not validator then
    local name = "Factoids.db"
    local conn = sqlite.open(name, "rw")
    database = conn
    validator = database:rowexec("SELECT validValue FROM validator WHERE validKey=='Valid'")
    logger.Log("notice","Database has been reconnected")
    logger.Log("notice","Database validator returned " .. validator)
    return validator
  else
    logger.Log("notice","Database status is healthy")
    logger.Log("notice","Database validator returned " .. validator)
    return validator
  end
end

function ConcatKey(tokens)
  local key = ""
  local max = table.count(tokens)
  for i=1,max do
    if i == max then
      key = key .. tokens[i]
    else
      key = key .. tokens[i] .. " "
    end
  end
  key = key:sub(2)
  key = key:lower()
  return key
end

function FactGet(key)
  local fact = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
  if not fact then
    fact = "Nothing found for that key"
  elseif string.find(fact, "<is>") then
    fact = key .. " " .. fact:gsub("<is>", "is") 
  elseif string.find(fact, "<reply>") then
    fact = fact:gsub("<reply>", "")
  end
  return fact
end

-- These function are yet to be implemented
--[[
function FactAdd(min)
  local max = table.count(Tokens)
  local key = Tokens[1]:sub(2)
  local fact = ""
  for i=min,max do
    fact = fact .. Tokens[i] .. " "
  end
  Log("notice","Added '" .. key .. "' with the content '" .. fact .. "'")
  return key, fact
end

function FactAppend()
end

function FactReplace()
end

function FactRemove()
end
--]]

return public