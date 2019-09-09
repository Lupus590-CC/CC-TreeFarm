require("treeFarm.libs.argChecker")
local utils = require("treeFarm.libs.utils")
local itemUtils = utils.itemUtils
local itemIds = itemUtils.itemIds
local daemonManager = require("treeFarm.libs.daemonManager")
local config = require("treeFarm.libs.config")
local taskManager = require("treeFarm.libs.taskManager")
local checkpoint = require("treeFarm.libs.checkpoint") -- do I need this here? I could just parallel all of the functions

-- maps peripheral names
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
  -- check confog for peripheral map

  -- if nothing is mapped yet then

    -- link to the turtle

    -- discover peripherals
    local peripherals = peripheral.getNames()
    -- TODO: bind the non-chest peripherals
    -- filter names for chests
    -- turtle drops 3 items
    -- the chest which gains 3 items in the input chest
    -- move one item to each other chest
    -- the turtle sucks an item from the output chest
    -- the chest now missing an item which is not the input chest is the refuel chest
    -- every other chest is an output chest
  -- else wrap the peripherals from the config
    -- where to put variable names for these wrapped peripherals?
    -- have each function wrap its own?
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
