-- This is where you enter plugins you wish to load, this is case-sensitive and should match the name of the lua file you want to load
local plugins     = {"factoids"}
-- This is the list of priority plugins, like libraries or system modules, to load. Only use this when told to, loading normal plugins here will break them.
local priorities  = {"permissions"}

local public      = {}
public.register   = {}

local d_table     = discordia.extensions.table

function public.LoadPriorities()
  if next(priorities) == nil then
    return 0
  else
    for i,priority in pairs(priorities) do
      public.register[priority] = require('./' .. priority)
    end
    if next(public.register) == nil then
      error("Loading priority plugins failed")
      return -1
    else
      return 0
    end
  end
end

function public.LoadPlugins()
  if next(plugins) == nil then
    return 0
  else
    for i,plugin in pairs(plugins) do
      public.register[plugin] = require('./' .. plugin)
    end
    if next(public.register) == nil then
      error("Loading normal plugins failed")
      return -1
    else
      return 0
    end
  end
end

return public