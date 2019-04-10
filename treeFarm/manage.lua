-- general management of the farm
local itemIds = require("utils.itemUtils.itemIds")

local function chopTree()
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
  -- TODO: does breaking leaves drop saplings?
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
        atEndOfLine = true -- TODO: count how far we go (or use a bounding box?)
      end
    end
  until atEndOfLine
end
