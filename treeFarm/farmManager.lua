-- general management of the farm
require("libs.argChecker")
local itemIds = require("libs.utils.itemUtils.itemIds")

-- TODO: inventory checks

local function chopTree() -- TODO: fuel checks
  -- TODO: handle chunk reloads
  -- if wood in front then we just started
  -- if wood above then we were digging up
  -- if wood below then we were going back down
  -- if there is wood below then we need to replace it with a sapling
  -- if there is a sapling below then we are done
  turtle.dig()
  turtle.forward()
  local hasBlock, blockId = turtle.inspect()
  while blockId.name == itemIds.log.name do
    turtle.digUp()
    turtle.up()
    hasBlock, blockId = turtle.inspect()
  end
  while turtle.down() do
  end
  turtle.digDown()
  -- TODO: relace sapling
end

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
