local plugins   = {"factoids"}
local register  = {}

for i,plugin in pairs(plugins) do
  register[plugin] = require('./' .. plugin)
end

return register