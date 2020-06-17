-- TODO: implement
local pipe = require("itemPipe").new()

local function triggerFunc()
  while redstone.getInput("right") do
    os.pullEvent("redstone")
  end
  return true
end

local function filterFunc(item)
  return item.name == "minecraft:log"
end
local function filterFunc2(item)
  return item.name == "minecraft:coal"
end

pipe:source("minecraft:chest_1"):trigger(triggerFunc)
pipe:destination("minecraft:chest_2"):filter(filterFunc):order(1)
pipe:destination("minecraft:chest_3"):filter(filterFunc2):order(1)
pipe:destination("minecraft:chest_4"):order(2)
pipe.enterLoop()
