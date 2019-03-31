Options:Default "trace"

Tasks:clean()

Tasks:minify "minify" {
	input = "build/treeFarm.lua",
	output = "build/treeFarm.min.lua",
}

Tasks:require "main" {
	include = "treeFarm/*.lua",
	startup = "treeFarm/main.lua",
	output = "build/treeFarm.lua",
}

Tasks:Task "build" { "clean", "minify" } :Description "Main build task"
