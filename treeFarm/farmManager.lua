-- general management of the farm
require("treeFarm.libs.argChecker")

local itemUtils = require("treeFarm.libs.utils.itemUtils")
local itemIds = itemUtils.itemIds
local checkpoint = require("treeFarm.libs.checkpoint")


-- TODO: inventory checks

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
  -- NOTE: breaking leaves can put saplings into the turtle
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
        turtle.dig()
      else
        atEndOfLine = true -- TODO: use a bounding box
      end
    end
  until atEndOfLine
end

function updateTreePositions()
  -- if pulled event is a notification then
    -- read the file (could I just pass the new table via the event?)
end

-- TODO: move to next line

-- TODO: detect full inventory and dropoff


-- TODO: restock



local function run()
  -- TODO: pcall things and for any uncaught errors, stop and spin, when the remote connects message the error
end

local farmManager = {
  chopTree = chopTree,
  doTreeLine = doTreeLine,
  updateTreePositions = updateTreePositions,
  run = run,
}

return farmManager
