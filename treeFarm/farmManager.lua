-- general management of the farm
require("treeFarm.libs.argChecker")

local itemUtils = require("treeFarm.libs.utils.itemUtils")
local itemIds = itemUtils.itemIds
local checkpoint = require("treeFarm.libs.checkpoint")


-- TODO: inventory checks

local function dumpInv()
  itemUtils.forEachSlotWithItem(itemIds.log, function() turtle.dropDown() end)
  -- merge sapling stacks
  itemUtils.forEachSlotWithItem(itemIds.sapling, function() turtle.transferTo(1) end) -- TODO: test this where the first slot is not saplings or is saplings and full
  -- and dump excess saplings
  turtle.select(1)
  local skippedFirst = false
  local function skipFirst()
    if skippedFirst then
      return true
    end
    skippedFirst = true
    return false
  end
  itemUtils.forEachSlotWithItem(itemIds.sapling, function() turtle.dropDown() end, skipFirst)
end


local function chopTree() -- TODO: fuel checks - use implied fuel checks?
  -- TODO: what if we fill our inventory with wood?
    -- just call the empty function, it doesn't matter if we don't empty everything and fill up again quickly, we can empty anywere and let the water catch it

  local hasBlock, blockId = turtle.inspect()
  while hasBlock and blockId.name == itemIds.log.name then
    hasBlock, blockId = turtle.inspectUp()
    if hasBlock and blockId.name == itemIds.leaves.name then
      if not itemUtils.selectItemByIdOrEmptySlot(itemId.log) then
        dumpInv()
      end
      turtle.digUp()
    end
    turtle.up()
    hasBlock, blockId = turtle.inspect()
  end

  hasBlock, blockId = turtle.inspect()
  while (not hasblock) or blockId.name == itemIds.leaves.name do
    hasBlock, blockId = turtle.inspect()
    if hasBlock and blockId.name == itemIds.log.name then
      if not itemUtils.selectItemByIdOrEmptySlot(itemId.log) then
        dumpInv()
      end
      turtle.dig()
    end
    turtle.down()
    hasBlock, blockId = turtle.inspect()
  end

  if blockId.name == itemIds.dirt.name then
    turtle.up()
  end

  -- we scan for missing saplings later so we can afford to not have any it's just less effient
  if itemUtils.selectItemById(itemIds.sapling) then
    turtle.place()
  end

  hasBlock, blockId = turtle.inspect()
  if blockId.name == itemIds.sapling.name then -- TODO: what if we didn't place the sapling? move this to do tree line?
    turtle.up()
  end

  checkpoint.reach("doTreeLine")
end
checkpoint.add("chopTree", chopTree)

local function doTreeLine()
  -- TODO: fuel checks and unloading
  local atEndOfLine = false
  repeat
    while turtle.forward() do
    end
    local hasBlock, blockId = turtle.inspect()
    if hasBlock then
      if blockId.name == itemIds.log.name then
        checkpoint.reach("chopTree")
        chopTree()
      elseif blockId.name == itemIds.leaves.name then
        itemUtils.selectItemByIdOrEmptySlot(itemIds.sapling)
        -- breaking leaves can put saplings into the turtle
        turtle.dig()
      else
        atEndOfLine = true
      end
    end
  until atEndOfLine
  checkpoint.reach("chopAllTrees")
end
checkpoint.add("doTreeLine", doTreeLine)

-- TODO: how to do this unload safe?
local function moveToNextTreeLine()

end

local function chopAllTrees()
  -- TODO: implement
end
checkpoint.add("chopAllTrees", chopAllTrees)




-- TODO: restock



local function run()
  -- TODO: pcall things and for any uncaught errors, message the furnace manager
end

local farmManager = {
  chopTree = chopTree,
  doTreeLine = doTreeLine,
  updateTreePositions = updateTreePositions,
  run = run,
}

return farmManager
