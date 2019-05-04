-- build the tree farm
local utils = require("utils")
local lama = require("lama")

local function placeTreePodium() -- TODO: fuel checks
	-- if fuel level is less than 18 + reserve then abort
  
  -- move check to before? this func is called?
  if not (utils.selectItemById(itemIds.dirt)
  and  utils.selectItemById(itemIds.jackOLantern)
  and (utils.selectItemById(itemIds.cobblestone)
  or utils.selectItemById(itemIds.stone))) then
    return false, "need more stuff" -- TODO: let caller sort out stocking?
  end
  
  -- TODO: figure out how to best place several of these podiums
  -- face south
  
  
  local _ = utils.selectItemById(itemIds.cobblestone) 
    or utils.selectItemById(itemIds.stone)
  turtle.place()
  
  turtle.up()
  utils.selectItemById(itemIds.jackOLantern)
  turtle.place()
  
  turtle.up()
  utils.selectItemByIdOrEmptySlot(itemIds.dirt)
  turtle.place()
  
  -- place height cap (prevent trees growing too big)
  for i = 1, 6 do
    turtle.up()
  end
  local _ = utils.selectItemById(itemIds.cobblestone) -- TODO: stone then cobble?
    or utils.selectItemById(itemIds.stone)
  turtle.place()
  
  for i = 1, 8 do
    turtle.down()
  end
  utils.selectItemByIdOrEmptySlot(itemIds.cobblestone)
    -- even if we placed stone it will be cobble when we dig it
  turtle.dig()
  --TODO: send message that location is built
  utils.rednetutils.sendToServer({messType="build", built="podium", 
    loc=table.pack(lama.getLocation())}
end



