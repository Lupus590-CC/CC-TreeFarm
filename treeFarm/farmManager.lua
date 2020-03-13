-- general management of the farm
local argValidationUtils = require("treeFarm.libs.utils.argValidationUtils")

local utils = require("treeFarm.libs.utils")
local invUtils = utils.invUtils -- TODO: this APi has changed alot and useage here is out of date
local itemUtils = invUtils.itemUtils
local itemIds = itemUtils.itemIds
local checkpoint = require("treeFarm.libs.checkpoint")

local turtleInv = invUtils.wrapTurtleInv()

-- 1,1,1 is the restock chest
-- 3,0,3 first tree
-- 13,0,13 last tree

-- TODO: inventory checks

-- by default full slots are not deemed valid for selection
local function selectForDigging(itemId)
 argValidationUtils.itemIdChecker(1, itemId)

 itemId = reverseItemLookup(itemId)
 if itemId.digsInto then
   itemId = itemId.digsInto
   -- stone turns into cobble when we dig it
 end

 return turtleInv.selectItemById(itemId) or turtleInv.selectEmptySlot()
end

-- items which give more fuel than targetFuelValue are not eligible
-- TODO: change how refueling works entirely to not use wood and only use saplings when given permission from the furnace manager
local function selectBestFuel(targetFuelValue) -- TODO: test targetFuelValue #homeOnly
 argValidationUtils.argChecker(1, targetFuelValue, {"number", "nil"})
 targetFuelValue = targetFuelValue or math.huge

 local bestFuelSlot
 local bestFuelValue = 0
 for slot, item in turtleInv.eachSlotSkippingEmpty() do

   if type(item) == "table"
   and reverseItemLookup(item).fuelValue
   and reverseItemLookup(item).fuelValue > bestFuelValue
   and reverseItemLookup(item).fuelValue <= targetFuelValue
   then
     bestFuelSlot = slot
     bestFuelValue = reverseItemLookup(item).fuelValue
   end
 end

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
 if turtleInv.selectItemById(itemId) then
   -- TODO: find non-modem side and equip to that side
   if equipped then
     return true, "equipped"
   else
     return false, "can't equip that"
   end
 end
 return false, "couldn't find that"
end
turtleInv.equipItemWithId = equipItemWithId

-- drops everything into the water stream
local function dumpInv()
  turtleInv.compactItemStacks()

  -- dump junk
  local keepItems = {
    itemId.charcoal,
    itemId.coal,
    itemId.wirelessModem,
    itemId.diamondPickaxe,
    itemId.coalCoke,
    itemId.coalCokeBlock,
    itemId.lavaBucket,
    itemId.coalBlock,
    itemId.sapling,
    itemId.blockScanner,
  }
  local function keepThis(item)
    for _, v in pairs(keepItems) do
      if itemUtils.itemEqualityComparer(item, v) then
        return true
      end
    end
    return false
  end
  for _, item in turtleInv.eachSlotSkippingEmpty() do
    if not keepThis(item) then
       turtle.dropDown()
    end
  end

  -- dump excess saplings
  local skippedFirstSaplingSlot = false -- first slot has the most saplings
  for _ in turtleInv.eachSlotWithItem(itemIds.sapling) do
    if skippedFirstSaplingSlot then
      turtle.dropDown()
    else
      skippedFirstSaplingSlot = true
    end
  end
end


local function chopTree() -- TODO: fuel checks - use implied fuel checks?
  turtleInv.compactItemStacks()
  if not equipItemWithId(itemIds.diamondPickaxe) then
    error("can't find pickaxe")
  end

  local hasBlock, blockId = turtle.inspect()
  if hasBlock and blockId.name == itemIds.log.name then
    if not turtleInv.selectEmptySlot() then
      dumpInv()
      if not turtleInv.selectEmptySlot() then
        error("inventory full after trying to empty it")
      end
    end
    turtle.dig()
    turtle.forward()
  end

  -- go up and dig the next log
  hasBlock, blockId = turtle.inspectUp()
  if not hasBlock then -- incase we stopped after digging but before climbing
    turtle.up()
    hasBlock, blockId = turtle.inspectUp()
  end
  while hasBlock and blockId.name == itemIds.log.name do
    turtle.digUp()
    turtle.up()
    hasBlock, blockId = turtle.inspectUp()
  end

  -- go back down
  hasBlock, blockId = turtle.inspectDown()
  while (not hasBlock) or (blockId.name ~= itemIds.dirt.name and blockId.name ~= itemIds.sapling.name) do -- TODO: reduce nots, it's comfusing
    if hasBlock then
      turtle.digDown()
    end
    turtle.down()
    hasBlock, blockId = turtle.inspectDown()
  end

  if blockId.name == itemIds.dirt.name then
    turtle.up()
  end
  -- we scan for missing saplings later so we can afford to not have any it's just less efficent
  if turtleInv.selectItemById(itemIds.sapling) then
    turtle.place() -- placing a sapling on a sapling should fail cleanly
  end
  checkpoint.reach("scanForWork")
end
checkpoint.add("chopTree", chopTree)

-- scan for trees and missing saplings
local function scanForWork()
  -- TODO: implement

  -- move to center of chunk (scanner range limitation means we need to be in the center)

  -- if we detect a tree then we go to it and chop it

  -- if we detect a missing sapling then we go to plant it

  -- if saplings or fuel looks low then restock
end
checkpoint.add("scanForWork", scanForWork)

local function restock()
  -- TODO: implement


  -- dump inventory?
  dumpInv()


  -- grab saplings

  -- grab fuel and refuel aggressivly
  while (not fullyRefueled) and chestHasFuel do
    -- grab fuel
    -- refuel
  end

  -- grab enough more fuel to have a stack

end


local function run()
  -- TODO: pcall things and for any uncaught errors, message the furnace manager
  -- run checkpoint
end

local farmManager = {
  chopTree = chopTree,
  scanForWork = scanForWork,
  restocl = restock,
  run = run,
}

return farmManager
