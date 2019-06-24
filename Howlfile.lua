Options:Default "trace"

Tasks:clean()

-- Tasks:minify "minify"
--   :Maps("wild:build/*.un.lua", "wild:build/*.min.un.lua")

-- add license to start of output file
Tasks:Task "license" (function(_, _, file, dest)
  local fs = require("howl.platform").fs
  local contents = table.concat( {
  "--[[\n",
  fs.read(File("License.txt")),
  "\n]]\n",
  fs.read(File(file)),
  })

  fs.write(File(dest), contents)
  end)
  :Maps("wild:build/*.un.lua", "wild:build/*.lua")
  :description "Prepends license"


-- TODO: separate into multiple tasks, farm, build, furnace, remote, combine
-- they may be best to put in separate folders, in which case it may be a good
-- idea to add another task which copies the shared folder into these separate
-- project folders since require can't go up directories
-- wouldn't the above duplicate stuff as things become nested?
Tasks:require "main" {
  include = "treeFarm/*.lua",
  startup = "treeFarm/launcher.lua",
  output = "build/treeFarm.un.lua",
}
Tasks:Default "main"

Tasks:Task "rename" (function() end)
  :Maps("wild:build/*.lua", "wild:build/*")
  :description "Removes .lua extention for Old CC compatability/convinience"

Tasks:Task "build" { "clean", "main", --[["minify", "license",]] "rename" }
  :Description "Main build task"
