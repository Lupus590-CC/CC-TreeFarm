-- build the tree farm
local utils = require("utils")
local lama = require("lama")

local function placeTreePodium()
  if not (utils.selectItemById(itemIds.dirt) and  utils.selectItemById(itemIds.jackOLantern)
  and (utils.selectItemById(itemIds.cobblestone) or utils.selectItemById(itemIds.stone)) then
    restock()
  end
  
  -- TODO: figure out how to best place several of these podiums
  -- face south
  
  
  utils.selectItemById(itemIds.cobblestone) or utils.selectItemById(itemIds.stone) -- TODO: test this
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
