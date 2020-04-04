Options:Default "trace"

Tasks:clean()

Tasks:minify "minify" {
	input = "build/treefarm.un.lua",
	output = "build/treefarm.min.un.lua",
}

-- add license to start of output file
Tasks:Task "license" (function(_, _, file, dest)
  local fs = require("howl.platform").fs
  local contents = table.concat( {
  "--[[\n",
  fs.read(File("License.txt")),
  "\n]]\n\n",
  fs.read(File("build/treefarm.min.un.lua")),
  })

  fs.write(File("build/treefarm.min.lua"), contents)
  end)
  :Maps("build/treefarm.min.un.lua", "build/treefarm.min.lua")
  :description "Prepends license"


-- TODO: separate into multiple tasks, farm, build, furnace, remote, combine
-- they may be best to put in separate folders, in which case it may be a good
-- idea to add another task which copies the shared folder into these separate
-- project folders since require can't go up directories
-- wouldn't the above duplicate stuff as things become nested?
Tasks:require "mainBuild" (function(spec)
  -- Whatever you had before

  spec.sources:modify(function(file)
    if file.name:find("%.lua$") then
      return ('return assert(load(%q, %q, nil, _ENV))(...)'):format(file.contents, "@" .. file.relative)
    end
  end)
end){
  include = "treeFarm/*.lua",
  exclude = {"treeFarm/test.lua", "test/*.lua"},
  startup = "treeFarm/launcher.lua",
  output = "build/treefarm.un.lua",
}
  :Description "Main build task"


Tasks:require "testBuild" (function(spec)
  -- Whatever you had before

  spec.sources:modify(function(file)
    if file.name:find("%.lua$") then
      return ('return assert(load(%q, %q, nil, _ENV))(...)'):format(file.contents, "@" .. file.relative)
    end
  end)
end){
  include = "treeFarm/*.lua",
  startup = "treeFarm/test.lua",
  output = "build/treefarm.test.lua",
}

Tasks:Task "runTestFile" (function()

	shell.run("build/treefarm.test")
 end) :Requires { "build/treefarm.test.lua" }

Tasks:Task "test" { "clean", "testBuild" }
  :Description "Test build chain task"

Tasks:Task "runTest" { "clean", "runTestFile" }
  :Description "Test build and run chain task"


 Tasks:Task "build" { "clean", "mainBuild", "minify", "license" }
   :Description "Main build chain task"

Tasks:Default "build"
