local argValidationUtils = require("treeFarm.libs.utils.argValidationUtils")
local touchpoint = require("treeFarm.libs.touchpoint")

-- summon turtles
-- check status of turtles

-- if only shell then open in background
  -- always do this?

-- TODO: implement
-- status screen
-- remote control
-- turtle position debug


local function run()
  if not term.isColour() then
    error("Requires coloured terminal", 0)
  end
end


local remote = {
  run = run,
}

return remote
