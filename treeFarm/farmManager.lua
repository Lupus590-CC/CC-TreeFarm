-- general management of the farm
require("treeFarm.libs.argChecker")

local itemUtils = require("treeFarm.libs.utils.itemUtils")
local itemIds = itemUtils.itemIds
local checkpoint = require("treeFarm.libs.checkpoint")


-- TODO: inventory checks

local function chopTree() -- TODO: fuel checks - use implied fuel checks?


  if not itemUtils.selectItemById(itemIds.sapling) then
    -- TODO: what to do when out of saplings
    -- spin error
    -- could we ask the furnace manager to get some for us?
  end

  -- TODO: select wood or empty

  -- TODO: what if we fill our inventory with wood?
    -- just call the empty function, it doesn't matter if we don't empty everything and fill up again quickly, we can empty anywere and let the water catch it

  local hasBlock, blockId = turtle.inspect()
  if blockId.name == itemIds.log.name then
    turtle.dig()
    turtle.forward() -- what if there is a cunk unload here? we could dig the log but not move forward making it look like we already compleated the tree
    --TODO: refactor to scan up the log and then dig down to the dirt block and then go up one to place the sapling, don't forget to chop the leaves on the way up
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
  end

  if hasBlock and blockId.name ~= itemIds.log.name
  and not itemIds.sapling.name then
    -- we dug the log and went too far down
    -- (likely due to a chunk unload before we could place the sapling)
    turtle.up()
  end

  -- if there is alreay a sapling then this will silently fail
  itemUtils.selectItemById(itemIds.sapling)
  turtle.placeDown()


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

-- TODO: furnace manager watchdog for if the furnace manager forwards an error to us
local function furnaceWatchdog()
  -- listen for specific rednet messages
  -- cause our own error catch system to trigger
end

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
