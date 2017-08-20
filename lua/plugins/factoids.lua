local definition  = {name = "factoids", version = "2.0", commands = {"no","forget","reloaddb"}, special = "process"}
local public      = {}

local netlib      = require('../../lua/netlib')
local logger      = netlib.Logger
local perms       = netlib.Permissions

local mconfig     = require('config')
local trigger     = GetMainConfig("trigger")

local fconfig     = require('factconfig')
local db_name     = GetFactConfig("database_name")

local log_msg     = {
    [101] = "Database '" .. db_name .. "' connected",
    [102] = "Database '" .. db_name .. "' disconnected",
    [103] = "Database '" .. db_name .. "' reloaded",
    [104] = "Could not connect to database '" .. db_name .. "'",
    [105] = "Database name returned invalid value nil"
}

local database, db_conn

--Component Functions--
local function CleanComponent(content)
  content = content:gsub("(%s*)$","")
  content = content:gsub("^(%s*)","")
  return content
end

local function GetComponents(content)
  local key = content:match(trigger .. "(.-)" .. "%sis")
  if not key then
    key = content:match(trigger .. "(.*)")
  end
  if key then
    if key:find("~(%w*)") then
      key = key:gsub("~(%w*)","")
    end
    key = CleanComponent(key)
    key = key:lower()
  end
  
  local fact = content:match("%sis" .. "(.*)$")
  if fact then
    fact = CleanComponent(fact)
  end
  
  return key,fact
end

--Database Functions--
local function Connect()
  if db_conn then
    return true
  else
    if not db_name then 
      logger.Log("warning",log_msg[105])
      return false
    else
      database = sqlite.open(db_name)
      database:exec[[
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
      logger.Log("notice",log_msg[101])
      return true
    end
  end
end

local function Disconnect()
  if db_conn then
    database:close()
    db_conn = false
    logger.Log("notice",log_msg[102])
  end
end

--Factoid Functions--
local function FactGet(key,content)
  local fact = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
  
  if not fact then
    fact = "Nothing found for the key '" .. key .. "'" 
  end
  
  if fact:find("''") then
    fact = fact:gsub("''","'")
  end
  
  local insert = content:match("~(%w*)")
  if insert then
    fact = fact:gsub("~([^%p%s]*)",insert)
  else
    fact = fact:gsub("~([^%p%s]*)","Placeholder")
  end

  return fact
end

--Public Functions--
function public.process(content,user)
  local key,fact = GetComponents(content)
  
  if Connect() then
    if key and not fact then
      output = FactGet(key,content)
    elseif key and fact then
      if content:find("(is)(%s*)(also)") then
        output,author = FactAppend(key,fact,user)
      else
        output,author = FactAdd(key,fact,user)
      end
    end
  else
    logger.Log("warning",log_msg[104])
  end
  
  return output, author
end

function public.no()
  print("Factoids' 'no' has been called")
end

function public.forget()
  print("Factoids' 'forget' has been called")
end

function public.reloaddb()
  Disconnect()
  Connect()
  logger.Log("notice",log_msg[103])
end

function public.Init()
  if Connect() then
    return definition
  else
    return false
  end
end

return public