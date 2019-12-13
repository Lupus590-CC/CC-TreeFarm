
-- TODO: nested wraps for nested protocols?

local rootProtocol = "exampleProtocol"

local namespaceSeperator = "."

local function errorIfRootProtocolNotValid()
  if type(rootProtocol) ~= "string" or string.gsub(rootProtocol, "%s+", "") == "" then
    error("rootProtocol must be set", 2)
  end
end

local function send(id, message, subProtocol)
  argChecker(1, id, {"number"})
  argChecker(3, subProtocol, {"string", "nil"})

  errorIfRootProtocolNotValid()


  if subProtocol and string.sub(subProtocol, 1, 1) ~= namespaceSeperator then
    subProtocol = namespaceSeperator..subProtocol
  end


  local fullProtocol = rootProtocol and rootProtocol..subProtocol or subProtocol

  rednet.send(id, message, fullProtocol)
end
