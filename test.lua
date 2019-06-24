do -- require setup
  local _ = require or dofile("require.lua")

  _G.package.path = table.concat({
      "treefarm/?.lua",
      "treefarm/?/init.lua",
      "treefarm/libs/?.lua",
      "treefarm/libs/?/init.lua",
      "treefarm/libs/utils/?.lua",
      "treefarm/libs/utils/?/init.lua",
      "treefarm/libs/utils/itemUtils/?.lua",
      "treefarm/libs/utils/itemUtils/?/init.lua",
    _G.package.path,
  }, ";")
end



require("argChecker")
print(_ENV.argChecker)
local t = require("itemUtils")

t.selectBestFuel(1)
