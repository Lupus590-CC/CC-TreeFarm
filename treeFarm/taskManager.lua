--
-- Copyright 2019 Lupus590
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--


-- TODO: implement

-- look at https://github.com/CC-Hive/Main needs

local patience = require("patience")

local taskfile = ".tasks"
local tasks = {} -- TODO: persist

local function addTask(name, trigger, recuring) -- TODO: implement -- TODO: how to do trigger?
  -- TODO: arg checks
  local taskId = math.random(1, 2147483647) -- it's good enough for rednet so it's good enough for us -- TODO: check file output, we may want to use ("%08x"):format(math.random( 1, 2^31-2 )) #homeOnly

  tasks[taskId] = something
  return taskId
end

local function removeTask(taskId) -- TODO: implement
  -- TODO: arg checks
  tasks[taskId] = nil
end

local doLoop = true
local function exitLoop()
  doLoop = false
end

local function enterLoop()
  if running then
    return false, "already running"
  end
  running = true;
  while doLoop do

  end
  doLoop = true -- just in case people want to start us again
  running = false
  return true
end

local function isRunning()
  return running
end

local taskManager = {
  addTask = addTask,
  removeTask = removeTask,
  exitLoop = exitLoop,
  enterLoop = enterLoop,
  run = enterLoop,
  start = enterLoop,
  stop = exitLoop,
  isRunning = isRunning,
  hasStarted = isRunning,
}
