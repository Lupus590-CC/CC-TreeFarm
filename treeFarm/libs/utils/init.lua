local rednetUtils = require("rednetUtils")
local itemUtils = require("itemUtils")
local nav = require("nav")



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
  itemUtils = itemUtils,
  nav = nav,
  fuelCheck = fuelCheck
}

return utils
