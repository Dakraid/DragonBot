local Settings = {database_name = "Factoids.db"}

function GetConfig(name)
  return Settings[name]
end