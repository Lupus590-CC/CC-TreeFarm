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
  turtleInventoryAsPlethoraInv.getItem = function(slot)
    argValidationUtils.argChecker(1, slot, {"number"})
    argValidationUtils.numberRangeChecker(1, slot, 1, turtleInventoryAsPlethoraInv.size())
    return turtle.getItemDetail(slot)
  end
  turtleInventoryAsPlethoraInv.list = function()
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
  argValidationUtils.argChecker(1, inventory, {"table", "string"})
  if type(inventory) == "string" then
    local peripheralName = inventory
    if not peripheral.isPresent(peripheralName) then
      error("Could not wrap peripheral with name "..peripheralName, 1)
    end
    inventory = peripheral.wrap(peripheralName)
    inventory._peripheralName = peripheralName
    pcall(argValidationUtils.tableChecker, "peripheral.wrap(arg[1])", inventory, {size = {"function"}, getItem = {"function"}, list = {"function"}}))
  else
    argValidationUtils.tableChecker("arg[1]", inventory, {size = {"function"}, getItem = {"function"}, list = {"function"}})
  end

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

  inventory.eachSlotSkippingEmpty = function() -- could be optimised on plethora with a call to inventory.list
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
    argValidationUtils.argChecker(1, targetItem, {"table", "nil"})
    if not targetItem then
      return inventory.eachSlotSkippingEmpty()
    end
    argValidationUtils.itemIdChecker(1, targetItem)
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
    argValidationUtils.argChecker(1, slot, {"number"})
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

  inventory.compactItemStacks = function()
    if turtle and inventory._isThisTurtleInv then
      for sourceSlot in inventory.eachSlotWithItem() do
        turtle.select(sourceSlot)
        for destinationSlot = 1, sourceSlot do
          turtle.transferTo(destinationSlot)
        end
      end
    else
      argValidationUtils.tableChecker("self", inventory, {list = {"function"}, _peripheralName = {"string"}, pushItems = {"function"}})
      for slot in pairs(inventory.list()) do
        chest.pushItems(chest._peripheralName, slot)
      end
    end
  end

  -- TODO: add parallel forEach methods?
  -- if the inv is a turtle one then we fall back to using the sequential methods


  inventory.eachSlotParrallel = function(callback)
    argValidationUtils.argChecker(1, callback, {"function"})
    -- turtles can't safely parrallel
    if inventory._isThisTurtleInv then
      for slot, item in inventory.eachSlot() do
        callback(slot, item)
      end
      return
    end

    local tasks = {}
    local itemMetaOrGetitemFunc = inventory.getItemMeta or inventory.getItemInfo
    for i = 1, inventory.size() do
      tasks[i] = function()
        local slot = i
        callback(slot, itemMetaOrGetitemFunc(slot))
      end
    end

    parrallel.waitForAll(table.unpack(tasks, 1, inventory.size()))
  end

  inventory.eachSlotSkippingEmptyParrallel = function(callback)
    argValidationUtils.argChecker(1, callback, {"function"})
    if inventory._isThisTurtleInv then
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
    argValidationUtils.itemIdChecker(1, targetItem)
    argValidationUtils.argChecker(2, callback, {"function"})

    if inventory._isThisTurtleInv then
      for slot, item in inventory.eachSlotWithItem() do
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

  inventory.findItemByIdParrallel = function(item) -- TODO: implement
    argValidationUtils.itemIdChecker(1, item)
    if inventory._isThisTurtleInv then
      return inventory.findItemById(item)
    end


    local iterator = inventory.eachSlotWithItem(item)
    local slot, item = iterator()
    return slot, item
  end

  inventory.eachEmptySlotParrallel = function(callback) -- TODO: implement
    argValidationUtils.argChecker(1, callback, {"function"})
    if inventory._isThisTurtleInv then
      for slot, item in inventory.eachEmptySlot() do
        callback(slot, item)
      end
      return
    end



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

  inventory.getTotalItemCountParrallel = function(item)  -- TODO: implement
    argValidationUtils.itemIdChecker(1, item)
    local total = 0
    for _, item in inventory.eachSlotWithItem(item)
      total = total +item.count
    end
    return total
  end

  inventory.getFreeSpaceCountParrallel = function()  -- TODO: implement
    local total = 0
    for _ in inventory.eachEmptySlot()
      total = total + 1
    end
    return total
  end

  inventory.compactItemStacksParrallel = function(item) -- TODO: implement and test #homeOnly
    argValidationUtils.itemIdChecker(1, item)
      if turtle and inventory._isThisTurtleInv then
        for sourceSlot in inventory.eachSlotWithItem() do
          turtle.select(sourceSlot)
          for destinationSlot = 1, sourceSlot do
            turtle.transferTo(destinationSlot)
          end
        end
      else
        argValidationUtils.tableChecker("self", inventory, {list = {"function"}, _peripheralName = {"string"}, pushItems = {"function"}})
        for slot in pairs(inventory.list()) do
          chest.pushItems(chest._peripheralName, slot)
        end
      end

  end

  return inventory
end

local invUtils = {
  wrapTurtleInventoryAsPlethoraInv = wrapTurtleInventoryAsPlethoraInv
  wrap = wrap

}
return invUtils
