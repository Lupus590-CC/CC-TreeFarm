require("treeFarm.libs.argChecker")
local checkpoint = require("treeFarm.libs.checkpoint")
local lama = require("treeFarm.libs.lama")
local utils = require("treeFarm.libs.utils")
local itemUtils = utils.itemUtils
local itemIds = itemUtils.itemIds
local patience = require("treeFarm.libs.patience")
local daemonManager = require("treeFarm.libs.daemonManager")
local config = require("treeFarm.libs.config")
local taskManager = require("treeFarm.libs.taskManager")

-- TODO: with plethora the furnace manager could be a computer

local function fuelValueForFurnace(turtleFuelValue)
  argChecker(1, turtleFuelValue, {"number"})
  return turtleFuelValue/10
end


local function loadThisFurnace(subState)
  -- Assumption for initual call, facing the furnace on the same level as it


  -- just have one furnace? empty it when we put more stuff in?

  subState = subState or "placeWood"
  if subState == "placeWood" then
    checkpoint.reach("loadThisFurnace:placeWood")

    -- TODO: check that we have enough charcoal
    if countItemQuantityById(itemIds.log) < 8 then
      subState = "abort"
    end

    local hasBlock, blockId = turtle.inspect()
    if blockId.name == itemIds.furnace.name then
      turtle.up()
    end

    hasBlock = turtle.detect()
    if not hasBlock then
      turtle.forward()
    end

    -- TODO: allow varous amounts of wood? will need to update fuel too
    selectItemById(itemIds.log)
    if turtle.getItemcount() < 8 then
      local electedSlot = turtle.getSelectedSlot()
      -- TODO: merge stacks untill we have 8 logs in one stack
      itemUtils.forEachSlotWithItem(itemIds.log, func[slotId, currentItem], extentionCriteria[slotId, currentItem])

      turtle.select(electedSlot)
      if turtle.getItemcount() < 8 then
        subState = "abort"
      end
    end

    if subState ~= "abort" then
      -- we found enough wood
      turtle.dropDown(8)

      checkpoint.reach("loadThisFurnace:placeFuel")
      subState = "placeFuel"
    end
  end
  if subState == "placeFuel" then

    local hasBlock, blockId = turtle.inspectDown()
    if blockId.name == itemIds.furnace.name then
      turtle.back()
    end

    hasBlock = turtle.detect()
    if not hasBlock then
      turtle.down()
    end

    turtle.selectItemById(itemIds.charcoal) -- TODO: adapt for other fuel, wood drop off assumes optimal smelt count of 8
    turtle.drop(1) -- TODO: how much fuel

    -- TODO: update furnaceStates
    local ok, err = config.save(furnaceStatesFile, furnaceStates)
    if not ok then
      error("Error saving furnace state: "..err)
    end

  end


end
checkpoint.add("loadThisFurnace", loadThisFurnace)
checkpoint.add("loadThisFurnace:placeWood", loadThisFurnace, "placeWood")
checkpoint.add("loadThisFurnace:placeFuel", loadThisFurnace, "placeFuel")
-- it takes about 20 seconds for items to get from the furthest point to the chest
-- it will probably take this turtle longer than that to get to the chest
local function getResources(subState) -- empty the bottom chest
  -- go to the exit
  -- go down to the chest
  -- suck as much as there is inventory space -- TODO: if there is only wood in the turtle and the first slot in the chest is not wood what happens? #homeOnly
  -- go back up to furnace room
  -- TODO: need a goto function?

  -- NOTE: home when there is nothing cooking is the input chest
  -- this means that this function needs replanned

  if subState == "goToChest" then

  elseif subState == "emptyChest" then

  elseif subState == "goBack" then

  else
    error("bad subState: "..tostring(subState), 2)
  end
end
checkpoint.add("getResources", getResources, "goToChest")
checkpoint.add("getResources:goTochest", getResources, "goToChest")
checkpoint.add("getResources:emptyChest", getResources, "emptyChest")
checkpoint.add("getResources:goBack", getResources, "goBack")

local function putAwayNotWood(subState)
  -- go to sapling chest
  -- put all saplings into chest

  -- NOTE: is this needed?
  -- go to fuel chest
  -- put spare charcoal in chest

  -- go to junk chest
  -- put in everything but the wood and fuel
  if subState == "state1" then

  elseif subState == "state2" then

  elseif subState == "state3" then

  else
    error("bad subState: "..tostring(subState), 2)
  end
end
checkpoint.add("putAwayNotWood", putAwayNotWood, "state1")
checkpoint.add("putAwayNotWood:state1", putAwayNotWood, "state1")
checkpoint.add("putAwayNotWood:state2", putAwayNotWood, "state2")
checkpoint.add("putAwayNotWood:state3", putAwayNotWood, "state3")



-- NOTE: have a task list?
  -- check wood chest
  -- empty this furnace

-- NOTE: the logging turtle could message the furnace turtle that it's dropped off more wood -- note, range issues. could use repeater or wait out thunderstorms (or only drop at specific spots where the range is known to be good iven during thunderstorms)

-- NOTE: furnace turtle could be the server

-- TODO: if it's not a log move it to the sapling or junk chest



-- collect from input
-- put sapligs away
-- put half of wood away -- TODO: furnaces take 8 wood at a time, what to do if half of the wood doesn't divide nicely like that?
 -- split the inventory? there is a slot for wood that should be burned and any wood outside of that is not sorted yet
 -- will that mean that there needs to be another wood chest, one for burning and another for keep
-- load up furnaces
-- collect from furnaces -- TODO: how to divide up fuel?
-- put some (ow much) charcoal back into furnace
-- put some charcoal into the output chest -- the rest stays in the turtle for it to used

local function run()
  -- TODO: pcall things and for any uncaught errors, message the other turtle
end


local furnaceManager = {
  loadThisFurnace = loadThisFurnace,
  getResources = getResources,
  putAwayNotWood = putAwayNotWood,
  run = run
}

return furnaceManager
