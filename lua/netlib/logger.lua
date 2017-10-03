local public = {}

local file = io.open("log.txt", "a")

function public.Log(msg_type,msg_content)
  if not msg_type then error("Missing msg_type parameter in function call", 2) end
  if not msg_content then error("Missing msg_content parameter in function call", 2) end
  
  local output
  local time = os.time()
  time = os.date('%Y-%m-%d %H:%M:%S', time)
  
  if msg_type == "notice" then
    output = time .. " | [NOTICE]: " .. msg_content
  elseif msg_type == "warning" then
    output = time .. " | [WARNING]: " .. msg_content
  elseif msg_type == "error" then
    error("[ERROR]: " .. msg_content,2)
  else
    error("Invalid msg_type parameter in function call", 2)
  end

  print(output)
  
  file:write("\n" .. output)
  file:flush()
end

return public