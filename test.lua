do -- require setup
local _ = require or dofile("require.lua")

_G.package.path = table.concat({
	"treefarm/?",
    "treefarm/?.lua",
    "treefarm/?/init.lua",
	_G.package.path,
}, ";")
end

-- TODO: what happens

local function move()
  while true do
    turtle.up()
  end
end

local function suck()
  while true do
    turtle.suck()
  end
end

parallel.waitforany(move,suck)