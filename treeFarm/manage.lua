-- general management of the farm
function chopTree() -- TODO: handle branches
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
