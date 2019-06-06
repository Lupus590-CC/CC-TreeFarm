-- general management of the farm
local itemIds = require("utils.itemUtils.itemIds")

-- TODO: inventory checks

local function chopTree() -- DODO: fuel checks
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
