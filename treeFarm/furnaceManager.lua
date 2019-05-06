local checkpoint = require("checkpoint")
local lama = require("lama")
local utils = require("utils")

local furnaceStates = { -- TODO: persist this table on the file system
	[1] = {
		started = -- time when it was started, can be used to check when it's finished
	}
}

-- TODO: do I want to load one furnace or all of them?
  -- one at a time is easier if less (turtle) fuel efficient

local function loadFurnace()
  -- go to top of furnace
  -- select wood
  -- place in furnace

  -- go to side of furnace
  -- select and place fuel

  -- start countdown

  -- go to bottom
  -- suck everything
end

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
