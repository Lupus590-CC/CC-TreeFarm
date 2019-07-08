require("treeFarm.libs.argChecker")


local checkpoint = require("treeFarm.libs.checkpoint")

-- rednet server lookup and host if not found
-- master slave setup
-- check if built already
-- divide and re-divide tasks

-- check for wireless modem
local modem = peripheral.find("modem", function(_, modem) return modem.isWireless() end)
if not modem then
  error("couldn't find wireless modem", 0)
end



-- TODO: identify computer type and launch correct part of program
-- ask user instead?
if pocket then
  local remote = require("treeFarm.remote")
  remote.run()
  -- launch remote control script
elseif turtle then

-- TODO: lama override
-- TODO: set start up file



  local function hasPickaxe()
    -- TODO: try peripheral.getType #homeOnly
    -- make sure to keep the modem if it's found
    return false
  end

  if hasPickaxe() then
    -- launch farming program
    local farmManager = require("treeFarm.farmManager")
    local farmBuilder = require("treeFarm.farmBuilder")
    -- TODO: decide how to run

  else
    -- launch furnace program
    local furnaceManager = require("treeFarm.furnaceManager")
    local furnaceManager.run()
  end
else
  error("program is not compatible with this device")
end
