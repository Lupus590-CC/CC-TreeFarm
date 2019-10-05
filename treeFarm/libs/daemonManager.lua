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

local daemons = {}
local raiseErrorsInDaemons = false
local running = false
local oldError = error
local function error(mess, level)
  running = false
  return oldError(mess, (level or 1) +1)
end

local function remove(daemonName)
  argChecker(1, daemonName, {"string"})
  daemons[daemonName] = nil
end

local function resumeDaemon(daemonName, event)
  argChecker(1, daemonName, {"string"})
  argChecker(2, event, {"table", "nil"})
  if coroutine.status(v) ~= "suspended" then
    local returnedValues = table.pack(coroutine.resume(daemons[daemonName].coroutine, event and table.unpack(event, 1, event.n) or nil))
    local ok = table.remove(returnedValues, 1)
    if not ok then
      if raiseErrorsInDaemons or daemons[daemonName].errorOnDaemonErrors then
        error("daemonManager error in daemon "
        ..daemonName.."\n"..table.concat(returnedValues,"\n"))
      end
      if daemons[daemonName].errorFunction then
        daemons[daemonName].errorFunction(daemonName, returnedValues)
      end
      if coroutine.status(daemons[daemonName].coroutine) == "dead" then
        -- the errorFunction might readd the daemon, if they do then it won't be dead and we shouldn't remove it
        remove(daemonName)
      end
    end
    daemons[daemonName].eventFilter = returnedValues[1]
    daemons[daemonName].returnedValues = returnedValues
  end
end


local function add(daemonName, mainLoopFunc, stopFunction, completeFunction, errorFunction, errorOnDaemonErrors, restartOnError)
  argChecker(1, daemonName, {"string"})
  argChecker(2, mainLoopFunc, {"function"})
  argChecker(3, stopFunction, {"function", "nil"})
  argChecker(4, completeFunction, {"function", "nil"})
  argChecker(5, errorFunction, {"function", "nil"})
  argChecker(6, errorOnDaemonErrors, {"boolean", "nil"})
  forwardErrors = forwardErrors or false

  if daemons[daemonName] then
    return false, "already exists"
  end
  daemons[daemonName] = {coroutine = coroutine.create(mainLoopFunc),
  eventFilter = nil, stopFunction = stopFunction,
  completeFunction = completeFunction, errorFunction = errorFunction,
  errorOnDaemonErrors = errorOnDaemonErrors,}
  resumeDaemon(daemonName, {})
  daemons[daemonName].eventFilter = returnedValues[1]

  return true
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

local function getListOfDaemonNames() -- NOTE: it's not clear from the function name that this returns the names of the deamons but not the deamons themselves.
  local list = {}
  for k,v in pairs(daemons) do
    table.add(list,k) -- users can list them all with ipairs
    list[k]=true -- or index by name to see if it's there
  end
  return list
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
    local event = table.pack(os.pullEventRaw())
    if not doLoop then
      return
    end
    for k, v in pairs(daemons) do
      if coroutine.status(v) == "suspended" then
        if v.eventFilter == nil or v.eventFilter == event[1] then
          resumeDaemon(k, event)
        end
      elseif coroutine.status(v) == "dead" then
        if v.completeFunction then
          v.completeFunction(k, v.returnedValues) -- if users want to restart the daemon they the should have made it not stop in the first place
        end
        if coroutine.status(v) == "dead" then
          -- the completeFunction might have readded the daemon, if they did then it won't be dead and we shouldn't remove it
          remove(k)
        end
      end
    end
  end
  running = false -- just in case people want to start us again
end

local function isRunning()
  return running
end


local daemonManager = {
  remove = remove,
  add = add,
  stopDaemon = stopDaemon,
  terminateDaemon = terminateDaemon,
  getListOfDaemonNames = getListOfDaemonNames,
  exitLoop = exitLoop,
  enterLoop = enterLoop,
  run = enterLoop,
  start = enterLoop,
  stop = exitLoop,
  isRunning = isRunning,
  hasStarted = isRunning,
}

return daemonManager
