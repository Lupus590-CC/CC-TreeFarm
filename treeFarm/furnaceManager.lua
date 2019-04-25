local checkpoint = require("checkpoint")
local lama = require("lama")

local furnaceStates = { -- TODO: persist this table on the file system
	[1] = {
		started = -- time when it was started, can be used to check when it's finished
	}
}

-- TODO: do I want to load one furnace or all of them?

-- NOTE: have a task list?
	-- check wood chest
	-- empty this furnace

-- NOTE: the logging turtle could message the furnace turtle that it's dropped off more wood

-- NOTE: furnace turtle could be the server

-- TODO: if it's not a log move it to the sapling/junk chest