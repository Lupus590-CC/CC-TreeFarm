local function load(filename)
  local function unsafeload()
    local file = fs.open(filename, "r")
    if file then
      local data = textutils.unserialize(file.readAll())
      file.close()
      return data
    end
    error("not a file")
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
