do -- require setup
local _ = require or dofile("require.lua")

_G.package.path = table.concat({
  "treefarm/?",
    "treefarm/?.lua",
    "treefarm/?/init.lua",
  _G.package.path,
}, ";")
end
