--wraps inventories and adds uility methods for them
local itemUtils = require("treeFarm.libs.utils.invUtils.itemUtils")

-- TODO: allow plethora to use this
-- NOTE: a lot of this is very turtle specific
-- TODO: convert to plethora and add a virtual plethora layer for the turtle inventory?
-- NOTE: turtle can't fully emulate plethora

-- TODO: convert this to wrap inventories (including the turtle internl onw by mimicing plethora with it)




local function forEachSlot(func, stopFunc)
  argChecker(1, func, {"function"})
  argChecker(2, stopFunc, {"function", "nil"})

  for i = 1, 16 do
    if stopFunc and stopFunc() then
      return
    end
    turtle.select(i)
    func(i)
  end
end

local function forEachSlotSkippingEmpty(func, stopFunc)
  argChecker(1, func, {"function"})
  argChecker(2, stopFunc, {"function", "nil"})

  local f = function(slotId)
    if turtle.getItemCount() > 0 then
      func(slotId)
    end
  end

  forEachSlot(f, stopFunc)
end
local function forEachSlotWithItem(itemId, func, extentionCriteria, stopFunc)
  itemIdArgCheck(itemId,1)
  argChecker(2, func, {"function"})
  argChecker(3, extentionCriteria, {"function", "nil"})
  extentionCriteria = extentionCriteria or function() return true end
  argChecker(4, stopFunc, {"function", "nil"})


  local f = function(slotId)
    local currentItem = turtle.getItemDetail()
    if type(currentItem) == "table"
      and itemEqualityComparer(currentItem, itemId)
      and extentionCriteria(slotId, currentItem)
    then
      func(slotId, currentItem)
    end
  end

  forEachSlotSkippingEmpty(f, stopFunc)
end

local function selectItemById(itemId, extentionCriteria)
  itemIdArgCheck(itemId,1)
  argChecker(2, extentionCriteria, {"function", "nil"})
  extentionCriteria = extentionCriteria or function() return true end

  -- if the current slot has it don't bother searching
  local currentItem = turtle.getItemDetail()
  if type(currentItem) == "table"
    and itemEqualityComparer(currentItem, itemId)
  then
    return true
  end

  local stop = false
  local stopFunc = function() return stop end
  local func = function() stop = true end

  forEachSlotWithItem(itemId, func, extentionCriteria, stopFunc)
end

local function currentSlotIsEmpty()
  if turtle.getItemCount() == 0 then
    return true
  end
  return false
end

local function selectEmptySlot()
  -- if the current slot is empty don't bother searching
  currentSlotIsEmpty()

  local stop = false
  local stopFunc = function() return stop end
  local func = function()
    if currentSlotIsEmpty() then
      stop = true
    end
  end

  forEachSlot(func, stopFunc)
end

 -- by default full slots are not deemed valid for selection
local function selectForDigging(itemId)
  itemIdArgCheck(itemId,1)

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

local function getItemCountById(itemId)
  itemIdArgCheck(itemId,1)
  local count = 0
  for i = 1, 16 do
    turtle.select(i)
    local currentItem = turtle.getItemDetail()
    if currentItem and currentItem.name == itemId.name
    and currentItem.damage == itemId.damage then
      count = count + currentItem.count
    end
  end
  return count
end


local function getFreeSpaceCount()
  local count = 0
  forEachSlotSkippingEmpty(function() count = count +1 end)
  return 16 - count
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


local turtleInventoryLikePlethoraInv = nil
local function getTurtleInventoryLikePlethoraInv()
  if turtleInventoryLikePlethoraInv then
    return turtleInventoryLikePlethoraInv
  end

  if not turtle then
    error("not a turtle")
  end

  local turtleInventoryLikePlethoraInv = {}
  turtleInventoryLikePlethoraInv.size = function()
    return 16 -- TODO: avoid hard coded value
  end
  turtleInventoryLikePlethoraInv.getItem = function(slot)
    argChecker(1, slot, {"number"})
    numberRangeChecker(1, slot, 1, turtleInventoryLikePlethoraInv.size())
    return turtle.getItemDetail(slot)
  end
  turtleInventoryLikePlethoraInv.list = function()
    -- TODO: if it's empty does plethora return an empty table or nil?
    -- documentation says that it only returns a table
    local list = {}
    for i = 1, turtleInventoryLikePlethoraInv.size() do
      list[i] = turtleInventoryLikePlethoraInv.getItem(i)
    end
    return list
  end

  -- TODO: attempt to complete implementation
  -- drop -- notImplementable? -- where does the chest drop too?
  -- getItemMeta -- notImplementable
  -- pullItmes -- notImplementable?
  -- pushItems -- notImplementable?
  -- suck -- notImplementable? -- where does the chest suck from?

  turtleInventoryLikePlethoraInv._isThisTurtleInv = true

  return turtleInventoryLikePlethoraInv
end

local function wrap(inventory) -- TODO: implement

  inventory.eachSlot = function()
    local currentSlot = 0
    local invSize = inventory.size() -- this = the wrapped inventory
    local function iterator()
      currentSlot = currentSlot+1
      if currentSlot > invSize then
        return
      end
      if inventory._isThisTurtleInv then
        turtle.select(i)
      end
      return currentSlot, inventory.getItemMeta and inventory.getItemMeta(currentSlot) or inventory.getItem(currentSlot) -- if we can then we give the itemMeta (it contains all of the getItem stuff anyways) otherwise we give the normal item details
    end

    return iterator
  end

  inventory.forEachSlotSkippingEmpty = function() -- TODO: make this be forEachSlotwithItem with no args?
    local eachSlotIterator = eachSlot()

    local function iterator()
      repeat
        local slot, item = eachSlotIterator()

        if slot == nil then
          return
        end
      until item

      return slot, item
    end

    return iterator
  end

  -- TODO: have the forEach functions be custom iterators
  --[[ to convert:
  may need to get rid of some of these
  forEachSlotWithItem = forEachSlotWithItem,
  selectItemById = selectItemById,
  currentSlotIsEmpty = currentSlotIsEmpty,
  selectEmptySlot = selectEmptySlot, -- findEmptySlot
  selectForDigging = selectForDigging, -- findItemStackWithFreeSpace
  selectBestFuel = selectBestFuel, -- findSlotWithBestFuel
  getItemCountById = getItemCountById,
  getFreeSpaceCount = getFreeSpaceCount,
  equipItemWithId = equipItemWithId,
  selectByTagPriority = selectByTagPriority,
  selectScaffoldBlock = selectScaffoldBlock,
  selectBuildingBlock = selectBuildingBlock,
  ]]

  return inventory
end

local invUtils = {
  itemUtils = itemUtils,
  -- TODO: cleanup
  -- forEachSlot = forEachSlot,
  -- forEachSlotSkippingEmpty = forEachSlotSkippingEmpty,
  -- forEachSlotWithItem = forEachSlotWithItem,
  -- selectItemById = selectItemById,
  -- currentSlotIsEmpty = currentSlotIsEmpty,
  -- selectEmptySlot = selectEmptySlot,
  -- selectForDigging = selectForDigging,
  -- selectBestFuel = selectBestFuel,
  -- getItemCountById = getItemCountById,
  -- getFreeSpaceCount = getFreeSpaceCount,
  -- equipItemWithId = equipItemWithId,
  -- selectByTagPriority = selectByTagPriority,
  -- selectScaffoldBlock = selectScaffoldBlock,
  -- selectBuildingBlock = selectBuildingBlock,
  wrapTurtleInventoryLikePlethoraInv = wrapTurtleInventoryLikePlethoraInv
  wrap = wrap

}
return invUtils
