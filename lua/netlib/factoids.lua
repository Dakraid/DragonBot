local logger    = require('./logger')
local perms     = require('./permissions')

local Config    = require('factconfig')
local db_name   = GetConfig("database_name")

local public    = {}

local database
local db_conn   = false
local db_lock   = false

local max_split = 4

function public.Process(tokens,user)
  local output
  local author
  local marker = nil
  logger.Log("notice","Entered Factoids.lua")
  -- Open connection to the SQLite database
  if not db_lock then
    public.Connect()
  end
  if db_conn then
    if KeepAlive() then
      for i=1,max_split do
        if tokens[i] == "is" then marker = i+1 end
      end
      local key = ConcatKey(tokens)
      logger.Log("notice","Compiled key is '" .. key .."'")
      if marker then
        if perms.CheckPermission(user,1) then
          output = FactAdd(key,tokens,marker,user)
          author = user.username
        end
      else
        output = FactGet(key,tokens,marker)
      end
    else
      logger.Log("warning","Database connection failed, reconnect was unsuccessful.")
    end
  else
    output = "Database is locked."
    logger.Log("notice","Database is not connected")
  end
  return output, author
end

function public.Reconnect()
  local output
  if not db_lock then
    if db_conn then
      if KeepAlive() then
        output = "Database reconnected."
        logger.Log("notice","Database has been reconnected")
      else
        output = "Database reconnection failed."
        logger.Log("notice","Database reconnect failed")
      end
    else
      public.Connect()
      output = "Database connected!"
    end
  else
    output = "Database is locked."
  end
  return output
end

function public.Connect()
  local name = db_name
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
  logger.Log("notice","Database connected")
  database = conn
end

function public.Disconnect()
  local output
  if db_conn then
    database:close()
    db_conn = false
    logger.Log("notice","Database has been disconnected")
    output = "Database disconnected."
  else
    output = "Database is already disconnected."
  end
  return output
end

function public.LockDatabase()
  local output
  if not db_lock then
    db_lock = true
    output = "Database locked."
    logger.Log("notice","Database locked")
  else
    output = "Database is already locked."
  end
  return output
end

function public.UnlockDatabase()
  local output
  if db_lock then
    db_lock = false
    output = "Database unlocked."
    logger.Log("notice","Database  unlocked")
  else
    output = "Database is already unlocked"
  end
  return output
end

function public.ListKeys()
  local output
  local tmp
  if db_conn then
    output = database:exec("select key from factoids")
  else
    if not db_lock then
      public.Connect()
      output = database:exec("select key from factoids")
    else
      output = "Database disconnected and locked."
    end
  end
  return output, 2
end

function KeepAlive()
  local validator = database:rowexec("SELECT validValue FROM validator WHERE validKey=='Valid'")
  if not validator then
    database:close()
    local conn = sqlite.open(db_name, "rw")
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
  if max >= max_split then max = max_split end
  for i=1,max do
    if tokens[i] == "is" then
      key = key:sub(1, -2)
      key = key:sub(2)
      key = key:lower()
      return key
    else
      if i == max then
        key = key .. tokens[i]
      else
        key = key .. tokens[i] .. " "
      end
    end
  end
  key = key:sub(2)
  key = key:lower()
  print(key)
  return key
end

function FactGet(key,tokens,min)
  local fact = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
  if not fact then
    fact = "Nothing found for that key"
  elseif string.find(fact, "<is>") then
    fact = key .. " " .. fact:gsub("<is>", "is") 
  elseif string.find(fact, "<reply>") then
    fact = fact:gsub("<reply>", "")
  end
  if fact:find("~s") then
    fact = fact:gsub("~s",tokens[min])
  end
  return fact
end

function FactAdd(key,tokens,min,user)
  local output
  local fact = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
  if not fact then
    fact = ""
    local max = table.count(tokens)
    local info = user.username .. " (ID: " .. user.id .. ")"
    local time = os.time()
    if max > 3 then
      for i=min,max do
        fact = fact .. tokens[i] .. " "
      end
    else
      fact = tokens[min] .. " "
    end
    fact = fact:sub(1, -2)
    database:rowexec("INSERT INTO factoids VALUES ('" .. key .. "','" .. info .. "','" .. time .. "',NULL,NULL,NULL,NULL,'" .. fact .. "',0)")
    logger.Log("notice","Added '" .. key .. "' with the content '" .. fact .. "'")
    output = "Fact has been added."
  else
    output = "That fact already exists."
  end
  return output
end

function public.FactRemove(tokens,trigger)
  local output
  if not db_conn and not db_lock then
    public.Connect()
  elseif not db_conn then
    output = "Database disconnected and locked."
    return output
  end
  if table.count(tokens) > 1 then
    table.remove(tokens, 1)
    tokens[1] = trigger .. tokens[1]
    local key = ConcatKey(tokens)
    local fact = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
    if fact then
      database:rowexec("DELETE FROM factoids WHERE key=='" .. key .. "'")
      logger.Log("notice","The fact with the key '" .. key .. "' and the content '" .. fact .. "'" .. " has been deleted")
      output = "Fact has been deleted."
    else
      output = "That fact doesn't exists."
    end
  end
  return output
end

function public.FactReplace(tokens,trigger,user)
  local output
  if not db_conn and not db_lock then
    public.Connect()
  elseif not db_conn then
    output = "Database disconnected and locked."
    return output
  end
  table.remove(tokens, 1)
  tokens[1] = trigger .. tokens[1]
  local key = ConcatKey(tokens)
  local fact = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
  if fact then
    fact = ""
    local min
    for i=1,max_split do
      if tokens[i] == "is" then min = i+1 end
    end
    local max = table.count(tokens)
    local info = user.username .. " (ID: " .. user.id .. ")"
    local time = os.time()
    if max > 3 then
      for i=min,max do
        fact = fact .. tokens[i] .. " "
      end
    else
      fact = tokens[min] .. " "
    end
    fact = fact:sub(1, -2)
    database:rowexec("REPLACE INTO factoids VALUES ('" .. key .. "','" .. info .. "','" .. time .. "',NULL,NULL,NULL,NULL,'" .. fact .. "',0)")
    logger.Log("notice","Replaced '" .. key .. "' with the content '" .. fact .. "'")
    output = "Fact has been replaced."
  else
    output = "That fact doesn't exists."
  end
  return output
end  

-- These function are yet to be implemented
--[[

function FactAppend()
end

--]]

return public