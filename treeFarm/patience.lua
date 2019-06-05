--
-- Copyright 2019 Lupus590
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
--  deal in the Software without restriction, including without limitation the
--  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
--  sell copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions: The above
--  copyright notice and this permission notice shall be included in all copies
--  or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.
--

local config = require("config")

local running = false

local oldError = error
local function error(mess, level)
  running = false
  return oldError(mess, (level or 1) +1)
end

local timers = {}

local function startTimer(secondsToWait)
  if type(secondsToWait) ~= "number" then
    error("arg[1] expected number got "..type(secondsToWait),2)
  end
  if not running then
    error("patience is not running yet, have you called enterLoop?")
  end

  -- add to list
  local timerId = tostring(math.random(1, 2147483647)) -- it's good enough for rednet so it's good enough for us
  timers[timerId] = secondsToWait

  return timerId
end

local function cancelTimer(timerId)
  if type(timerId) ~= "number" then
    error("arg[1] expected number got "..type(timerId),2)
  end
  if not running then
    error("patience is not running yet, have you called enterLoop?")
  end

  timers[timerId] = nil
end

local doLoop = true
local function exitLoop()
  doLoop = false
end

local function enterLoop(patienceFileName, updateInterval)
  if running then
    return false, "already running"
  end
  running = true
  doLoop = true

  patienceFileName = patienceFileName or ".patience"
  if type(patienceFileName) ~= "string" then
    error("arg[1] expected string or nil got "..type(patienceFileName),2)
  end
  updateInterval = updateInterval or 5 -- TODO: is there a way to get this more accurate without hammering the HDD?
  if type(updateInterval) ~= "number" then
    error("arg[2] expected number or nil got "..type(updateInterval),2)
  end

  -- read the file
  local ok, data = config.load(patienceFileName)
  if ok then
    timers = data
  else
    if data == "not a file" then
      timers = {}
    else
      error("patience couldn't load file with name: "..patienceFileName
      .."\ngot error: "..data)
    end
  end
  while doLoop do
    for timerId, timeRemaining in pairs(timers) do
      -- queue events if expired
      if timeRemaining <= 0 then
        os.queueEvent("patienceTimer", timerId)
        timers[timerId] = nil
      end
    end
    -- decrement the timeRemaining
    for k, timeRemaining in pairs(timers) do
      timers[k] = timeRemaining - updateInterval
    end
    local ok, err = config.save(patienceFileName, timers)
    if not ok then
      error("patience couldn't save file, got error: "..err)
    end
    if doLoop then -- quick exit
      sleep(updateInterval)
    end
  end
  running = false -- just in case people want to start us again
  return true
end

local function isRunning()
  return running
end

local patience = {
  startTimer = startTimer,
  cancelTimer = cancelTimer,
  exitLoop = exitLoop,
  enterLoop = enterLoop,
  run = enterLoop,
  start = enterLoop,
  stop = exitLoop,
  isRunning = isRunning,
  hasStarted = isRunning,
}

return patience
