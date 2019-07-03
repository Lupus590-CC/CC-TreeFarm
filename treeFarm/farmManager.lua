-- general management of the farm
require("treeFarm.libs.argChecker")

local itemUtils = require("treeFarm.libs.utils.itemUtils")
local itemIds = itemUtils.itemIds
local checkpoint = require("treeFarm.libs.checkpoint")

-- TODO: inventory checks

local function chopTree() -- TODO: fuel checks
  
  if not itemUtils.selectItemById(itemIds.sapling) then
    -- TODO: get more saplings
  end

  local hasBlock, blockId = turtle.inspect()
  if blockId.name == itemIds.log.name then
    turtle.dig()
    turtle.forward()
  end

  hasBlock, blockId = turtle.inspectUp()
  while blockId.name == itemIds.log.name do
    turtle.digUp()
    turtle.up()
    hasBlock, blockId = turtle.inspectUp()
  end
  while turtle.down() do
  end

  hasBlock, blockId = turtle.inspectDown()
  if blockId.name == itemIds.log.name then
    turtle.digDown()
    itemUtils.selectItemById(itemIds.sapling)
    turtle.placeDown()
  end
  -- NOTE: what if the chunk unload is when we dug the log but have not placed the sapling yet? is this really a concern? #homeOnly

  checkpoint.reach("doTreeLine")
end
checkpoint.add("chopTree", chopTree)

local function doTreeLine()
  -- TODO: fuel checks and unloading
  -- NOTE:breaking leaves can put saplings into the turtle
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

chopTree()
