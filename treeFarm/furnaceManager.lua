require("treeFarm.libs.argChecker")
local checkpoint = require("treeFarm.libs.checkpoint")
local lama = require("treeFarm.libs.lama")
local utils = require("treeFarm.libs.utils")
local patience = require("treeFarm.libs.patience")
local daemonManager = require("treeFarm.libs.daemonManager")
local config = require("treeFarm.libs.config")
local taskManager = require("treeFarm.libs.taskManager")



local function fuelValueForFurnace(turtleFuelValue)
  argChecker(1, turtleFuelValue, {"number"})
  return turtleFuelValue/10
end


local function loadThisFurnace(subState) -- TODO: empty the furnace first?
  -- TODO: what to do if this is interupted by chunk unload?
  -- could do alot of checkpoints for each step
  -- thats a lot of functions
  -- could use args and different lables.


  -- Assumption, facing the furnace on the same level as it
  emptyThisFurnace() -- what to do with the stuff we took out?

  -- go to top of furnace
  turtle.up()
  turtle.forward()
  -- select wood
  -- place in furnace -- what if there is stuff in there? -- TODO: can turtles take from furnace's input/fuel slots? #homeOnly

  -- go to side of furnace
  turtle.back()
  turtle.down()
  -- select and place fuel

  -- update furnaceStates
  local ok, err = config.save(furnaceStatesFile, furnaceStates)
  if not ok then
    error("Error saving furnace state: "..err)
  end



  if subState == "state1" then

  elseif subState == "state2" then

  elseif subState == "state3" then

  else
    error("bad subState: "..tostring(subState), 2)
  end
end
checkpoint.add("loadThisFurnace", loadThisFurnace, "state1")
checkpoint.add("loadThisFurnace:state1", loadThisFurnace, "state1")
checkpoint.add("loadThisFurnace:state2", loadThisFurnace, "state2")
checkpoint.add("loadThisFurnace:state3", loadThisFurnace, "state3")

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
