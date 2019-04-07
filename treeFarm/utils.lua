
local serverName = "lupus590TreeFarm"
local protocolName = "lupus590TreeFarm"

local function selectItemById(itemId, orEmpty)
  if not type(itemId) == "table" then
    error("arg[1] exspected table, got"..type(itemId),2)
  end
  if not type(itemId.name) == "string" then
    error("arg[1].name exspected string, got"..type(itemId.name),2)
  end
  if not type(itemId.damage) == "number" then
    error("arg[1].damage exspected number, got"..type(itemId.damage),2)
  end

  if orEmpty and (not type(orEmpty) == "boolean") then
    error("arg[2] exspected boolean or nil, got"..type(orEmpty),2)
  end



  for i = 1, 16 do
      turtle.select(i)
      local currentItem = turtle.getItemDetail()
      if type(currentItem) == "table" and currentItem.name == itemId.name and currentItem.damage == itemId.damage then
        return true
      end
  end
  if orEmpty then
    for i = 1, 16 do
        turtle.select(i)
        if turtle.getItemCount() == 0 then
          return true
        end
    end
  end
  return false
end

local utils = {
  selectItemById = selectItemById
}

return utils
