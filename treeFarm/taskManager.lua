-- TODO: license #high

-- TODO: implement

-- look at https://github.com/CC-Hive/Main needs

local patience = require("patience")

local taskfile = ".tasks"
local tasks = {} -- TODO: persist

local function addTask(name, trigger, recuring) -- TODO: implement -- TODO: how to do trigger?
  -- TODO: arg checks
  local taskId = tostring({}) -- TODO: this is bad

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
