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

local function ScrubCommand(content,command)
    content = content:gsub(command,"")
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
        fact = "Nothing found for '" .. key .. "'"
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
    if fact:match("^%((.+)%)") then
        fact = fact:match("%((.+)%)")
        local fact_select = fact:split("|")
        fact = fact_select[math.random(#fact_select)]
    end
    return fact
end

local function FactAdd(key,fact,user)
    local output
    local test = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
    if not test then
        if fact then
            if fact:find("'") then
                fact = fact:gsub("'","''")
            end
            local info = user.username .. " (ID: " .. user.id .. ")"
            local time = os.time()
            database:rowexec("INSERT INTO factoids VALUES ('" .. key .. "','" .. info .. "','" .. time .. "',NULL,NULL,NULL,NULL,'" .. fact .. "',0)")
            logger.Log("notice","User '" .. info ..  "' added '" .. key .. "' with the content '" .. fact .. "'")
            output = "Fact " .. key .. " has been added."
        else
            output = "No Fact has been provided."
        end
    else
        output = "The key '" .. key .. "' already exists."
    end
    return output
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

function public.no(content,user)
    local key,fact = GetComponents(content)
    key = ScrubCommand(key,"no")
    if Connect() then
        local test = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
        if test then
            if fact then
                if fact:find("'") then
                    fact = fact:gsub("'","''")
                end
                local info = user.username .. " (ID: " .. user.id .. ")"
                local time = os.time()
                database:rowexec("REPLACE INTO factoids VALUES ('" .. key .. "','" .. info .. "','" .. time .. "',NULL,NULL,NULL,NULL,'" .. fact .. "',0)")
                logger.Log("notice","User '" .. info ..  "' replaced '" .. key .. "' with the content '" .. fact .. "'")
                output = "Fact " .. key .. " has been replaced."
            else
                output = "No Fact has been provided."
            end
        else
            output = "The key '" .. key .. "' doesn't exists."
        end
    end
    return output
end

function public.forget(content,user)
    local output
    local key = GetComponents(content)
    key = ScrubCommand(key,"forget")
    print(key)
    if Connect() then
        local fact = database:rowexec("SELECT fact FROM factoids WHERE key=='" .. key .. "'")
        local info = user.username .. " (ID: " .. user.id .. ")"
        if fact then
            database:rowexec("DELETE FROM factoids WHERE key=='" .. key .. "'")
            logger.Log("notice","The fact with the key '" .. key .. "' and the content '" .. fact .. "'" .. " has been deleted by User '" .. info .. "'")
            output = "Fact " .. key .. " has been deleted."
        else
            output = "The fact " .. key .. " doesn't exists."
        end
    end
    return output
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

function public.GetProperty(name)
    return definition[name]
end

return public
