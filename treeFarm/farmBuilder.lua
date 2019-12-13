-- build the tree farm
require("treeFarm.libs.errorCatchUtils")
local utils = require("treeFarm.libs.utils")
local invUtils = utils.invUtils
local itemUtils = invUtils.itemUtils
local itemIds = itemUtils.itemIds
local lama = require("treeFarm.libs.lama")
local task = require("treeFarm.libs.taskManager")

-- TODO: first pair with remote and then mark out farm

-- TODO: make this a semi-intelligent 3d printer?

-- by default full slots are not deemed valid for selection
local function selectForDigging(itemId)
 itemIdChecker(1, itemId)

 item = reverseItemLookup(item)
 if item.digsInto then
   item = item.digsInto
   -- stone turns into cobble when we dig it
 end

 return selectItemById(selectItemById) or selectEmptySlot()
end

-- items which give more fuel than targetFuelValue are not eligible
-- TODO: change how refueling works entirely to not use wood and only use saplings when given permission from the furnace manager
local function selectBestFuel(targetFuelValue) -- TODO: test targetFuelValue #homeOnly
 -- TODO: add an argument to skip saplings?
 argChecker(1, targetFuelValue, {"number", "nil"})
 targetFuelValue = targetFuelValue or math.huge

 local bestFuelSlot
 local bestFuelValue = 0
 forEachSlotSkippingEmpty(function(selectedSlot)
   local currentItem = turtle.getItemDetail()
   if type(currentItem) == "table"
   and reverseItemLookup(currentItem).fuelValue
   and reverseItemLookup(currentItem).fuelValue > bestFuelValue
   and reverseItemLookup(currentItem).fuelValue <= targetFuelValue
   then
     bestFuelSlot = selectedSlot
     bestFuelValue = reverseItemLookup(currentItem).fuelValue
   end
 end)

 if bestFuelSlot then
   turtle.select(bestFuelSlot)
   return true
 end

 return false
end

-- implicitly preserves the wireless modem
local function equipItemWithId(itemId)
 -- will peripheral.getType(side:string):string tell me that there is a pickaxe on that side? nope
 -- TODO: check currently equipped peripherals
 if alreadyEquiped then
   return true, "already equipped"
 end
 if selectItemById(itemId) then
   -- TODO: find non-modem side and equip to that side
   if equipped then
     return true, "equipped"
   else
     return false, "can't equip that"
   end
 end
 return false, "couldn't find that"
end

local function selectByTagPriority(tag)
 local validBlocks = {}
 for _, v in pairs(itemIds) do
   if v[tag] then
     validBlocks[v[tag]] = 0
   end
 end
 local func = function(slotNumber)
   local _, item = turtle.getItemDetail()
   local reversedItem = reverseItemLookup(item)
   if reversedItem[tag] then
     validBlocks[reversedItem[tag]] = slotNumber
   end
 end

 forEachSlotSkippingEmpty(func)

 local bestSlot;
 for _, slotNumber in ipairs(validBlocks) do
   if slotNumber > 0 then
     bestSlot = slotNumber
     break;
   end
 end
 if bestSlot then
   turtle.select(bestSlot)
   return true
 else
   return false
 end
end

local function selectScaffoldBlock()
 return selectByTagPriority("scaffoldBlock")
end

local function selectBuildingBlock()
 return selectByTagPriority("buildingBlock")
end

local function placeTreePodium() -- TODO: fuel checks
  -- if fuel level is less than 20 + reserve then abort -- NOTE: don't worry, should never happen

  -- TODO: make unload safe?
  -- hard to do, can we use coord and y level?

  -- move check to before? this func is called?
  if not (invUtils.selectItemById(itemIds.dirt)
  and invUtils.selectItemById(itemIds.jackOLantern)
  and invUtils.selectScaffoldBlock())
  then
    return false, "bad inventory" -- TODO: let caller sort out stocking?
  end

  -- TODO: check that where we are in the (a?) correct location

  turtle.back() -- current location is where we need to build


  local _ = invUtils.selectScaffoldBlock()
  turtle.place()

  turtle.up()
  invUtils.selectItemById(itemIds.jackOLantern)
  turtle.place()

  turtle.up()
  invUtils.selectItemByIdOrEmptySlot(itemIds.dirt)
  turtle.place()

  local _, item = turtle.inspect()
  while itemUtils.itemEqualityComparer(item, itemIds.dirt)
    or itemUtils.itemEqualityComparer(item, itemIds.jackOLantern) do
    turtle.down()
  end

  _, item = turtle.inspect()
  invUtils.selectForDigging(item)
  turtle.dig()
end

local function placeWater()
  invUtils.selectItemById(itemIds.waterBucket)
  turtle.placeDown()
  turtle.forward()
  turtle.forward()
  while true do
    invUtils.selectItemById(itemIds.waterBucket)
    turtle.placeDown()
    turtle.back()
    invUtils.selectItemById(itemIds.bucket)
    turtle.placeDown() -- refill the bucket with the infinite water we just made
    turtle.forward()
    if not turtle.forward() then -- if we can't go forward then we are finished
      return
    end
  end
end

local function placeStaticBlocks()
  -- TODO: implement
  -- layers?
end


local function run()
  -- TODO: pcall things and for any uncaught errors, stop and spin
end

local farmBuilder = {
  placeTreePodium = placeTreePodium,
  placeWater = placeWater,
  run = run,
}

return farmBuilder
