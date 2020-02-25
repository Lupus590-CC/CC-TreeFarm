local argValidationUtils = require("treeFarm.libs.utils.argValidationUtils")
local utils = require("treeFarm.libs.utils")
local invUtils = utils.invUtils -- TODO: use invUtils (existing may be out of date)
local itemUtils = utils.itemUtils
local itemIds = require("treeFarm.libs.itemIds")
local daemonManager = require("treeFarm.libs.daemonManager")
local config = require("treeFarm.libs.config")
local taskManager = require("treeFarm.libs.taskManager")
local checkpoint = require("treeFarm.libs.checkpoint") -- do I need this here? I could just parallel all of the functions
local virtualChestMerge = require("treeFarm.libs.virtualChestMerge")

-- maps peripheral names
local chestMapFile = ".chestMap"
local chests = {} -- input, output, charcoal, saplings, logs
local furnaces = {}
local wirelessModem
local monitor
local furnaceLowEfficiencyMode -- true if burning logs to make charcoal -- TODO: message the turtle about this. What should the turtle do?

local FURNACE_INPUT_SLOT = 1
local FURNACE_FUEL_SLOT = 2
local FURNACE_OUTPUT_SLOT = 3

local linkedTurtleId = "manualTesting" -- TODO: change to nil and implement turtle pairing and communicating #turtle

local function fuelValueForFurnace(turtleFuelValue)
  argValidationUtils.argChecker(1, turtleFuelValue, {"number"})
  return turtleFuelValue/10
end


local function init()
  -- check config for peripheral map
  local chestMap
  local ok, data = config.load(chestMapFile)
  if ok then
    chestMap = data
  else
    if data == "not a file" then
      chestMap = {}
    else
      error("couldn't load file with name: "..chestMapFile
      .."\ngot error: "..data)
    end
  end

  -- discover peripherals

  -- bind the non-chest peripherals
  monitor = peripheral.find("monitor")
  wirelessModem = peripheral.find("modem", function(_, m) return m.isWireless() end)
  furnaces = {n = 0}
  peripheral.find("minecraft:furnace", function(name)
    furnaces.n = furnaces.n + 1
    furnaces[furnaces.n] = virtualChestMerge(name)
  end) -- oh the hacks




  -- if we have a turtle then test the connection to make sure it still exists
  if linkedTurtleId then
    --TODO: ping the turtle, if no responce then unpair the turtle #turtle
    monitor.clear()
    monitor.write("Player is standing in for the turtle for init testing, click the monitor to continue")
    os.pullEvent("monitor_touch")
  end


  if not linkedTurtleId then

    monitor.clear()
    monitor.write("Waiting to pair with turtle, pairing code: "..os.getComputerID().."\nplease access turtle and pair")

    -- TODO: how to do pairing #turtle
    -- rednet host stuff? unhost once paired (will unhosting disrupt the turtle?)
    -- how does bluetooth pair?
    -- other conputer handshake things
    -- need to sort out the rednetUtils

    -- computer broadcast "I am ready to pair, here is my id"
    -- turtle directly "I want to pair with you, here's my id"
    -- computer broadcast "I have paired with a turtle with id"
  end

  -- if nothing is mapped yet then start mapping
  if not (chestMap.input and chestMap.output and chestMap.charcoal and chestMap.saplings and chestMap.logs) then -- always reset if one fails?

    monitor.clear()
    monitor.write("Please don't open the chests or drop items into the water stream, chest mapping in progress")


    -- filter names for chests and get their inital state
    local chestStates = {}
    local peripherals = peripheral.getNames()
    for _, peripheralName in pairs(peripherals) do
      if string.find(peripheralName, "chest") then
          chestStates[peripheralName] = peripheral.call(peripheralName, "list")
      end
    end

    -- TODO: message the turtle to drop stuff #turtle
    -- need to tell the turtle how many chests we have so that it can drop atleast that many items (could get away with one less as one will be the input chest)
    -- TODO: wait for turtle to say that it has dropped the stuff #turtle

    -- TODO: what if the turtle doesn't have enough items to drop? #turtle
      -- have the turtle message as if an error accured

    monitor.clear()
    monitor.write("waiting for drop signal")
    os.pullEvent("monitor_touch")

    -- wait a few seconds for the items to get the chest
    sleep(5)

    -- the chest which has different items in is the input chest
    for chestName, oldState in pairs(chestStates) do
      local newState = peripheral.call(chestName, "list")
      for slot, item in pairs(oldState) do
        if itemUtils.itemEqualityComparerWithQuantity(newState[slot], item) then
          chestMap.input = chestName
          chestStates[chestName] = nil
          break
        end
      end
      if chestMap.input then -- early exit
        break
      end
    end

    -- move one item to each of the other chests and rescan the chest states
    for chestName in pairs(chestStates) do
      local fromSlot
      for k in pairs(peripheral.call(chestName, "list")) do -- any slot with an item will do
        if type(k) == "number" then
          fromSlot = k
          break
        end
      end
      peripheral.call(chestMap.input, "pushItems", chestName, fromSlot, 1)
      chestStates[chestName] = peripheral.call(chestName, "list")
    end


    -- TODO: message the turtle to remove an item from the charcoal chest #turtle
    monitor.clear()
    monitor.write("waiting for turtle to remove item from charcoal chest")
    os.pullEvent("monitor_touch")

    -- the chest now missing an item is the charcoal chest
    for chestName, oldState in pairs(chestStates) do
      local newState = peripheral.call(chestName, "list")
      for slot, item in pairs(oldState) do
        if itemUtils.itemEqualityComparerWithQuantity(newState[slot], item) then
          chestMap.charcoal = chestName
          chestStates[chestName] = nil
          break
        end
      end
      if chestMap.charcoal then -- early exit
        break
      end
    end

    -- TODO: message the turtle to remove an item from the sapling chest #turtle
    monitor.clear()
    monitor.write("waiting for turtle to remove item from sapling chest")
    os.pullEvent("monitor_touch")

    -- the chest now missing an item is the sapling chest
    for chestName, oldState in pairs(chestStates) do
      local newState = peripheral.call(chestName, "list")
      for slot, item in pairs(oldState) do
        if itemUtils.itemEqualityComparerWithQuantity(newState[slot], item) then
          chestMap.sapling = chestName
          chestStates[chestName] = nil
          break
        end
      end
      if chestMap.saplings then -- early exit
        break
      end
    end

    -- TODO: message the turtle to remove an item from the log chest #turtle
    monitor.clear()
    monitor.write("waiting for turtle to remove item from log chest")
    os.pullEvent("monitor_touch")

    -- the chest now missing an item is the log chest
    for chestName, oldState in pairs(chestStates) do
      local newState = peripheral.call(chestName, "list")
      for slot, item in pairs(oldState) do -- TODO: should be for each slot?
        if itemUtils.itemEqualityComparerWithQuantity(newState[slot], item) then
          chestMap.logs = chestName
          chestStates[chestName] = nil
          break
        end
      end
      if chestMap.logs then -- early exit
        break
      end
    end


    -- every other chest is an output chest
    chestMap.output = {}
    for chestName in pairs(chestStates) do
      table.insert(chestMap.output, chestName)
      chestStates[chestName] = nil
    end

    -- update monitor to say that chest mapping is complete
    monitor.clear()
    monitor.write("Chest mapping complete")

    -- save maps (only need to save chests, the others can be rediscovered on next load)
    config.save(chestMapFile, chestMap)

  end

  -- wrap the chests
  for chestRole, peripheralName in pairs(chestMap) do
    if type(peripheralName) == "table" then -- output "chest" is a list of chests not a single chest
      chests[chestRole] = invUtils.inject(virtualChestMerge.wrap(table.unpack(peripheralName)))
    else
      chests[chestRole] = invUtils.inject(virtualChestMerge.wrap(peripheralName))
    end
  end
end

local outputChestFull()
  -- TODO: pause everything
  -- stop the turtle and let the user know that the program has stopped because the output is full
  monitor.clear()
  monitor.write("PAUSED: Output inventory is full")
  os.pullEvent("monitor_touch")
  -- need an event which tells us that the output has space again
end

local function outputChestExtender()
  while true do
    local event, side = os.pullEvent()
    if event == "peripheral" or event == "peripheral_detach" then
      local chestMap
      local ok, data = config.load(chestMapFile)
      if ok then
        chestMap = data
      else
        if data == "not a file" then
          chestMap = {}
        else
          error("couldn't load file with name: "..chestMapFile
          .."\ngot error: "..data)
        end
      end

      if event == "peripheral" then
        chests.output.addBackingPeripheral(side)
        table.insert(chestMap.output, chestName)
      else -- detach
        local removed = chests.output.removeBackingPeripheral(side)
        if not (removed and removed[side]) then
          -- one of the other peripherals which don't support hotswapping no longer exist
          error("A required peripheral was detached "..side)
        end
      end

      config.save(chestMapFile, chestMap)
    end
  end
end

local function emptyInputChest()
  local wrappedInputChest = virtualChestMerge.wrap(chests.input.PERIPHERAL_NAME)
  for slot, item in pairs(chests.input.list()) do
    local destination
    if itemUtils.itemEqualityComparer(item, itemIds.sapling) then
      destination = chests.saplings
    elseif itemUtils.itemEqualityComparer(item, itemIds.charcoal) then
      destination = chests.charcoal
    elseif itemUtils.itemEqualityComparer(item, itemIds.log) then
      destination = chests.logs
    else -- junk
      destination = chests.output
    end
    local moved = wrappedInputChest.pushItems(destination.PERIPHERAL_NAME, slot)
    if moved < item.count then -- if it's junk then we push to output twice but it should be fine
      moved = moved + wrappedInputChest.pushItems(chests.output.PERIPHERAL_NAME, slot)
      if moved < item.count then
        outputChestFull()
      end
    end
  end
end

local function emptyFurnaces()
  for _, furnace in pairs(furnaces) do
    local moved = furnace.pushItems(chests.charcoal.PERIPHERAL_NAME, FURNACE_OUTPUT_SLOT)
    if moved < item.count then
      moved = moved + furnace.pushItems(chests.output.PERIPHERAL_NAME, FURNACE_OUTPUT_SLOT)
      if moved < item.count then
        outputChestFull()
      end
    end
  end
end

local function loadFurnaces()
  for _, furnace in pairs(furnaces) do
    -- make sure that each has a multiple of 8
    local inputItemStack = furnace.getItemMeta(FURNACE_INPUT_SLOT)
    local inputItemCount = inputItemStack and inputItemCount.count or 0
    local charcoalItemBurnCount = fuelValueForFurnace(itemIds.charcoal)
    local limit = inputItemCount % charcoalItemBurnCount
    limit = limit == 0 and charcoalItemBurnCount or limit -- if at 8 add another 8 else add enough to make it 8
    if inputItemCount < inputItemStack.maxCount and chests.logs.getTotalItemCount(itemIds.log) > limit then
      for slot in chests.logs.eachSlotWithItem(itemIds.log) do
        limit = limit - furnace.pullItems(chests.logs.PERIPHERAL_NAME, slot, limit, FURNACE_INPUT_SLOT)
        if limit == 0 then
          break
        end
      end
    end
  end
end

local function fuelFurnaces()
  local emergencyState = setmetatable({}, {
    __call = function(t)
      for _, v in pairs(t) do
        if not v then
          furnaceLowEfficiencyMode = false
          return false
        end
      end
      furnaceLowEfficiencyMode = true
      return true
    end
  })

  for furnaceId, furnace in pairs(furnaces) do
    -- control furnace with fuel, only add fuel if there are 8 items and output spaces
    local inputItemStack = furnace.getItemMeta(FURNACE_INPUT_SLOT)
    local fuelItemStack = furnace.getItemMeta(FURNACE_FUEL_SLOT)
    local outputItemStack = furnace.getItemMeta(FURNACE_OUTPUT_SLOT)

    local inputItemCount = inputItemStack and inputItemCount.count or 0
    local fuelItemCount = fuelItemStack and fuelItemStack.count or 0
    local outputItemSpace = outputItemStack and outputItemStack.maxCount - outputItemStack.count or 64

    local safeSmeltCount = math.min(inputItemCount, outputItemSpace)
    local requiredFuelCount = math.floor(safeSmeltCount / fuelValueForFurnace(itemIds.charcoal))

    local limit = requiredFuelCount
    if limit > 0 then
      for slot in chests.charcoal.eachSlotWithItem(itemIds.charcoal) do
        limit = limit - furnace.pullItems(chests.charcoal.PERIPHERAL_NAME, slot, limit, FURNACE_FUEL_SLOT)
        if limit == 0 then
          break
        end
      end
    end
    emergencyState[furnaceId] = (limit == requiredFuelCount and outputItemSpace == 64) -- we didn't get any fuel and our output (which would have more fuel) is empty
  end



  if emergencyState() then
    -- TODO: emergency mode: furnace[1] checks its fuel status and uses one log if it's out and not burning pending logs
    local furnace = furnaces[1]
    local inputItemStack = furnace.getItemMeta(FURNACE_INPUT_SLOT)
    local inputItemCount = inputItemStack and inputItemCount.count or 0
    -- what if out of logs?

  end
end

-- TODO: support dynamic furnace adding/removing?

-- TODO: farm manager watchdog for if the farm manager forwards an error to us
local function farmerWatchdog()
  -- listen for specific rednet messages
  -- mark the screen if one such message is recived
end

local function run()
  -- TODO: pcall things and for any uncaught errors mark the screen
end


local furnaceManager = {
  run = run
}

return furnaceManager
