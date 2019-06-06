-- build the tree farm
local utils = require("utils")
local lama = require("lama")
local task = require("taskManager")

-- TODO: first pair with remote and then mark out farm

local function placeTreePodium() -- TODO: fuel checks
  -- if fuel level is less than 20 + reserve then abort

  -- move check to before? this func is called?
  if not (utils.itemUtils.selectItemById(itemIds.dirt)
  and utils.itemUtils.selectItemById(itemIds.jackOLantern)
  and (utils.itemUtils.selectItemById(itemIds.cobblestone)
  or utils.itemUtils.selectItemById(itemIds.stone)
  and utils.itemUtils.selectEmptySlot()))
  then
    return false, "bad inventory" -- TODO: let caller sort out stocking?
  end

  -- TODO: check that where we are in the (a?) correct location

  turtle.back() -- current location is where we need to build


  local _ = utils.itemUtils.selectItemById(itemIds.cobblestone)
  or utils.itemUtils.selectItemById(itemIds.stone)
  turtle.place()

  turtle.up()
  utils.itemUtils.selectItemById(itemIds.jackOLantern)
  turtle.place()

  turtle.up()
  utils.itemUtils.selectItemByIdOrEmptySlot(itemIds.dirt)
  turtle.place()

  -- place height cap (prevent trees growing too big)
  for i = 1, 6 do
    turtle.up()
  end
  local _ = utils.itemUtils.selectItemById(itemIds.stone)
  or utils.itemUtils.selectItemById(itemIds.cobblestone)
  turtle.place()

  for i = 1, 8 do
    turtle.down()
  end
  utils.itemUtils.selectItemByIdOrEmptySlot(itemIds.cobblestone)
  -- even if we placed stone it will be cobble when we dig it
  turtle.dig()


  turtle.forward() -- go back to where we started


  --TODO: send message that location is built
  -- not needed if single turtle (which is starting to sound like the better idea)
  utils.rednetutils.sendToServer({messageType="build", built="podium",
  loc=table.pack(lama.getLocation())})

  -- TODO: update bounding box

end

local function updateTreePositions()
  -- write to file
  -- queue event
end

-- TODO: build while waiting for things to grow
-- arguably maintaining the farm and building a podium are different Hive tasks

-- when building the water ways, make sure that the boundry has a wall, we don't want the water flowing the wrong way
