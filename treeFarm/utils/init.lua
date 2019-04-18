local rednetUtils = require("rednetUtils")
local itemUtils = require("itemUtils")
local nav = require("nav")

-- tODO: move to nav?
local function fuelCheck() -- TODO: fuel check
	-- if fuel is low
		-- find fuel in inventory
		-- refuel
		-- if fuel still low
			-- get more fuel
	
end


local utils = {
  rednetUtils = rednetUtils,
  itemUtils = itemUtils,
  nav = nav,
  fuelCheck = fuelCheck
}

return utils
