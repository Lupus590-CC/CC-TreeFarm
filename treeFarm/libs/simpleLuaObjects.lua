-- Not Implemented
--  constructors
--  private variables and methods
--  inheritence (single can be faked but will break with uplift; multiple not supported)

local function new(prototype) -- o:f()
  local function cachingLookup(tab, key)
    tab[key] = prototype[key]
    return prototype[key]
  end
  return setmetatable({}, {__index = cachingLookup})
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




-- TODO: tostring on a function
-- tables can be called so function.tostring can be a method of that table
-- lua decompiler for string.dump?
