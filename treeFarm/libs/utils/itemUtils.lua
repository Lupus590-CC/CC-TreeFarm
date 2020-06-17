local argValidationUtils = require("treeFarm.libs.utils.argValidationUtils")
-- TODO: easy to McFly


local function itemEqualityComparer(itemId1, itemId2)
  argValidationUtils.argChecker(1, itemId1, {"table", "nil"})
  argValidationUtils.argChecker(2, itemId2, {"table", "nil"})
  if itemId1 then
    argValidationUtils.itemIdChecker(1, itemId1)
  else
    itemId1 = {}
  end
  if itemId2 then
    argValidationUtils.itemIdChecker(2, itemId2)
  else
    itemId1 = {}
  end
  if itemId1 == itemId2 or (itemId1.name == itemId2.name and (itemId1.damage and itemId2.damage and itemId1.damage == itemId2.damage or true)) then -- NOTE: what about tools? a pickaxe is still a pickaxe when damaged. systems whould have nil damage on their template item? (really wishing I could catch up with the flattening now)
    return true
  end
  return false
end

local function itemEqualityComparerWithCount(itemId1, itemId2)
  argValidationUtils.argChecker(1, itemId1, {"table", "nil"})
  argValidationUtils.argChecker(2, itemId2, {"table", "nil"})

  local function countCheck(pos, item)
    argValidationUtils.tableChecker("arg["..pos.."]", item, {count = {"number"}})
  end

  if itemId1 then
    argValidationUtils.itemIdChecker(1, itemId1)
    countCheck(1, itemId1)
  end
  if itemId2 then
    argValidationUtils.itemIdChecker(2, itemId2)
    countCheck(2, itemId2)
  end

  if itemId1 == itemId2 or ((type(itemId1) == "table" and itemId1.count) == (type(itemId1) == "table" and itemId2.count) and itemEqualityComparer(itemId1, itemId2)) then
    return true
  end
  return false
end

local itemUtils = {
  itemEqualityComparer = itemEqualityComparer,
  itemEqualityComparerWithCount = itemEqualityComparerWithCount,
}

return itemUtils
