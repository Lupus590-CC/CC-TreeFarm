Options:Default "trace"
Tasks:Default "build"

Tasks:clean()

Tasks:minify "minify" {
	input = "build/treeFarm.lua",
	output = "build/treeFarm.min.lua",
}

-- TODO: separate into multiple tasks, farm, build, furnace, remote, combine
-- they may be best to put in separate folders, in which case it may be a good idea to
-- add another task which copies the shared folder into these separate
-- project folders since require can't go up directories
Tasks:require "main" {
	include = "treeFarm/*.lua",
	startup = "treeFarm/main.lua",
	output = "build/treeFarm.lua",
}

Tasks:Task "build" { "clean", "minify" } :Description "Main build task"
