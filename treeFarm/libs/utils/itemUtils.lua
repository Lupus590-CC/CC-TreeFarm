local errorCatchUtils = require("treeFarm.libs.utils.errorCatchUtils")



local function itemEqualityComparer(itemId1, itemId2)
  errorCatchUtils.itemIdChecker(1, itemId1)
  errorCatchUtils.itemIdChecker(2, itemId2)
  if itemId1 == itemId2 or (itemId1.name == itemId2.name and itemId1.damage == itemId2.damage) then
    return true
  end
  return false
end

local function itemEqualityComparerWithCount(itemId1, itemId2)
  errorCatchUtils.argChecker(1, itemId1, {"table", "nil"})
  errorCatchUtils.argChecker(2, itemId2, {"table", "nil"})

  local function countCheck(pos, item)
    errorCatchUtils.tableCheckerFunc("arg["..pos.."]", item, {count = {"number"})
  end

  if itemId1 then
    errorCatchUtils.itemIdChecker(1, itemId1)
    countCheck(1, itemId1)
  end
  if itemId2 then
    errorCatchUtils.itemIdChecker(2, itemId2)
    countCheck(2, itemId2)
  end

  if itemId1 == itemId2 or (itemId1.count == itemId2.count and itemEqualityComparer(itemId1, itemId2)) then
    return true
  end
  return false
end

local itemUtils = {
  itemEqualityComparer = itemEqualityComparer,
  itemEqualityComparerWithCount = itemEqualityComparerWithCount,
}

return itemUtils
