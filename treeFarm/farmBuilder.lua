-- build the tree farm
require("treeFarm.libs.errorCatchUtils")
local utils = require("treeFarm.libs.utils")
local invUtils = utils.invUtils
local itemUtils = invUtils.itemUtils
local itemIds = itemUtils.itemIds
local lama = require("treeFarm.libs.lama")
local task = require("treeFarm.libs.taskManager")

-- TODO: first pair with remote and then mark out farm

-- TODO: make this a semi-intelligent 3d printer?

local function placeTreePodium() -- TODO: fuel checks
  -- if fuel level is less than 20 + reserve then abort -- NOTE: don't worry, should never happen

  -- TODO: make unload safe?
  -- hard to do, can we use coord and y level?

  -- move check to before? this func is called?
  if not (invUtils.selectItemById(itemIds.dirt)
  and invUtils.selectItemById(itemIds.jackOLantern)
  and invUtils.selectScaffoldBlock())
  then
    return false, "bad inventory" -- TODO: let caller sort out stocking?
  end

  -- TODO: check that where we are in the (a?) correct location

  turtle.back() -- current location is where we need to build


  local _ = invUtils.selectScaffoldBlock()
  turtle.place()

  turtle.up()
  invUtils.selectItemById(itemIds.jackOLantern)
  turtle.place()

  turtle.up()
  invUtils.selectItemByIdOrEmptySlot(itemIds.dirt)
  turtle.place()

  local _, item = turtle.inspect()
  while itemUtils.itemEqualityComparer(item, itemIds.dirt)
    or itemUtils.itemEqualityComparer(item, itemIds.jackOLantern) do
    turtle.down()
  end

  _, item = turtle.inspect()
  invUtils.selectForDigging(item)
  turtle.dig()
end

local function placeWater()
  invUtils.selectItemById(itemIds.waterBucket)
  turtle.placeDown()
  turtle.forward()
  turtle.forward()
  while true do
    invUtils.selectItemById(itemIds.waterBucket)
    turtle.placeDown()
    turtle.back()
    invUtils.selectItemById(itemIds.bucket)
    turtle.placeDown() -- refill the bucket with the infinite water we just made
    turtle.forward()
    if not turtle.forward() then -- if we can't go forward then we are finished
      return
    end
  end
end

local function placeStaticBlocks()
  -- TODO: implement
  -- layers?
end


local function run()
  -- TODO: pcall things and for any uncaught errors, stop and spin
end

local farmBuilder = {
  placeTreePodium = placeTreePodium,
  placeWater = placeWater,
  run = run,
}

return farmBuilder
