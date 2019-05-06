local itemIds = {
  dirt = { name = "minecraft:dirt", damage = 0, maxStackSize = 64 },
  jackOLantern = { name = "minecraft:lit_pumpkin", damage = 0, maxStackSize = 64 },
  charcoal = { name= "minecraft:coal", damage = 1, fuelValue = 80, maxStackSize = 64 },
  coal = { name= "minecraft:coal", damage = 0, fuelValue = 80, maxStackSize = 64 },
  log = { name = "minecraft:log", damage = 0, fuelValue = 15, maxStackSize = 64 },
  wirelessModem = { name = "ComputerCraft:CC-Peripheral", damage = 1, maxStackSize = 64 },
  diamondPickaxe = { name = "minecraft:diamond_pickaxe", damage = 0, maxStackSize = 1 },
  chest = { name = "minecraft:chest", damage = 0, maxStackSize = 64 },
  torch = { name = "minecraft:torch", damage = 0, maxStackSize = 64 },
  furnace = { name = "minecraft:furnace", damage = 0, maxStackSize = 64 },
  fence = { name = "minecraft:fence", damage = 0, maxStackSize = 64 },
  hopper = { name = "minecraft:hopper", damage = 0, maxStackSize = 64 },
  packedIce = { name = "minecraft:packed_ice", damage = 0, maxStackSize = 64 },
  waterBucket = { name = "minecraft:water_bucket", damage = 0, maxStackSize = 1 },
  tone = { name = "minecraft:stone", damage = 0, maxStackSize = 64 },
  cobblestone = { name = "minecraft:cobblestone", damage = 0, maxStackSize = 64 },
  coalCoke = { name = "Railcraft:fuel.coke", damage = 0, fuelValue = 160, maxStackSize = 64 },
  coalCokeBlock = { name = "Railcraft:cube", damage = 0, fuelValue = 1600, maxStackSize = 64 },
  lavaBucket = { name = "minecraft:lava_bucket", damage = 0, fuelValue = 1000, maxStackSize = 64 },
  bucket = { name = "minecraft:bucket", damage = 0, maxStackSize = 64 },
  coalBlock = { name= "minecraft:coal_block", damage = 0, fuelValue = 800, maxStackSize = 64 },
}

for k, v in pairs(itemIds) do
  itemIds[k].internalName = k
end



return itemIds
