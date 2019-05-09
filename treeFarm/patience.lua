-- TODO: add license here and to license file

-- make part of checkpoint?
  

local subscribers
local running = false
local function startTimer(secondsToWait)
  if type(secondsToWait) ~= "number" then
    error("arg[1] expected number got "..type(secondsToWait),2)
  end
  if not running then
    error("patience is not running yet, have you called enterLoop?")
  end
  
  -- add to list
  local subscriptionId = {}
  subscribers[subscriptionId] = secondsToWait
  
  return subscriptionId
end

local doLoop = true
local function exitLoop()
  doLoop = false
end


local function enterLoop(patienceFile, updateInterval)
  if running then
    return false, "already running"
  end
  running = true;
  
  patienceFile = patienceFile or ".patience" 
  if type(patienceFile) ~= "string" then
    error("arg[1] expected string or nil got "..type(patienceFile),2)
  end
  updateInterval = updateInterval or 5 -- NOTE: is there a way to get this more accurate without hammering the HDD?
  if type(updateInterval) ~= "number" then
    error("arg[2] expected number or nil got "..type(updateInterval),2)
  end
  
  -- read the file
  local file, err = config.load(patienceFile)
  if not file then
    if err == "not a file" then
      subscribers = {}
    else
      error("patience couldn't load file with name: "..patienceFile.."\ngot error: "..err,2)
    end    
  end
  while doLoop do
    for subscriptionId, timeRemaining in pairs(subscribers) do
      -- queue events if expired
      if timeRemaining <= 0 then
        os.queueEvent("patienceTimer", subscriptionId) -- Can we merge subscriptionIds if multiple subs want it?
        subscribers[subscriptionId] = nil
      end
    end
    -- decrement the timeRemaining
    for _, timeRemaining in pairs(subscribers) do
      timeRemaining = timeRemaining - updateInterval
    end
    local ok, err = config.save(patienceFile, subscribers)
    if not ok then
      error("patience couldn't save file, got error: "..err)
    end
    if doLoop then -- quick exit
      sleep(updateInterval)
    end
  end
  doLoop = true -- just in case people want to start us again
  running = false
  return true
end

local function isRunning()
  return running
end

local patience = {
  startTimer = startTimer,
  exitLoop=exitLoop,
  enterLoop=enterLoop,
  run = enterLoop,
  start = enterLoop,
  stop = exitLoop,
  isRunning = isRunning,
  hasStarted = isRunning,
}

return patience
