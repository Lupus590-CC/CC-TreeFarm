--wraps inventories and adds uility methods for them
local itemUtils = require("treeFarm.libs.utils.invUtils.itemUtils")

-- TODO: allow plethora to use this
-- NOTE: a lot of this is very turtle specific
-- TODO: convert to plethora and add a virtual plethora layer for the turtle inventory?
-- NOTE: turtle can't fully emulate plethora

-- TODO: convert this to wrap inventories (including the turtle internl onw by mimicing plethora with it)

local function wrapTurtleInventoryAsPlethoraInv()
  if not turtle then
    error("not a turtle")
  end

  turtleInventoryAsPlethoraInv = {}
  turtleInventoryAsPlethoraInv.size = function()
    return 16 -- TODO: avoid hard coded value
  end
  turtleInventoryAsPlethoraInv.getItem = function(slot)
    argChecker(1, slot, {"number"})
    numberRangeChecker(1, slot, 1, turtleInventoryAsPlethoraInv.size())
    return turtle.getItemDetail(slot)
  end
  turtleInventoryAsPlethoraInv.list = function()
    -- TODO: if it's empty does plethora return an empty table or nil?
    -- documentation says that it only returns a table
    local list = {}
    for i = 1, turtleInventoryAsPlethoraInv.size() do
      list[i] = turtleInventoryAsPlethoraInv.getItem(i)
    end
    return list
  end

  -- TODO: attempt to complete implementation
  -- drop -- notImplementable? -- where does the chest drop too?
  -- getItemMeta -- notImplementable
  -- pullItmes -- notImplementable?
  -- pushItems -- notImplementable?
  -- suck -- notImplementable? -- where does the chest suck from?

  turtleInventoryAsPlethoraInv._isThisTurtleInv = true
  turtleInventoryAsPlethoraInv.allowChangeOfSelectedSlot = true

  return turtleInventoryAsPlethoraInv
end

local function wrap(inventory)
  if turtle then
    inventory = inventory or wrapTurtleInventoryAsPlethoraInv()
  end
  argChecker(1, inventory, {"table"})
  tableChecker("arg[1]", inventory, {size = {"function"}, getItem = {"function"}, list = {"function"}})

  inventory.eachSlot = function()
    local currentSlot = 0
    local invSize = inventory.size()
    local function iterator()
      currentSlot = currentSlot+1
      if currentSlot > invSize then
        return
      end
      if inventory.allowChangeOfSelectedSlot and inventory._isThisTurtleInv then
        turtle.select(i)
      end
      return currentSlot, inventory.getItemMeta and inventory.getItemMeta(currentSlot) or inventory.getItem(currentSlot) -- if we can then we give the itemMeta (it contains all of the getItem stuff anyways) otherwise we give the normal item details
    end
    return iterator
  end

  inventory.eachSlotSkippingEmpty = function()
    local eachSlotIterator = inventory.eachSlot()
    local function iterator()
      repeat
        local slot, item = eachSlotIterator()
        if slot == nil then
          return
        end
      until item
      return slot, item
    end
    return iterator
  end

  inventory.eachSlotWithItem = function(targetItem)
    argChecker(1, targetItem, {"table", "nil"})
    if not targetItem then
      return inventory.eachSlotSkippingEmpty()
    end
    itemIdChecker(1, targetItem)
    local eachSlotSkippingEmptyIterator = inventory.eachSlotSkippingEmpty()
    local function iterator()
      repeat
        local slot, item = eachSlotSkippingEmptyIterator()
        if slot == nil then
          return
        end
      until itemEqualityComparer(item, targetItem)
      return slot, item
    end
    return iterator
  end

  inventory.findItemById = function(item)
    itemArgChecker(1, item)
    local iterator = inventory.eachSlotWithItem(item)
    local slot, item = iterator()
    return slot, item
  end

  inventory.slotIsEmpty = function(slot)
    if turtle and inventory._isThisTurtleInv then
      slot = slot or turtle.getSelectedSlot()
    end
    argChecker(1, slot, {"number"})
    local item = inventory.getItem(slot)
    if not item then
      return true
    end
    return false
  end

  inventory.eachEmptySlot = function()
    local eachSlotIterator = inventory.eachSlot()
    local function iterator()
      repeat
        local slot, item = eachSlotIterator()
        if slot == nil then
          return
        end
      until not item
      return slot
    end
    return iterator
  end

  inventory.findEmptySlot = function()
    local iterator = inventory.eachEmptySlot()
    local slot = iterator()
    return slot
  end

  inventory.getTotalItemCount = function(item)
    itemArgChecker(1, item)
    local total = 0
    for _, item in inventory.eachSlotWithItem(item)
      total = total +item.count
    end
    return total
  end

  inventory.getFreeSpaceCount = function()
    local total = 0
    for _ in inventory.eachEmptySlot()
      total = total + 1
    end
    return total
  end

  inventory.compactItemStacks = function(item)
    itemArgChecker(1, item)

    if turtle and inventory._isThisTurtleInv then
      tableChecker("self", inventory, {list = {"function"}, pushItems = {"function"}})
      -- TODO: investigate how turtles move items onto full or incompatable stacks
    else
      tableChecker("arg[1]", chest, {list = {"function"}, _peripheralName = {"string"}, pushItems = {"function"}})
      for slot in pairs(inventory.list())
        chest.pushItems(chest._peripheralName, slot)
      end
    end
  end

  return inventory
end

local invUtils = {
  itemUtils = itemUtils,
  wrapTurtleInventoryAsPlethoraInv = wrapTurtleInventoryAsPlethoraInv
  wrap = wrap

}
return invUtils
