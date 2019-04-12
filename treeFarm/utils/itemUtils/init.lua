local itemIds = require("itemIds")

local function selectItemById(itemId, orEmpty)
  if not type(itemId) == "table" then
    error("arg[1] expected table, got"..type(itemId),2)
  end
  if not type(itemId.name) == "string" then
    error("arg[1].name expected string, got"..type(itemId.name),2)
  end
  if not type(itemId.damage) == "number" then
    error("arg[1].damage expected number, got"..type(itemId.damage),2)
  end

  if orEmpty and (not type(orEmpty) == "boolean") then
    error("arg[2] expected boolean or nil, got"..type(orEmpty),2)
  end



  for i = 1, 16 do
      turtle.select(i)
      local currentItem = turtle.getItemDetail()
      if type(currentItem) == "table" and currentItem.name == itemId.name and currentItem.damage == itemId.damage then
        return true
      end
  end
  if orEmpty then -- TODO: only select empty if could not find item or item stack was full
    for i = 1, 16 do
        turtle.select(i)
        if turtle.getItemCount() == 0 then
          return true
        end
    end
  end
  return false
end

local function selectItemByIdOrEmptySlot(itemId)
  return selectItemById(selectItemById, true)
end

local itemUtils = {
  itemIds = itemIds,
  selectItemById = selectItemById,
  selectItemByIdOrEmptySlot = selectItemByIdOrEmptySlot,
  
}

return itemUtils
