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
local chests = {} -- input, output, charcoal, sapling, log
local furnaces = {}
local wirelessModem
local monitor

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
  if not (chestMap.input and chestMap.output and chestMap.charcoal and chestMap.sapling) then -- always reset if one fails?

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

    -- the chest which has different items in the input chest
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
      if chestMap.sapling then -- early exit
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
          chestMap.log = chestName
          chestStates[chestName] = nil
          break
        end
      end
      if chestMap.log then -- early exit
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
      chests[chestRole] = virtualChestMerge.wrap(table.unpack(peripheralName))
    else
      chests[chestRole] = virtualChestMerge.wrap(peripheralName)
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
  local wrappedInputChest = virtualChestMerge.wrap(chest.input.PERIPHERAL_NAME)
  for slot, item in pairs(chest.input.list()) do
    local destination
    if itemUtils.itemEqualityComparer(item, itemIds.sapling) then
      destination = chests.saplings
    elseif itemUtils.itemEqualityComparer(item, itemIds.charcoal) then
      destination = chests.charcoal
    elseif itemUtils.itemEqualityComparer(item, itemIds.log) then
      destination = chests.log
    else -- junk
      destination = chests.output
    end
    local moved = wrappedInputChest.pushItems(destination.PERIPHERAL_NAME, slot)
    if moved < item.count then -- if it's junk then we push to output twice but it should be fine
      moved = moved + wrappedInputChest.pushItems(chest.output.PERIPHERAL_NAME, slot)
      if moved < item.count then
        outputChestFull()
      end
    end
  end
end

local function emptyFurnaces()
  for _, furnace in pairs(furnaces) do
    local moved = furnace.pushItems(chest.charcoal.PERIPHERAL_NAME, FURNACE_OUTPUT_SLOT)
    if moved < item.count then
      moved = moved + furnace.pushItems(chest.output.PERIPHERAL_NAME, FURNACE_OUTPUT_SLOT)
      if moved < item.count then
        outputChestFull()
      end
    end
  end
end

local function loadFurnaces()
  -- TODO: how to do load splitting?
  -- make sure that each has 16 then round robin the extra in 8's
  for _, furnace in pairs(furnaces) do
    for i = 1, chest.charcoal.size() do

    end
    local limit = 2
    local moved = furnace.pullItems(chest.charcoal.PERIPHERAL_NAME, 1, limit, FURNACE_INPUT_SLOT)
    if moved < limit then
      for
        furnace.pullItems(chest.output.PERIPHERAL_NAME, 1, limit, FURNACE_INPUT_SLOT)
      end
    end
  end
end

local function fuelFurnaces()
  -- if we empty the charcoal chest should we start pulling from output?
  for _, furnace in pairs(furnaces) do
    -- control furnace with fuel, only add fuel if there are 8 items and output spaces
    local inputItemStack = furnace.getItemMeta(FURNACE_INPUT_SLOT)
    local fuelItemStack = furnace.getItemMeta(FURNACE_FUEL_SLOT)
    local outputItemStack = furnace.getItemMeta(FURNACE_OUTPUT_SLOT)

    local inputItemCount = inputItemStack and inputItemCount.count or 0
    local fuelItemCount = fuelItemStack and fuelItemStack.count or 0
    local outputItemSpace = outputItemStack and outputItemStack.maxCount - outputItemStack.count or 64

    -- make sure that there is atleast 16 items and spaces and one fuel, the odd 8 is a buffer for efficient fuel use

    -- TODO: implement fuelFurnaces

  end
end

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
