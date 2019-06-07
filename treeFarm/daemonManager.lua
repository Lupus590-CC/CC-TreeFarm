--
-- daemon manager
--
-- background process host
--
-- Copyright 2019 Lupus590
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions: The above copyright
-- notice and this permission notice shall be included in all copies or
-- substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.
--



-- TODO: messaging system
  -- daemons receive as an event
  -- look at how rednet works?
  -- should a daemon be able to message itself?

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
  for k, v in pairs(validTypesList) do
    if type(k) ~= "number" then
      error("argChecker: arg[3] non-numeric index "..k.." in table",2)
    end
    if type(v) ~= "string" then
      error("argChecker: arg[3]["..k.."] expected string got "..type(v),2)
    end
  end
  if type(level) ~= "nil" and type(level) ~= "number" then
    error("argChecker: arg[4] expected number or nil got "..type(level),2)
  end
  level = level and level + 1 or 2

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

  error("arg["..position.."] expected "..expectedTypes
  .." got "..type(value), level)
end

local daemons = {}
local raiseErrorsInDaemons = false
local running = false
local oldError = error
local function error(mess, level)
  running = false
  return oldError(mess, (level or 1) +1)
end
local function resumeDaemon(daemonName, event)
  argChecker(1, daemonName, {"string"})
  argChecker(2, event, {"table", "nil"})
  if coroutine.status(v) ~= "suspended" then
    local returnedValues = table.pack(coroutine.resume(daemons[newDaemonName].coroutine, event and table.unpack(event, 1, event.n) or nil))
    local ok = table.remove(returnedValues, 1)
    if not ok then
      if raiseErrorsInDaemons then
        error("daemonManager error in daemon "
        ..daemonName.."\n"
        ..toString(table.unpack(returnedValues, 1, returnedValues.n)))
      end
      daemos[newDaemonName] = nil
    end
    daemons[newDaemonName].eventFilter = returnedValues[1]
  end
end


local function add(daemonName, mainLoopFunc, stopFunction)
  argChecker(1, daemonName, {"string"})
  argChecker(2, mainLoopFunc, {"function"})
  argChecker(3, stopFunction, {"function", "nil"})
  if daemons[daemonName] then
    error("daemon with name "..daemonName
    .." exists - if you want to replace it then remove it first (you may want to stop or terminate it before removing it)",2)
  end
  daemons[daemonName] = {coroutine = coroutine.create(mainLoopFunc), eventFilter = nil, stopFunction = stopFunction}
  resumeDaemon(daemonName, {})
  daemons[daemonName].eventFilter = returnedValues[1]
end

local function remove(daemonName)
  argChecker(1, daemonName, {"string"})
  daemons[daemonName] = nil
end

local function stopDaemon(daemonName)
  argChecker(1, daemonName, {"string"})
  if not daemons[daemonName] then
    return false, "no daemon with that name"
  end
  if not daemons[daemonName].stopFunction then
    return false, "no stop function for this daemon"
  end
  return true, daemons[daemonName].stopFunction() -- the stop function may give it's own status info
end

local function terminateDaemon(daemonName)
  argChecker(1, daemonName, {"string"})
  if not daemons[daemonName] then
    return false, "no daemon with that name"
  end
  local ok, err = pcall(resumeDaemon, newDaemonName, table.pack("terminate", "daemonManager"))
  if (not ok) and err == "Terminated" then
    return true -- we killed it
  end
  return false -- it won't die (it might on future resumes, no guarantee)
end

local function getDaemonList()
  local list = {}
  for k,v in pairs(daemons) do
    table.add(list,k) -- users can list them all with ipairs
    list[k]=true -- or index by name to see if it's there
  end
  return list
end

local function daemonHost()
  local event = table.pack(os.pullEventRaw())
  if not doLoop then
    return
  end
  for k, v in pairs(daemons)
    if coroutine.status(v) == "suspended" then
      if v.eventFilter == nil or v.eventFilter == event[1] then
        resumeDaemon(k, event))
      end
    elseif coroutine.status(v) == "dead" then
      daemons[k] = nil
    end
  end
end

local doLoop = true
local function exitLoop()
  doLoop = false
end

local function enterLoop(raiseErrors)
  running = true
  doLoop = true
  raiseErrorsInDaemons = raiseErrors
  while doLoop do
    daemonHost()
  end
  running = false -- just in case people want to start us again
end

local function isRunning()
  return running
end


local daemonManager = {
  add = add,
  remove = remove,
  stopDaemon = stopDaemon,
  terminateDaemon = terminateDaemon
  getDaemonList = getDaemonList,
  daemonHost = daemonHost,
  exitLoop = exitLoop,
  enterLoop = enterLoop,
  run = enterLoop,
  start = enterLoop,
  stop = exitLoop,
  isRunning = isRunning,
  hasStarted = isRunning,
}

return daemonManager
