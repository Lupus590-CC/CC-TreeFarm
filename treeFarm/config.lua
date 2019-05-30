local function load(filename)
  local file = fs.open(filename, "r")
  if file then
    local data = textutils.unserialize(file.readAll())
    file.close()
    return data
  end
  return nil, "not a file"
end

local function save(filename, data)
    local file = fs.open(filename, "w")
    file.write(textutils.serialize(data))
    file.close()
end


local config = {
  load = load,
  save = save,
}

return config
