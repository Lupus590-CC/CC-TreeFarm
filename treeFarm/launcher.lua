require("treeFarm.libs.argChecker")


local checkpoint = require("treeFarm.libs.checkpoint")

-- rednet server lookup and host if not found
-- master slave setup
-- check if built already
-- divide and re-divide tasks

-- check for wireless modem
local modem = peripheral.find("modem", function(_, modem) return modem.isWireless() end)
if not modem then
  error("couldn't find wireless modem, please attach one to this device and restart this program", 0)
end



-- TODO: identify computer type and launch correct part of program
-- ask user instead?
if pocket then
  require("treeFarm.remote").run()
elseif turtle then -- If furnace manager is a normal computer than this will change

-- TODO: lama override
-- TODO: set start up file



  local function hasPickaxe()
    -- TODO: try peripheral.getType #homeOnly
    -- make sure to keep the modem if it's found
    return false
  end

  if hasPickaxe() then
    if hasBuilt() then
      require("treeFarm.farmManager").run()
    else
      require("treeFarm.farmBuilder").run()
      -- TODO: mark as built
    end

  else
    -- launch furnace program
    local furnaceManager = require("treeFarm.furnaceManager")
    local furnaceManager.run()
  end
else
  error("program is not compatible with this device", 0)
end
