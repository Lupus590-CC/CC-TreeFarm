--local rednetUtils = require("treeFarm.libs.utils.rednetUtils")
local invUtils = require("treeFarm.libs.utils.invUtils")
local itemUtils = require("treeFarm.libs.utils.itemUtils")
local nav = require("treeFarm.libs.utils.nav")
local argValidationUtils = require("treeFarm.libs.utils.argValidationUtils")



-- TODO: move to nav?
-- TODO: overwrite turtle api to do automatic refuelling?
-- fuelRequiredForAction is the amount of fuel that the caller wants us to have as that is what they expect to use
local function fuelCheck(fuelRequiredForAction) -- TODO: fuel check
  -- if fuel is low
    if itemUtils.selectBestFuel() then -- find fuel in inventory
    -- refuel
    -- if fuel still low
      -- get more fuel
    else
      -- go to fuel chest -- NOTE: should this go get fuel?
        -- NOTE: turtle state system? just use the Hive task system with restocking for fuel being a top priority task
    end

end


local utils = {
  rednetUtils = rednetUtils,
  invUtils = invUtils,
  itemUtils = itemUtils,
  nav = nav,
  fuelCheck = fuelCheck,
  argValidationUtils = argValidationUtils,
}

return utils
