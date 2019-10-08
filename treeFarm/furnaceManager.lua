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
local chests = {} -- input, output, refuel
local furnaces = {}
local wirelessModem -- NOTE: should I move the wireless modemodem onto the computer or just upstairs? code shouldn't care as I use peripheral.find
local monitor

-- TODO: test furnace slots
local furnaceInputSlotNumber = 1
local furnaceFuelSlotNumber = 2
local furnaceOutputSlotNumber = 3

local linkedTurtleId = "manualTesting" -- TODO: change to nil and implement turtle pairing and communicating

local function fuelValueForFurnace(turtleFuelValue)
  argChecker(1, turtleFuelValue, {"number"})
  return turtleFuelValue/10
end

-- NOTE: don't fill the turtle refuel chest, just keep a stack of both items in there.

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
        furnaces[k]._peripheralName = peripheralName
    end
  end




  -- if we have a turtle then test the connection to make sure it still exists
  if linkedTurtleId then
    --TODO: ping the turtle, if no responce then unpair the turtle
    monitor.clear()
    monitor.write("Player is standing in for the turtle for init testing, click the monitor to continue")
    os.pullEvent("monitor_touch")
  end


  if not linkedTurtleId then

    monitor.clear()
    monitor.write("Waiting to pair with turtle, pairing code: "..os.getComputerID().."\nplease access turtle and pair")

    -- TODO: how to do pairing
    -- rednet host stuff? unhost once paired (will unhosting disrupt the turtle?)
    -- how does bluetooth pair?
    -- other conputer handshake things
    -- need to sort out the rednetUtils

    -- computer broadcast "I am ready to pair, here is my id"
    -- turtle directly "I want to pair with you, here's my id"
    -- computer broadcast "I have paired with a turtle with id"
  end

  -- if nothing is mapped yet then start mapping
  if (not chestMap.input) or (not chestMap.output) or (not chestMap.refuel) then

    monitor.clear()
    monitor.write("Please don't open the chests or drop items into the water stream, chest mapping in progress")


    -- filter names for chests and get their inital state
    local chestStates = {}
    for _, peripheralName in pairs(peripherals) do
      if string.find(peripheralName, "chest") then
          chestStates[peripheralName] = peripheral.call(peripheralName, "list")
      end
    end

    -- TODO: message the turtle to drop stuff
    -- need to tell the turtle how many chests we have so that it can drop atleast that many items (could get away with one less as one will be the input chest)
    -- TODO: wait for turtle to say that it has dropped the stuff

    -- TODO: what if the turtle doesn't have enough items to drop?

    monitor.clear()
    monitor.write("waiting for drop signal")
    os.pullEvent("monitor_touch")

    -- wait a few seconds for the items to get the chest
    sleep(5) -- TODO: time how long it takes for items to move from the turtles best drop position #homeOnly

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
      peripheral.call(chestMap.input, "pushItem", chestName, fromSlot, 1)
      chestStates[chestName] = peripheral.call(chestName, "list")
    end


    -- TODO: message the turtle to remove an item from the refuel chest
    monitor.clear()
    monitor.write("waiting for turtle to remove item from refuel chest")
    os.pullEvent("monitor_touch")

    -- the chest now missing an item which is not the input chest is the refuel chest
    for chestName, oldState in pairs(chestStates) do
      local newState = peripheral.call(chestName, "list")
      for slot, item in pairs(oldState) do
        if itemUtils.itemEqualityComparerWithQuantity(newState[slot], item) then
          chestMap.refuel = chestName
          chestStates[chestName] = nil
          break
        end
      end
      if chestMap.refuel then -- early exit
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

local function emptyCollectionChest()
  -- TODO: implement emptyCollectionChest
  -- for each slot in the imput chest
    -- if the item stack is saplings then put as much as possible in the turtle's refuel chest and move the rest to the output chests
    -- elseif the item is logs then move half of it to the furnaces input (make multiples of 8) and the other half to the output chests
    -- else move the item to the output chests

end

-- TODO: how much fuel to keep where?

local function refuelfurnaces() -- NOTE: can I get this to use different fuels?
  -- TODO: implement refuelfurnaces
  -- if a furnace has 8 items or more that will not get smelted due to insufficent fuel then search output chests and furnace output slots and add a charcoal
end

local function emptyFurnaces()
  for k, v in ipairs(furnaces) do
    chests.refuel.pullItems(v, furnaceOutputSlotNumber)
  end
end

local function refillTurtleChest()
  -- TODO: implement refillTurtleChest
  -- move stuff from the output chests to fill the turtle chest
  -- move oeverflow to output
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
