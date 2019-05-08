-- TODO: license

-- make part of checkpoint?
  
-- #NOTE: use daemon manager?

local patienceFile = ".patience"

local blarg -- TODO: rename blarg (patience file instance)

local function subscribe(seconds) -- TODO: os.sleep uses seconds?
  -- add to list
  
  return eventId
end

local function run()
  -- read the file
  blarg = config.load(patienceFile) or {} -- TODO: better handle first time run and bad files
  while true do
    for eventId, timeRemaining in pairs(blarg) do
      -- queue events if expired
      if timeRemaining <= 0 then
        os.queueEvent("patience", eventId)
        blarg[eventId] = nil
      end
    end
    -- decrement the timeRemaining
    for _, timeRemaining in pairs(blarg) do
      timeRemaining = timeRemaining - 5
    end
    config.save(patienceFile, blarg) -- TODO: handle save errors
    sleep(5) -- TODO: seconds?
  end
end

-- TODO: register with deamonmanager

local patience = {
  subscribe = subscribe,
  run = run, -- NOTE: remove?
}

return patience
