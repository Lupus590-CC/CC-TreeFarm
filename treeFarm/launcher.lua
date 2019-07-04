require("treeFarm.libs.argChecker")


local checkpoint = require("treeFarm.libs.checkpoint")

-- rednet server lookup and host if not found
-- master slave setup
-- check if built already
-- divide and re-divide tasks

-- TODO: check for modem



-- TODO: identify computer type and launch correct part of program
-- ask user instead?
if pocket then
  -- launch remote control script
elseif turtle then

-- TODO: lama override
-- TODO: set start up file



  local function hasPickaxe()
    return false -- TODO: implement
  end

  if hasPickaxe() then
    -- launch farming program
    local farmManagementScript = require("treeFarm.farmManager")
    local builderScript = require("treeFarm.farmBuilder")
  else
    -- launch furnace program
    local furnaceManagementScript = require("treeFarm.furnaceManager")
  end
else
  error("program is not compatible with this device")
end
