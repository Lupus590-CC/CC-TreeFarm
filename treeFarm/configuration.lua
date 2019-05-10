--[[
The MIT License (MIT)

Copyright (c) 2014 Lyqyd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

-- Converted to be Require compatible by Lupus590 and released under the same MIT license.
local configuration = shell and {} or (_ENV or getfenv()) -- see https://github.com/lupus590/CC-Random-Code/blob/8cb3bd9b6e54c0176ff3e9418fc96b7866d3c963/src/dofile%20and%20loadAPI%20compatable%20API's.lua#L3

function configuration.load(path, _env)
  --load a configuration file, given a fully-resolved path and an optional environment.
  if not fs.exists(path) or fs.isDir(path) then return false, "not a file" end
  local env
  if not _env then
    --if we were not provided an environment, create one.
    env = setmetatable({}, {__index = _G})
  else
    env = _env
  end
  local fn, err = loadfile(path)
  if fn then
    setfenv(fn, env) -- TODO: does this still work?
    local success, err = pcall(fn)
    if success then
      --strip the metatable from the environment before returning it.
      return setmetatable(env, {})
    else
      return false, err
    end
  else
    return false, err
  end
end

function configuration.save(path, config)
  if not config or type(config) ~= "table" then return false, "not a configuration" end
  local handle = io.open(path, "w")
  if handle then
    for k, v in pairs(config) do
      local success, str = pcall(textutils.serialize, v)
      if success then
        handle:write(k.." = "..str.."\n\n")
      else
        handle:close()
        return false, "could not serialize value with key "..k
      end
    end
    handle:close()
    return true
  else
    return false, "could not write configuration."
  end
end

return configuration
