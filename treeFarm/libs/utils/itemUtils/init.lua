local itemIds = require("treeFarm.libs.utils.itemUtils.itemIds")
-- TODO: reimplement various utilities using the other utilities

-- TODO: allow plethora to use this

-- internal utility
local function itemIdArgCheck(itemIdArg, argPosition)
  argChecker(2, argPosition, {"number"}, 2)

  argChecker(argPosition, itemIdArg, {"table"}, 3)
  --argChecker(position, value, validTypesList, level)
  -- NOTE: argChecker can't check the contents of a table
  if type(itemIdArg.name) ~= "string" then
    error("arg["..argPosition.."].name expected string, got "
    ..type(itemIdArg.name),3)
  end
  --argChecker(position, value, validTypesList, level)
  if type(itemIdArg.damage) ~= "number" then
    error("arg["..argPosition.."].damage expected number, got "
    ..type(itemIdArg.damage),3)
  end
end

-- allows finding item info from the itemIds table using the details
  -- provided by turtle.getItemDetail
local reverseItemLookup = {}
for k, v in pairs(itemIds) do
  reverseItemLookup[v.name..":"..tostring(v.damage)] = itemIds[k]
end
setmetatable(reverseItemLookup, {
  __call = function(_self, itemId)
    itemIdArgCheck(itemId, 1)
    return reverseItemLookup[itemId.name..":"..tostring(itemId.damage)]
  end
})

local function selectItemById(itemId, extentionCriteria)
  itemIdArgCheck(itemId,1)
  argChecker(2, extentionCriteria, {"function", "nil"})
  extentionCriteria = extentionCriteria or function() return true end

  local function checkCurrectItem()
    local currentItem = turtle.getItemDetail()
    if type(currentItem) == "table" and currentItem.name == itemId.name
    and currentItem.damage == itemId.damage and extentionCriteria(currentItem)
    then
      return true
    end
    return false
  end

  -- if the current slot has it don't bother searching
  if checkCurrectItem() then
    return true
  end

  for i = 1, 16 do
    turtle.select(i)
    if checkCurrectItem() then
      return true
    end
  end
  return false
end

local function selectEmptySlot()
  -- if the current slot is empty don't bother searching
  if turtle.getItemCount() == 0 then
    return true
  end

  for i = 1, 16 do
      turtle.select(i)
      if turtle.getItemCount() == 0 then
        return true
      end
  end
  return false
end

 -- by default full slots are not deemed valid for selection
local function selectItemByIdWithFreeSpaceOrEmptySlot(itemId, allowFullSlots)
  itemIdArgCheck(itemId,1)
  argChecker(2, allowFullSlots, {"boolean", "nil"})

  local vetoFullSlots = nil

  -- if the stack is full then don't select it (when we call
      -- selectItemByIdOrEmptySlot we are likely wanting to dig something)
  local function vetoFullSlotsFunc(currentItem)
    return not reverseItemLookup(currentItem).maxStackSize == currentItem.count
  end

  if allowFullSlots then
    vetoFullSlotsFunc = nil
  end

  return selectItemById(selectItemById, vetoFullSlotsFunc) or selectEmptySlot()
end

-- items which give more fuel than targetFuelValue are not eligible
-- TODO: change how refueling works entirely to not use wood and only use saplings when given permission from the furnace manager
local function selectBestFuel(targetFuelValue) -- TODO: test targetFuelValue #homeOnly
  -- TODO: add an argument to skip saplings?
  argChecker(1, targetFuelValue, {"number", "nil"})
  targetFuelValue = targetFuelValue or math.huge

  local bestFuelSlot
  local bestFuelValue = 0
  for i = 1, 16 do -- TODO: use forEachSlotSkippingEmpty?
      turtle.select(i)
      local currentItem = turtle.getItemDetail()
      if type(currentItem) == "table"
      and reverseItemLookup(currentItem).fuelValue
      and reverseItemLookup(currentItem).fuelValue > bestFuelValue
      and reverseItemLookup(currentItem).fuelValue <= targetFuelValue
      then
        bestFuelSlot = i
        bestFuelValue = reverseItemLookup(currentItem).fuelValue
      end
  end

  if bestFuelSlot then
    turtle.select(bestFuelSlot)
    return true
  end

  return false
end

local function countItemQuantityById(itemId)
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

local function forEachSlot(func)
  argChecker(1, func, {"function"})

  for i = 1, 16 do
    turtle.select(i)
    func(i)
  end
end

local function forEachSlotSkippingEmpty(func)
  argChecker(1, func, {"function"})

  local f = function(slotId)
    if turtle.getItemCount() > 0 then
      func(slotId)
    end
  end

  forEachSlot(f)
end

local function forEachSlotWithItem(itemId, func, extentionCriteria)
  itemIdArgCheck(itemId,1)
  argChecker(1, func, {"function"})
  argChecker(2, extentionCriteria, {"function", "nil"})
  extentionCriteria = extentionCriteria or function() return true end

  local f = function(slotId)
    local currentItem = turtle.getItemDetail()
    if type(currentItem) == "table" and currentItem.name == itemId.name
    and currentItem.damage == itemId.damage and extentionCriteria(slotId, currentItem)
    then
      func(slotId, currentItem)
    end
  end

  forEachSlotSkippingEmpty(f)
end

local function getFreeSpaceCount()
  local count = 0
  forEachSlotSkippingEmpty(function() count = count +1 end)
  return 16 - count
end

local itemUtils = {
  itemIds = itemIds,
  reverseItemLookup = reverseItemLookup,
  selectItemById = selectItemById,
  selectEmptySlot = selectEmptySlot,
  selectItemByIdWithFreeSpaceOrEmptySlot = selectItemByIdWithFreeSpaceOrEmptySlot,
  selectBestFuel = selectBestFuel,
  countItemQuantityById = countItemQuantityById,
  forEachSlot = forEachSlot,
  forEachSlotSkippingEmpty = forEachSlotSkippingEmpty,
  forEachSlotWithItem = forEachSlotWithItem,
  getFreeSpaceCount = getFreeSpaceCount,


}

return itemUtils
