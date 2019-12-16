-- general management of the farm
require("treeFarm.libs.errorCatchUtils")

local utils = require("treeFarm.libs.utils")
local invUtils = utils.invUtils
local itemUtils = invUtils.itemUtils
local itemIds = itemUtils.itemIds
local checkpoint = require("treeFarm.libs.checkpoint")

-- 1,1,1 is the restock chest
-- 3,0,3 first tree
-- 13,0,13 last tree

-- TODO: inventory checks

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

local function dumpInv()
  invUtils.forEachSlotWithItem(itemIds.log, function() turtle.dropDown() end)
  -- merge sapling stacks
  invUtils.forEachSlotWithItem(itemIds.sapling, function() turtle.transferTo(1) end) -- TODO: test this where the first slot is not saplings or is saplings and full #homeOnly
  -- and dump excess saplings
  turtle.select(1)
  local skippedFirst = false
  local function skipFirst()
    if skippedFirst then
      return true
    end
    skippedFirst = true
    return false
  end
  invUtils.forEachSlotWithItem(itemIds.sapling, function() turtle.dropDown() end, skipFirst)

  local keepItems = {
    itemId.charcoal,
    itemId.coal,
    itemId.log,
    itemId.wirelessModem,
    itemId.diamondPickaxe,
    itemId.coalCoke,
    itemId.coalCokeBlock,
    itemId.lavaBucket,
    itemId.coalBlock,
    itemId.sapling,
    itemId.blockScanner,

  }


  -- TODO: dump excess of stack
  -- dump junk
  local function keepThis()
    local _, currentItem = turtle.getItemDetail()
    for k, v in pairs(keepItems) do
      if itemUtils.itemEqualityComparer(currentItem, v) then
        return true
      end
    end
    return false
  end

  invUtils.forEachSlotSkippingEmpty(function(_)
    if not keepThis() then
       turtle.dropDown()
    end
  end)
end


local function chopTree() -- TODO: fuel checks - use implied fuel checks?
  -- TODO: equip pickaxe (could have block scanner equiped)
  local hasBlock, blockId = turtle.inspect()
  while hasBlock and blockId.name == itemIds.log.name then
    hasBlock, blockId = turtle.inspectUp()
    if hasBlock and blockId.name == itemIds.leaves.name then
      if not invUtils.selectItemByIdOrEmptySlot(itemId.log) then
        dumpInv()
      end
      turtle.digUp()
    end
    turtle.up()
    hasBlock, blockId = turtle.inspect()
  end

  hasBlock, blockId = turtle.inspect()
  while (not hasblock) or blockId.name == itemIds.leaves.name do
    hasBlock, blockId = turtle.inspect()
    if hasBlock and blockId.name == itemIds.log.name then
      if not invUtils.selectItemByIdOrEmptySlot(itemId.log) then
        dumpInv()
      end
      turtle.dig()
    end
    turtle.down()
    hasBlock, blockId = turtle.inspect()
  end

  if blockId.name == itemIds.dirt.name then
    turtle.up()
  end

  -- we scan for missing saplings later so we can afford to not have any it's just less effient
  if invUtils.selectItemById(itemIds.sapling) then
    turtle.place()
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

  -- go towards chest but stop one block away over the water

  -- dump inventory - not dumping first incase we need to use the wood as fuel
  dumpInv()

  -- go over chest and wrap it with plethora
  turtle.forwards() -- TODO: fuel check
  local chest = peripheral.wrap("down")

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
