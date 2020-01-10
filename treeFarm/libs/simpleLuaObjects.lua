-- Not Implemented
--  constructors
--  private variables and methods
--  inheritence (single can be faked but will break with uplift; multiple not supported)

-- best techneque based on speed of object creation and function call
-- best o:f() is new2
-- best o.f() is uplift (which depends on a o:f())
-- overal new2 is best but has o:f() syntax but uplift doesn't add to much overhead 

local function new(prototype) -- o:f()
  return setmetatable({}, {__index = prototype})
end

local function new2(prototype) -- o:f()
  local function cachingLookup(tab, key)
    tab[key] = prototype[key]
    return prototype[key]
  end
  return setmetatable({}, {__index = cachingLookup})
end

local function new3(prototype) -- o.f()
  local object = {}
  local env = setmetatable({self = object}, {__index = _ENV and _ENV or getfenv(1)})
  for k,v in pairs(prototype) do
    object[k] = v
    if type(v) == "function" then
      object[k] = setfenv(loadstring(string.dump(v)),env)
    end
  end
  return object
end

local function uplift(object) -- converts o:f() to o.f()
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

local function upliftNew(prototype) -- o.f()
  return uplift(new(prototype))
end

for j = 1, 1 do
local p = {
  f = function() end
}

local o = new(p)

local max = 1,000,000

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
os.sleep(0.1)

o = new3(p)
startTime = os.clock("utc")
for i = 1, max do
  o.f()
end
stopTime = os.clock("utc")
deltaTime = stopTime - startTime
print("setfenv "..deltaTime)
os.sleep(0.1)








startTime = os.clock("utc")
for i = 1, max do
  new(p)
end
stopTime = os.clock("utc")
deltaTime = stopTime - startTime
print("new "..deltaTime)
os.sleep(0.1)

startTime = os.clock("utc")
for i = 1, max do
  upliftNew(p)
end
stopTime = os.clock("utc")
deltaTime = stopTime - startTime
print("upliftNew "..deltaTime)
os.sleep(0.1)

startTime = os.clock("utc")
for i = 1, max do
  new2(p)
end
stopTime = os.clock("utc")
deltaTime = stopTime - startTime
print("new2 "..deltaTime)
os.sleep(0.1)

startTime = os.clock("utc")
for i = 1, max do
  new3(p)
end
stopTime = os.clock("utc")
deltaTime = stopTime - startTime
print("new3 "..deltaTime)
os.sleep(0.1)

print()
end


-- TODO: tostring on a function
-- tables can be called so function.tostring can be a method of that table
-- lua decompiler for string.dump?
