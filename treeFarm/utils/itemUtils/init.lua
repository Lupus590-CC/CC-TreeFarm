local itemIds = require("itemIds")

-- TODO: how to do user config support for this?
-- reverse lookup
local reverseItemLookup = {}
for k, v in pairs(itemIds) do
  reverseItemLookup[v.name..":"..tostring(v.damage)] = {name = k, fuelValue = v.fuelValue}
end
setmetatable(reverseItemLookup, {
  __call = function(itemId)
    if not type(itemId) == "table" then
      error("arg[1] expected table, got"..type(itemId),2)
    end
    if not type(itemId.name) == "string" then
      error("arg[1].name expected string, got"..type(itemId.name),2)
    end
    if not type(itemId.damage) == "number" then
      error("arg[1].damage expected number, got"..type(itemId.damage),2)
    end

    return reverseItemLookup[itemId.name..":"..tostring(itemId.damage)]
  end})

local function selectItemById(itemId)
  if not type(itemId) == "table" then
    error("arg[1] expected table, got"..type(itemId),2)
  end
  if not type(itemId.name) == "string" then
    error("arg[1].name expected string, got"..type(itemId.name),2)
  end
  if not type(itemId.damage) == "number" then
    error("arg[1].damage expected number, got"..type(itemId.damage),2)
  end

  for i = 1, 16 do
      turtle.select(i)
      local currentItem = turtle.getItemDetail()
      if type(currentItem) == "table" and currentItem.name == itemId.name and currentItem.damage == itemId.damage then
        return true
      end
  end
  return false
end

local function selectEmptySlot()
  for i = 1, 16 do
      turtle.select(i)
      if turtle.getItemCount() == 0 then
        return true
      end
  end
  return false
end

local function selectItemByIdOrEmptySlot(itemId)
  return selectItemById(selectItemById) or selectEmptySlot()
end

local function selectBestFuel()
  local bestFuelSlot
  local bestFuelValue = 0
  for i = 1, 16 do -- We usually put fuel in the last slot, but if we run out then a log or sapling will do fine
      turtle.select(i)
      local currentItem = turtle.getItemDetail()
      if type(currentItem) == "table" and reverseItemLookup(currentItem).fuelValue and reverseItemLookup(currentItem).fuelValue > bestFuelValue then
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
