-- TODO: serverless?
  -- remote just broadcasts
  -- remote only needs to talk to the main turtle
  -- still have multiple farming turtles?

 -- TODO: take from config
 -- multiple server names? remote has one and the furnace has one?
 -- turtle and furnace manager pair like bluetooth

local modem = peripheral.find("modem", function(_, modem) return modem.isWireless() end)
rednet.open(modem)

local protocolSeperator = "."
local rootProtocol = "Lupus590"..protocolSeperator.."treeFarm"
local pingProtocol = rootProtocol..protocolSeperator.."ping"

local function concatProtocols(...)
  local protocols = table.pack(...)

  local function trimProtocolSeperator(protocolToTrim)
    -- first character
    if string.sub(protocolToTrim,1,1) == protocolSeperator then
      protocolToTrim = string.gsub(protocolToTrim, protocolSeperator, "", 1)
    end

    -- last character
    local length = string.length(protocolToTrim)
    if string.sub(protocolToTrim,length) == protocolSeperator then
      protocolToTrim = string.sub(protocolToTrim, 1, length-1)
    end
    return protocolToTrim
  end

  for k, v in pairs(protocols)
    argValidationUtils.argChecker(k, v, {"string"})
    protocol[k] = trimProtocolSeperator(v)
  end

  -- if we only have one protocol then concat it with the root protocol
  if #protocols == 1 then
    protocol[2] = protocol[1]
    protocol[1] = rootProtocol
  end

  return table.concat(protocols, protocolSeperator)
end

local function ping(targetId, timeout)
  argValidationUtils.argChecker(1, targetId, {"number"})
  argValidationUtils.argChecker(2, timeout, {"number", "nil"})
  timeout = timeout or 2 -- seconds

  local randomPayload = string.format("%08x", math.random(1, 2147483647)
  local expectedResponce = "pong:"..randomPayload
  rednet.send(targetId, "ping:"..randomPayload, pingProtocol)

  local timerId = os.startTimer(timeout)
  while true do
    local event = table.pack(os.pullEvent())

    if event[1] == "rednet_message" and event[4] == pingProtocol
    and event[2] == targetId and event[3] == expectedResponce then
      os.cancelTimer(timerID)
      return true -- remote responded correctly

    elseif event[1] == "timer" and event[2] == timerID then
      return false -- no responce
    end
  end
end

local function run()
  while true do
    local sender, message, protocol = rednet.receive()

    if protocol == pingProtocol and string.sub(message, 1, 5) == "ping:" then
      rednet.send(sender, "pong:"..string.sub(message, 6), pingProtocol)
    end
  end
end

local rednetUtils = {
  concatProtocols = concatProtocols,
  ping = ping,
  run = run,
}

return rednetUtils
