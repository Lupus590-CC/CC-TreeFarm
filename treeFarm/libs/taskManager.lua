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

local running = false
local oldError = error
local function error(mess, level)
  running = false
  return oldError(mess, (level or 1) +1)
end

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

local patience = require("treeFarm.libs.patience")
local config = require("treeFarm.libs.config")

local fileNamePrefix = ".taskManager"
local taskLibrary = {} -- every task we know about
  -- how do I edit tasks? should I be able to?
    -- have a getTask and replaceTask commands?

local taskQueue = {} -- triggered tasks which need to run (task name only, lookup in taskLibrary)
local inProgressTasks = {} -- tasks which have been marked as started but not completed (task name only, lookup in taskLibrary)

local function saveTaskLibrary()
  local ok, err = config.save(fileNamePrefix..".taskLibrary", taskLibrary)
  if not ok then
    error("taskManager: couldn't save taskLibrary. Got error:\n"..err)
  end
end
local function loadTaskLibrary()
  local ok, data = config.load(fileNamePrefix..".taskLibrary")
  if not ok then
    if data == "not a file" then
      taskLibrary = {}
      return
    end
    error("taskManager: couldn't load taskLibrary. Got error:\n"..data)
  end
  taskLibrary = data
end

local function saveTaskQueue()
  local ok, err = config.save(fileNamePrefix..".taskQueue",taskQueue)
  if not ok then
    error("taskManager: couldn't save taskQueue. Got error:\n"..err)
  end
end
local function loadTaskQueue()
  local ok, data = config.load(fileNamePrefix..".taskQueue")
  if not ok then
    if data == "not a file" then
      taskQueue = {}
      return
    end
    error("taskManager: couldn't load taskQueue. Got error:\n"..data)
  end
  taskQueue = data
end

local function saveInProgressTasks()
  local ok, err = config.save(fileNamePrefix..".inProgressTasks",data)
  if not ok then
    error("taskManager: couldn't save inProgressTasks. Got error:\n"..err)
  end
end
local function loadInProgressTasks()
  local ok, data = config.load(fileNamePrefix..".inProgressTasks")
  if not ok then
    if data == "not a file" then
      inProgressTasks = {}
      return
    end
    error("taskManager: couldn't load inProgressTasks. Got error:\n"..data)
  end
  inProgressTasks = data
end



 local exampleTriggerList = { -- nil is treated as wildcard
   {"timer", timerId},
   {"patienceTimer", patienceTimerId},
   {"rednet_message", nil, nil, approveProtocol}, -- any rednet message with that protocal
}

local function validateTriggerList(argPosition, triggerList, level)
  argChecker(1, argPosition, {"number"})
  argChecker(2, triggerList, {"table"})
  argChecker(3, level, {"number","nil"})
  level = level + 1 or 2

  if #triggerList == 0 then
    error("arg["..argPosition.."] table has no valid keys, tasks must have at least one tigger event", level)
  end
  for keyOfCurrentTriggerValue, currentTrigger in ipairs(triggerList) do
    -- validate the event arg
    if type(currentTrigger) ~= "table" then
      error("arg["..argPosition.."]["..keyOfCurrentTriggerValue.."] expected table got "..type(currentTrigger),level)
    end
    if type(currentTrigger[1]) ~= "string" then
      error("arg["..argPosition.."]["..keyOfCurrentTriggerValue.."][1] expected string got "..type(currentTrigger[1])
      .."\n this should be an event name like the first return value of os.pullEvent. The other values of the table can be the arguments of that event, nils are treated as wildcards for the arguments.",level)
    end
    -- we checked the first value for a string already but skipping that will take more effort than it's worth
    for currentTriggerKey, currentTriggerValue in pairs(currentTrigger) do
      if not pcall(textutils.serialize, currentTriggerValue) then
        error("arg["..argPosition.."]["..keyOfCurrentTriggerValue.."]["..currentTriggerKey.."] could not serialize value with type "
        ..type(currentTriggerValue),level)
      end
    end
  end
end

local function addTask(name, triggerList, priority, recuring)
  argChecker(1, name, {"string"})
  argChecker(2, triggerList, {"table"})

  validateTriggerList(2, triggerList)

  argChecker(3, priority, {"number"})
  argChecker(4, recuring, {"boolean", "nil"})
  recuring = recuring or false

  local uniqueTaskId = string.format("%08x", math.random(1, 2147483647))

  taskLibrary[uniqueTaskId] = {
    triggerList = triggerList,
    priority = priority,
    recuring = recuring,
    uniqueTaskId = uniqueTaskId,
    name = name
  }

  saveTaskLibrary()
  return true, uniqueTaskId
end

local function removeTask(uniqueTaskId)
  argChecker(1, uniqueTaskId, {"string"})

  for k, v in ipairs(taskQueue) do
    while v.taskId == uniqueTaskId do -- have to do this as we are editing as we iterate
      table.remove(taskQueue, k)
      v = taskQueue[k]
    end
  end
  taskLibrary[uniqueTaskId] = nil
  inProgressTasks[uniqueTaskId] = nil

  saveInProgressTasks()
  saveTaskQueue() -- we might not have changed it but whatever
  saveTaskLibrary()
end

local doLoop = true
local function exitLoop()
  doLoop = false
end

local function queueTask(taskId, triggeredEvent)
  argChecker(1, taskId, {"string"})
  argChecker(2, triggeredEvent, {"table"})

  if not taskLibrary[taskId] then
    return false, "task doesn't exist"
  end

    -- TODO: what do we do with retriggered tasks already in progress or in the queue? #askDiscord

  -- should the client care about the event that triggered the task?
  os.queueEvent(taskEventType, taskLibrary[taskId].name, taskId, triggeredEvent)
  table.add(taskQueue, {taskId=taskId, triggeredEvent=triggeredEvent})
  saveTaskQueue()
  return true
end

local function enterLoop(taskFileNamePrefix)
  argChecker(1, taskFileNamePrefix, {"string", "nil"})
  fileNamePrefix = taskFileNamePrefix or fileNamePrefix

  if running then
    return false, "already running"
  end
  running = true;
  doLoop = true

  loadTaskQueue()
  loadTaskLibrary()
  loadInProgressTasks()

  local function eventMatchesThisTrigger(event, trigger)
    for k, v in pairs(trigger) do
      if type(k) == "number" and event[k] ~= v then
        return false
      end
    end
    return true
  end

  local function eventMatchesATriggerInList(event, triggerList)
    for _, trigger in ipairs(triggerList) do
      if event[1] == trigger[1]
      and eventMatchesThisTrigger(event, trigger) then
        return true
      end
    end
    return false
  end

  while doLoop do
    local event = table.pack(os.pullEvent())
    if event[1] ~= taskEventType then -- ignore task events as we queue them
      for taskId, taskData in pairs(taskLibrary) do
        if eventMatchesATriggerInList(event, taskData.triggerList) then
          queueTask(taskId, event)
        end
      end
    end
  end

  running = false -- just in case people want to start us again
  return true
end

local function isRunning()
  return running
end

local taskEventType = "task"
local function waitForTask(taskName, uniqueTaskId)
  argChecker(1, taskName, {"string", "nil"})
  argChecker(2, uniqueTaskId, {"string", "nil"})
  while true do
    local _, eventTaskName, eventTaskId, triggerEventData
     = os.pullEvent(taskEventType)
    if taskName == eventTaskName and uniqueTaskId == eventTaskId then
      return eventTaskName, eventTaskId, triggerEventData
    end
  end
end

-- doing tasks out of order is fine, maybe the current task host can't do the first task
local function markTaskAsStarted(uniqueTaskId, taskHostId)
  argChecker(1, uniqueTaskId, {"string"})
  argChecker(2, taskHostId, {"string"})
  for k, v in ipairs(taskQueue) do
    if v.taskId == uniqueTaskId then
      local startedTask = table.remove(taskQueue, k)
      inProgressTasks[uniqueTaskId] = taskHostId
      saveInProgressTasks()
      saveTaskQueue()
      return true
    end
  end
  return false, "task doesn't exist or has not been triggered"
end

-- TODO: how to interrupt tasks? #Hive
-- put the task back in the queue?
-- preferably with the progress preserved

local function markTaskAsComplete(uniqueTaskId, taskHostId)
  argChecker(1, uniqueTaskId, {"string"})
  argChecker(2, taskHostId, {"string"})
  if inProgressTasks[uniqueTaskId] == taskHostId then
    inProgressTasks[uniqueTaskId] = nil
    saveInProgressTasks()
    return true
  elseif inProgressTasks[uniqueTaskId] then
    return false, "task is owned by another task host"
  end
  return false, "task has not been started or doesn't exist"
end

local function taskIsInprogress(uniqueTaskId)
  argChecker(1, uniqueTaskId, {"string"})
  return inProgressTasks[uniqueTaskId] and true or false
end

local function copyTable(from)
  local copy = {}
  for k, v in pairs(from) do
    if type(v) == "table" then
      copy[k] = copyTable(v)
    else
      copy[k] = v
    end
  end
  return copy
end

local function getInprogressTasks()
  return copyTable(inProgressTasks)
end

local function getTaskQueue()
  return copyTable(taskQueue)
end

local function getTaskLibrary()
  return copyTable(taskLibrary)
end

local function getTaskInfoById(taskId)
  if taskLibrary[taskId] then
    return true, copyTable(taskLibrary[taskId])
  end
  return false, "could not find that task"
end

local taskManager = {
  addTask = addTask,
  removeTask = removeTask,
  exitLoop = exitLoop,
  queueTask = queueTask, -- here to allow manual task triggering
  enterLoop = enterLoop,
  run = enterLoop,
  start = enterLoop,
  stop = exitLoop,
  isRunning = isRunning,
  hasStarted = isRunning,
  taskEventType = taskEventType,
  waitForTask = waitForTask,
  markTaskAsStarted = markTaskAsStarted,
  markTaskAsComplete = markTaskAsComplete,
  taskIsInprogress = taskIsInprogress,
  getInprogressTasks = getInprogressTasks,
  getTaskQueue = getTaskQueue,
  getTaskLibrary = getTaskLibrary,
  getTaskInfoById = getTaskInfoById,
}
