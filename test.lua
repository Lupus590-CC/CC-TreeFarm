local _ = require or dofile(shell.dir().."require.lua"")


function chopTree()
  turtle.dig()
  turtle.forward()
  while turtle.detectUp() do
    turtle.digUp()
    turtle.up()
  end
  while turtle.down() do
  end
  turtle.digDown()
end

local before = os.clock()

chopTree()
turtle.forward()
turtle.forward()

local after = os.clock()

print("time taken: "..tostring(after-before))
