local itemIds = require("itemIds")

-- TODO: how to do user config support for this?
-- reverse lookup
local reverseItemLookup = {}
for k, v in pairs(itemIds) do
  reverseItemLookup[v.name..":"..tostring(v.damage)] = 
    {name = k, fuelValue = v.fuelValue}
end
setmetatable(reverseItemLookup, {
  __call = function(_self, itemId)
    if not type(itemId) == "table" then
      error("arg[1] expected table, got"..type(itemId),2)
    end
    if not type(itemId.name) == "string" then -- NOTE: this didn't error when I had the args in the wrong place, why?
      error("arg[1].name expected string, got"..type(itemId.name),2)
    end
    if not type(itemId.damage) == "number" then
      error("arg[1].damage expected number, got"..type(itemId.damage),2)
    end

    return reverseItemLookup[itemId.name..":"..tostring(itemId.damage)]
  end})

local function selectItemById(itemId, extentionCriteria)
  if not type(itemId) == "table" then
    error("arg[1] expected table, got"..type(itemId),2)
  end
  if not type(itemId.name) == "string" then
    error("arg[1].name expected string, got"..type(itemId.name),2)
  end
  if not type(itemId.damage) == "number" then
    error("arg[1].damage expected number, got"..type(itemId.damage),2)
  end
  extentionCriteria = extentionCriteria or function() return true end
  if not type(extentionCriteria) == "function" then
    error("arg[2] expected function or nil, got"..type(extentionCriteria), 2)
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

local function selectItemByIdOrEmptySlot(itemId, allowFullSlots) -- full slots are not deemed valid for selection
  do -- selectItemById checks (copied so that blame value in error() gets elevated correctly)
    if not type(itemId) == "table" then
      error("arg[1] expected table, got"..type(itemId),2)
    end
    if not type(itemId.name) == "string" then
      error("arg[1].name expected string, got"..type(itemId.name),2)
    end
    if not type(itemId.damage) == "number" then
      error("arg[1].damage expected number, got"..type(itemId.damage),2)
    end
  end
  
  if allowFullSlots and not type(allowFullSlots) == "boolean" then
    error("arg[2] expected boolean or nil, got"..type(allowFullSlots),2)
  end
  
  local vetoFullSlots = nil
  
  -- if the stack is full then don't select it (when we call selectItemByIdOrEmptySlot we are likely wanting to dig something)
  local function vetoFullSlotsFunc(currentItem)
    return not reverseItemLookup(currentItem).maxStackSize == currentItem.count
  end 
  
  if allowFullSlots then
    vetoFullSlotsFunc = nil
  end

  return selectItemById(selectItemById, vetoFullSlotsFunc) or selectEmptySlot()
end

local function selectBestFuel(targetFuelGain) -- TODO: targetFuelGain error above or below? allow external criteria?
  local bestFuelSlot
  local bestFuelValue = 0
  for i = 1, 16 do
      turtle.select(i)
      local currentItem = turtle.getItemDetail()
      if type(currentItem) == "table"
      and reverseItemLookup(currentItem).fuelValue
      and reverseItemLookup(currentItem).fuelValue > bestFuelValue then
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

local itemUtils = {
  itemIds = itemIds,
  reverseItemLookup = reverseItemLookup,
  selectItemById = selectItemById,
  selectEmptySlot = selectEmptySlot,
  selectItemByIdOrEmptySlot = selectItemByIdOrEmptySlot,
  selectBestFuel = selectBestFuel,

}

return itemUtils
