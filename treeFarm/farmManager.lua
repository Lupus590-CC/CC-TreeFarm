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

local statusUpdaterState = {["error"] = true, ["ok"] = true, ["warning"] = true, ["warn"] = true,}
local function statusUpdater(state, message)
  argValidationUtils.argChecker(1, state, {"string"})
  state = string.lower(state)
  if not statusUpdaterState[state] then
    error("invalid status updator state",2)
  end
  message = message ~= nil and tostring(message)

  -- TODO: send a message to the furnace manager

end

-- TODO: turtleUtils
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

-- TODO: turtleUtils
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

-- TODO: turtleUtils
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
local function dumpInv(dropFunc)
  turtleInv.compactItemStacks()
  dropFunc = dropFunc or turtle.dropDown

  -- dump junk
  local keepItems = {
    itemId.coal,
    itemId.wirelessModem,
    itemId.diamondPickaxe,
    itemId.coalCoke,
    itemId.coalCokeBlock,
    itemId.lavaBucket,
    itemId.coalBlock,
    itemId.blockScanner,
    itemId.sapling,
    itemId.charcoal,
  }
  local function keepThis(item)
    for _, v in pairs(keepItems) do
      if itemUtils.itemEqualityComparer(item, v) then
        return true
      end
    end
    return false
  end

  -- dump excess saplings and charcoal
  -- also dump junk
  local skippedFirstSaplingSlot = false -- first slot has the most saplings
  local skippedFirstCharcoalSlot = false -- first slot has the most charcoal
  for _, item in turtleInv.eachSlotSkippingEmpty() do
    if itemEqualityComparer(item, itemIds.sapling) then
      if skippedFirstSaplingSlot then
        dropFunc()
      else
        skippedFirstSaplingSlot = true
      end
    elseif itemEqualityComparer(item, itemIds.chacoal) then
      if skippedFirstCharcoalSlot then
        dropFunc()
      else
        skippedFirstCharcoalSlot = true
      end
    elseif not keepThis(item) then
       dropFunc()
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
  -- TODO: go to?

  -- rotate so that we face out
  while turtle.detect() do
    turtle.turnRight()
  end

  -- dump inventory?
  dumpInv(turtle.drop)

  local function isSaplingChest(chest)
    return itemEqualityComparer(pairs(c.list())(), itemIds.sapling) -- TODO: fix ugly code
  end

  local function isCharcoalChest(chest)
    return itemEqualityComparer(pairs(c.list())(), itemIds.charcoal) -- TODO: fix ugly code
  end

  -- TODO: does the turtle suck across slots in the chest? e.g. the chest has 1 item in the first slot but more of that item in the second, if the turtle trys to suck 2 of the item does it get 2? #homeOnly
  -- grab saplings
  local c = peripheral.wrap("up")
  if not isSaplingChest(c) then
    c = peripheral.wrap("down") -- try the other chest
  end
  if isSaplingChest(c) then -- if this fails then the sapling chest is empty
    if not turtleInv.findItemById(itemIds.sapling) then
      statusUpdater("WARNING", "out of saplings")
  end

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
