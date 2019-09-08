local itemIds = { -- TODO: remove non-charcoal fuels?
-- TODO: save to file and allow override?
  dirt = { name = "minecraft:dirt", damage = 0, maxStackSize = 64 },
  jackOLantern = { name = "minecraft:lit_pumpkin", damage = 0, maxStackSize = 64, },
  charcoal = { name= "minecraft:coal", damage = 1, fuelValue = 80, maxStackSize = 64, },
  -- coal = { name= "minecraft:coal", damage = 0, fuelValue = 80, maxStackSize = 64, },
  log = { name = "minecraft:log", damage = 0, fuelValue = 15, maxStackSize = 64, },
  wirelessModem = { name = "ComputerCraft:CC-Peripheral", damage = 1, maxStackSize = 64, equippedName = "modem", },
  diamondPickaxe = { name = "minecraft:diamond_pickaxe", damage = 0, maxStackSize = 1, }, -- why doesn't this have an equip name?!?!?
  chest = { name = "minecraft:chest", damage = 0, maxStackSize = 64, },
  torch = { name = "minecraft:torch", damage = 0, maxStackSize = 64, },
  furnace = { name = "minecraft:furnace", damage = 0, maxStackSize = 64, },
  fence = { name = "minecraft:fence", damage = 0, maxStackSize = 64, },
  hopper = { name = "minecraft:hopper", damage = 0, maxStackSize = 64, },
  packedIce = { name = "minecraft:packed_ice", damage = 0, maxStackSize = 64, },
  waterBucket = { name = "minecraft:water_bucket", damage = 0, maxStackSize = 1, },
  stone = { name = "minecraft:stone", damage = 0, maxStackSize = 64, scaffoldBlock = 5, buildingBlock = 1 },
  cobblestone = { name = "minecraft:cobblestone", damage = 0, maxStackSize = 64, scaffoldBlock = 1, buildingBlock = 5 },
  -- coalCoke = { name = "Railcraft:fuel.coke", damage = 0, fuelValue = 160, maxStackSize = 64, },
  -- coalCokeBlock = { name = "Railcraft:cube", damage = 0, fuelValue = 1600, maxStackSize = 64, },
  -- lavaBucket = { name = "minecraft:lava_bucket", damage = 0, fuelValue = 1000, maxStackSize = 64, },
  bucket = { name = "minecraft:bucket", damage = 0, maxStackSize = 64 },
  -- coalBlock = { name= "minecraft:coal_block", damage = 0, fuelValue = 800, maxStackSize = 64, },
  sapling = { name = "minecraft:sapling", damage = 0, fuelValue = 5, maxStackSize = 64, },
  leaves = { name = "minecraft:leaves", damage = 0, maxStackSize = 64, },
  moonDirt = { name = "galacticraftcore:basic_block_moon", damage = 3, maxStackSize = 64, scaffoldBlock = 2, buildingBlock = 2 },
  moonTurf = { name = "galacticraftcore:basic_block_moon", damage = 5, maxStackSize = 64, scaffoldBlock = 3, buildingBlock = 3 },
  moonRock = { name = "galacticraftcore:basic_block_moon", damage = 4, maxStackSize = 64, scaffoldBlock = 4, buildingBlock = 4 },
  blockScanner = { name = "plethora:module", damage = 2, maxStackSize = 64, equippedName = "plethora:scanner", },
}

for k, v in pairs(itemIds) do
  itemIds[k].internalName = k
end

itemIds.stone.digsInto = cobblestone


return itemIds
