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

local running = false
local oldError = error
local function error(mess, level)
  running = false
  return oldError(mess, (level or 0) +1)
end

 local exampleTrigger = {
 {"timer", timerId},
 {"patienceTimer", patienceTimerId},
 {"rednet_message", nil, nil, approveProtocol}, -- any rednet message with that protocal -- TODO: how does table.length handle this? enforce an n property?
}
local function addTask(name, trigger, priority, recuring) -- TODO: implement
  -- TODO: arg checks
  if type(name) ~= "string" then -- TODO: use this as the task table key instead of creating an id?
    error("arg[1] expected string got "..type(name),1)
  end

  if type(trigger) ~= "table" then
    error("arg[2] expected table got "..type(trigger),1)
  end
  if type(trigger[1]) ~= "table" then
    error("arg[2][1] expected table got "..type(trigger[1].."\n tasks must have at least one tigger event"),1)
  end
  -- TODO: check all tiggers

  if type(priority) ~= "number" then
    error("arg[3] expected number got "..type(priority),1)
  end

  recuring = recuring or false
  if type(recuring) ~= "boolean" then
    error("arg[4] expected boolean got "..type(recuring),1)
  end



  local taskId = math.random(1, 2147483647) -- it's good enough for rednet so it's good enough for us -- TODO: check file output, we may want to use ("%08x"):format(math.random( 1, 2^31-2 )) #homeOnly

  tasks[taskId] = {name = "name",
    trigger = trigger,
    priority = priority,
    recuring = recuring,
  }
  return taskId
end

local function removeTask(taskId) -- TODO: arge check?
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
    -- make sure to pass the tigger event to the task

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
