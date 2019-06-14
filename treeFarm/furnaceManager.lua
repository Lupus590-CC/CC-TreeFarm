require("libs.argChecker")
local checkpoint = require("libs.checkpoint")
local lama = require("libs.lama")
local utils = require("libs.utils")
local patience = require("libs.patience")
local daemonManager = require("libs.daemonManager")
local config = require("libs.config")


-- TODO: should the furnace turtle have a crafting peripheral?

local furnaceStatesFile = ".furnaceStates"
--[[
local furnaceStates = {
  [timerId] = {
    furnaceId -- use position instead?
  }
}
]]

local furnaceStates, err = config.load(furnaceStatesFile)
if not furnaceStates then
  error("Error loading furnace states: "..err)
end

local function fuelValueForFurnace(turtleFuelValue)
  argChecker(1, turtleFuelValue, {"number"})
  return turtleFuelValue/10
end


local function loadThisFurnace() -- TODO: empty the furnace first?
  -- Assumption, facing the furnace on the same level as it
  emptyThisFurnace()

  -- go to top of furnace
  turtle.up()
  turtle.forward()
  -- select wood
  -- place in furnace -- what if there is stuff in there? -- can turtles take from the input/fuel slots?

  -- go to side of furnace
  turtle.back()
  turtle.down()
  -- select and place fuel

  -- update furnaceStates
  local ok, err = config.save(furnaceStatesFile, furnaceStates)
  if not ok then
    error("Error saving furnace state: "..err)
  end
end

-- it takes about 20 seconds for items to get from the furthest point to the chest
local function getResources() -- empty the bottom chest
  -- go to the exit
  -- go down to the chest
  -- suck as much as there is inventory space -- TODO: if there is only wood in the turtle and the first slot in the chest is not wood what happens?
  -- go back up to furnace room
end

local function putAwayNotWood()
  -- go to sapling chest
  -- put all saplings into chest

  -- NOTE: is this needed?
  -- go to fuel chest
  -- put spare charcoal in chest

  -- go to junk chest
  -- put in everything but the wood and fuel
end

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
