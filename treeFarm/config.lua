local function load(filename)
  local function unsafeload()
    local file = fs.open(filename, "r")
    local data = textutils.unserialize(file.readAll())
    file.close()
    return data
  end

  if not fs.exists(filename) or fs.isDir(filename) then
    return false, "not a file"
  end


  return pcall(unsafeload)
end

local function save(filename, data)
  local function unsafeSave()
    local file = fs.open(filename, "w")
    file.write(textutils.serialize(data))
    file.close()
  end

  return pcall(unsafeSave)
end


local config = {
  load = load,
  save = save,
}

return config
