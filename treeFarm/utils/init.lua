local rednetUtils = require("rednetUtils")
local itemUtils = require("itemUtils")
local nav = require("nav")

-- TODO: move to nav?
local function fuelCheck() -- TODO: fuel check
	-- if fuel is low
		if itemUtils.selectBestFuel() then -- find fuel in inventory
		-- refuel
		-- if fuel still low
			-- get more fuel
		else
			-- go to fuel chest
		end

end


local utils = {
  rednetUtils = rednetUtils,
  itemUtils = itemUtils,
  nav = nav,
  fuelCheck = fuelCheck
}

return utils
