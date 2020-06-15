--wraps inventories and adds uility methods for them

local itemUtils = require("treeFarm.libs.utils.itemUtils")
local argValidationUtils = require("treeFarm.libs.utils.argValidationUtils")

local turtleInventoryAsPlethoraInv

local function wrapTurtleInventoryAsPlethoraInv()
  if not turtle then
    error("not a turtle")
  end

  if turtleInventoryAsPlethoraInv then
    return turtleInventoryAsPlethoraInv
  end

  turtleInventoryAsPlethoraInv = {}
  turtleInventoryAsPlethoraInv.size = function()
    return 16
  end
  turtleInventoryAsPlethoraInv.getItemMeta = function(slot) -- NOTE: not complete implementation
    argValidationUtils.argChecker(1, slot, {"number"})
    argValidationUtils.numberRangeChecker(1, slot, 1, turtleInventoryAsPlethoraInv.size())
    return turtle.getItemDetail(slot)
  end
  turtleInventoryAsPlethoraInv.getItem = function(slot)
    argValidationUtils.argChecker(1, slot, {"number"})
    argValidationUtils.numberRangeChecker(1, slot, 1, turtleInventoryAsPlethoraInv.size())
    return { getMetadata = function() return turtleInventoryAsPlethoraInv.getItemMeta(slot) end}
  end
  turtleInventoryAsPlethoraInv.list = function()
    local list = {}
    for i = 1, turtleInventoryAsPlethoraInv.size() do
      list[i] = turtleInventoryAsPlethoraInv.getItemMeta(i)
    end
    return list
  end

  -- drop -- notImplementable? -- where does the chest drop too?
  -- getItemMeta -- notImplementable
  -- pullItmes -- notImplementable?
  -- pushItems -- notImplementable?
  -- suck -- notImplementable? -- where does the chest suck from?

  turtleInventoryAsPlethoraInv.IS_THIS_TURTLE_INV = true
  turtleInventoryAsPlethoraInv.allowChangeOfSelectedSlot = true

  return turtleInventoryAsPlethoraInv
end

local function inject(inventory)
  if turtle then
    inventory = inventory or wrapTurtleInventoryAsPlethoraInv()
  end
  argValidationUtils.argChecker(1, inventory, {"table", "string"})
  if type(inventory) == "string" then
    local peripheralName = inventory
    if not peripheral.isPresent(peripheralName) then
      error("Could not wrap peripheral with name "..peripheralName, 1)
    end
    inventory = peripheral.wrap(peripheralName)
    inventory.PERIPHERAL_NAME = peripheralName
    argValidationUtils.tableChecker("peripheral.wrap(arg[1])", inventory, {size = {"function"}, getItem = {"function"}, list = {"function"}})
  else
    argValidationUtils.tableChecker("arg[1]", inventory, {size = {"function"}, getItem = {"function"}, list = {"function"}})
  end

  -- TODO: conform to lua iterators better, see how `pairs` works
  inventory.eachSlot = function()
    local currentSlot = 0
    local invSize = inventory.size()
    local function iterator()
      currentSlot = currentSlot+1
      if currentSlot > invSize then
        return
      end
      if inventory.allowChangeOfSelectedSlot and inventory.IS_THIS_TURTLE_INV then
        turtle.select(currentSlot)
      end
      return currentSlot, inventory.getItemMeta(currentSlot)
    end
    return iterator
  end

  inventory.eachSlotSkippingEmpty = function()
    local eachSlotIterator = inventory.eachSlot()
    local function iterator()
      local slot, item
      repeat
        slot, item = eachSlotIterator()
        if slot == nil then
          return
        end
      until item
      return slot, item
    end
    return iterator
  end

  inventory.eachSlotWithItem = function(targetItem)
    argValidationUtils.argChecker(1, targetItem, {"table", "nil"})
    if not targetItem then
      return inventory.eachSlotSkippingEmpty()
    end
    argValidationUtils.itemIdChecker(1, targetItem)
    local eachSlotSkippingEmptyIterator = inventory.eachSlotSkippingEmpty()
    local function iterator()
      local slot, item
      repeat
         slot, item = eachSlotSkippingEmptyIterator()
        if slot == nil then
          return
        end
      until itemUtils.itemEqualityComparer(item, targetItem)
      return slot, item
    end
    return iterator
  end

  inventory.findItemById = function(item)
    argValidationUtils.itemIdChecker(1, item)
    local iterator = inventory.eachSlotWithItem(item)
    local slot, item = iterator()
    return slot, item
  end

  inventory.slotIsEmpty = function(slot)
    if inventory.IS_THIS_TURTLE_INV then
      slot = slot or turtle.getSelectedSlot()
    end
    argValidationUtils.argChecker(1, slot, {"number"})
    local item = inventory.getItemMeta(slot)
    if not item then
      return true
    end
    return false
  end

  inventory.eachEmptySlot = function()
    local eachSlotIterator = inventory.eachSlot()
    local function iterator()
      local slot, item
      repeat
        slot, item = eachSlotIterator()
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

  inventory.getTotalItemCount = function(itemToCount)
    argValidationUtils.argChecker(1, itemToCount, {"table", "nil"})
    if itemToCount then
      argValidationUtils.itemIdChecker(1, itemToCount)
    end
    local total = 0
    for _, item in inventory.eachSlotWithItem(itemToCount) do
      total = total + item.getMetadata().count
    end
    return total
  end

  inventory.getFreeSpaceCount = function()
    local total = 0
    for _ in inventory.eachEmptySlot() do
      total = total + 1
    end
    return total
  end

  inventory.compactItemStacks = function()
    if inventory.IS_THIS_TURTLE_INV then
      for sourceSlot in inventory.eachSlotWithItem() do
        if inventory.allowChangeOfSelectedSlot then
          turtle.select(sourceSlot)
        end
        for destinationSlot = 1, sourceSlot do
          if turtle.getItemCount() > 0 then
            turtle.transferTo(destinationSlot)
          end
        end
      end
    else
      argValidationUtils.tableChecker("self", inventory, {list = {"function"}, PERIPHERAL_NAME = {"string"}, pushItems = {"function"}})
      for slot in pairs(inventory.list()) do
        inventory.pushItems(inventory.PERIPHERAL_NAME, slot)
      end
    end
  end

-- parrallel methods
  -- if the inv is a turtle one then we fall back to using the sequential methods


  inventory.eachSlotParrallel = function(callback)
    argValidationUtils.argChecker(1, callback, {"function"})
    -- turtles can't safely parrallel
    if inventory.IS_THIS_TURTLE_INV then
      for slot, item in inventory.eachSlot() do
        callback(slot, item)
      end
      return
    end

    local tasks = {}
    local itemMetaOrGetitemFunc = inventory.getItemMeta or inventory.getItemInfo
    for i = 1, inventory.size() do -- TODO: check performance on large inventories #homeOnly
      tasks[i] = function()
        local slot = i
        callback(slot, itemMetaOrGetitemFunc(slot))
      end
    end

    parallel.waitForAll(table.unpack(tasks, 1, inventory.size()))
  end

  inventory.eachSlotSkippingEmptyParrallel = function(callback)
    argValidationUtils.argChecker(1, callback, {"function"})
    if inventory.IS_THIS_TURTLE_INV then
      for slot, item in inventory.eachSlotSkippingEmpty() do
        callback(slot, item)
      end
      return
    end

    inventory.eachSlotParrallel(function(slot, item)
      if item then
        callback(slot, item)
      end
    end)
  end

  inventory.eachSlotWithItemParrallel = function(targetItem, callback)
    argValidationUtils.argChecker(1, targetItem, {"table", "nil"})
    argValidationUtils.argChecker(2, callback, {"function"})
    if not targetItem then
      return inventory.eachSlotSkippingEmptyParrallel(callback)
    end
    argValidationUtils.itemIdChecker(1, targetItem)

    if inventory.IS_THIS_TURTLE_INV then
      for slot, item in inventory.eachSlotWithItem(targetItem) do
        callback(slot, item)
      end
      return
    end

    inventory.eachSlotParrallel(function(slot, item)
      if itemUtils.itemEqualityComparer(item, targetItem) then
        callback(slot, item)
      end
    end)
  end

  inventory.findItemByIdParrallel = function(item)
    argValidationUtils.itemIdChecker(1, item)
    if inventory.IS_THIS_TURTLE_INV then
      return inventory.findItemById(item)
    end

    local slotfound, itemFound
    inventory.eachSlotWithItemParrallel(item, function(slot, item) -- could be faster with parallel.waitForAny
      slotfound = slot
      itemFound = itemFound
    end)
    return slotfound, itemFound
  end

  inventory.eachEmptySlotParrallel = function(callback)
    argValidationUtils.argChecker(1, callback, {"function"})
    if inventory.IS_THIS_TURTLE_INV then
      for slot, item in inventory.eachEmptySlot() do
        callback(slot, item)
      end
      return
    end

    inventory.eachSlotParrallel(function(slot, item)
      if not item then
        callback(slot)
      end
    end)
  end

  inventory.getTotalItemCountParrallel = function(itemToCount)
    argValidationUtils.argChecker(1, itemToCount, {"table", "nil"})
    if itemToCount then
      argValidationUtils.itemIdChecker(1, itemToCount)
    end
    local total = 0
    inventory.eachSlotWithItemParrallel(itemToCount, function(_, item)
      total = total + item.count
    end)
    return total
  end

  inventory.getFreeSpaceCountParrallel = function()
    local total = 0
    inventory.eachEmptySlotParrallel(itemToCount, function()
      total = total + 1
    end)
    return total
  end

  inventory.compactItemStacksParrallel = function()
    if inventory.IS_THIS_TURTLE_INV then
      inventory.compactItemStacks()
    else
      argValidationUtils.tableChecker("self", inventory, {list = {"function"}, PERIPHERAL_NAME = {"string"}, pushItems = {"function"}})
      local tasks = {}
      local taskCount = 0
      for slot in pairs(inventory.list()) do  -- TODO: check performance on large inventories #homeOnly
         taskCount = taskCount + 1
         tasks[taskCount] = function() inventory.pushItems(inventory.PERIPHERAL_NAME, slot) end
      end
      parallel.waitForAll(table.unpack(tasks, 1, taskCount))
    end
  end

  return inventory
end

local function wrapTurtleInv()
  if not turtle then
    error("Not a turtle", 2)
  end
  return inject(wrapTurtleInventoryAsPlethoraInv())
end

local invUtils = {
  wrapTurtleInventoryAsPlethoraInv = turtle and wrapTurtleInventoryAsPlethoraInv,
  inject = inject,
  wrap = inject,
  wrapTurtleInv = turtle and wrapTurtleInv,
}
return invUtils
