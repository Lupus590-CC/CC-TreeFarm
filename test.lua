local itemIds = { -- TODO: allow user edits via config
  dirt = { name = "minecraft:dirt", damage = 0 },
  jackOLantern = { name = "minecraft:lit_pumpkin", damage = 0 },
  charcoal = { name= "minecraft:coal", damage = 1, fuelValue = 80 },
  coal = { name= "minecraft:coal", damage = 0, fuelValue = 80 },
  log = { name = "minecraft:log", damage = 0, fuelValue = 15 },
  wirelessModem = { name = "ComputerCraft:CC-Peripheral", damage = 1 },
  chest = { name = "minecraft:chest", damage = 0 },
  torch = { name = "minecraft:torch", damage = 0 },
  furnace = { name = "minecraft:furnace", damage = 0 },
  fence = { name = "minecraft:fence", damage = 0 },
  hopper = { name = "minecraft:hopper", damage = 0 },
  packedIce = { name = "minecraft:packed_ice", damage = 0 },
  waterBucket = { name = "minecraft:water_bucket", damage = 0 },
  disk = { name = "ComputerCraft:disk", damage = 0 },
  diskDrive = { name = "ComputerCraft:CC-Peripheral", damage = 0 },
  advanceComputer = { name = "ComputerCraft:CC-Computer", damage = 16384 },
  computer = { name = "ComputerCraft:CC-Computer", damage = 0 },
  stone = { name = "minecraft:stone", damage = 0 },
  cobblestone = { name = "minecraft:cobblestone", damage = 0 },
  coalCoke = { name = "Railcraft:fuel.coke", damage = 0, fuelValue = 160 },
  coalCokeBlock = { name = "Railcraft:cube", damage = 0, fuelValue = 1600 },
  lavaBucket = { name = "minecraft:lava_bucket", damage = 0, fuelValue = 1000 },
  bucket = { name = "minecraft:bucket", damage = 0 },
  coalBlock = { name= "minecraft:coal_block", damage = 0, fuelValue = 800 },
}

local reverseItemLookup = {}
for k, v in pairs(itemIds) do
  reverseItemLookup[v.name..":"..tostring(v.damage)] = {name = k, fuelValue = v.fuelValue}
end
setmetatable(reverseItemLookup, {
  __call = function(self, itemId)
    if not type(itemId) == "table" then
      error("arg[1] expected table, got"..type(itemId),2)
    end
    if not type(itemId.name) == "string" then
      error("arg[1].name expected string, got"..type(itemId.name),2)
    end
    if not type(itemId.damage) == "number" then
      error("arg[1].damage expected number, got"..type(itemId.damage),2)
    end



    return reverseItemLookup[itemId.name..":"..tostring(itemId.damage)]
  end})

local function selectBestFuel()
  local bestFuelSlot
  local bestFuelValue = 0
  for i = 1, 16 do -- We usually put fuel in the last slot, but if we run out then a log or sapling will do fine
      turtle.select(i)
      local currentItem = turtle.getItemDetail()
      if type(currentItem) == "table" and reverseItemLookup(currentItem).fuelValue and reverseItemLookup(currentItem).fuelValue > bestFuelValue then
        bestFuelSlot = i
        bestFuelValue = reverseItemLookup(currentItem).fuelValue
      end
  end

  if bestFuelSlot then
    turtle.select(bestFuelSlot)
    return true
  end

  return false
end

local v = selectBestFuel()

print(tostring(v))
