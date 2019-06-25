-- fake turtle api
if not turtle then
  _G.turtle = {
    getFuelLevel = function() return 0 end,
    select = function() end,
    getItemDetail = function() return {name = "minecraft:cobblestone", damage = 0} end,
  }
end



require("treeFarm.farmBuilder")
require("treeFarm.farmManager")
require("treeFarm.furnaceManager")
require("treeFarm.launcher")
require("treeFarm.remote")

require("treeFarm.libs.argChecker")
require("treeFarm.libs.checkpoint")
require("treeFarm.libs.config")
require("treeFarm.libs.daemonManager")
require("treeFarm.libs.lama")
require("treeFarm.libs.patience")
require("treeFarm.libs.taskManager")

require("treeFarm.libs.utils")
