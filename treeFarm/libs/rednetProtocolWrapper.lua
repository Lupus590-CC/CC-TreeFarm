-- TODO does this work?

-- TODO: use argValidationUtils?
local function argChecker(position, value, validTypesList, level)
  -- check our own args first, sadly we can't use ourself for this
  if type(position) ~= "number" then
    error("argChecker: arg[1] expected number got "..type(position),2)
  end
  -- value could be anything, it's what the caller wants us to check for them
  if type(validTypesList) ~= "table" then
    error("argChecker: arg[3] expected table got "..type(validTypesList),2)
  end
  if not validTypesList[1] then
    error("argChecker: arg[3] table must contain at least one element",2)
  end
  for k, v in ipairs(validTypesList) do
    if type(v) ~= "string" then
      error("argChecker: arg[3]["..tostring(k).."] expected string got "..type(v),2)
    end
  end
  if type(level) ~= "nil" and type(level) ~= "number" then
    error("argChecker: arg[4] expected number or nil got "..type(level),2)
  end
  level = level and level + 1 or 3

  -- check the client's stuff
  for k, v in ipairs(validTypesList) do
    if type(value) == v then
      return
    end
  end

  local expectedTypes
  if #validTypesList == 1 then
      expectedTypes = validTypesList[1]
  else
      expectedTypes = table.concat(validTypesList, ", ", 1, #validTypesList - 1) .. " or " .. validTypesList[#validTypesList]
  end

  error("arg["..tostring(position).."] expected "..expectedTypes
  .." got "..type(value), level)
end

local function toEventName(protocol)
  argChecker(1, protocol, {"string"})
  return "rednet_protocol_message_"..protocol
end

local function wrap(protocol)
  argChecker(1, protocol, {"string"})

  local wrappedRednetProtocol = {
    protocol = protocol
  }

  wrappedRednetProtocol.send = function(id, message)
    argChecker(1, id, {"number"})
    return rednet.send(id, message, wrappedRednetProtocol.protocol)
  end

  wrappedRednetProtocol.broadcast = function(message)
    return rednet.broadcast(message, wrappedRednetProtocol.protocol)
  end

  wrappedRednetProtocol.receive = function(timeout)
    argChecker(1, id, {"number","nil"})
    return rednet.receive(wrappedRednetProtocol.protocol, timeout) -- TODO: test wth nil timeout and protocol #homeOnly
  end

  wrappedRednetProtocol.host = function (hostname)
    argChecker(1, hostname, {"string"})
    return rednet.host(wrappedRednetProtocol.protocol, hostname)
  end

  wrappedRednetProtocol.unhost = function (hostname)
    argChecker(1, hostname, {"string"})
    return rednet.unhost(wrappedRednetProtocol.protocol, hostname)
  end

  wrappedRednetProtocol.lookup = function (hostname)
    argChecker(1, hostname, {"string", nil})
    return rednet.lookup(wrappedRednetProtocol.protocol, hostname)
  end

  wrappedRednetProtocol.getEventName = function()
    return toEventName(wrappedRednetProtocol.protocol)
  end
end

local function run() -- only required for events, the wrapped methods still work stand alone
  while true do
    local event = table.pack(os.pullevent("rednet_message"))
    os.queueEvent(toEventName(event[4]), event[2], event[3])
  end
end

local rednetProtocolWrapper = {
  toEventName = toEventName,
  wrap = wrap,
  run = run,
  open = rednet.open,
  close = rednet.close,
  isOpen = rednet.isOpen,
}
