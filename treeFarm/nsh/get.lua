-- TODO: convert to API?
  -- once converted copy to hive
    -- maybe not, it's not very flexible: the nsh protocol (tror) doesn't seem to do files very well

--[[
Copyright (c) 2012 Christopher Beach

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
]]

if not nsh then print("No nsh session!") return end

local args = {...}

if #args < 2 then
  print("Usage: get <remote> <local>")
  print("<remote>: any file on the server")
  print("<local>: any non-existant file on the client")
  return
end

if fs.exists(args[1]) then
  nsh.send("FS:;t="..args[2])
  local message = nsh.receive()
  if message == "FR:;ok" then
    nsh.send("FH:;"..args[1])
    local handle = io.open(args[1], "r")
    if handle then
      nsh.send("FD:;t="..handle:read("*a"))
      handle:close()
    end
    nsh.send("FE:;end")
  else
    print("Client rejected file!")
  end
end
