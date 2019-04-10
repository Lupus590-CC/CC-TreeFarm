-- general management of the farm
local itemIds = require("utils.itemUtils.itemIds")

local function chopTree()
  turtle.dig()
  turtle.forward()
  while turtle.detectUp() do
    turtle.digUp()
    turtle.up()
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
        atEndOfLine = true
      end
    end
  until atEndOfLine
end
