local itemIds = require("treeFarm.libs.utils.invUtils.itemUtils.itemIds")




local function itemIdChecker(argPosition, itemIdArg)
  argChecker(1, argPosition, {"number"}, 2)

  argChecker(argPosition, itemIdArg, {"table"}, 3)
  --argChecker(position, value, validTypesList, level)
  tableCheckerFunc("arg["..argPosition.."]", itemIdArg, {name = {"string"}, damage = {"number"}}, nil, 3)
end

-- allows finding item info from the itemIds table using the details
  -- provided by turtle.getItemDetail
local reverseItemLookup = {}
for k, v in pairs(itemIds) do
  reverseItemLookup[v.name..":"..tostring(v.damage)] = itemIds[k]
end
setmetatable(reverseItemLookup, {
  __call = function(_self, itemId)
    itemIdChecker(1, itemId)
    return reverseItemLookup[itemId.name..":"..tostring(itemId.damage)]
  end
})

local function itemEqualityComparer(itemId1, itemId2)
  itemIdChecker(1, itemId1)
  itemIdChecker(2, itemId2)
  if itemId1 == itemId2 or (itemId1.name == itemId2.name and itemId1.damage == itemId2.damage) then
    return true
  end
  return false
end

local function itemEqualityComparerWithCount(itemId1, itemId2)
  argChecker(1, itemId1, {"table", "nil"})
  argChecker(2, itemId2, {"table", "nil"})

  local function countCheck(pos, item)
    tableCheckerFunc("arg["..pos.."]", item, {count = {"number"})
  end

  if itemId1 then
    itemIdChecker(1, itemId1)
    countCheck(1, itemId1)
  end
  if itemId2 then
    itemIdChecker(2, itemId2)
    countCheck(2, itemId2)
  end

  if itemId1 == itemId2 or (itemId1.count == itemId2.count and itemEqualityComparer(itemId1, itemId2)) then
    return true
  end
  return false
end



local itemUtils = {
  itemIds = itemIds,
  itemIdChecker = itemIdChecker,
  reverseItemLookup = reverseItemLookup,
  itemEqualityComparer = itemEqualityComparer,
  itemEqualityComparerWithCount = itemEqualityComparerWithCount,

}

return itemUtils
