local itemIds = require("itemIds")

-- internal utility
local function itemIdArgCheck(itemIdArg, argPosition)
  if not type(argPosition) == "number" then
    error("arg[2] expected number got "..type(argPosition),2)
  end


  if not type(itemId) == "table" then
    error("arg["..argPosition.."] expected table, got "..type(itemId),3)
  end
  if not type(itemId.name) == "string" then
    error("arg["..argPosition.."].name expected string, got "..type(itemId.name),3)
  end
  if not type(itemId.damage) == "number" then
    error("arg["..argPosition.."].damage expected number, got "..type(itemId.damage),3)
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
  
  extentionCriteria = extentionCriteria or function() return true end
  if not type(extentionCriteria) == "function" then
    error("arg[2] expected function or nil, got "..type(extentionCriteria), 2)
  end
  
  local function checkCurrectItem()
    local currentItem = turtle.getItemDetail()
    if type(currentItem) == "table" and currentItem.name == itemId.name
    and currentItem.damage == itemId.damage and extentionCriteria(currentItem) then
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
  
  if allowFullSlots and not type(allowFullSlots) == "boolean" then
    error("arg[2] expected boolean or nil, got "..type(allowFullSlots),2)
  end
  
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
local function selectBestFuel(targetFuelValue) -- TODO: test targetFuelValue
  targetFuelValue = targetFuelValue or math.huge
  if not type(targetFuelValue) == "number" then
      error("arg[1] expected number or nil, got "..type(targetFuelValue),2)
  end
  
  local bestFuelSlot
  local bestFuelValue = 0
  for i = 1, 16 do
      turtle.select(i)
      local currentItem = turtle.getItemDetail()
      if type(currentItem) == "table"
      and reverseItemLookup(currentItem).fuelValue
      and reverseItemLookup(currentItem).fuelValue > bestFuelValue and reverseItemLookup(currentItem).fuelValue =< targetFuelValue then
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

local function mergeItemStacks() -- TODO: implement
  local currentSlot = 1
end

local countItemQuantityById(itemId) -- TODO: implement
  itemIdArgCheck(itemId,1)
  for 
end

-- if quantityToDrop is negative then that is quantity to keep
local function dropItemsById(itemId, quantityToDrop) -- TODO: discard this? just use selectById and turtle.drop?
  itemIdArgCheck(itemId,1)
  
  
  quantityToDrop = quantityToDrop or 1 -- TODO: check turtle.drop behaviour, I think it does the whole stack when without a number
  if not type(quantityToDrop) == "number" then
    error("arg[2] expected number or nil, got "..type(quantityToDrop))
  end
  
  
  -- if quantityToDrop is negative then that is quantity to keep
  if quantityToDrop < 0 then 
    quantityToDrop = countItemQuantityById(itemId) - quantityToDrop
  end
  
  -- TODO: what does turtle.drop do?
  -- TODO: if not enough items to drop then drop anyway but return false and a reason string
  -- TODO: if not enough items to keep then return false and a reason string
  
  
  
end

local itemUtils = {
  itemIds = itemIds,
  reverseItemLookup = reverseItemLookup,
  selectItemById = selectItemById,
  selectEmptySlot = selectEmptySlot,
  selectItemByIdWithFreeSpaceOrEmptySlot = selectItemByIdWithFreeSpaceOrEmptySlot,
  selectBestFuel = selectBestFuel,
  mergeItemStacks = mergeItemStacks,
  dropItemsById = dropItemsById

}

return itemUtils
