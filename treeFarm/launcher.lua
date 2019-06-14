require("libs.argChecker")
local builderScript = require("farmBuilder")

local farmManagementScript = require("farmManager")
local furnaceManagementScript = require("furnaceManager")

local checkpoint = require("libs.checkpoint")

-- rednet server lookup and host if not found
-- master slave setup
-- check if built already
-- divide and re-divide tasks


-- TODO: check for modem

-- TODO: set start up file

-- TODO: identify computer type and launch correct part of program
-- ask user instead?
if pocket then
  -- launch remote control script
elseif turtle then
  if hasPickaxe() then
    -- launch farming program
  else
    -- launch furnace program
  end
else
  error("program is not compatible with this device")
end
