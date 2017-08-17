local logger    = require('./logger')
local perms     = require('./permissions')

local mconfig   = require('config')
local trigger   = GetMainConfig("trigger")

local fconfig   = require('factconfig')
local db_name   = GetFactConfig("database_name")

local public    = {}

local database, db_conn, db_lock

function public.Process(content,user)
  local key,fact = GetComponents(content)
  
  if Connect() then
    if key and not fact then
      FactGet(key)
    elseif key and fact then
      if content:find("(is)(%s*)(also)") then
        FactAppend(key,fact,user)
      else
        FactAdd(key,fact,user)
      end
    end
  else
    logger.Log("warning","Could not connect to database")
  end
  
  return output, author
end

--Component Functions--
function GetComponents(content)
  local key = content:match(trigger .. "(.-)" .. "%sis")
  if not key then
    key = content:match(trigger .. "(.*)")
  end
  if key then
    key = CleanComponent(key)
    key = key:lower()
  end
  
  local fact = content:match("%sis" .. "(.*)$")
  if fact then
    fact = CleanComponent(fact)
  end
  
  return key,fact
end

function CleanComponent(content)
  content = content:gsub("(%s*)$","")
  content = content:gsub("^(%s*)","")
  return content
end

--Factoid Functions--
function FactGet(key)
  local fact = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
  
  if not fact then
    fact = "Nothing found for that key"
  end
  
  if fact:find("''") then
    fact = fact:gsub("''","'")
  end
  
  if fact:find("<is>") then
    fact = key .. " " .. fact:gsub("<is>", "is") 
  elseif fact:find("<reply>") then
    fact = fact:gsub("<reply>", "")
  end
  
  if fact:find("~+.") then
    local param
    for i=1,max do
      if tokens[i]:find("~+.") then
        param = tokens[i]
        param = param:sub(2)
      end
    end
    if param then
      fact = fact:gsub("~([^%p%s]*)",param)
    else
      fact = fact:gsub("~([^%p%s]*)","placeholder")
    end
  end
  return fact
end

--Database Functions--
function Connect()
  if not db_name then 
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
    logger.Log("notice","Database '" .. db_name .. "' connected")
    return true
  end
end

return public