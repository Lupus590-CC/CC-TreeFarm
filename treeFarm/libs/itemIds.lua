
local itemIds = { -- TODO: remove non-charcoal fuels?
-- TODO: save to file and allow override?
  dirt = { name = "minecraft:dirt", damage = 0, maxCount = 64 },
  jackOLantern = { name = "minecraft:lit_pumpkin", damage = 0, maxCount = 64, },
  charcoal = { name= "minecraft:coal", damage = 1, fuelValue = 80, maxCount = 64, },
  -- coal = { name= "minecraft:coal", damage = 0, fuelValue = 80, maxCount = 64, },
  log = { name = "minecraft:log", damage = 0, fuelValue = 15, maxCount = 64, },
  wirelessModem = { name = "ComputerCraft:CC-Peripheral", damage = 1, maxCount = 64, equippedName = "modem", },
  diamondPickaxe = { name = "minecraft:diamond_pickaxe", damage = 0, maxCount = 1, }, -- why doesn't this have an equip name?!?!?
  chest = { name = "minecraft:chest", damage = 0, maxCount = 64, },
  torch = { name = "minecraft:torch", damage = 0, maxCount = 64, },
  furnace = { name = "minecraft:furnace", damage = 0, maxCount = 64, },
  fence = { name = "minecraft:fence", damage = 0, maxCount = 64, },
  hopper = { name = "minecraft:hopper", damage = 0, maxCount = 64, },
  packedIce = { name = "minecraft:packed_ice", damage = 0, maxCount = 64, },
  waterBucket = { name = "minecraft:water_bucket", damage = 0, maxCount = 1, },
  stone = { name = "minecraft:stone", damage = 0, maxCount = 64, scaffoldBlock = 5, buildingBlock = 1 },
  cobblestone = { name = "minecraft:cobblestone", damage = 0, maxCount = 64, scaffoldBlock = 1, buildingBlock = 5 },
  -- coalCoke = { name = "Railcraft:fuel.coke", damage = 0, fuelValue = 160, maxCount = 64, },
  -- coalCokeBlock = { name = "Railcraft:cube", damage = 0, fuelValue = 1600, maxCount = 64, },
  -- lavaBucket = { name = "minecraft:lava_bucket", damage = 0, fuelValue = 1000, maxCount = 64, },
  bucket = { name = "minecraft:bucket", damage = 0, maxCount = 64 },
  -- coalBlock = { name= "minecraft:coal_block", damage = 0, fuelValue = 800, maxCount = 64, },
  sapling = { name = "minecraft:sapling", damage = 0, fuelValue = 5, maxCount = 64, },
  leaves = { name = "minecraft:leaves", damage = 0, maxCount = 64, },
  moonDirt = { name = "galacticraftcore:basic_block_moon", damage = 3, maxCount = 64, scaffoldBlock = 2, buildingBlock = 2 },
  moonTurf = { name = "galacticraftcore:basic_block_moon", damage = 5, maxCount = 64, scaffoldBlock = 3, buildingBlock = 3 },
  moonRock = { name = "galacticraftcore:basic_block_moon", damage = 4, maxCount = 64, scaffoldBlock = 4, buildingBlock = 4 },
  blockScanner = { name = "plethora:module", damage = 2, maxCount = 64, equippedName = "plethora:scanner", },
}

for k, v in pairs(itemIds) do
  itemIds[k].internalName = k
end

itemIds.stone.digsInto = cobblestone


-- allows finding item info from the itemIds table using the details
  -- provided by turtle.getItemDetail
local reverseItemLookup = {}
for k, v in pairs(itemIds) do
  reverseItemLookup[v.name..":"..tostring(v.damage)] = itemIds[k]
end
setmetatable(reverseItemLookup, {
  __call = function(_self, itemId) -- converts real items to their table version above
    if itemId == nil then
      itemId = _self
      _self = reverseItemLookup
    end
    argValidationUtils.itemIdChecker(1, itemId)
    return reverseItemLookup[itemId.name..":"..tostring(itemId.damage)]
  end
})

return {itemIds = itemIds, reverseItemLookup = reverseItemLookup}
