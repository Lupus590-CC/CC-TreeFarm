require("treeFarm.libs.errorCatchUtils")
local utils = require("treeFarm.libs.utils")
local itemUtils = utils.itemUtils
local itemIds = itemUtils.itemIds
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

local furnaceInputSlotNumber = 1
local furnaceFuelSlotNumber = 2
local furnaceOutputSlotNumber = 3

local linkedTurtleId = "manualTesting" -- TODO: change to nil and implement turtle pairing and communicating #turtle

local function fuelValueForFurnace(turtleFuelValue)
  argChecker(1, turtleFuelValue, {"number"})
  return turtleFuelValue/10
end


local function init()
  -- check config for peripheral map
  local chestMap = {}
  local ok, data =  config.load(chestMapFile)
  if ok then
    timers = data
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
  furnaces = table.pack(peripheral.find("minecraft:furnace"))
  local peripherals = peripheral.getNames()
  for k, peripheralName in pairs(peripherals) do
    if string.find(peripheralName, "furnace") then
        furnaces[k] = virtualChestMerge.wrap(peripheralName)
    end
  end




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
  if not (chestMap.input and chestMap.output and chestMap.charcoal and chestMap.sapling) then

    monitor.clear()
    monitor.write("Please don't open the chests or drop items into the water stream, chest mapping in progress")


    -- filter names for chests and get their inital state
    local chestStates = {}
    for _, peripheralName in pairs(peripherals) do
      if string.find(peripheralName, "chest") then
          chestStates[peripheralName] = peripheral.call(peripheralName, "list")
      end
    end

    -- TODO: message the turtle to drop stuff #turtle
    -- need to tell the turtle how many chests we have so that it can drop atleast that many items (could get away with one less as one will be the input chest)
    -- TODO: wait for turtle to say that it has dropped the stuff #turtle

    -- TODO: what if the turtle doesn't have enough items to drop? #turtle

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
      for slot, item in pairs(oldState) do
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

local function compactSlots(chest)
  tableChecker("arg[1]", chest, {list = {"function"}, _peripheralName = {"string"}, pushItems = {"function"}})
  for slot in pairs(chest.list()) do
    chest.pushItems(chest._peripheralName, slot)
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

-- NOTE: SquidDev says that it should be safe to split up and parallelise this function
local function chestAndFurnaceManagmentLoop()
  -- remove junk from the input chest
  for slot, item in pairs(chest.input.list()) do
    if not (itemUtils.itemEqualityComparer(item, itemIds.sapling) or itemUtils.itemEqualityComparer(item, itemIds.charcoal) or itemUtils.itemEqualityComparer(item, itemIds.log)) then
      local moved = chest.input.pushItems(chest.output._peripheralName, slot)
      if moved < item.count then
        outputChestFull()
      end
    end
  end

  -- if any of the other chests end up full then let it 'overflow' into the output chest

  -- TODO: lots of repeated code here
  -- restock the charcoal chest from the input chest
  for slot, item in pairs(chest.input.list()) do
    if itemUtils.itemEqualityComparer(item, itemIds.charcoal) then
      local moved = chest.input.pushItems(chest.charcoal._peripheralName, slot)
      if moved < item.count then
        break -- chest full
      end
    end
  end

  -- move any remaining charcoal to the output chest
  for slot, item in pairs(chest.input.list()) do
    if itemUtils.itemEqualityComparer(item, itemIds.charcoal) then
      local moved = chest.input.pushItems(chest.output._peripheralName, slot)
      if moved < item.count then
        outputChestFull()
      end
    end
  end

  -- restock the sapling chest from the input chest
  for slot, item in pairs(chest.input.list()) do
    if itemUtils.itemEqualityComparer(item, itemIds.sapling) then
      local moved = chest.input.pushItems(chest.sapling._peripheralName, slot)
      if moved < item.count then
        break -- chest full
      end
    end
  end

  -- move any remaining saplings to the output chest
  for slot, item in pairs(chest.input.list()) do
    if itemUtils.itemEqualityComparer(item, itemIds.sapling) then
      local moved = chest.input.pushItems(chest.output._peripheralName, slot)
      if moved < item.count then
        outputChestFull()
      end
    end
  end

  -- restock the log chest from the input chest
  for slot, item in pairs(chest.input.list()) do
    if itemUtils.itemEqualityComparer(item, itemIds.log) then
      local moved = chest.input.pushItems(chest.log._peripheralName, slot)
      if moved < item.count then
        break -- chest full
      end
    end
  end

  -- move any remaining logs to the output chest
  for slot, item in pairs(chest.input.list()) do
    if itemUtils.itemEqualityComparer(item, itemIds.log) then
      local moved = chest.input.pushItems(chest.output._peripheralName, slot)
      if moved < item.count then
        outputChestFull()
      end
    end
  end

  -- empty out the output of the furnaces, only remove 8 at a time so that if the output is full then it won't waste fuel
  for _, furnace in pairs(furnaces) do
    local item = furnace.getItemMeta(furnaceOutputSlotNumber)
    local currentCount = item and item.count or 0
    local moveLimit = 0
    while currentCount > moveLimit + 8 do
      moveLimit = moveLimit + 8
    end
    if moveLimit > 0 then
      furnace.pushItems(chests.charcoal._peripheralName, furnaceOutputSlotNumber, moveLimit)
    end
  end


  -- restock the charcoal chest from the input chest
  for slot, item in pairs(chest.input.list()) do
    if itemUtils.itemEqualityComparer(item, itemIds.charcoal) then
      local moved = chest.input.pushItems(chest.charcoal._peripheralName, slot)
      if moved < item.count then
        break -- chest full
      end
    end
  end

  -- move any remaining charcoal to the output chest
  for slot, item in pairs(chest.input.list()) do
    if itemUtils.itemEqualityComparer(item, itemIds.charcoal) then
      local moved = chest.input.pushItems(chest.output._peripheralName, slot)
      if moved < item.count then
        outputChestFull()
      end
    end
  end


  -- TODO: refuel the furnaces
  -- if we frequently empty the charcoal chest then start pulling from output
  for _, furnace in pairs(furnaces) do
    for i = 1, chest.charcoal.size() do

    end
    local limit = 2
    local moved = furnace.pullItems(chest.charcoal._peripheralName, 1, limit, furnaceInputSlotNumber)
    if moved < limit then
      for
        furnace.pullItems(chest.output._peripheralName, 1, limit, furnaceInputSlotNumber)
      end
    end
  end

  -- TODO: reload the furnaces, 8 at a time to use fuel efficiently
  -- TODO: add a furnace log intermediary chest #homeOnly
  --[[for _, furnace in pairs(furnaces) do
    local item = furnace.getItemMeta(furnaceOutputSlotNumber)
    local currentCount = item and item.count or 0
    local moveLimit = 0
    while currentCount > moveLimit + 8 do
      moveLimit = moveLimit + 8
    end
    if moveLimit > 0 then
      furnace.pushItems(chests.charcoal._peripheralName, furnaceOutputSlotNumber, moveLimit)
    end
  end]]

  -- restock the charcoal chest from the output chest
  for slot, item in pairs(chest.output.list()) do
    if itemUtils.itemEqualityComparer(item, itemIds.charcoal) then
      local moved = chest.input.pushItems(chest.charcoal._peripheralName, slot)
      if moved < item.count then
        break -- chest full
      end
    end
  end

  -- restock the sapling chest from the output chest
  for slot, item in pairs(chest.output.list()) do
    if itemUtils.itemEqualityComparer(item, itemIds.sapling) then
      local moved = chest.input.pushItems(chest.sapling._peripheralName, slot)
      if moved < item.count then
        break -- chest full
      end
    end
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
