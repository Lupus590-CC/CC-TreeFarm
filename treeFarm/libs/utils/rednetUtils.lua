-- TODO: serverless?
  -- remote just broadcasts
  -- remote only needs to talk to the main turtle
  -- still have multiple farming turtles?

 -- TODO: take from config
 -- multiple server names? remote has one and the furnace has one?
 -- turtle and furnace manager pair like bluetooth
local rootProtocol = "lupus590:TreeFarm"

rednet.open() -- NOTE: does rednet use all modems or just the first one it finds?

local function send(id, message, subProtocol)
  argChecker(1, id, {"number"})
  argChecker(1, id, {"number"})


  if subProtocol and string.sub(subProtocol, 1, 1) ~=":" then
    subProtocol = ":"..subProtocol
  end

  rednet.send(id, message, rootProtocol..subProtocol )
end

local function ping(id)
  argChecker()

  -- send ping message

  -- listen for responce

  if responce then
    return true
  else
    return false
  end

end

local function run()
  while true do
    local message = table.pack(rednet.recive())

    if message is ping then
      repond to ping
    end

  end
end

local rednetUtils = {
  rootProtocol = rootProtocol,
  send = send,
  ping = ping,
  run = run,
}

return rednetUtils
