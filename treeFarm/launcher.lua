require("treeFarm.libs.errorCatchUtils")


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




if pocket then
  require("treeFarm.remote").run()
elseif turtle then -- If furnace manager is a normal computer than this will change

-- TODO: lama override
-- TODO: set start up file



  local function hasPickaxe()
    -- TODO: only way to detect an euiped tool is to unequip it and getItemDetail then reequip it
    -- make sure to keep the modem attached
    return false
  end

  if hasPickaxe() then
    if hasBuilt() then
      require("treeFarm.farmManager").run()
    else
      require("treeFarm.farmBuilder").run()
      -- TODO: mark as built
    end

  end
else
  -- launch furnace program
  local furnaceManager = require("treeFarm.furnaceManager")
  local furnaceManager.run()
end
