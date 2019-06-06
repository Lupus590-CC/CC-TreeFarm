local function argChecker(position, value, validTypes, level) -- TODO: test and refactor #VERY_HIGH #easy
  -- check our own args first
  if type(position) ~= "number" then
    error("argChecker: arg[1] expected number got "..type(position),2)
  end
  -- value could be anything, it's what the caller wants us to check for them
  if type(validTypes) ~= "table" then
    error("argChecker: arg[3] expected table got "..type(validTypes),2)
  end
  if not validTypes[k] then
    error("argChecker: arg[3] table must contain at least one element",2)
  end
  for k, v in pairs(validTypes) do
    if type(validTypes[k]) ~= "number" then
      error("argChecker: arg[3] non-numeric index "..k.." in table",2)
    end
    if type(v) ~= "string" then
      error("argChecker: arg[3]["..k.."] expected string got "..type(v),2)
    end
  end
  if type(level) ~= "nil" and type(level) ~= "number" then
    error("argChecker: arg[4] expected number or nil got "..type(level),2)
  end
  level = level or 2

  -- check the client's stuff
  for k, v in ipairs(validTypes) do
    if type(value) == v then
      return
    end
  end

  local expectedTypes = table.concat(validTypes, ", ", 1, #validTypes - 1) .. " or " .. validTypes[#validTypes]

  local expectedTypes
  if #validTypes == 1 then
      expectedTypes = validTypes[1]
  else
      expectedTypes = table.concat(validTypes, ", ", 1, #validTypes - 1) .. " or " .. types[#validTypes]
  end


  error("arg["..position.."] expected "..expectedTypes
  .." got "..type(value), level)
end
_ENV.argChecker = argChecker -- the below requires depend on this function

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
