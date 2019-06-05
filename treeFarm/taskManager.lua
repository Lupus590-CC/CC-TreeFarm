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


-- TODO: implement

-- look at https://github.com/CC-Hive/Main needs

local patience = require("patience")
local config = require("config")

local taskFileName = ".tasks"
local tasks = {} -- TODO: persist (we load but never save) when is best to save?
  -- how do I edit tasks? should I be able to? how do I make sure to save after but not too often?
    -- have a getTask and replaceTask commands?
local running = false
local oldError = error
local function error(mess, level)
  running = false
  return oldError(mess, (level or 1) +1)
end

 local exampleTriggerList = {
   {"timer", timerId},
   {"patienceTimer", patienceTimerId},
   {"rednet_message", nil, nil, approveProtocol}, -- any rednet message with that protocal -- TODO: how does table.length handle this? enforce an n property?
   -- allow sencond value to be a function? this function is a user defined filter which gets the event arg data --NOTE: can't save functions, but can save their string.dump (if they don't have up values - how to detect and reject up values?)
   --[[
local u = "world"
local function test()
  print("hello "..u)
  print("hello "..os.version())
end

test()

local dump = string.dump(test)



local loaded = load(dump, nil, "t", _ENV or getfenv(1))
local ok, err = pcall(loaded)

if not ok then
  print(err)
end


local dump2 = "function()\n"
    .."print(\"hello \".."u")\n"
    .."print(\"hello \"..os.version())\n"
  .."end"

local loaded2 = load(dump2, nil, "t", _ENV or getfenv(1))
local ok2, err2 = pcall(loaded2)

if not ok2 then
  print(err2)
end]]
  -- don't worry about up values for tree farm, try to support them in Hive
}

local function addTask(name, triggerList, priority, recuring) -- TODO: implement
  -- TODO: arg checks
  if type(name) ~= "string" then
    error("arg[1] expected string got "..type(name),1)
  end

  if type(triggerList) ~= "table" then
    error("arg[2] expected table got "..type(triggerList),1)
  end
  for k, v in ipairs(triggerList) do
    if type(v) ~= "table" then
      error("arg[2]["..k.."] expected table got "..type(v)
      .."\n tasks must have at least one tigger event"),1)
    end
    if type(v[1]) ~= "string" then
      error("arg[2]["..k.."][1] expected string got "..type(v[1])
      .."\n this should be an event name like the first return value of "),1)
    end
  end

  if type(priority) ~= "number" then
    error("arg[3] expected number got "..type(priority),1)
  end

  recuring = recuring or false
  if type(recuring) ~= "boolean" then
    error("arg[4] expected boolean got "..type(recuring),1)
  end



  tasks[name] = {
    triggerList = triggerList,
    priority = priority,
    recuring = recuring,
  }
end

local function removeTask(name)
  if type(name) ~= "string" then
    error("arg[1] expected string got "..type(name),1)
  end

  tasks[name] = nil
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
  doLoop = true

  local ok, data = config.load(taskFileName)
  if ok then
    tasks = data
  else
    if data == "not a file" then
      tasks = {}
    else
      error("taskManager couldn't load file with name: "..taskFileName
      .."\ngot error: "..data)
    end
  end

  while doLoop do
    -- make sure to pass the tigger event to the task
    -- TODO: how do we trigger events? we can't save callback.
    -- raise events? the task name is the event type? will we need a blacklist to prevent collisions with events? that's not practical to maintain

  end
  running = false -- just in case people want to start us again
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
