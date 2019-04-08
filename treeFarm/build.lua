-- build the tree farm
local utils = require("utils")
local lama = require("lama")

local function placeTreePodium()
  if not (utils.selectItemById(itemIds.dirt) and  utils.selectItemById(itemIds.jackOLantern)) then
    restock()
  end

  utils.selectItemById(itemIds.dirt)
  turtle.place()
  turtle.up()
  utils.selectItemById(itemIds.jackOLantern)
  turtle.place()
  turtle.down()
  utils.selectItemById(itemIds.dirt, true)
  turtle.dig
  turtle.up()
  turtle.place()
  for i = 1, 2 do
    turtle.down()
  end
  turtle.dig()
  --TODO: send message that location is built
  utils.rednetutils.sendToServer({messType="build", built="podium", loc=table.pack(lama.getLocation())}
end
