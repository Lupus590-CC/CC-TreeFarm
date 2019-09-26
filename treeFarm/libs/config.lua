--
-- Copyright 2019 Lupus590
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions: The above copyright
-- notice and this permission notice shall be included in all copies or
-- substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.


-- heavily inspired by Lyqyd's own config API https://github.com/lyqyd/cc-configuration

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
