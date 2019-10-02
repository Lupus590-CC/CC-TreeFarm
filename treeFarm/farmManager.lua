-- general management of the farm
require("treeFarm.libs.errorCatchUtils")

local itemUtils = require("treeFarm.libs.utils.itemUtils")
local itemIds = itemUtils.itemIds
local checkpoint = require("treeFarm.libs.checkpoint")

-- 1,1,1 is the restock chest
-- 3,0,3 first tree
-- 13,0,13 last tree

-- TODO: inventory checks

local function dumpInv()
  itemUtils.forEachSlotWithItem(itemIds.log, function() turtle.dropDown() end)
  -- merge sapling stacks
  itemUtils.forEachSlotWithItem(itemIds.sapling, function() turtle.transferTo(1) end) -- TODO: test this where the first slot is not saplings or is saplings and full
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
  itemUtils.forEachSlotWithItem(itemIds.sapling, function() turtle.dropDown() end, skipFirst)

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

  itemUtils.forEachSlotSkippingEmpty(function(_)
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
      if not itemUtils.selectItemByIdOrEmptySlot(itemId.log) then
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
      if not itemUtils.selectItemByIdOrEmptySlot(itemId.log) then
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
  if itemUtils.selectItemById(itemIds.sapling) then
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
