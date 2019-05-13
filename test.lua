do -- require setup
local _ = require or dofile("require.lua")

_G.package.path = table.concat({
  "treefarm/?",
    "treefarm/?.lua",
    "treefarm/?/init.lua",
  _G.package.path,
}, ";")
end

local p = require("patience")

local temp = ""


parallel.waitForAny(p.run, function()
error() -- BUG: this doesn't run. p.run probably finishes to quickly, why/how?
print("hello world")
local f = fs.open("hello", "w")
f.write("world")
f.close()

temp = temp..tostring(p.isRunning()).."\n"
local t = p.startTimer(5)

temp = temp..tostring(t).."\n"
local e, e1 = os.pullEvent("patienceTimer")

temp = temp..tostring(e).."\n"
temp = temp..tostring(e1).."\n"

end)

print(temp)

-- TODO: post to forums #high
-- Why is only a new line being printed?
-- and why did nothing print when I had the prints in the waitForAny?

-- is the issue still present when config is stubbed?
  -- yes
