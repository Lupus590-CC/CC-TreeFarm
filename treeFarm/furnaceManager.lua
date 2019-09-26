require("treeFarm.libs.argChecker")
local utils = require("treeFarm.libs.utils")
local itemUtils = utils.itemUtils
local itemIds = itemUtils.itemIds
local daemonManager = require("treeFarm.libs.daemonManager")
local config = require("treeFarm.libs.config")
local taskManager = require("treeFarm.libs.taskManager")
local checkpoint = require("treeFarm.libs.checkpoint") -- do I need this here? I could just parallel all of the functions

-- maps peripheral names
local chestMapFile = ".chestMap"
local chestMap = {}
local furnaces = {}
local wirelessModem -- NOTE: should I move the wireless modemodem onto the computer or just upstairs?
local monitor


local function fuelValueForFurnace(turtleFuelValue)
  argChecker(1, turtleFuelValue, {"number"})
  return turtleFuelValue/10
end

-- NOTE: don't fill the turtle refuel chest, just keep a stack of both items in there.

local function init()
  -- check config for peripheral map
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
    monitor = peripheral.find("monitor") -- TODO: test this #homeOnly
    wirelessModem = peripheral.find("modem", function(_, m) return m.isWireless() end) -- TODO: test this #homeOnly
    furnaces = table.pack(peripheral.find("furnace")) -- TODO: test this #homeOnly




  -- if we have a turtle then test the connection to make sure it still exists
  if turtle then -- TODO: proper check
    --ping the turtle, if no responce then unpair the turtle
  end


  -- TODO: if turtle not paired
  -- change to while not turtle
  if not turtle then -- TODO: proper check

    -- TODO: link to the turtle
    monitor.clear()
    monitor.write("Waiting to pair with turtle, pairing code: "..os.computerId().."\nplease access turtle and pair") -- TODO: test this #homeOnly

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
  if not chestMap.input then

    monitor.clear()
    monitor.write("Please don't open the chests, chest mapping in progress")


    -- filter names for chests and get their inital state
    local chestStates = {}
    local peripherals = peripheral.getNames()
    for _, peripheralName in pairs(peripheral) do
      if string.find(peripheralName, "chest") then
          chestStates[peripheralName] = peripheral.call(peripheralName, "list")
      end
    end

    -- message the turtle to drop stuff
    -- TODO: turtle drops 3 items
    -- wait for turtle to say that it has dropped the stuff

    -- the chest which has different items in the input chest
    for chestName, oldState in pairs(chestStates) do
      local newState = peripheral.call(chestName, "list")
      for slot, item in pairs(oldState) do
        if newState[slot] ~= item then -- TODO: item is a table, this will always fail
          chestMap.input = chestName
          chestStates[chestName] = nil
          break
        end
      end
      if chestMap.input then -- early exit
        break
      end
    end
    -- TODO: move one item to each other chests


    -- the turtle sucks an item from the output chest
    -- the chest now missing an item which is not the input chest is the refuel chest
    -- every other chest is an output chest
    chestMap.output = {}
    for chestName in pairs(chestStates) do
      table.insert(chestMap.output, chestName) -- TODO: can I virtually combine of the output chests like a RAID on several HDD
      -- meta table methods on the chestMap.output table?
      chestStates[chestName] = nil
    end

    -- update monitor to say that chest mapping is complete
    monitor.clear()
    monitor.write("Chest mapping complete")

    -- TODO: save maps (only need to save chests, the others can be rediscovered on next load)
    config.save(chestMapFile, chestMap)

  else
  -- else wrap the peripherals from the config
    -- where to put variable names for these wrapped peripherals?
    -- have each function wrap its own?
  end
end

local function emptyCollectionChest()
  -- TODO: implement
  -- for each slot in the imput chest
    -- if the item stack is saplings then put as much as possible in the turtle's refuel chest and move the rest to the output chests
    -- elseif the item is logs then move half of it to the furnaces input (make multiples of 8) and the other half to the output chests
    -- else move the item to the output chests

end

local function refuelfurnaces() -- NOTE: can I get this to use different fuels?
  -- TODO: implement
  -- if a furnace has 8 items or more that will not get smelted due to insufficent fuel then search output chests and furnace output slots and add a charcoal
end

local function emptyFurnaces()
  -- TODO: implement
  -- just dump everything in the output slot into the output chests
  -- don't forget the turtle refuel chest
end

local function refillTurtleChest()
  -- TODO: implement
  -- move stuff from the output chests to fill the turtle chest
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
  loadThisFurnace = loadThisFurnace,
  getResources = getResources,
  putAwayNotWood = putAwayNotWood,
  run = run
}

return furnaceManager
