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

local function addTask(name, triggerList, priority, recuring) 
  argChecker(1, name, {"string"})
  argChecker(2, triggerList, {"table"})
  -- argChecker can't do contents of tables
  -- TODO: list checker
  -- tTODO: fix this looking really ugly
  for keyOfCurrentTriggerValue, currentTrigger in ipairs(triggerList) do
    if type(currentTrigger) ~= "table" then
      error("arg[2]["..keyOfCurrentTriggerValue.."] expected table got "..type(currentTrigger)
      .."\n tasks must have at least one tigger event"),2)
    end
    if type(currentTrigger[1]) ~= "string" then
      error("arg[2]["..keyOfCurrentTriggerValue.."][1] expected string got "..type(currentTrigger[1])
      .."\n this should be an event name like the first return value of os.pullEvent. The other values of the table can be the arguments of that event, nils are fine.",2)
    end
    -- we checked the first value for a string already but skipping that will take more effort than it's worth
    for currentTriggerKey, currentTriggerValue in ipairs(currentTrigger) do
      if not pcall(textutils.serialize, currentTriggerValue) then
        error("arg[2]["..keyOfCurrentTriggerValue.."]["..currentTriggerKey.."] could not serialize value with type "
        ..type(currentTriggerValue),2)
    end
  end

  argChecker(3, priority, {"number"})

  argChecker(4, recuring, {"boolean", "nil"})
  recuring = recuring or false

  tasks[name] = {
    triggerList = triggerList,
    priority = priority,
    recuring = recuring,
  }
end

local function removeTask(name)
  argChecker(1, name, {"string"})

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
    -- should we do this?

    -- TODO: how do we trigger events? we can't save callback.
    -- raise events? the task name is the event type? will we need a blacklist to prevent collisions with events? that's not practical to maintain
    -- this means that there is a coroutine sat arround waiting for one event
    -- file path?
    -- that's the recivers problem?

  end
  running = false -- just in case people want to start us again
  return true
end

local function isRunning()
  return running
end

local taskEventType = "task"
local function waitForTask(taskName)
  argChecker(1, taskName, {"string", "nil"})
  while true do
    local _, eventTaskName, triggerEventData = os.pullEvent(taskEventType)
    if taskName == eventTaskName then
      return eventTaskName, triggerEventData
    end
  end
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
  taskEventType = taskEventType,
  waitForTask = waitForTask
}
