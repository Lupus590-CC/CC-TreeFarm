-- Copyright hydraz 2019
-- available at https://hydraz.semi.works/txt/stub.lua.html
-- https://discordapp.com/channels/477910221872824320/477911902152949771/593523800465866755

local stub_mt = {}
stub_mt.__index = stub_mt

local function pairwise_equal(ta, tb)
  if #ta ~= #tb then
    return false
  end

  for i = 1, #ta do
    if ta[i] ~= tb[i] then
      return false
    end
  end

  return true
end

function stub_mt.__call(it, ...)
  table.insert(it.arguments, table.pack(...))
end

function stub_mt:called()
  return #self.arguments ~= 0
end

function stub_mt:called_with(...)
  local args = {...}
  for i = 1, #self.arguments do
    if pairwise_equal(self.arguments[i], args) then
      return true
    end
  end
  return false
end

function stub_mt:revert()
  self.stubbed_in[self.key] = self.old
end

local function stub(it, ...)
  local keys = table.pack(...)
  for i = 1, keys.n do
    local thing = it[keys[i]]
    assert(thing and type(thing) == 'function')
    it[keys[i]] = setmetatable({
      arguments = {},
      stubbed_in = it,
      key = keys[i],
      old = thing
    }, stub_mt)
  end
  return table
end

return stub
