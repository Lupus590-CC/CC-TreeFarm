local itemIds = require("treeFarm.libs.utils.itemUtils.itemIds")

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

local function itemEqualityComparer(itemId1, itemId2, testQuantity)
  itemIdArgCheck(itemId1,1)
  itemIdArgCheck(itemId2,2)
  argChecker(3, testQuantity, {"boolean", "nil"})
  if itemId1.name == itemId2.name and itemId1.damage == itemId2.damage then
    return true
  end
  return false
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


local function getFreeSpaceCount()
  local count = 0
  forEachSlotSkippingEmpty(function() count = count +1 end)
  return 16 - count
end

-- implicitly preserves the wireless modem
local function equipItemWithId(itemId)
  -- will peripheral.getType(side:string):string tell me that there is a pickaxe on that side?
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

local itemUtils = {
  itemIds = itemIds,
  reverseItemLookup = reverseItemLookup,
  forEachSlot = forEachSlot,
  forEachSlotSkippingEmpty = forEachSlotSkippingEmpty,
  itemEqualityComparer = itemEqualityComparer,
  forEachSlotWithItem = forEachSlotWithItem,
  selectItemById = selectItemById,
  currentSlotIsEmpty = currentSlotIsEmpty,
  selectEmptySlot = selectEmptySlot,
  selectForDigging = selectForDigging,
  selectBestFuel = selectBestFuel,
  countItemQuantityById = countItemQuantityById,
  getFreeSpaceCount = getFreeSpaceCount,
  equipItemWithId = equipItemWithId,
  selectByTagPriority = selectByTagPriority,
  selectScaffoldBlock = selectScaffoldBlock,
  selectBuildingBlock = selectBuildingBlock,

}

return itemUtils
