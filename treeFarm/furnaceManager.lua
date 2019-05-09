local checkpoint = require("checkpoint")
local lama = require("lama")
local utils = require("utils")
local patience = require("patience")
local daemonManager = require("daemonManager")
local config = require("configuration")

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
  if type(turtleFuelValue) ~= "number" then
    error("arg[1] expected number got "..type(turtleFuelValue),2)
  end
  return turtleFuelValue/10
end


local function loadThisFurnace() -- TODO: empty the furnace first?
  -- Assumption, facing the furnace on the same level as it
  emptyThisFurnace()
  
  -- go to top of furnace
  turtle.up()
  turtle.forwards()
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

-- NOTE: if farmer rednets that it has dropped stuff then how long do we wait for the items to get to the chest? -- TODO: investigate how long it takes for items to drift
local function getResources() -- empty the bottom chest
  -- go to the exit
  -- go down to the chest
  -- suck as much as there is inventory space -- TODO: if there is only wood in the turtles and the first slot in the chest is not wood what happens?
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

-- NOTE: the logging turtle could message the furnace turtle that it's dropped off more wood

-- NOTE: furnace turtle could be the server

-- TODO: if it's not a log move it to the sapling or junk chest



-- collect from input
-- put sapligs away
-- put half of wood away -- TODO: furnaces take 8 wood at a time, what to do if half of the wood doesn't divide nicely like that?
                         -- slit the inventory, there is a slot for wood that should be burned and any wood outside of that is not sorted yet
                         -- will that mean that there needs to be another wood chest, one for burning and another for keep
-- load up furnaces
-- collect from furnaces -- TODO: how to divide up fuel?
-- put some (ow much) charcoal back into furnace
-- put some charcoal into the output chest -- the rest stays in the turtle for it to used
