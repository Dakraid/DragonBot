local public = {}
local definition = {
  name = "factoids",
  version = "2.1",
  help = "New Facts can be added by using the bot trigger, a key and the fact like this '!x is y'. 'is' indicates the split between key and fact, everything before the 'is' will be considered as key, everything after as the fact. You can also replace keys by using 'no' before the actual key. Facts can be removed by placing 'forget' before the key. You can also append a fact to a key by using 'is also' instead of just 'is'.",
  commands = {"no", "forget", "reloaddb", "lock", "unlock"},
  special = "factoid"
}

local netlib = require('../../lua/netlib')
local logger = netlib.Logger
local loader = netlib.Loader
local perms = loader.GetPlugin("permissions")

local mconfig = require('config')
local trigger = GetMainConfig("trigger")

local fconfig = require('factconfig')
local db_name = GetFactConfig("database_name")
local p_char = "$"

local log_msg = {
  [101] = "Database '" .. db_name .. "' connected",
  [102] = "Database '" .. db_name .. "' disconnected",
  [103] = "Database '" .. db_name .. "' reloaded",
  [104] = "Could not connect to database '" .. db_name .. "'",
  [105] = "Database name returned invalid value nil"
}

local database, db_conn

--Component Functions--
local function CleanComponent(content)
  content = content:gsub("(%s*)$", "")
  content = content:gsub("^(%s*)", "")
  return content
end

local function ScrubCommand(content, command)
  content = content:gsub(command, "")
  content = content:gsub("(%s*)$", "")
  content = content:gsub("^(%s*)", "")
  return content
end

local function GetComponents(content)
  local key = content:match(trigger .. "(.-)" .. "%sis")
  if not key then
    key = content:match(trigger .. "(.*)")
  end
  if key then
    if key:find("~(%w*)") then
      key = key:gsub("~(%w*)", "")
    end
    key = CleanComponent(key)
    key = key:lower()
  end
  local fact = content:match("%sis" .. "(.*)$")
  if fact then
    fact = CleanComponent(fact)
  end
  return key, fact
end

--Database Functions--
local function Connect()
  if db_conn then
    return true
  else
    if not db_name then
      logger.Log("warning", log_msg[105])
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
      logger.Log("notice", log_msg[101])
      return true
    end
  end
end

local function Disconnect()
  if db_conn then
    database:close()
    db_conn = false
    logger.Log("notice", log_msg[102])
  end
end

--Factoid Functions--
local function FactGet(key, content, user)
  local fact = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
  if not fact then
    fact = "Nothing found for '" .. key .. "'"
  end
  if fact:find("''") then
    fact = fact:gsub("''", "'")
  end
  if fact:match(p_char .. "r%((.+)%)") then
    if fact:match("^" .. p_char .. "r%((.+)%)") then
      local fact_select = fact:match("^" .. p_char .. "r%((.+)%)")
      fact_select = discordia.extensions.string.split(fact_select, "|")
      fact = fact_select[math.random(#fact_select)]
    else
      local fact_select = fact:match(p_char .. "r%((.+)%)")
      fact_select = discordia.extensions.string.split(fact_select, "|")
      local fact_selected = fact_select[math.random(#fact_select)]
      fact = fact:gsub(p_char .. "r%((.+)%)", fact_selected)
    end
  end
  if fact:match(p_char .. "u") then
    fact = fact:gsub(p_char .. "u", user.username)
  end
  return fact
end

local function FactAdd(key, fact, user)
  local output
  local test = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
  if not test then
    if fact then
      if fact:find("'") then
        fact = fact:gsub("'", "''")
      end
      local info = user.fullname .. " (ID: " .. user.id .. ")"
      local time = os.time()
      database:rowexec("INSERT INTO factoids VALUES ('" .. key .. "','" .. info .. "','" .. time .. "',NULL,NULL,NULL,NULL,'" .. fact .. "',0)")
      logger.Log("notice", "User '" .. info .. "' added '" .. key .. "' with the content '" .. fact .. "'")
      output = "Fact " .. key .. " has been added."
    else
      output = "No Fact has been provided."
    end
  else
    output = "The key '" .. key .. "' already exists."
  end
  return output
end

local function FactAppend(key, fact, user)
  local output
  local test = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
  if test then
    local lock = database:rowexec("SELECT locked_by FROM factoids WHERE key=='" .. key .. "'")
    if not lock then
      if fact then
        if fact:find("'") then
          fact = fact:gsub("'", "''")
        end
        local info = user.fullname .. " (ID: " .. user.id .. ")"
        local time = os.time()
        fact = ScrubCommand(fact, "also")
        fact = test .. " | " .. fact
        database:rowexec("UPDATE factoids SET fact = '" .. fact .. "',modified_by = '" .. info .. "', modified_at = '" .. time .. "' WHERE key=='" .. key .. "'")
        logger.Log("notice", "User '" .. info .. "' added '" .. key .. "' with the content '" .. fact .. "'")
        output = "Fact " .. key .. " has been added."
      else
        output = "No Fact has been provided."
      end
    else
      output = "Fact " .. key .. " is locked."
    end
  else
    output = "The key '" .. key .. "' doesn't exists."
  end
  return output
end

--Public Functions--
function public.factoid(content, user)
  local key, fact = GetComponents(content)
  if Connect() then
    if key and not fact then
      output = FactGet(key, content, user)
    elseif key and fact then
      if content:find("(is)(%s*)(also)") then
        output, author = FactAppend(key, fact, user)
      else
        output, author = FactAdd(key, fact, user)
      end
    end
  else
    logger.Log("warning", log_msg[104])
  end
  return output, author
end

function public.no(content, user)
  local key, fact = GetComponents(content)
  key = ScrubCommand(key, "no")
  key = ScrubCommand(key, "^,")
  if Connect() then
    local test = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
    if test then
      local lock = database:rowexec("SELECT locked_by FROM factoids WHERE key=='" .. key .. "'")
      if not lock then
        if fact then
          if fact:find("'") then
            fact = fact:gsub("'", "''")
          end
          local info = user.fullname .. " (ID: " .. user.id .. ")"
          local time = os.time()
          database:rowexec("UPDATE factoids SET fact = '" .. fact .. "',modified_by = '" .. info .. "', modified_at = '" .. time .. "' WHERE key=='" .. key .. "'")
          logger.Log("notice", "User '" .. info .. "' replaced '" .. key .. "' with the content '" .. fact .. "'")
          output = "Fact " .. key .. " has been replaced."
        else
          output = "No Fact has been provided."
        end
      else
        output = "Fact " .. key .. " is locked."
      end
    else
      output = "The key '" .. key .. "' doesn't exists."
    end
  end
  return output
end

function public.forget(content, user)
  local output
  local key = GetComponents(content)
  key = ScrubCommand(key, "forget")
  if Connect() then
    local fact = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
    local info = user.fullname .. " (ID: " .. user.id .. ")"
    if fact then
      local lock = database:rowexec("SELECT locked_by FROM factoids WHERE key=='" .. key .. "'")
      if not lock then
        database:rowexec("DELETE FROM factoids WHERE key=='" .. key .. "'")
        logger.Log("notice", "The fact with the key '" .. key .. "' and the content '" .. fact .. "'" .. " has been deleted by User '" .. info .. "'")
        output = "Fact " .. key .. " has been deleted."
      else
        output = "The key '" .. key .. "' is locked."
      end
    else
      output = "The fact " .. key .. " doesn't exists."
    end
  end
  return output
end

function public.lock(content, user)
  local key = GetComponents(content)
  key = ScrubCommand(key, "lock")
  if Connect() then
    local test = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
    if test then
      local lock = database:rowexec("SELECT locked_by FROM factoids WHERE key=='" .. key .. "'")
      if not lock then
        local info = user.fullname .. " (ID: " .. user.id .. ")"
        local time = os.time()
        database:rowexec("UPDATE factoids SET locked_by = '" .. info .. "', locked_at = '" .. time .. "' WHERE key=='" .. key .. "'")
        logger.Log("notice", "User '" .. info .. "' locked Fact '" .. key .. "'")
        output = "Fact " .. key .. " has been locked."
      else
        output = "The key '" .. key .. "' is already locked."
      end
    else
      output = "The key '" .. key .. "' doesn't exists."
    end
  end
  print(output)
  return output
end

function public.unlock(content, user)
  local key = GetComponents(content)
  key = ScrubCommand(key, "unlock")
  if Connect() then
    local test = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
    if test then
      local lock = database:rowexec("SELECT locked_by FROM factoids WHERE key=='" .. key .. "'")
      if lock then
        local info = user.fullname .. " (ID: " .. user.id .. ")"
        local time = os.time()
        database:rowexec("UPDATE factoids SET locked_by = NULL, locked_at = NULL WHERE key=='" .. key .. "'")
        logger.Log("notice", "User '" .. info .. "' unlocked Fact '" .. key .. "'")
        output = "Fact " .. key .. " has been unlocked."
      else
        output = "The key '" .. key .. "' is already unlocked."
      end
    else
      output = "The key '" .. key .. "' doesn't exists."
    end
  end
  return output
end

function public.reloaddb()
  Disconnect()
  Connect()
  logger.Log("notice", log_msg[103])
end

function public.Init()
  if Connect() then
    return definition
  else
    return false
  end
end

function public.GetProperty(name)
  return definition[name]
end

return public
