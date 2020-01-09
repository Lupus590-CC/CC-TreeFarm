
local function new(prototype)
  return setmetatable({}, {__index = prototype})
end

local function new2(prototype)
  local function cachingLookup(tab, key)
    tab[key] = prototype[key]
    return prototype[key]
  end
  return setmetatable({}, {__index = cachingLookup})
end

local function uplift(object) -- TODO: performance test vs unuplifted object
  local prototype = getmetatable(object).__index
  local uplifitedObject = {}
  for k, v in pairs(prototype) do
    if type(v) == "function" then
      uplifitedObject[k] = function(...)
        return v(uplifitedObject, ...) -- TODO: catch errors which are blamed on this function's caller and blame our caller
      end
    else
      uplifitedObject[k] = v
    end
  end
  for k, v in pairs(object) do
    if type(v) == "function" then
      uplifitedObject[k] = function(...)
        return v(uplifitedObject, ...) -- TODO: catch errors which are blamed on this function's caller and blame our caller
      end
    else
      uplifitedObject[k] = v
    end
  end
  return uplifitedObject
end

local function upliftNew(prototype)
  return uplift(new(prototype))
end

while true do
local p = {
  f = function() end
}

local o = new(p)

local max = 10000000

local stopTime, startTime, deltaTime
startTime = os.clock("utc")
for i = 1, max do
  o:f()
end
stopTime = os.clock("utc")
deltaTime = stopTime - startTime
print("metamethod lookup "..deltaTime)
os.sleep(0.1)

o = uplift(o)
startTime = os.clock("utc")
for i = 1, max do
  o.f()
end
stopTime = os.clock("utc")
deltaTime = stopTime - startTime
print("uplifted "..deltaTime)
os.sleep(0.1)

o = new2(p)
startTime = os.clock("utc")
for i = 1, max do
  o:f()
end
stopTime = os.clock("utc")
deltaTime = stopTime - startTime
print("caching metamethod lookup "..deltaTime)
print()
os.sleep(0.1)
end


-- TODO: tostring on a function
-- tables can be called so function.tostring can be a method of that table
