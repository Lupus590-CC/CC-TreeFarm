local function _W(f) local e=setmetatable({}, {__index = _ENV or getfenv()}) if setfenv then setfenv(f, e) end return f(e) or e end
local Dump=_W(function(_ENV, ...)
--- A util module that is only ever used in debugging
-- @module Utils.Dump

--- Format an object
-- @param object The object to foramt
-- @treturn string The object
local function InternalFormat(object)
	if type(object) == "string" then
		return string.format("%q", object)
	else
		return tostring(object)
	end
end

--- Core dumping of object
-- @param object The object to dump
-- @tparam ?|string indent The indent to use
-- @tparam table seen A list of seen objects
-- @tparam boolean meta Print metatables too
local function InternalDump(object, indent, seen, meta)
	local result = ""
	local objType = type(object)
	if objType == "table" then
		local id = seen[object]

		if id then
			result = result .. (indent .. "--[[ Object@" .. id .. " ]] { }") .. "\n"
		else
			id = seen.length + 1
			seen[object] = id
			seen.length = id
			result = result .. (indent .. "--[[ Object@" .. id .. " ]] {") .. "\n"
			for k, v in pairs(object) do

				if type(k) == "table" then
					result = result .. (indent .. "\t{") .. "\n"
					result = result .. InternalDump(k, indent .. "\t\t", seen, meta)
					result = result .. InternalDump(v, indent .. "\t\t", seen, meta)
					result = result .. (indent .. "\t},") .. "\n"
				elseif type(v) == "table" then
					result = result .. (indent .. "\t[" .. InternalFormat(k) .. "] = {") .. "\n"
					result = result .. InternalDump(v, indent .. "\t\t", seen, meta)
					result = result .. (indent .. "\t},") .. "\n"
				else
					result = result .. (indent .. "\t[" .. InternalFormat(k) .. "] = " .. InternalFormat(v) .. ",") .. "\n"
				end
			end

			if meta then
				local metatable = getmetatable(object)

				if metatable then
					result = result .. (indent .. "\tMetatable = {") .. "\n"
					result = result .. InternalDump(metatable, indent .. "\t\t", seen, meta)
					result = result .. (indent .. "\t}") .. "\n"
				end
			end
			result = result .. (indent .. "}") .. "\n"
		end
	else
		result = result .. (indent .. InternalFormat(object)) .. "\n"
	end

	return result
end

--- Dumps an object
-- @param object The object to dump
-- @tparam boolean meta Print metatables too
-- @tparam ?|string indent The indent to use
local function Dump(object, meta, indent)
	if meta == nil then meta = true end
	return InternalDump(object, indent or "", { length = 0 }, meta)
end

return Dump
end)
local Helpers=_W(function(_ENV, ...)
-- Emulates the bits I use of the shell API
-- @module interop.Shell

local push, pull = os.queueEvent, coroutine.yield

local function refreshYield()
	push("sleep")
	if pull() == "terminate" then error("Terminated") end
end

return {
	dir = shell.dir,
	refreshYield = refreshYield,
	serialize = textutils.serialize,
}
end)
local Utils=_W(function(_ENV, ...)
--- Useful little helpers for things
-- @module Utils

local isVerbose = false

--- Prints a string in a colour if colour is supported
-- @tparam int color The colour to print
-- @param ... Values to print
local function PrintColor(color, ...)
	local isColor = term.isColor()
	if isColor then term.setTextColor(color) end
	print(...)
	if isColor then term.setTextColor(colors.white) end
end

--- Writes a string in a colour if colour is supported
-- @tparam int color The colour to print
-- @tparam string text Values to print
local function WriteColor(color, text)
	local isColor = term.isColor()
	if isColor then term.setTextColor(color) end
	io.write(text)
	if isColor then term.setTextColor(colors.white) end
end

--- Prints a string in green if colour is supported
-- @param ... Values to print
local function PrintSuccess(...) PrintColor(colors.green, ...) end

--- Prints a string in red if colour is supported
-- @param ... Values to print
local function PrintError(...) PrintColor(colors.red, ...) end

--- Check if verbose is true
-- @tparam ?|value If not nil, set verbose to true
-- @treturn boolean Is verbose output on
local function IsVerbose(value)
	if value ~= nil then isVerbose = value end
	return isVerbose
end

--- Prints a verbose string if verbose is turned on
-- @param ... Values to print
local function Verbose(...)
	if isVerbose then
		local _, m = pcall(function() error("", 4) end)
		WriteColor(colors.gray, m)
		PrintColor(colors.lightGray, ...)
	end
end

--- Pretty prints values if verbose is turned on
-- @param ... Values to print
local function VerboseLog(...)
	if isVerbose then
		local _, m = pcall(function() error("", 4) end)
		WriteColor(colors.gray, m)

		local hasPrevious = false
		for _, value in ipairs({ ... }) do
			local t = type(value)
			if t == "table" then
				local dmp = Dump or Helpers.serialize
				value = dmp(value)
			else
				value = tostring(value)
			end

			if hasPrevious then value = " " .. value end
			hasPrevious = true
			WriteColor(colors.lightGray, value)
		end
		print()
	end
end

local matches = {
	["^"] = "%^",
	["$"] = "%$",
	["("] = "%(",
	[")"] = "%)",
	["%"] = "%%",
	["."] = "%.",
	["["] = "%[",
	["]"] = "%]",
	["*"] = "%*",
	["+"] = "%+",
	["-"] = "%-",
	["?"] = "%?",
	["\0"] = "%z",
}

--- Escape a string for using in a pattern
-- @tparam string pattern The string to escape
-- @treturn string The escaped pattern
local function EscapePattern(pattern)
	return (pattern:gsub(".", matches))
end

local basicMatches = {
	["^"] = "%^",
	["$"] = "%$",
	["("] = "%(",
	[")"] = "%)",
	["%"] = "%%",
	["."] = "%.",
	["["] = "%[",
	["]"] = "%]",
	["+"] = "%+",
	["-"] = "%-",
	["?"] = "%?",
	["\0"] = "%z",
}

--- A resulting pattern
-- @table Pattern
-- @tfield string Type `Pattern` or `Normal`
-- @tfield string Text The resulting pattern

--- Parse a series of patterns
-- @tparam string text Pattern to parse
-- @tparam boolean invert If using a wildcard, invert it
-- @treturn Pattern
local function ParsePattern(text, invert)
	local beginning = text:sub(1, 5)
	if beginning == "ptrn:" or beginning == "wild:" then

		local text = text:sub(6)
		if beginning == "wild:" then
			if invert then
				local counter = 0
				-- Escape the pattern and then replace wildcards with the results of the capture %1, %2, etc...
				text = ((text:gsub(".", basicMatches)):gsub("(%*)", function()
					counter = counter + 1
					return "%" .. counter
				end))
			else
				-- Escape the pattern and replace wildcards with (.*) capture
				text = "^" .. ((text:gsub(".", basicMatches)):gsub("(%*)", "(.*)")) .. "$"
			end
		end

		return { Type = "Pattern", Text = text }
	else
		return { Type = "Normal", Text = text }
	end
end

--- Create a lookup table from a list of values
-- @tparam table tbl The table of values
-- @treturn The same table, with lookups as well
local function CreateLookup(tbl)
	for _, v in ipairs(tbl) do
		tbl[v] = true
	end
	return tbl
end

--- Checks if two tables are equal
-- @tparam table a
-- @tparam table b
-- @treturn boolean If they match
local function MatchTables(a, b)
	local length = #a
	if length ~= #b then return false end

	for i = 1, length do
		if a[i] ~= b[i] then return false end
	end
	return true
end

-- Hacky docs for objects

--- Print messages
local Print = print

--- @export
return {
	Print = Print,
	PrintError = PrintError,
	PrintSuccess = PrintSuccess,
	PrintColor = PrintColor,
	WriteColor = WriteColor,
	IsVerbose = IsVerbose,
	Verbose = Verbose,
	VerboseLog = VerboseLog,
	EscapePattern = EscapePattern,
	ParsePattern = ParsePattern,
	CreateLookup = CreateLookup,
	MatchTables = MatchTables,
}
end)
local Mediator=_W(function(_ENV, ...)
local type, pairs = type, pairs

local Subscriber = {}
function Subscriber:update(options)
	if options then
		self.fn = options.fn or self.fn
		self.options = options.options or self.options
	end
end

local function SubscriberFactory(fn, options)
	return setmetatable({
		options = options or {},
		fn = fn,
		channel = nil,
		id = math.random(1000000000), -- sounds reasonable, rite?
	}, { __index = Subscriber })
end

local Channel = {}
local function ChannelFactory(namespace, parent)
	return setmetatable({
		stopped = false,
		namespace = namespace,
		callbacks = {},
		channels = {},
		parent = parent,
	}, { __index = Channel })
end

function Channel:addSubscriber(fn, options)
	local callback = SubscriberFactory(fn, options)
	local priority = (#self.callbacks + 1)

	options = options or {}

	if options.priority and
		options.priority >= 0 and
		options.priority < priority
	then
		priority = options.priority
	end

	table.insert(self.callbacks, priority, callback)

	return callback
end

function Channel:getSubscriber(id)
	for i = 1, #self.callbacks do
		local callback = self.callbacks[i]
		if callback.id == id then return { index = i, value = callback } end
	end
	local sub
	for _, channel in pairs(self.channels) do
		sub = channel:getSubscriber(id)
		if sub then break end
	end
	return sub
end

function Channel:setPriority(id, priority)
	local callback = self:getSubscriber(id)

	if callback.value then
		table.remove(self.callbacks, callback.index)
		table.insert(self.callbacks, priority, callback.value)
	end
end

function Channel:addChannel(namespace)
	self.channels[namespace] = ChannelFactory(namespace, self)
	return self.channels[namespace]
end

function Channel:hasChannel(namespace)
	return namespace and self.channels[namespace] and true
end

function Channel:getChannel(namespace)
	return self.channels[namespace] or self:addChannel(namespace)
end

function Channel:removeSubscriber(id)
	local callback = self:getSubscriber(id)

	if callback and callback.value then
		for _, channel in pairs(self.channels) do
			channel:removeSubscriber(id)
		end

		return table.remove(self.callbacks, callback.index)
	end
end

function Channel:publish(result, ...)
	for i = 1, #self.callbacks do
		local callback = self.callbacks[i]

		-- if it doesn't have a predicate, or it does and it's true then run it
		if not callback.options.predicate or callback.options.predicate(...) then
			-- just take the first result and insert it into the result table
			local continue, value = callback.fn(...)

			if value then result[#result] = value end
			if continue == false then return false, result end
		end
	end

	if parent then
		return parent:publish(result, ...)
	else
		return true, result
	end
end

local channel = ChannelFactory('root')
local function GetChannel(channelNamespace)
	local channel = channel

	if type(channelNamespace) == "string" then
		if channelNamespace:find(":") then
			channelNamespace = { channelNamespace:match((channelNamespace:gsub("[^:]+:?", "([^:]+):?"))) }
		else
			channelNamespace = { channelNamespace }
		end
	end

	for i = 1, #channelNamespace do
		channel = channel:getChannel(channelNamespace[i])
	end

	return channel
end

local function Subscribe(channelNamespace, fn, options)
	return GetChannel(channelNamespace):addSubscriber(fn, options)
end

local function GetSubscriber(id, channelNamespace)
	return GetChannel(channelNamespace):getSubscriber(id)
end

local function RemoveSubscriber(id, channelNamespace)
	return GetChannel(channelNamespace):removeSubscriber(id)
end

local function Publish(channelNamespace, ...)
	return GetChannel(channelNamespace):publish({}, ...)
end

return {
	GetChannel = GetChannel,
	Subscribe = Subscribe,
	GetSubscriber = GetSubscriber,
	RemoveSubscriber = RemoveSubscriber,
	Publish = Publish,
}
end)
local ArgParse=_W(function(_ENV, ...)
--- Parses command line arguments
-- @module ArgParse

--- Simple wrapper for Options
-- @type Option
local Option = {
	__index = function(self, func)
		return function(self, ...)
			local parser = self.parser
			local value = parser[func](parser, self.name, ...)

			if value == parser then return self end -- Allow chaining
			return value
		end
	end
}

--- Parses command line arguments
-- @type Parser
local Parser = {}

--- Returns the value of a option
-- @tparam string name The name of the option
-- @tparam string|boolean default The default value (optional)
-- @treturn string|boolean The value of the option
function Parser:Get(name, default)
	local options = self.options

	local value = options[name]
	if value ~= nil then return value end

	local settings = self.settings[name]
	if settings then
		local aliases = settings.aliases
		if aliases then
			for _, alias in ipairs(aliases) do
				value = options[alias]
				if value ~= nil then return value end
			end
		end

		value = settings.default
		if value ~= nil then return value end
	end


	return default
end

--- Ensure a option exists, throw an error otherwise
-- @tparam string name The name of the option
-- @treturn string|boolean The resulting value
function Parser:Ensure(name)
	local value = self:Get(name)
	if value == nil then
		error(name .. " must be set")
	end
	return value
end

--- Set the default value for an option
-- @tparam string name The name of the options
-- @tparam string|boolean value The default value
-- @treturn Parser The current object
function Parser:Default(name, value)
	if value == nil then value = true end
	self:_SetSetting(name, "default", value)

	self:_Changed()
	return self
end

--- Sets an alias for an option
-- @tparam string name The name of the option
-- @tparam string alias The alias of the option
-- @treturn Parser The current object
function Parser:Alias(name, alias)
	local settings = self.settings
	local currentSettings = settings[name]
	if currentSettings then
		local currentAliases = currentSettings.aliases
		if currentAliases == nil then
			currentSettings.aliases = { alias }
		else
			table.insert(currentAliases, alias)
		end
	else
		settings[name] = { aliases = { alias } }
	end

	self:_Changed()
	return self
end

--- Sets the description, and type for an option
-- @tparam string name The name of the option
-- @tparam string description The description of the option
-- @treturn Parser The current object
function Parser:Description(name, description)
	return self:_SetSetting(name, "description", description)
end

--- Sets if this option takes a value
-- @tparam string name The name of the option
-- @tparam boolean takesValue If the option takes a value
-- @treturn Parser The current object
function Parser:TakesValue(name, takesValue)
	if takesValue == nil then
		takesValue = true
	end
	return self:_SetSetting(name, "takesValue", takesValue)
end

--- Sets a setting for an option
-- @tparam string name The name of the option
-- @tparam string key The key of the setting
-- @tparam boolean|string value The value of the setting
-- @treturn Parser The current object
-- @local
function Parser:_SetSetting(name, key, value)
	local settings = self.settings
	local thisSettings = settings[name]

	if thisSettings then
		thisSettings[key] = value
	else
		settings[name] = { [key] = value }
	end

	return self
end

--- Creates a useful option helper object
-- @tparam string name The name of the option
-- @treturn Option The created option
function Parser:Option(name)
	return setmetatable({
		name = name,
		parser = self
	}, Option)
end

--- Returns a list of arguments
-- @treturn table The argument list
function Parser:Arguments()
	return self.arguments
end

--- Fires the on changed event
-- @local
function Parser:_Changed()
	Mediator.Publish({ "ArgParse", "changed" }, self)
end

--- Generates a help string
-- @tparam string indent The indent to print it at
function Parser:Help(indent)
	for name, settings in pairs(self.settings) do
		local prefix = '-'

		-- If we take a value then we should say so
		if settings.takesValue then
			prefix = "--"
			name = name .. "=value"
		end

		-- If length is more than one then we should set
		-- the prefix to be --
		if #name > 1 then
			prefix = '--'
		end

		Utils.WriteColor(colors.white, indent .. prefix .. name)

		local aliasStr = ""
		local aliases = settings.aliases
		if aliases and #aliases > 0 then
			local aliasLength = #aliases
			aliasStr = aliasStr .. " ("

			for i = 1, aliasLength do
				local alias = "-" .. aliases[i]

				if #alias > 2 then -- "-" and another character
					alias = "-" .. alias
				end

				if i < aliasLength then
					alias = alias .. ', '
				end

				aliasStr = aliasStr .. alias
			end
			aliasStr = aliasStr .. ")"
		end

		Utils.WriteColor(colors.brown, aliasStr)
		local description = settings.description
		if description and description ~= "" then
			Utils.PrintColor(colors.lightGray, " " .. description)
		end
	end
end

--- Parse the options
-- @treturn Parser The current object
function Parser:Parse(args)
	local options = self.options
	local arguments = self.arguments
	for _, arg in ipairs(args) do
		if arg:sub(1, 1) == "-" then -- Match `-`
			if arg:sub(2, 2) == "-" then -- Match `--`
				local key, value = arg:match("([%w_%-]+)=([%w_%-]+)", 3) -- Match [a-zA-Z0-9_-] in form key=value
				if key then
					options[key] = value
				else
					-- If it starts with not- or not_ then negate it
					arg = arg:sub(3)
					local beginning = arg:sub(1, 4)
					local value = true
					if beginning == "not-" or beginning == "not_" then
						value = false
						arg = arg:sub(5)
					end
					options[arg] = value
				end
			else -- Handle switches
				for i = 2, #arg do
					options[arg:sub(i, i)] = true
				end
			end
		else
			table.insert(arguments, arg)
		end
	end

	return self
end

--- Create a new options parser
-- @tparam table args The command line arguments passed
-- @treturn Parser The resulting parser
local function Options(args)
	return setmetatable({
		options = {}, -- The resulting values
		arguments = {}, -- Spare arguments

		settings = {}, -- Settings for options
	}, { __index = Parser }):Parse(args)
end

--- @export
return {
	Parser = Parser,
	Options = Options,
}
end)
local Context=_W(function(_ENV, ...)
--- Manages the running of tasks
-- @module tasks.Context

--- Holds task contexts
-- @type Context
local Context = {}

function Context:DoRequire(path, quite)
	if self.filesProduced[path] then return true end

	-- Check for normal files
	local task = self.producesCache[path]
	if task then
		self.filesProduced[path] = true
		return self:Run(task)
	end

	-- Check for file mapping
	task = self.normalMapsCache[path]
	local from, name
	local to = path
	if task then
		self.filesProduced[path] = true

		-- Convert task.Pattern.From to path
		-- (which should be task.Pattern.To)
		name = task.Name
		from = task.Pattern.From
	end

	for match, data in pairs(self.patternMapsCache) do
		if path:match(match) then
			self.filesProduced[path] = true

			-- Run task, replacing match with the replacement pattern
			name = data.Name
			from = path:gsub(match, data.Pattern.From)
			break
		end
	end

	if name then
		local canCreate = self:DoRequire(from, true)
		if not canCreate then
			if not quite then
				Utils.PrintError("Cannot find '" .. from .. "'")
			end
			return false
		end

		return self:Run(name, from, to)
	end

	if fs.exists(fs.combine(self.env.CurrentDirectory , path)) then
		self.filesProduced[path] = true
		return true
	end

	if not quite then
		Utils.PrintError("Cannot find a task matching '" .. path .. "'")
	end
	return false
end

local function arrayEquals(x, y)
	local len = #x
	if #x ~= #y then return false end

	for i = 1, len do
		if x[i] ~= y[i] then return false end
	end
	return true
end

--- Run a task
-- @tparam string|Task.Task name The name of the task or a Task object
-- @param ... The arguments to pass to it
-- @treturn boolean Success in running the task?
function Context:Run(name, ...)
	local task = name
	if type(name) == "string" then
		task = self.tasks[name]

		if not task then
			Utils.PrintError("Cannot find a task called '" .. name .. "'")
			return false
		end
	elseif not task or not task.Run then
		Utils.PrintError("Cannot call task as it has no 'Run' method")
		return false
	end

	-- Search if this task has been run with the given arguments
	local args = { ... }
	local ran = self.ran[task]
	if not ran then
		ran = { args }
		self.ran[task] = ran
	else
		for i = 1, #ran do
			if arrayEquals(args, ran[i]) then return true end
		end
		ran[#ran + 1] = args
	end

	-- Sleep before every task just in case
	Helpers.refreshYield()

	return task:Run(self, ...)
end

--- Start the task process
-- @tparam string name The name of the task (Optional)
-- @treturn boolean Success in running the task?
function Context:Start(name)
	local task
	if name then
		task = self.tasks[name]
	else
		task = self.default
		name = "<default>"
	end

	if not task then
		Utils.PrintError("Cannot find a task called '" .. name .. "'")
		return false
	end

	return self:Run(task)
end

--- Build a cache of tasks
-- This is used to speed up finding file based tasks
-- @treturn Context The current context
function Context:BuildCache()
	local producesCache = {}
	local patternMapsCache = {}
	local normalMapsCache = {}

	self.producesCache = producesCache
	self.patternMapsCache = patternMapsCache
	self.normalMapsCache = normalMapsCache

	for name, task in pairs(self.tasks) do
		local produces = task.produces
		if produces then
			for _, file in ipairs(produces) do
				local existing = producesCache[file]
				if existing then
					error(string.format("Both '%s' and '%s' produces '%s'", existing, name, file))
				end
				producesCache[file] = name
			end
		end

		local maps = task.maps
		if maps then
			for _, pattern in ipairs(maps) do
				-- We store two separate caches for each of them
				local toMap = (pattern.Type == "Pattern" and patternMapsCache or normalMapsCache)
				local match = pattern.To
				local existing = toMap[match]
				if existing then
					error(string.format("Both '%s' and '%s' match '%s'", existing, name, match))
				end
				toMap[match] = { Name = name, Pattern = pattern }
			end
		end
	end

	return self
end

--- Create a new task context
-- @tparam Runner.Runner runner The task runner to run tasks from
-- @treturn Context The resulting context
local function Factory(runner)
	return setmetatable({
		ran = {}, -- List of task already run
		filesProduced = {},
		tasks = runner.tasks,
		default = runner.default,

		Traceback = runner.Traceback,
		ShowTime = runner.ShowTime,
		env = runner.env,
	}, { __index = Context }):BuildCache()
end

--- @export
return {
	Factory = Factory,
	Context = Context,
}
end)
local Task=_W(function(_ENV, ...)
--- The main task class
-- @module tasks.Task

--- Convert a pattern
local function ParsePattern(from, to)
	local fromParsed = Utils.ParsePattern(from, true)
	local toParsed = Utils.ParsePattern(to)

	local newType = fromParsed.Type
	assert(newType == toParsed.Type, "Both from and to must be the same type " .. newType .. " and " .. fromParsed.Type)

	return { Type = newType, From = fromParsed.Text, To = toParsed.Text }
end

--- A single task: actions, dependencies and metadata
-- @type Task
local Task = {}

--- Define what this task depends on
-- @tparam string|table name Name/list of dependencies
-- @treturn Task The current object (allows chaining)
function Task:Depends(name)
	if type(name) == "table" then
		local dependencies = self.dependencies
		for _, task in ipairs(name) do
			table.insert(dependencies, task)
		end
	else
		table.insert(self.dependencies, name)
	end

	return self
end

--- Sets a file this task requires
-- @tparam string|table file The path of the file
-- @treturn Task The current object (allows chaining)
function Task:Requires(file)
	if type(file) == "table" then
		local requires = self.requires
		for _, file in ipairs(file) do
			table.insert(requires, file)
		end
	else
		table.insert(self.requires, file)
	end
	return self
end

--- Sets a file this task produces
-- @tparam string|table file The path of the file
-- @treturn Task The current object (allows chaining)
function Task:Produces(file)
	if type(file) == "table" then
		local produces = self.produces
		for _, file in ipairs(file) do
			table.insert(produces, file)
		end
	else
		table.insert(self.produces, file)
	end
	return self
end

--- Sets a file mapping
-- @tparam string from The file to map form
-- @tparam string to The file to map to
-- @treturn Task The current object (allows chaining)
function Task:Maps(from, to)
	table.insert(self.maps, ParsePattern(from, to))
	return self
end

--- Set the action for this task
-- @tparam function action The action to run
-- @treturn Task The current object (allows chaining)
function Task:Action(action)
	self.action = action
	return self
end

--- Set the description for this task
-- @tparam string text The description of the task
-- @treturn Task The current object (allows chaining)
function Task:Description(text)
	self.description = text
	return self
end

--- Run the action with no bells or whistles
function Task:_RunAction(env, ...)
	return self.action(self, env, ...)
end

--- Execute the task
-- @tparam Context.Context context The task context
-- @param ... The arguments to pass to task
-- @tparam boolean Success
function Task:Run(context, ...)
	for _, depends in ipairs(self.dependencies) do
		if not context:Run(depends) then
			return false
		end
	end

	for _, file in ipairs(self.requires) do
		if not context:DoRequire(file) then
			return false
		end
	end

	for _, file in ipairs(self.produces) do
		context.filesProduced[file] = true
	end

	-- Technically we don't need to specify an action
	if self.action then
		local args = { ... }
		local description = ""

		-- Get a list of arguments
		if #args > 0 then
			local newArgs = {}
			for _, arg in ipairs(args) do
				table.insert(newArgs, tostring(arg))
			end
			description = " (" .. table.concat(newArgs, ", ") .. ")"
		end
		Utils.PrintColor(colors.cyan, "Running " .. self.name .. description)

		local oldTime = os.clock()
		local s, err = true, nil
		if context.Traceback then
			xpcall(function() self:_RunAction(context.env, unpack(args)) end, function(msg)
				for i = 5, 15 do
					local _, err = pcall(function() error("", i) end)
					if msg:match("Howlfile") then break end
					msg = msg .. "\n  " .. err
				end

				err = msg
				s = false
			end)
		else
			s, err = pcall(self._RunAction, self, context.env, ...)
		end

		if s then
			Utils.PrintSuccess(self.name .. ": Success")
		else
			Utils.PrintError(self.name .. ": Failure\n" .. err)
		end

		if context.ShowTime then
			Utils.Print(" ", "Took " .. os.clock() - oldTime .. "s")
		end

		return s
	end

	return true
end

--- A Task that can store options
-- @type OptionTask
local OptionTask = {
	__index = function(self, key)
		local parent = Task[key]
		if parent then
			return parent
		end
		if key:match("^%u") then
			local normalFunction = Task[key]
			if normalFunction then
				return normalFunction
			end
			return function(self, value)
				if value == nil then value = true end
				self[(key:gsub("^%u", string.lower))] = value
				return self
			end
		end
	end
}

--- Create a task
-- @tparam string name The name of the task
-- @tparam table dependencies A list of tasks this task requires
-- @tparam function action The action to run
-- @tparam table prototype The base class of the Task
-- @treturn Task The created task
local function Factory(name, dependencies, action, prototype)
	-- Check calling with no dependencies
	if type(dependencies) == "function" then
		action = dependencies
		dependencies = {}
	end

	return setmetatable({
		name = name, -- The name of the function
		action = action, -- The action to call
		dependencies = dependencies or {}, -- Task dependencies
		description = nil, -- Description of the task
		maps = {}, -- Reads and produces list
		requires = {}, -- Files this task requires
		produces = {}, -- Files this task produces
	}, prototype or { __index = Task })
end

--- @export
return {
	Factory = Factory,
	Task = Task,
	OptionTask = OptionTask,
}
end)
local Runner=_W(function(_ENV, ...)
--- Handles tasks and dependencies
-- @module tasks.Runner

--- Handles a collection of tasks and running them
-- @type Runner
local Runner = {}

--- Create a task
-- @tparam string name The name of the task to create
-- @treturn function A builder for tasks
function Runner:Task(name)
	return function(dependencies, action) return self:AddTask(name, dependencies, action) end
end

--- Add a task to the collection
-- @tparam string name The name of the task to add
-- @tparam table dependencies A list of tasks this task requires
-- @tparam function action The action to run
-- @treturn Task The created task
function Runner:AddTask(name, dependencies, action)
	return self:InjectTask(Task.Factory(name, dependencies, action))
end

--- Add a Task object to the collection
-- @tparam Task task The task to insert
-- @tparam string name The name of the task (optional)
-- @treturn Task The current task
function Runner:InjectTask(task, name)
	self.tasks[name or task.name] = task
	return task
end

--- Set the default task
-- @tparam ?|string|function task The task to run or the name of the task
-- @treturn Runner The current object for chaining
function Runner:Default(task)
	local defaultTask
	if task == nil then
		self.default = nil
	elseif type(task) == "string" then
		self.default = self.tasks[task]
		if not self.default then
			error("Cannot find task " .. task)
		end
	else
		self.default = Task.Factory("<default>", {}, task)
	end

	return self
end

--- Run a task, and all its dependencies
-- @tparam string name Name of the task to run
-- @treturn Runner The current object for chaining
function Runner:Run(name)
	return self:RunMany({ name })
end

--- Run a task, and all its dependencies
-- @tparam table names Names of the tasks to run
-- @return The result of the last task
function Runner:RunMany(names)
	local oldTime = os.clock()
	local value

	local context = Context.Factory(self)
	if #names == 0 then
		context:Start()
	else
		for _, name in ipairs(names) do
			value = context:Start(name)
		end
	end

	if context.ShowTime then
		Utils.PrintColor(colors.orange, "Took " .. os.clock() - oldTime .. "s in total")
	end

	return value
end

--- Create a @{Runner} object
-- @tparam env env The current environment
-- @treturn Runner The created runner object
local function Factory(env)
	return setmetatable({
		tasks = {},
		default = nil,
		env = env,
	}, { __index = Runner })
end

--- @export
return {
	Factory = Factory,
	Runner = Runner
}
end)
local HowlFile=_W(function(_ENV, ...)
--- Handles loading and creation of HowlFiles
-- @module HowlFile

--- Names to test when searching for Howlfiles
-- @tfield string names
local names = { "Howlfile", "Howlfile.lua" }

--- Finds the howl file
-- @treturn string The name of the howl file or nil if not found
-- @treturn string The path of the howl file or the error message if not found
local function FindHowl()
	local currentDirectory = Helpers.dir()

	while true do
		for _, file in ipairs(names) do
			local howlFile = fs.combine(currentDirectory, file)
			if fs.exists(howlFile) and not fs.isDir(howlFile) then
				return file, currentDirectory
			end
		end

		if currentDirectory == "/" or currentDirectory == "" then
			break
		end
		currentDirectory = fs.getDir(currentDirectory)
	end


	return nil, "Cannot find HowlFile. Looking for '" .. table.concat(howlFiles, "', '") .. "'"
end

--- Create an environment for running howl files
-- @tparam table variables A list of variables to include in the environment
-- @treturn table The created environment
local function SetupEnvironment(variables)
	local env = setmetatable(variables or {}, { __index = getfenv() })

	env._G = _G
	function env.loadfile(path)
		return setfenv(loadfile(path), env)
	end

	function env.dofile(path)
		return env.loadfile(path)()
	end

	Mediator.Publish({ "HowlFile", "env" }, env)

	return env
end

--- Setup tasks
-- @tparam string currentDirectory Current directory
-- @tparam string howlFile location of Howlfile relative to current directory
-- @tparam Options options Command line options
-- @treturn Runner The task runner
local function SetupTasks(currentDirectory, howlFile, options)
	local tasks = Runner.Factory({
		CurrentDirectory = currentDirectory,
		Options = options,
	})

	Mediator.Subscribe({ "ArgParse", "changed" }, function(options)
		tasks.ShowTime = options:Get "time"
		tasks.Traceback = options:Get "trace"
	end)

	-- Setup an environment
	local environment = SetupEnvironment({
		-- Core globals
		CurrentDirectory = currentDirectory,
		Tasks = tasks,
		Options = options,
		-- Helper functions
		Verbose = Utils.Verbose,
		Log = Utils.VerboseLog,
		File = function(...) return fs.combine(currentDirectory, ...) end,
	})

	-- Load the file
	environment.dofile(fs.combine(currentDirectory, howlFile))

	return tasks
end

--- @export
return {
	FindHowl = FindHowl,
	SetupEnvironment = SetupEnvironment,
	SetupTasks = SetupTasks,
	Names = names,
}
end)
do
--- Basic extensions to classes
-- @module tasks.Extensions

--- Prints all tasks in a TaskRunner
-- Extends the @{Runner.Runner} class
-- @tparam string indent The indent to print at
-- @tparam boolean all Include all tasks (otherwise exclude ones starting with _)
-- @treturn Runner.Runner The current task runner (allows chaining)
function Runner.Runner:ListTasks(indent, all)
	local taskNames = {}
	local maxLength = 0
	for name, task in pairs(self.tasks) do
		local start = name:sub(1, 1)
		if all or (start ~= "_" and start ~= ".") then
			local description = task.description or ""
			local length = #name
			if length > maxLength then
				maxLength = length
			end

			taskNames[name] = description
		end
	end

	maxLength = maxLength + 2
	indent = indent or ""
	for name, description in pairs(taskNames) do
		Utils.WriteColor(colors.white, indent .. name)
		Utils.PrintColor(colors.lightGray, string.rep(" ", maxLength - #name) .. description)
	end

	return self
end

--- A task for cleaning a directory
-- Extends the @{Runner.Runner} class
-- @tparam string name Name of the task
-- @tparam string directory The directory to clean
-- @tparam table taskDepends A list of tasks this task requires
-- @treturn Runner.Runner The task runner (for chaining)
function Runner.Runner:Clean(name, directory, taskDepends)
	return self:AddTask(name, taskDepends, function(task, env)
		Utils.Verbose("Emptying directory '" .. directory .. "'")
		local file = fs.combine(env.CurrentDirectory, directory)
		if fs.isDir(file) then
			for _, sub in pairs(fs.list(file)) do
				fs.delete(fs.combine(file, sub))
			end
		else
			fs.delete(file)
		end
	end):Description("Clean the '" .. directory .. "' directory")
end
end
local Depends=_W(function(_ENV, ...)
--- Specify multiple dependencies
-- @module depends.Depends

--- Stores a file and the dependencies of the file
-- @type File
local File = {}

--- Define the name of this file
-- @tparam string name The name of this file
-- @treturn File The current object (allows chaining)
function File:Name(name)
	self.name = name
	self:Alias(name)
	return self
end

--- Define the alias of this file
-- An alias is used in Howlfiles to refer to the file, but has
-- no effect on the variable name
-- @tparam string name The alias of this file
-- @treturn File The current object (allows chaining)
function File:Alias(name)
	self.alias = name
	return self
end

--- Define what this file depends on
-- @tparam string|table name Name/list of dependencies
-- @treturn File The current object (allows chaining)
function File:Depends(name)
	if type(name) == "table" then
		for _, file in ipairs(name) do
			self:Depends(file)
		end
	else
		table.insert(self.dependencies, name)
	end

	return self
end

--- Define what this file really really needs
-- @tparam string|table name Name/list of dependencies
-- @treturn File The current object (allows chaining)
function File:Prerequisite(name)
	if type(name) == "table" then
		for _, file in ipairs(name) do
			self:Prerequisite(file)
		end
	else
		table.insert(self.dependencies, 1, name)
	end

	return self
end

--- Should this file be set as a global. This has no effect if the module does not have an name
-- @tparam boolean shouldExport Boolean value setting if it should be exported or not
-- @treturn File The current object (allows chaining)
function File:Export(shouldExport)
	if shouldExport == nil then shouldExport = true end
	self.shouldExport = shouldExport
	return self
end

--- Prevent this file be wrapped in a custom environment or a do...end block
-- @tparam boolean noWrap `true` to prevent the module being wrapped
-- @treturn File The current object (allows chaining)
function File:NoWrap(noWrap)
	if noWrap == nil then noWrap = true end
	self.noWrap = noWrap
	return self
end

--- Stores an entire list of dependencies and handles resolving them
-- @type Dependencies
local Dependencies = {}

--- Create a new Dependencies object
-- @tparam string path The base path of the dependencies
-- @tparam Dependencies parent The parent dependencies
-- @treturn Dependencies The new Dependencies object
local function Factory(path, parent)
	return setmetatable({
		mainFiles = {},
		files = {},
		path = path,
		namespaces = {},
		shouldExport = false,
		parent = parent,
	}, { __index = Dependencies })
end

--- Add a file to the dependency list
-- @tparam string path The path of the file relative to the Dependencies' root
-- @treturn File The created file object
function Dependencies:File(path)
	local file = self:_File(path)
	self.files[path] = file
	Mediator.Publish({ "Dependencies", "create" }, self, file)
	return file
end

--- Add a resource to the file list. A resource is saved as a string instead
-- @tparam string path The path of the file relative to the Dependencies' root
-- @treturn File The created file object
function Dependencies:Resource(path)
	local file = self:_File(path)
	file.type = "Resource"
	self.files[path] = file
	Mediator.Publish({ "Dependencies", "create" }, self, file)
	return file
end

--- Create a file
-- @tparam string path The path of the file relative to the Dependencies' root
-- @treturn File The created file object
function Dependencies:_File(path)
	return setmetatable({
		dependencies = {},
		name = nil,
		alias = nil,
		path = path,
		shouldExport = true,
		noWrap = false,
		type = "File",
		parent = self,
	}, { __index = File })
end

--- Add a 'main' file to the dependency list. This is a file that will be executed (added to the end of a script)
-- Nothing should depend on it.
-- @tparam string path The path of the file relative to the Dependencies' root
-- @treturn File The created file object
function Dependencies:Main(path)
	local file = self:FindFile(path) or self:_File(path)
	file.type = "Main"
	table.insert(self.mainFiles, file)
	Mediator.Publish({ "Dependencies", "create" }, self, file)
	return file
end

--- Basic 'hack' to enable you to add a dependency to the build
-- @tparam string|table name Name/list of dependencies
-- @treturn Dependencies The current object (allows chaining)
function Dependencies:Depends(name)
	local main = self.mainFiles[1]
	assert(main, "Cannot find a main file")
	main:Depends(name)
	return self
end

--- Basic 'hack' to enable you to add a very important dependency to the build
-- @tparam string|table name Name/list of dependencies
-- @treturn Dependencies The current object (allows chaining)
function Dependencies:Prerequisite(name)
	local main = self.mainFiles[1]
	assert(main, "Cannot find a main file")
	main:Prerequisite(name)
	return self
end

--- Attempts to find a file based on its name or path
-- @tparam string name Name/Path of the file
-- @treturn ?|file The file or nil on failure
function Dependencies:FindFile(name)
	local files = self.files
	local file = files[name] -- Attempt loading file through path
	if file then return file end

	file = files[name .. ".lua"] -- Common case with name being file minus '.lua'
	if file then return file end

	for _, file in pairs(files) do
		if file.alias == name then
			return file
		end
	end

	return nil
end

--- Iterate through each file, yielding each dependency before the file itself
-- @treturn function A coroutine which is used to loop through items
function Dependencies:Iterate()
	local done = {}

	-- Hacky little function which uses co-routines to loop
	local function internalLoop(fileObject)
		if done[fileObject.path] then return end
		done[fileObject.path] = true

		for _, depName in ipairs(fileObject.dependencies) do
			local dep = self:FindFile(depName)
			if not dep then error("Cannot find file " .. depName) end
			internalLoop(dep)
		end
		coroutine.yield(fileObject)
	end

	-- If we have no dependencies
	local mainFiles = self.mainFiles
	if #mainFiles == 0 then mainFiles = self.files end
	return coroutine.wrap(function()
		for _, file in pairs(mainFiles) do
			internalLoop(file)
		end
	end)
end

--- Return a table of exported values
-- @tparam boolean shouldExport Should globals be exported
-- @treturn Depencencies The current object (allows chaining)
function Dependencies:Export(shouldExport)
	if shouldExport == nil then shouldExport = true end
	self.shouldExport = shouldExport
	return self
end

--- Generate a submodule
-- @tparam string name The name of the namespace
-- @tparam string path The sub path of the namespace
-- @tparam function generator Function used to add dependencies
-- @treturn Dependencies The resulting namespace
function Dependencies:Namespace(name, path, generator)
	local namespace = Factory(fs.combine(self.path, path or ""), self)
	self.namespaces[name] = namespace
	generator(namespace)
	return namespace
end

--- Clone dependencies, whilst ignoring the main file
-- @tparam Dependencies The cloned dependencies object
function Dependencies:CloneDependencies()
	local result = setmetatable({}, { __index = Dependencies })

	for k, v in pairs(self) do
		result[k] = v
	end

	result.mainFiles = {}
	return result
end

function Dependencies:Paths()
	local i, t = table.insert, {}
	for _, file in pairs(self.files) do
		i(t, file.path)
	end
	return t
end

--- Add files to environment
Mediator.Subscribe({ "HowlFile", "env" }, function(env)
	env.Dependencies = function(...) return Factory(env.CurrentDirectory, ...) end
	env.Sources = Factory(env.CurrentDirectory)
end)

--- @export
return {
	File = File,
	Dependencies = Dependencies,
	Factory = Factory,
}
end)
do
--- Creates a bootstrap file, which is used to run dependencies
-- @module depends.Bootstrap

local format = string.format
local tracebackHeader = [[
local args = {...}
xpcall(function()
	(function(...)
]]

local tracebackFooter = [[
	end)(unpack(args))
end, function(err)
	printError(err)
	for i = 3, 15 do
		local s, msg = pcall(error, "", i)
		if msg:match("xpcall") then break end
		printError("  ", msg)
	end
	error(err:match(":.+"):sub(2), 3)
end)
]]

local header = [[
local env = setmetatable({}, {__index = getfenv()})
local function openFile(filePath)
	local f = assert(fs.open(filePath, "r"), "Cannot open " .. filePath)
	local contents = f.readAll()
	f.close()
	return contents
end
local function doWithResult(file)
	local currentEnv = setmetatable({}, {__index = env})
	local result = setfenv(assert(loadfile(file), "Cannot find " .. file), currentEnv)()
	if result ~= nil then return result end
	return currentEnv
end
local function doFile(file, ...)
	return setfenv(assert(loadfile(file), "Cannot find " .. file), env)(...)
end
]]

--- Combines dependencies dynamically into one file
-- These files are loaded using loadfile rather than loaded at compile time
-- @tparam env env The current environment
-- @tparam string outputFile The path of the output file
-- @tparam table options Include code to print the traceback
-- @see Depends.Dependencies
function Depends.Dependencies:CreateBootstrap(env, outputFile, options)
	local path = self.path

	local output = fs.open(fs.combine(env.CurrentDirectory, outputFile), "w")
	assert(output, "Could not create" .. outputFile)

	if options.traceback then
		output.writeLine(tracebackHeader)
	end

	output.writeLine(header)

	for file in self:Iterate() do
		local filePath = format("%q", fs.combine(path, file.path))

		local moduleName = file.name
		if file.type == "Main" then -- If the file is a main file then execute it with the file's arguments
			output.writeLine("doFile(" .. filePath .. ", ...)")
		elseif file.type == "Resource" then -- If the file is a main file then execute it with the file's arguments
			output.writeLine("env[" .. format("%q", moduleName) "] = openFile(" .. filePath .. ")")

		elseif moduleName then -- If the file has an module name then use that
			output.writeLine("env[" .. format("%q", moduleName) .. "] = " .. (file.noWrap and "doFile" or "doWithResult") .. "(" .. filePath .. ")")

		else -- We have no name so we can just execute it normally
			output.writeLine("doFile(" .. filePath .. ")")
		end
	end

	if options.traceback then
		output.writeLine(tracebackFooter)
	end

	output.close()
end

--- A task creating a 'dynamic' combination of files
-- @tparam string name Name of the task
-- @tparam Depends.Dependencies dependencies The dependencies to compile
-- @tparam string outputFile The file to save to
-- @tparam table taskDepends A list of @{tasks.Task.Task|tasks} this task requires
-- @treturn Bootstrap The created task
-- @see tasks.Runner.Runner
function Runner.Runner:CreateBootstrap(name, dependencies, outputFile, taskDepends)
	return self:InjectTask(Task.Factory(name, taskDepends, function(task, env)
		dependencies:CreateBootstrap(env, outputFile, task)
	end, Task.OptionTask))
		:Description("Creates a 'dynamic' combination of files in '" .. outputFile .. "')")
		:Produces(outputFile)
		:Requires(dependencies:Paths())
end
end
do
--- Verify a source file
-- @module depends.modules.Verify

local loadstring = loadstring
-- Verify a source file
Mediator.Subscribe({ "Combiner", "include" }, function(self, file, contents, options)
	if options.verify and file.verify ~= false then
		local success, err = loadstring(contents)
		if not success then
			local name = file.path
			local msg = "Could not load " .. (name and ("file " .. name) or "string")
			if err ~= "nil" then msg = msg .. ":\n" .. err end
			return false, msg
		end
	end
end)

-- We should explicitly prevent a resource being verified
Mediator.Subscribe({ "Dependencies", "create" }, function(depends, file)
	if file.type == "Resource" then
		file:Verify(false)
	end
end)

--- Verify this file on inclusion
function Depends.File:Verify(verify)
	if verify == nil then verify = true end
	self.verify = verify
	return self
end
end
do
--- Handles finalizers and tracebacks
-- @module depends.modules.Traceback

local find = string.find

--- LineMapper template
local lineMapper = {
	header = [[
		-- Maps
		local lineToModule = {{lineToModule}}
		local getLine(line)
			while line >= 0 do
				local l = lineToModule[line]
				if l then return l end
				line = line - 1
			end
			return -1
		})
		local moduleStarts = {{moduleStarts}}
		local programEnd = {{lastLine}}

		-- Stores the current file, safer than shell.getRunningProgram()
		local _, currentFile = pcall(error, "", 2)
		currentFile = currentFile:match("[^:]+")
	]],
	updateError = [[
		-- If we are in the current file then we should map to the old modules
		if filename == currentFile then

			-- If this line is after the program end then
			-- something is broken, and so we just roll with it
			if line > programEnd then return end

			-- convert to module lines
			filename = getLine(line) or "<?>"
			local newLine = moduleStarts[filename]
			if newLine then
				line = line - newLine + 1
			else
				line = -1
			end
		end
	]]
}

--- Finalizer template
local finalizer = {
	header = [[
		local finalizer = function(message, traceback) {{finalizer}} end
	]],
	parseTrace = [[
		local ok, finaliserError = pcall(finalizer, message, traceback)

		if not ok then
			printError("Finalizer Error: ", finaliserError)
		end
	]]
}

--- Traceback template
local traceback = ([[
end
-- The main program executor
	local args = {...}
	local currentTerm = term.current()
	local ok, returns = xpcall(
		function() return {__program(unpack(args))} end,
		function(message)
			local _, err = pcall(function()
			local error, pcall, printError, tostring,setmetatable = error, pcall, printError, tostring, setmetatable
			{{header}}

			local messageMeta = {
				__tostring = function(self)
					local msg = self[1] or "<?>"
					if self[2] then msg = msg .. ":" .. tostring(self[2]) end
					if self[3] and self[3] ~= " " then msg = msg .. ":" .. tostring(self[3]) end
					return msg
				end
			}
			local function updateError(err)
				local filename, line, message = err:match("([^:]+):(%d+):?(.*)")
				-- Something is really broken if we can't find a filename
				-- If we can't find a line number than we must have `pcall:` or `xpcall`
				-- This means, we shouldn't have an error, so we must be debugging somewhere
				if not filename or not line then return end
				line = tonumber(line)
				{{updateError}}
				return setmetatable({filename, line, message}, messageMeta)
			end

			-- Reset terminal
			term.redirect(currentTerm)

			-- Build a traceback
			local topError = updateError(message) or message
			local traceback = {topError}
			for i = 6, 6 + 18 do
				local _, err = pcall(error, "", i)
				err = updateError(err)
				if not err then break end
				traceback[#traceback + 1] = err
			end

			{{parseTrace}}

			printError(tostring(topError))
			if #traceback > 1 then
				printError("Raw Stack Trace:")
				for i = 2, #traceback do
					printError("  ", tostring(traceback[i]))
				end
			end
			end)
			if not _ then printError(err) end
		end
	)

	if ok then
		return unpack(returns)
	end
]])

--- Counts the number of lines in a string
-- @tparam string contents The string to count
-- @treturn int The line count
local function countLines(contents)
	local position, start, newPosition = 1, 1, 1
	local lineCount = 1
	local length = #contents
	while position < length do
		start, newPosition = find(contents, '\n', position, true);
		if not start then break end
		lineCount = lineCount + 1
		position = newPosition + 1
	end
	return lineCount
end

--- Create a template, replacing {{...}} with replacers
-- @tparam string contents The string to count
-- @treturn int The line count
local function replaceTemplate(source, replacers)
	return source:gsub("{{(.-)}}", function(whole)
		return replacers[whole] or ""
	end)
end

Mediator.Subscribe({ "Combiner", "start" }, function(self, outputFile, options)
	if self.finalizer then
		options.traceback = true
	end

	if options.lineMapping then
		options.oldLine = 0
		options.line = 0
		options.lineToModule = {}
		options.moduleStarts = {}
	end

	if options.traceback then
		outputFile.write("local __program = function(...)")
	end
end)

local min = math.min
Mediator.Subscribe({ "Combiner", "write" }, function(self, name, contents, options)
	if options.lineMapping then
		name = name or "file"

		local oldLine = options.line
		options.oldLine = oldLine

		local line = oldLine + countLines(contents)
		options.line = line

		oldLine = oldLine + 1
		line = line - 1

		local moduleStarts, lineToModule = options.moduleStarts, options.lineToModule

		local starts = moduleStarts[name]
		if starts then
			moduleStarts[name] = min(oldLine, starts)
		else
			moduleStarts[name] = oldLine
		end

		lineToModule[min(oldLine, line)] = name
	end
end)

Mediator.Subscribe({ "Combiner", "end" }, function(self, outputFile, options)
	if options.traceback then
		local tracebackIncludes = {}
		local replacers = {}

		-- Handle finalizer
		if self.finalizer then
			local finalizerPath = self.finalizer.path
			local path = fs.combine(self.path, finalizerPath)
			local finalizerFile = assert(fs.open(path, "r"), "Finalizer " .. path .. " does not exist")

			local finalizerContents = finalizerFile.readAll()
			finalizerFile.close()

			if #finalizerContents == 0 then
				finalizerContents = nil
			else
				Mediator.Publish({ "Combiner", "include" }, self, finalizer, finalizerContents, options)
			end

			-- Register template
			if finalizerContents then
				tracebackIncludes[#tracebackIncludes + 1] = finalizer
				replacers.finalizer = finalizerContents
			end
		end

		-- Handle line mapper
		if options.lineMapping then
			tracebackIncludes[#tracebackIncludes + 1] = lineMapper

			local dump = Helpers.serialize
			replacers.lineToModule = dump(options.lineToModule)
			replacers.moduleStarts = dump(options.moduleStarts)
			replacers.lastLine = options.line
		end

		-- And handle replacing
		local toReplace = {}
		for _, template in ipairs(tracebackIncludes) do
			for part, contents in pairs(template) do
				local current = toReplace[part]
				if current then
					current = current .. "\n"
				else
					current = ""
				end
				toReplace[part] = current .. contents
			end
		end

		-- Replace templates and write it
		outputFile.write(replaceTemplate(replaceTemplate(traceback, toReplace), replacers))
	end
end)


--- Add a finalizer
function Depends.Dependencies:Finalizer(path)
	local file = self:FindFile(path) or self:File(path)
	file.type = "Finalizer"
	self.finalizer = file
	Mediator.Publish({ "Dependencies", "create" }, self, file)
	return file
end
end
do
--- Combines multiple files into one file
-- Extends @{depends.Depends.Dependencies} and @{tasks.Runner.Runner} classes
-- @module depends.Combiner

local combinerMediator = Mediator.GetChannel { "Combiner" }

local functionLoaderName = "_W"
--[[
	If the function returns a non nil value then we use that, otherwise we
	export the environment that it ran in (and so get the globals of it)
	This probably need some work as a function but...
]]
local functionLoader = ("local function " .. functionLoaderName .. [[(f)
	local e=setmetatable({}, {__index = _ENV or getfenv()})
	if setfenv then setfenv(f, e) end
	return f(e) or e
end]]):gsub("[\t\n ]+", " ")

--- Combiner options
-- @table CombinerOptions
-- @tfield boolean verify Verify source
-- @tfield boolean lineMapping Map line numbers (Requires traceback)
-- @tfield boolean traceback Print the traceback out

--- Combines Dependencies into one file
-- @tparam env env The current environment
-- @tparam string outputFile The path of the output file
-- @tparam CombinerOptions options Options for combining
-- @see Depends.Dependencies
function Depends.Dependencies:Combiner(env, outputFile, options)
	options = options or {}
	local path = self.path
	local shouldExport = self.shouldExport
	local format = Helpers.serialize

	local output = fs.open(fs.combine(env.CurrentDirectory, outputFile), "w")
	assert(output, "Could not create " .. outputFile)

	local includeChannel = combinerMediator:getChannel("include")

	local outputObj, write
	do -- Create the write object
		local writeLine = output.writeLine
		local writeChannel = combinerMediator:getChannel("write")
		local writePublish = writeChannel.publish

		write = function(contents, file)
			if writePublish(writeChannel, {}, self, file, contents, options) then
				writeLine(contents)
			end
		end

		outputObj = {
			write = write,
			path = outputFile
		}
	end

	combinerMediator:getChannel("start"):publish({}, self, outputObj, options)

	-- If header == nil or header is true then include the header
	if options.header ~= false then write(functionLoader) end

	local exports = {}
	for file in self:Iterate() do
		local filePath = file.path
		local fileHandle = fs.open(fs.combine(path, filePath), "r")
		assert(fileHandle, "File " .. filePath .. " does not exist")

		local contents = fileHandle.readAll()
		fileHandle.close()

		-- Check if it is OK to include this file
		local continue, result = includeChannel:publish({}, self, file, contents, options)
		if not continue then
			output.close()
			error(result[#result] or "Unknown error")
		end

		Utils.Verbose("Adding " .. filePath)

		local moduleName = file.name
		if file.type == "Main" then -- If the file is a main file then just print it
			write(contents, file.alias or file.path)
		elseif file.type == "Resource" then
			local line = assert(moduleName, "A name must be specified for resource " .. file.path) .. "="
			if not file.shouldExport then
				line = "local " .. line
			elseif not shouldExport then
				exports[#exports + 1] = moduleName
				line = "local " .. line
			end
			write(line .. format(contents), file.alias or file.path) -- If the file is a resource then quote it and print it
		elseif moduleName then -- If the file has an module name then use that
			-- Check if we are prevented in setting a custom environment
			local startFunc, endFunc = functionLoaderName .. '(function(_ENV, ...)', 'end)'
			if file.noWrap then
				startFunc, endFunc = '(function(...)', 'end)()'
			end

			local line = moduleName .. '=' .. startFunc
			if not file.shouldExport then -- If this object shouldn't be exported then add local
				line = "local " .. line
			elseif not shouldExport then -- If we shouldn't export globally then add to the export table and mark as global
				exports[#exports + 1] = moduleName
				line = "local " .. line
			end

			write(line)
			write(contents, moduleName)
			write(endFunc)

		else -- We have no name so we can just export it normally
			local wrap = not file.noWrap -- Don't wrap in do...end if noWrap is set

			if wrap then write("do") end
			write(contents, file.alias or file.path)
			if wrap then write('end') end
		end
	end

	-- Should we export any values?
	if #exports > 0 and #self.mainFiles == 0 then
		local exported = {}
		for _, export in ipairs(exports) do
			exported[#exported + 1] = export .. "=" .. export .. ", "
		end
		write("return {" .. table.concat(exported) .. "}")
	end

	combinerMediator:getChannel("end"):publish({}, self, outputObj, options)
	output.close()
end

--- A task for combining stuff
-- @tparam string name Name of the task
-- @tparam depends.Depends.Dependencies dependencies The dependencies to compile
-- @tparam string outputFile The file to save to
-- @tparam table taskDepends A list of @{tasks.Task.Task|tasks} this task requires
-- @treturn CombinerTask The created task
-- @see tasks.Runner.Runner
function Runner.Runner:Combine(name, dependencies, outputFile, taskDepends)
	return self:InjectTask(Task.Factory(name, taskDepends, function(options, env)
		dependencies:Combiner(env, outputFile, options)
	end, Task.OptionTask))
		:Description("Combines files into '" .. outputFile .. "'")
		:Produces(outputFile)
		:Requires(dependencies:Paths())
end
end
local Constants=_W(function(_ENV, ...)
--- Lexer constants
-- @module lexer.Constants

createLookup = Utils.CreateLookup

--- List of white chars
WhiteChars = createLookup { ' ', '\n', '\t', '\r' }

--- Lookup of escape characters
EscapeLookup = { ['\r'] = '\\r', ['\n'] = '\\n', ['\t'] = '\\t', ['"'] = '\\"', ["'"] = "\\'" }

--- Lookup of lower case characters
LowerChars = createLookup {
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
	'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
}

--- Lookup of upper case characters
UpperChars = createLookup {
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
	'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
}

--- Lookup of digits
Digits = createLookup { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' }

--- Lookup of hex digits
HexDigits = createLookup {
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
	'A', 'a', 'B', 'b', 'C', 'c', 'D', 'd', 'E', 'e', 'F', 'f'
}

--- Lookup of valid symbols
Symbols = createLookup { '+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#' }

--- Lookup of valid keywords
Keywords = createLookup {
	'and', 'break', 'do', 'else', 'elseif',
	'end', 'false', 'for', 'function', 'goto', 'if',
	'in', 'local', 'nil', 'not', 'or', 'repeat',
	'return', 'then', 'true', 'until', 'while',
}

--- Keywords that end a block
StatListCloseKeywords = createLookup { 'end', 'else', 'elseif', 'until' }

--- Unary operators
UnOps = createLookup { '-', 'not', '#' }
end)
local Scope=_W(function(_ENV, ...)
--- Holds variables for one scope
-- This implementation is inefficient. Instead of using hashes,
-- a linear search is used instead to look up variables
-- @module lexer.Scope

local keywords = Constants.Keywords

--- Holds the data for one variable
-- @table Variable
-- @tfield Scope Scope The parent scope
-- @tfield string Name The name of the variable
-- @tfield boolean IsGlobal Is the variable global
-- @tfield boolean CanRename If the variable can be renamed
-- @tfield int References Number of references

--- Holds variables for one scope
-- @type Scope
-- @tfield ?|Scope Parent The parent scope
-- @tfield table Locals A list of locals variables
-- @tfield table Globals A list of global variables
-- @tfield table Children A list of children @{Scope|scopes}

local Scope = {}

--- Add a local to this scope
-- @tparam Variable variable The local object
function Scope:AddLocal(variable)
	table.insert(self.Locals, variable)
end

--- Create a @{Variable} and add it to the scope
-- @tparam string name The name of the local
-- @treturn Variable The created local
function Scope:CreateLocal(name)
	local variable = self:GetLocal(name)
	if variable then return variable end

	variable = {
		Scope = self,
		Name = name,
		IsGlobal = false,
		CanRename = true,
		References = 1,
	}

	self:AddLocal(variable)
	return variable
end

--- Get a local variable
-- @tparam string name The name of the local
-- @treturn ?|Variable The variable
function Scope:GetLocal(name)
	for _, var in pairs(self.Locals) do
		if var.Name == name then return var end
	end

	if self.Parent then
		return self.Parent:GetLocal(name)
	end
end

--- Find an local variable by its old name
-- @tparam string name The old name of the local
-- @treturn ?|Variable The local variable
function Scope:GetOldLocal(name)
	if self.oldLocalNamesMap[name] then
		return self.oldLocalNamesMap[name]
	end
	return self:GetLocal(name)
end

--- Rename a local variable
-- @tparam string|Variable oldName The old variable name
-- @tparam string newName The new variable name
function Scope:RenameLocal(oldName, newName)
	oldName = type(oldName) == 'string' and oldName or oldName.Name
	local found = false
	local var = self:GetLocal(oldName)
	if var then
		var.Name = newName
		self.oldLocalNamesMap[oldName] = var
		found = true
	end
	if not found and self.Parent then
		self.Parent:RenameLocal(oldName, newName)
	end
end

--- Add a global to this scope
-- @tparam Variable name The name of the global
function Scope:AddGlobal(name)
	table.insert(self.Globals, name)
end

--- Create a @{Variable} and add it to the scope
-- @tparam string name The name of the global
-- @treturn Variable The created global
function Scope:CreateGlobal(name)
	local variable = self:GetGlobal(name)
	if variable then return variable end

	variable = {
		Scope = self,
		Name = name,
		IsGlobal = true,
		CanRename = true,
		References = 1,
	}

	self:AddGlobal(variable)
	return variable
end

--- Get a global variable
-- @tparam string name The name of the global
-- @treturn ?|Variable The variable
function Scope:GetGlobal(name)
	for _, v in pairs(self.Globals) do
		if v.Name == name then return v end
	end

	if self.Parent then
		return self.Parent:GetGlobal(name)
	end
end

--- Find a Global by its old name
-- @tparam string name The old name of the global
-- @treturn ?|Variable The variable
function Scope:GetOldGlobal(name)
	if self.oldGlobalNamesMap[name] then
		return self.oldGlobalNamesMap[name]
	end
	return self:GetGlobal(name)
end

--- Rename a global variable
-- @tparam string|Variable oldName The old variable name
-- @tparam string newName The new variable name
function Scope:RenameGlobal(oldName, newName)
	oldName = type(oldName) == 'string' and oldName or oldName.Name
	local found = false
	local var = self:GetGlobal(oldName)
	if var then
		var.Name = newName
		self.oldGlobalNamesMap[oldName] = var
		found = true
	end
	if not found and self.Parent then
		self.Parent:RenameGlobal(oldName, newName)
	end
end

--- Get a variable by name
-- @tparam string name The name of the variable
-- @treturn ?|Variable The found variable
-- @fixme This is a very inefficient implementation, as with @{Scope:GetLocal} and @{Scope:GetGlocal}
function Scope:GetVariable(name)
	return self:GetLocal(name) or self:GetGlobal(name)
end

--- Find an variable by its old name
-- @tparam string name The old name of the variable
-- @treturn ?|Variable The variable
function Scope:GetOldVariable(name)
	return self:GetOldLocal(name) or self:GetOldGlobal(name)
end

--- Rename a variable
-- @tparam string|Variable oldName The old variable name
-- @tparam string newName The new variable name
function Scope:RenameVariable(oldName, newName)
	oldName = type(oldName) == 'string' and oldName or oldName.Name
	if self:GetLocal(oldName) then
		self:RenameLocal(oldName, newName)
	else
		self:RenameGlobal(oldName, newName)
	end
end

--- Get all variables in the scope
-- @treturn table A list of @{Variable|variables}
function Scope:GetAllVariables()
	return self:getVars(true, self:getVars(true))
end

--- Get all variables
-- @tparam boolean top If this values is the 'top' of the function stack
-- @tparam table ret Table to fill with return values (optional)
-- @treturn table The variables
-- @local
function Scope:getVars(top, ret)
	local ret = ret or {}
	if top then
		for _, v in pairs(self.Children) do
			v:getVars(true, ret)
		end
	else
		for _, v in pairs(self.Locals) do
			table.insert(ret, v)
		end
		for _, v in pairs(self.Globals) do
			table.insert(ret, v)
		end
		if self.Parent then
			self.Parent:getVars(false, ret)
		end
	end
	return ret
end

--- Rename all locals to smaller values
-- @tparam string validNameChars All characters that can be used to make a variable name
-- @fixme Some of the string generation happens a lot, this could be looked at
function Scope:ObfuscateLocals(validNameChars)
	-- Use values sorted for letter frequency instead
	local startChars = validNameChars or "etaoinshrdlucmfwypvbgkqjxz_ETAOINSHRDLUCMFWYPVBGKQJXZ"
	local otherChars = validNameChars or "etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"

	local startCharsLength, otherCharsLength = #startChars, #otherChars
	local index = 0
	local floor = math.floor
	for _, var in pairs(self.Locals) do
		local name

		repeat
			if index < startCharsLength then
				index = index + 1
				name = startChars:sub(index, index)
			else
				if index < startCharsLength then
					index = index + 1
					name = startChars:sub(index, index)
				else
					local varIndex = floor(index / startCharsLength)
					local offset = index % startCharsLength
					name = startChars:sub(offset, offset)

					while varIndex > 0 do
						offset = varIndex % otherCharsLength
						name = otherChars:sub(offset, offset) .. name
						varIndex = floor(varIndex / otherCharsLength)
					end
					index = index + 1
				end
			end
		until not (keywords[name] or self:GetVariable(name))
		self:RenameLocal(var.Name, name)
	end
end

--- Converts the scope to a string
-- No, it actually just returns '&lt;scope&gt;'
-- @treturn string '&lt;scope&gt;'
function Scope:ToString()
	return '<Scope>'
end

--- Create a new scope
-- @tparam Scope parent The parent scope
-- @treturn Scope The created scope
local function NewScope(parent)
	local scope = setmetatable({
		Parent = parent,
		Locals = {},
		Globals = {},
		oldLocalNamesMap = {},
		oldGlobalNamesMap = {},
		Children = {},
	}, { __index = Scope })

	if parent then
		table.insert(parent.Children, scope)
	end

	return scope
end

return NewScope
end)
local TokenList=_W(function(_ENV, ...)
--- Provides utilities for reading tokens from a 'stream'
-- @module lexer.TokenList

--- Stores a list of tokens
-- @type TokenList
-- @tfield table tokens List of tokens
-- @tfield number pointer Pointer to the current
-- @tfield table savedPointers A save point
local TokenList = {}

--- Get this element in the token list
-- @tparam int offset The offset in the token list
function TokenList:Peek(offset)
	local tokens = self.tokens
	offset = offset or 0
	return tokens[math.min(#tokens, self.pointer + offset)]
end

--- Get the next token in the list
-- @tparam table tokenList Add the token onto this table
-- @treturn Token The token
function TokenList:Get(tokenList)
	local tokens = self.tokens
	local pointer = self.pointer
	local token = tokens[pointer]
	self.pointer = math.min(pointer + 1, #tokens)
	if tokenList then
		table.insert(tokenList, token)
	end
	return token
end

--- Check if the next token is of a type
-- @tparam string type The type to compare it with
-- @treturn bool If the type matches
function TokenList:Is(type)
	return self:Peek().Type == type
end

--- Save position in a stream
function TokenList:Save()
	table.insert(self.savedPointers, self.pointer)
end

--- Remove the last position in the stream
function TokenList:Commit()
	local savedPointers = self.savedPointers
	savedPointers[#savedPointers] = nil
end

--- Restore to the previous save point
function TokenList:Restore()
	local savedPointers = self.savedPointers
	local sPLength = #savedPointers
	self.pointer = savedP[sPLength]
	savedPointers[sPLength] = nil
end

--- Check if the next token is a symbol and return it
-- @tparam string symbol Symbol to check (Optional)
-- @tparam table tokenList Add the token onto this table
-- @treturn [ 0 ] ?|token If symbol is not specified, return the token
-- @treturn [ 1 ] boolean If symbol is specified, return true if it matches
function TokenList:ConsumeSymbol(symbol, tokenList)
	local token = self:Peek()
	if token.Type == 'Symbol' then
		if symbol then
			if token.Data == symbol then
				self:Get(tokenList)
				return true
			else
				return nil
			end
		else
			self:Get(tokenList)
			return token
		end
	else
		return nil
	end
end

--- Check if the next token is a keyword and return it
-- @tparam string kw Keyword to check (Optional)
-- @tparam table tokenList Add the token onto this table
-- @treturn [ 0 ] ?|token If kw is not specified, return the token
-- @treturn [ 1 ] boolean If kw is specified, return true if it matches
function TokenList:ConsumeKeyword(kw, tokenList)
	local token = self:Peek()
	if token.Type == 'Keyword' and token.Data == kw then
		self:Get(tokenList)
		return true
	else
		return nil
	end
end

--- Check if the next token matches is a keyword
-- @tparam string kw The particular keyword
-- @treturn boolean If it matches or not
function TokenList:IsKeyword(kw)
	local token = self:Peek()
	return token.Type == 'Keyword' and token.Data == kw
end

--- Check if the next token matches is a symbol
-- @tparam string symbol The particular symbol
-- @treturn boolean If it matches or not
function TokenList:IsSymbol(symbol)
	local token = self:Peek()
	return token.Type == 'Symbol' and token.Data == symbol
end

--- Check if the next token is an end of file
-- @treturn boolean If the next token is an end of file
function TokenList:IsEof()
	return self:Peek().Type == 'Eof'
end

--- Produce a string off all tokens
-- @tparam boolean includeLeading Include the leading whitespace
-- @treturn string The resulting string
function TokenList:Print(includeLeading)
	includeLeading = (includeLeading == nil and true or includeLeading)

	local out = ""
	for _, token in ipairs(self.tokens) do
		if includeLeading then
			for _, whitespace in ipairs(token.LeadingWhite) do
				out = out .. whitespace:Print() .. "\n"
			end
		end
		out = out .. token:Print() .. "\n"
	end

	return out
end

return TokenList
end)
local Parse=_W(function(_ENV, ...)
--- The main lua parser and lexer.
-- LexLua returns a Lua token stream, with tokens that preserve
-- all whitespace formatting information.
-- ParseLua returns an AST, internally relying on LexLua.
-- @module lexer.Parse

local createLookup = Utils.CreateLookup

local lowerChars = Constants.LowerChars
local upperChars = Constants.UpperChars
local digits = Constants.Digits
local symbols = Constants.Symbols
local hexDigits = Constants.HexDigits
local keywords = Constants.Keywords
local statListCloseKeywords = Constants.StatListCloseKeywords
local unops = Constants.UnOps
local setmeta = setmetatable

--- One token
-- @table Token
-- @tparam string Type The token type
-- @param Data Data about the token
-- @tparam string CommentType The type of comment  (Optional)
-- @tparam number Line Line number (Optional)
-- @tparam number Char Character number (Optional)
local Token = {}

--- Creates a string representation of the token
-- @treturn string The resulting string
function Token:Print()
	return "<"..(self.Type .. string.rep(' ', math.max(3, 12-#self.Type))).."  "..(self.Data or '').." >"
end

local tokenMeta = { __index = Token }

--- Create a list of @{Token|tokens} from a Lua source
-- @tparam string src Lua source code
-- @treturn TokenList The list of @{Token|tokens}
local function LexLua(src)
	--token dump
	local tokens = {}

	do -- Main bulk of the work
		--line / char / pointer tracking
		local pointer = 1
		local line = 1
		local char = 1

		--get / peek functions
		local function get()
			local c = src:sub(pointer,pointer)
			if c == '\n' then
				char = 1
				line = line + 1
			else
				char = char + 1
			end
			pointer = pointer + 1
			return c
		end
		local function peek(n)
			n = n or 0
			return src:sub(pointer+n,pointer+n)
		end
		local function consume(chars)
			local c = peek()
			for i = 1, #chars do
				if c == chars:sub(i,i) then return get() end
			end
		end

		--shared stuff
		local function generateError(err)
			error(">> :"..line..":"..char..": "..err, 0)
		end

		local function tryGetLongString()
			local start = pointer
			if peek() == '[' then
				local equalsCount = 0
				local depth = 1
				while peek(equalsCount+1) == '=' do
					equalsCount = equalsCount + 1
				end
				if peek(equalsCount+1) == '[' then
					--start parsing the string. Strip the starting bit
					for _ = 0, equalsCount+1 do get() end

					--get the contents
					local contentStart = pointer
					while true do
						--check for eof
						if peek() == '' then
							generateError("Expected `]"..string.rep('=', equalsCount).."]` near <eof>.", 3)
						end

						--check for the end
						local foundEnd = true
						if peek() == ']' then
							for i = 1, equalsCount do
								if peek(i) ~= '=' then foundEnd = false end
							end
							if peek(equalsCount+1) ~= ']' then
								foundEnd = false
							end
						else
							if peek() == '[' then
								-- is there an embedded long string?
								local embedded = true
								for i = 1, equalsCount do
									if peek(i) ~= '=' then
										embedded = false
										break
									end
								end
								if peek(equalsCount + 1) == '[' and embedded then
									-- oh look, there was
									depth = depth + 1
									for i = 1, (equalsCount + 2) do
										get()
									end
								end
							end
							foundEnd = false
						end

						if foundEnd then
							depth = depth - 1
							if depth == 0 then
								break
							else
								for i = 1, equalsCount + 2 do
									get()
								end
							end
						else
							get()
						end
					end

					--get the interior string
					local contentString = src:sub(contentStart, pointer-1)

					--found the end. Get rid of the trailing bit
					for i = 0, equalsCount+1 do get() end

					--get the exterior string
					local longString = src:sub(start, pointer-1)

					--return the stuff
					return contentString, longString
				else
					return nil
				end
			else
				return nil
			end
		end

		--main token emitting loop
		while true do
			--get leading whitespace. The leading whitespace will include any comments
			--preceding the token. This prevents the parser needing to deal with comments
			--separately.
			local leading = { }
			local leadingWhite = ''
			local longStr = false
			while true do
				local c = peek()
				if c == '#' and peek(1) == '!' and line == 1 then
					-- #! shebang for linux scripts
					get()
					get()
					leadingWhite = "#!"
					while peek() ~= '\n' and peek() ~= '' do
						leadingWhite = leadingWhite .. get()
					end

					table.insert(leading, setmeta({
						Type = 'Comment',
						CommentType = 'Shebang',
						Data = leadingWhite,
						Line = line,
						Char = char
					}, tokenMeta))
					leadingWhite = ""
				end
				if c == ' ' or c == '\t' then
					--whitespace
					--leadingWhite = leadingWhite..get()
					local c2 = get() -- ignore whitespace
					table.insert(leading, setmeta({
						Type = 'Whitespace',
						Line = line,
						Char = char,
						Data = c2
					}, tokenMeta))
				elseif c == '\n' or c == '\r' then
					local nl = get()
					if leadingWhite ~= "" then
						table.insert(leading, setmeta({
							Type = 'Comment',
							CommentType = longStr and 'LongComment' or 'Comment',
							Data = leadingWhite,
							Line = line,
							Char = char,
						}, tokenMeta))
						leadingWhite = ""
					end
					table.insert(leading, setmeta({
						Type = 'Whitespace',
						Line = line,
						Char = char,
						Data = nl,
					}, tokenMeta))
				elseif c == '-' and peek(1) == '-' then
					--comment
					get()
					get()
					leadingWhite = leadingWhite .. '--'
					local _, wholeText = tryGetLongString()
					if wholeText then
						leadingWhite = leadingWhite..wholeText
						longStr = true
					else
						while peek() ~= '\n' and peek() ~= '' do
							leadingWhite = leadingWhite..get()
						end
					end
				else
					break
				end
			end
			if leadingWhite ~= "" then
				table.insert(leading, setmeta(
				{
					Type = 'Comment',
					CommentType = longStr and 'LongComment' or 'Comment',
					Data = leadingWhite,
					Line = line,
					Char = char,
				}, tokenMeta))
			end

			--get the initial char
			local thisLine = line
			local thisChar = char
			local errorAt = ":"..line..":"..char..":> "
			local c = peek()

			--symbol to emit
			local toEmit = nil

			--branch on type
			if c == '' then
				--eof
				toEmit = { Type = 'Eof' }

			elseif upperChars[c] or lowerChars[c] or c == '_' then
				--ident or keyword
				local start = pointer
				repeat
					get()
					c = peek()
				until not (upperChars[c] or lowerChars[c] or digits[c] or c == '_')
				local dat = src:sub(start, pointer-1)
				if keywords[dat] then
					toEmit = {Type = 'Keyword', Data = dat}
				else
					toEmit = {Type = 'Ident', Data = dat}
				end

			elseif digits[c] or (peek() == '.' and digits[peek(1)]) then
				--number const
				local start = pointer
				if c == '0' and peek(1) == 'x' then
					get();get()
					while hexDigits[peek()] do get() end
					if consume('Pp') then
						consume('+-')
						while digits[peek()] do get() end
					end
				else
					while digits[peek()] do get() end
					if consume('.') then
						while digits[peek()] do get() end
					end
					if consume('Ee') then
						consume('+-')
						while digits[peek()] do get() end
					end
				end
				toEmit = {Type = 'Number', Data = src:sub(start, pointer-1)}

			elseif c == '\'' or c == '\"' then
				local start = pointer
				--string const
				local delim = get()
				local contentStart = pointer
				while true do
					local c = get()
					if c == '\\' then
						get() --get the escape char
					elseif c == delim then
						break
					elseif c == '' then
						generateError("Unfinished string near <eof>")
					end
				end
				local content = src:sub(contentStart, pointer-2)
				local constant = src:sub(start, pointer-1)
				toEmit = {Type = 'String', Data = constant, Constant = content}

			elseif c == '[' then
				local content, wholetext = tryGetLongString()
				if wholetext then
					toEmit = {Type = 'String', Data = wholetext, Constant = content}
				else
					get()
					toEmit = {Type = 'Symbol', Data = '['}
				end

			elseif consume('>=<') then
				if consume('=') then
					toEmit = {Type = 'Symbol', Data = c..'='}
				else
					toEmit = {Type = 'Symbol', Data = c}
				end

			elseif consume('~') then
				if consume('=') then
					toEmit = {Type = 'Symbol', Data = '~='}
				else
					generateError("Unexpected symbol `~` in source.", 2)
				end

			elseif consume('.') then
				if consume('.') then
					if consume('.') then
						toEmit = {Type = 'Symbol', Data = '...'}
					else
						toEmit = {Type = 'Symbol', Data = '..'}
					end
				else
					toEmit = {Type = 'Symbol', Data = '.'}
				end

			elseif consume(':') then
				if consume(':') then
					toEmit = {Type = 'Symbol', Data = '::'}
				else
					toEmit = {Type = 'Symbol', Data = ':'}
				end

			elseif symbols[c] then
				get()
				toEmit = {Type = 'Symbol', Data = c}

			else
				local contents, all = tryGetLongString()
				if contents then
					toEmit = {Type = 'String', Data = all, Constant = contents}
				else
					generateError("Unexpected Symbol `"..c.."` in source.", 2)
				end
			end

			--add the emitted symbol, after adding some common data
			toEmit.LeadingWhite = leading -- table of leading whitespace/comments

			toEmit.Line = thisLine
			toEmit.Char = thisChar
			tokens[#tokens+1] = setmeta(toEmit, tokenMeta)

			--halt after eof has been emitted
			if toEmit.Type == 'Eof' then break end
		end
	end

	--public interface:
	local tokenList = setmetatable({
		tokens = tokens,
		savedPointers = {},
		pointer = 1
	}, {__index = TokenList})

	return tokenList
end

--- Create a AST tree from a Lua Source
-- @tparam TokenList tok List of tokens from @{LexLua}
-- @treturn table The AST tree
local function ParseLua(tok)
	--- Generate an error
	-- @tparam string msg The error message
	-- @raise The produces error message
	local function GenerateError(msg)
		local err = ">> :"..tok:Peek().Line..":"..tok:Peek().Char..": "..msg.."\n"
		--find the line
		local lineNum = 0
		if type(src) == 'string' then
			for line in src:gmatch("[^\n]*\n?") do
				if line:sub(-1,-1) == '\n' then line = line:sub(1,-2) end
				lineNum = lineNum+1
				if lineNum == tok:Peek().Line then
					err = err..">> `"..line:gsub('\t','    ').."`\n"
					for i = 1, tok:Peek().Char do
						local c = line:sub(i,i)
						if c == '\t' then
							err = err..'    '
						else
							err = err..' '
						end
					end
					err = err.."   ^^^^"
					break
				end
			end
		end
		error(err)
	end

	local ParseExpr,
	      ParseStatementList,
	      ParseSimpleExpr,
	      ParsePrimaryExpr,
	      ParseSuffixedExpr

	--- Parse the function definition and its arguments
	-- @tparam Scope.Scope scope The current scope
	-- @tparam table tokenList A table to fill with tokens
	-- @treturn Node A function Node
	local function ParseFunctionArgsAndBody(scope, tokenList)
		local funcScope = Scope(scope)
		if not tok:ConsumeSymbol('(', tokenList) then
			GenerateError("`(` expected.")
		end

		--arg list
		local argList = {}
		local isVarArg = false
		while not tok:ConsumeSymbol(')', tokenList) do
			if tok:Is('Ident') then
				local arg = funcScope:CreateLocal(tok:Get(tokenList).Data)
				argList[#argList+1] = arg
				if not tok:ConsumeSymbol(',', tokenList) then
					if tok:ConsumeSymbol(')', tokenList) then
						break
					else
						GenerateError("`)` expected.")
					end
				end
			elseif tok:ConsumeSymbol('...', tokenList) then
				isVarArg = true
				if not tok:ConsumeSymbol(')', tokenList) then
					GenerateError("`...` must be the last argument of a function.")
				end
				break
			else
				GenerateError("Argument name or `...` expected")
			end
		end

		--body
		local body = ParseStatementList(funcScope)

		--end
		if not tok:ConsumeKeyword('end', tokenList) then
			GenerateError("`end` expected after function body")
		end

		return {
			AstType   = 'Function',
			Scope     = funcScope,
			Arguments = argList,
			Body      = body,
			VarArg    = isVarArg,
			Tokens    = tokenList,
		}
	end

	--- Parse a simple expression
	-- @tparam Scope.Scope scope The current scope
	-- @treturn Node the resulting node
	function ParsePrimaryExpr(scope)
		local tokenList = {}

		if tok:ConsumeSymbol('(', tokenList) then
			local ex = ParseExpr(scope)
			if not tok:ConsumeSymbol(')', tokenList) then
				GenerateError("`)` Expected.")
			end

			return {
				AstType = 'Parentheses',
				Inner   = ex,
				Tokens  = tokenList,
			}

		elseif tok:Is('Ident') then
			local id = tok:Get(tokenList)
			local var = scope:GetLocal(id.Data)
			if not var then
				var = scope:GetGlobal(id.Data)
				if not var then
					var = scope:CreateGlobal(id.Data)
				else
					var.References = var.References + 1
				end
			else
				var.References = var.References + 1
			end

			return {
				AstType  = 'VarExpr',
				Name     = id.Data,
				Variable = var,
				Tokens   = tokenList,
			}
		else
			GenerateError("primary expression expected")
		end
	end

	--- Parse some table related expressions
	-- @tparam Scope.Scope scope The current scope
	-- @tparam boolean onlyDotColon Only allow '.' or ':' nodes
	-- @treturn Node The resulting node
	function ParseSuffixedExpr(scope, onlyDotColon)
		--base primary expression
		local prim = ParsePrimaryExpr(scope)

		while true do
			local tokenList = {}

			if tok:IsSymbol('.') or tok:IsSymbol(':') then
				local symb = tok:Get(tokenList).Data
				if not tok:Is('Ident') then
					GenerateError("<Ident> expected.")
				end
				local id = tok:Get(tokenList)

				prim = {
					AstType  = 'MemberExpr',
					Base     = prim,
					Indexer  = symb,
					Ident    = id,
					Tokens   = tokenList,
				}

			elseif not onlyDotColon and tok:ConsumeSymbol('[', tokenList) then
				local ex = ParseExpr(scope)
				if not tok:ConsumeSymbol(']', tokenList) then
					GenerateError("`]` expected.")
				end

				prim = {
					AstType  = 'IndexExpr',
					Base     = prim,
					Index    = ex,
					Tokens   = tokenList,
				}

			elseif not onlyDotColon and tok:ConsumeSymbol('(', tokenList) then
				local args = {}
				while not tok:ConsumeSymbol(')', tokenList) do
					args[#args+1] = ParseExpr(scope)
					if not tok:ConsumeSymbol(',', tokenList) then
						if tok:ConsumeSymbol(')', tokenList) then
							break
						else
							GenerateError("`)` Expected.")
						end
					end
				end

				prim = {
					AstType   = 'CallExpr',
					Base      = prim,
					Arguments = args,
					Tokens    = tokenList,
				}

			elseif not onlyDotColon and tok:Is('String') then
				--string call
				prim = {
					AstType    = 'StringCallExpr',
					Base       = prim,
					Arguments  = { tok:Get(tokenList) },
					Tokens     = tokenList,
				}

			elseif not onlyDotColon and tok:IsSymbol('{') then
				--table call
				local ex = ParseSimpleExpr(scope)
				-- FIX: ParseExpr(scope) parses the table AND and any following binary expressions.
				-- We just want the table

				prim = {
					AstType   = 'TableCallExpr',
					Base      = prim,
					Arguments = { ex },
					Tokens    = tokenList,
				}

			else
				break
			end
		end
		return prim
	end

	--- Parse a simple expression (strings, numbers, booleans, varargs)
	-- @tparam Scope.Scope scope The current scope
	-- @treturn Node The resulting node
	function ParseSimpleExpr(scope)
		local tokenList = {}

		if tok:Is('Number') then
			return {
				AstType = 'NumberExpr',
				Value   = tok:Get(tokenList),
				Tokens  = tokenList,
			}

		elseif tok:Is('String') then
			return {
				AstType = 'StringExpr',
				Value   = tok:Get(tokenList),
				Tokens  = tokenList,
			}

		elseif tok:ConsumeKeyword('nil', tokenList) then
			return {
				AstType = 'NilExpr',
				Tokens  = tokenList,
			}

		elseif tok:IsKeyword('false') or tok:IsKeyword('true') then
			return {
				AstType = 'BooleanExpr',
				Value   = (tok:Get(tokenList).Data == 'true'),
				Tokens  = tokenList,
			}

		elseif tok:ConsumeSymbol('...', tokenList) then
			return {
				AstType  = 'DotsExpr',
				Tokens   = tokenList,
			}

		elseif tok:ConsumeSymbol('{', tokenList) then
			local entryList = {}
			local v = {
				AstType = 'ConstructorExpr',
				EntryList = entryList,
				Tokens  = tokenList,
			}

			while true do
				if tok:IsSymbol('[', tokenList) then
					--key
					tok:Get(tokenList)
					local key = ParseExpr(scope)
					if not tok:ConsumeSymbol(']', tokenList) then
						GenerateError("`]` Expected")
					end
					if not tok:ConsumeSymbol('=', tokenList) then
						GenerateError("`=` Expected")
					end
					local value = ParseExpr(scope)
					entryList[#entryList+1] = {
						Type  = 'Key',
						Key   = key,
						Value = value,
					}

				elseif tok:Is('Ident') then
					--value or key
					local lookahead = tok:Peek(1)
					if lookahead.Type == 'Symbol' and lookahead.Data == '=' then
						--we are a key
						local key = tok:Get(tokenList)
						if not tok:ConsumeSymbol('=', tokenList) then
							GenerateError("`=` Expected")
						end
						local value = ParseExpr(scope)
						entryList[#entryList+1] = {
							Type  = 'KeyString',
							Key   = key.Data,
							Value = value,
						}

					else
						--we are a value
						local value = ParseExpr(scope)
						entryList[#entryList+1] = {
							Type = 'Value',
							Value = value,
						}

					end
				elseif tok:ConsumeSymbol('}', tokenList) then
					break

				else
					--value
					local value = ParseExpr(scope)
					entryList[#entryList+1] = {
						Type = 'Value',
						Value = value,
					}
				end

				if tok:ConsumeSymbol(';', tokenList) or tok:ConsumeSymbol(',', tokenList) then
					--all is good
				elseif tok:ConsumeSymbol('}', tokenList) then
					break
				else
					GenerateError("`}` or table entry Expected")
				end
			end
			return v

		elseif tok:ConsumeKeyword('function', tokenList) then
			local func = ParseFunctionArgsAndBody(scope, tokenList)

			func.IsLocal = true
			return func

		else
			return ParseSuffixedExpr(scope)
		end
	end

	local unopprio = 8
	local priority = {
		['+'] = {6,6},
		['-'] = {6,6},
		['%'] = {7,7},
		['/'] = {7,7},
		['*'] = {7,7},
		['^'] = {10,9},
		['..'] = {5,4},
		['=='] = {3,3},
		['<'] = {3,3},
		['<='] = {3,3},
		['~='] = {3,3},
		['>'] = {3,3},
		['>='] = {3,3},
		['and'] = {2,2},
		['or'] = {1,1},
	}

	--- Parse an expression
	-- @tparam Skcope.Scope scope The current scope
	-- @tparam int level Current level (Optional)
	-- @treturn Node The resulting node
	function ParseExpr(scope, level)
		level = level or 0
		--base item, possibly with unop prefix
		local exp
		if unops[tok:Peek().Data] then
			local tokenList = {}
			local op = tok:Get(tokenList).Data
			exp = ParseExpr(scope, unopprio)

			local nodeEx = {
				AstType = 'UnopExpr',
				Rhs     = exp,
				Op      = op,
				OperatorPrecedence = unopprio,
				Tokens  = tokenList,
			}

			exp = nodeEx
		else
			exp = ParseSimpleExpr(scope)
		end

		--next items in chain
		while true do
			local prio = priority[tok:Peek().Data]
			if prio and prio[1] > level then
				local tokenList = {}
				local op = tok:Get(tokenList).Data
				local rhs = ParseExpr(scope, prio[2])

				local nodeEx = {
					AstType = 'BinopExpr',
					Lhs     = exp,
					Op      = op,
					OperatorPrecedence = prio[1],
					Rhs     = rhs,
					Tokens  = tokenList,
				}

				exp = nodeEx
			else
				break
			end
		end

		return exp
	end

	--- Parse a statement (if, for, while, etc...)
	-- @tparam Scope.Scope scope The current scope
	-- @treturn Node The resulting node
	local function ParseStatement(scope)
		local stat = nil
		local tokenList = {}
		if tok:ConsumeKeyword('if', tokenList) then
			--setup
			local clauses = {}
			local nodeIfStat = {
				AstType = 'IfStatement',
				Clauses = clauses,
			}
			--clauses
			repeat
				local nodeCond = ParseExpr(scope)

				if not tok:ConsumeKeyword('then', tokenList) then
					GenerateError("`then` expected.")
				end
				local nodeBody = ParseStatementList(scope)
				clauses[#clauses+1] = {
					Condition = nodeCond,
					Body = nodeBody,
				}
			until not tok:ConsumeKeyword('elseif', tokenList)

			--else clause
			if tok:ConsumeKeyword('else', tokenList) then
				local nodeBody = ParseStatementList(scope)
				clauses[#clauses+1] = {
					Body = nodeBody,
				}
			end

			--end
			if not tok:ConsumeKeyword('end', tokenList) then
				GenerateError("`end` expected.")
			end

			nodeIfStat.Tokens = tokenList
			stat = nodeIfStat
		elseif tok:ConsumeKeyword('while', tokenList) then
			--condition
			local nodeCond = ParseExpr(scope)

			--do
			if not tok:ConsumeKeyword('do', tokenList) then
				return GenerateError("`do` expected.")
			end

			--body
			local nodeBody = ParseStatementList(scope)

			--end
			if not tok:ConsumeKeyword('end', tokenList) then
				GenerateError("`end` expected.")
			end

			--return
			stat = {
				AstType = 'WhileStatement',
				Condition = nodeCond,
				Body      = nodeBody,
				Tokens    = tokenList,
			}
		elseif tok:ConsumeKeyword('do', tokenList) then
			--do block
			local nodeBlock = ParseStatementList(scope)
			if not tok:ConsumeKeyword('end', tokenList) then
				GenerateError("`end` expected.")
			end

			stat = {
				AstType = 'DoStatement',
				Body    = nodeBlock,
				Tokens  = tokenList,
			}
		elseif tok:ConsumeKeyword('for', tokenList) then
			--for block
			if not tok:Is('Ident') then
				GenerateError("<ident> expected.")
			end
			local baseVarName = tok:Get(tokenList)
			if tok:ConsumeSymbol('=', tokenList) then
				--numeric for
				local forScope = Scope(scope)
				local forVar = forScope:CreateLocal(baseVarName.Data)

				local startEx = ParseExpr(scope)
				if not tok:ConsumeSymbol(',', tokenList) then
					GenerateError("`,` Expected")
				end
				local endEx = ParseExpr(scope)
				local stepEx
				if tok:ConsumeSymbol(',', tokenList) then
					stepEx = ParseExpr(scope)
				end
				if not tok:ConsumeKeyword('do', tokenList) then
					GenerateError("`do` expected")
				end

				local body = ParseStatementList(forScope)
				if not tok:ConsumeKeyword('end', tokenList) then
					GenerateError("`end` expected")
				end

				stat = {
					AstType  = 'NumericForStatement',
					Scope    = forScope,
					Variable = forVar,
					Start    = startEx,
					End      = endEx,
					Step     = stepEx,
					Body     = body,
					Tokens   = tokenList,
				}
			else
				--generic for
				local forScope = Scope(scope)

				local varList = { forScope:CreateLocal(baseVarName.Data) }
				while tok:ConsumeSymbol(',', tokenList) do
					if not tok:Is('Ident') then
						GenerateError("for variable expected.")
					end
					varList[#varList+1] = forScope:CreateLocal(tok:Get(tokenList).Data)
				end
				if not tok:ConsumeKeyword('in', tokenList) then
					GenerateError("`in` expected.")
				end
				local generators = {ParseExpr(scope)}
				while tok:ConsumeSymbol(',', tokenList) do
					generators[#generators+1] = ParseExpr(scope)
				end

				if not tok:ConsumeKeyword('do', tokenList) then
					GenerateError("`do` expected.")
				end

				local body = ParseStatementList(forScope)
				if not tok:ConsumeKeyword('end', tokenList) then
					GenerateError("`end` expected.")
				end

				stat = {
					AstType      = 'GenericForStatement',
					Scope        = forScope,
					VariableList = varList,
					Generators   = generators,
					Body         = body,
					Tokens       = tokenList,
				}
			end
		elseif tok:ConsumeKeyword('repeat', tokenList) then
			local body = ParseStatementList(scope)

			if not tok:ConsumeKeyword('until', tokenList) then
				GenerateError("`until` expected.")
			end

			local cond = ParseExpr(body.Scope)

			stat = {
				AstType   = 'RepeatStatement',
				Condition = cond,
				Body      = body,
				Tokens    = tokenList,
			}
		elseif tok:ConsumeKeyword('function', tokenList) then
			if not tok:Is('Ident') then
				GenerateError("Function name expected")
			end
			local name = ParseSuffixedExpr(scope, true) --true => only dots and colons

			local func = ParseFunctionArgsAndBody(scope, tokenList)

			func.IsLocal = false
			func.Name    = name
			stat = func
		elseif tok:ConsumeKeyword('local', tokenList) then
			if tok:Is('Ident') then
				local varList = { tok:Get(tokenList).Data }
				while tok:ConsumeSymbol(',', tokenList) do
					if not tok:Is('Ident') then
						GenerateError("local var name expected")
					end
					varList[#varList+1] = tok:Get(tokenList).Data
				end

				local initList = {}
				if tok:ConsumeSymbol('=', tokenList) then
					repeat
						initList[#initList+1] = ParseExpr(scope)
					until not tok:ConsumeSymbol(',', tokenList)
				end

				--now patch var list
				--we can't do this before getting the init list, because the init list does not
				--have the locals themselves in scope.
				for i, v in pairs(varList) do
					varList[i] = scope:CreateLocal(v)
				end

				stat = {
					AstType   = 'LocalStatement',
					LocalList = varList,
					InitList  = initList,
					Tokens    = tokenList,
				}

			elseif tok:ConsumeKeyword('function', tokenList) then
				if not tok:Is('Ident') then
					GenerateError("Function name expected")
				end
				local name = tok:Get(tokenList).Data
				local localVar = scope:CreateLocal(name)

				local func = ParseFunctionArgsAndBody(scope, tokenList)

				func.Name    = localVar
				func.IsLocal = true
				stat = func

			else
				GenerateError("local var or function def expected")
			end
		elseif tok:ConsumeSymbol('::', tokenList) then
			if not tok:Is('Ident') then
				GenerateError('Label name expected')
			end
			local label = tok:Get(tokenList).Data
			if not tok:ConsumeSymbol('::', tokenList) then
				GenerateError("`::` expected")
			end
			stat = {
				AstType = 'LabelStatement',
				Label   = label,
				Tokens  = tokenList,
			}
		elseif tok:ConsumeKeyword('return', tokenList) then
			local exList = {}
			if not tok:IsKeyword('end') then
				-- Use PCall as this may produce an error
				local st, firstEx = pcall(function() return ParseExpr(scope) end)
				if st then
					exList[1] = firstEx
					while tok:ConsumeSymbol(',', tokenList) do
						exList[#exList+1] = ParseExpr(scope)
					end
				end
			end
			stat = {
				AstType   = 'ReturnStatement',
				Arguments = exList,
				Tokens    = tokenList,
			}
		elseif tok:ConsumeKeyword('break', tokenList) then
			stat = {
				AstType = 'BreakStatement',
				Tokens  = tokenList,
			}
		elseif tok:ConsumeKeyword('goto', tokenList) then
			if not tok:Is('Ident') then
				GenerateError("Label expected")
			end
			local label = tok:Get(tokenList).Data
			stat = {
				AstType = 'GotoStatement',
				Label   = label,
				Tokens  = tokenList,
			}
		else
			--statementParseExpr
			local suffixed = ParseSuffixedExpr(scope)

			--assignment or call?
			if tok:IsSymbol(',') or tok:IsSymbol('=') then
				--check that it was not parenthesized, making it not an lvalue
				if (suffixed.ParenCount or 0) > 0 then
					GenerateError("Can not assign to parenthesized expression, is not an lvalue")
				end

				--more processing needed
				local lhs = { suffixed }
				while tok:ConsumeSymbol(',', tokenList) do
					lhs[#lhs+1] = ParseSuffixedExpr(scope)
				end

				--equals
				if not tok:ConsumeSymbol('=', tokenList) then
					GenerateError("`=` Expected.")
				end

				--rhs
				local rhs = {ParseExpr(scope)}
				while tok:ConsumeSymbol(',', tokenList) do
					rhs[#rhs+1] = ParseExpr(scope)
				end

				--done
				stat = {
					AstType = 'AssignmentStatement',
					Lhs     = lhs,
					Rhs     = rhs,
					Tokens  = tokenList,
				}

			elseif suffixed.AstType == 'CallExpr' or
				   suffixed.AstType == 'TableCallExpr' or
				   suffixed.AstType == 'StringCallExpr'
			then
				--it's a call statement
				stat = {
					AstType    = 'CallStatement',
					Expression = suffixed,
					Tokens     = tokenList,
				}
			else
				GenerateError("Assignment Statement Expected")
			end
		end

		if tok:IsSymbol(';') then
			stat.Semicolon = tok:Get( stat.Tokens )
		end
		return stat
	end

	--- Parse a a list of statements
	-- @tparam Scope.Scope scope The current scope
	-- @treturn Node The resulting node
	function ParseStatementList(scope)
		local body = {}
		local nodeStatlist   = {
			Scope   = Scope(scope),
			AstType = 'Statlist',
			Body    = body,
			Tokens  = {},
		}

		while not statListCloseKeywords[tok:Peek().Data] and not tok:IsEof() do
			local nodeStatement = ParseStatement(nodeStatlist.Scope)
			--stats[#stats+1] = nodeStatement
			body[#body + 1] = nodeStatement
		end

		if tok:IsEof() then
			local nodeEof = {}
			nodeEof.AstType = 'Eof'
			nodeEof.Tokens  = { tok:Get() }
			body[#body + 1] = nodeEof
		end

		--nodeStatlist.Body = stats
		return nodeStatlist
	end

	return ParseStatementList(Scope())
end

--- @export
return { LexLua = LexLua, ParseLua = ParseLua }
end)
local Rebuild=_W(function(_ENV, ...)
--- Rebuild source code from an AST
-- Does not preserve whitespace
-- @module lexer.Rebuild

local lowerChars = Constants.LowerChars
local upperChars = Constants.UpperChars
local digits = Constants.Digits
local symbols = Constants.Symbols

--- Join two statements together
-- @tparam string left The left statement
-- @tparam string right The right statement
-- @tparam string sep The string used to separate the characters
-- @treturn string The joined strings
local function JoinStatements(left, right, sep)
	sep = sep or ' '
	local leftEnd, rightStart = left:sub(-1, -1), right:sub(1, 1)
	if upperChars[leftEnd] or lowerChars[leftEnd] or leftEnd == '_' then
		if not (rightStart == '_' or upperChars[rightStart] or lowerChars[rightStart] or digits[rightStart]) then
			--rightStart is left symbol, can join without seperation
			return left .. right
		else
			return left .. sep .. right
		end
	elseif digits[leftEnd] then
		if rightStart == '(' then
			--can join statements directly
			return left .. right
		elseif symbols[rightStart] then
			return left .. right
		else
			return left .. sep .. right
		end
	elseif leftEnd == '' then
		return left .. right
	else
		if rightStart == '(' then
			--don't want to accidentally call last statement, can't join directly
			return left .. sep .. right
		else
			return left .. right
		end
	end
end

--- Returns the minified version of an AST. Operations which are performed:
--  - All comments and whitespace are ignored
--  - All local variables are renamed
-- @tparam Node ast The AST tree
-- @treturn string The minified string
-- @todo Ability to control minification level
local function Minify(ast)
	local formatStatlist, formatExpr
	local count = 0
	local function joinStatements(left, right, sep)
		if count > 150 then
			count = 0
			return left .. "\n" .. right
		else
			return JoinStatements(left, right, sep)
		end
	end

	formatExpr = function(expr, precedence)
		local precedence = precedence or 0
		local currentPrecedence = 0
		local skipParens = false
		local out = ""
		if expr.AstType == 'VarExpr' then
			if expr.Variable then
				out = out .. expr.Variable.Name
			else
				out = out .. expr.Name
			end

		elseif expr.AstType == 'NumberExpr' then
			out = out .. expr.Value.Data

		elseif expr.AstType == 'StringExpr' then
			out = out .. expr.Value.Data

		elseif expr.AstType == 'BooleanExpr' then
			out = out .. tostring(expr.Value)

		elseif expr.AstType == 'NilExpr' then
			out = joinStatements(out, "nil")

		elseif expr.AstType == 'BinopExpr' then
			currentPrecedence = expr.OperatorPrecedence
			out = joinStatements(out, formatExpr(expr.Lhs, currentPrecedence))
			out = joinStatements(out, expr.Op)
			out = joinStatements(out, formatExpr(expr.Rhs))
			if expr.Op == '^' or expr.Op == '..' then
				currentPrecedence = currentPrecedence - 1
			end

			if currentPrecedence < precedence then
				skipParens = false
			else
				skipParens = true
			end
		elseif expr.AstType == 'UnopExpr' then
			out = joinStatements(out, expr.Op)
			out = joinStatements(out, formatExpr(expr.Rhs))

		elseif expr.AstType == 'DotsExpr' then
			out = out .. "..."

		elseif expr.AstType == 'CallExpr' then
			out = out .. formatExpr(expr.Base)
			out = out .. "("
			for i = 1, #expr.Arguments do
				out = out .. formatExpr(expr.Arguments[i])
				if i ~= #expr.Arguments then
					out = out .. ","
				end
			end
			out = out .. ")"

		elseif expr.AstType == 'TableCallExpr' then
			out = out .. formatExpr(expr.Base)
			out = out .. formatExpr(expr.Arguments[1])

		elseif expr.AstType == 'StringCallExpr' then
			out = out .. formatExpr(expr.Base)
			out = out .. expr.Arguments[1].Data

		elseif expr.AstType == 'IndexExpr' then
			out = out .. formatExpr(expr.Base) .. "[" .. formatExpr(expr.Index) .. "]"

		elseif expr.AstType == 'MemberExpr' then
			out = out .. formatExpr(expr.Base) .. expr.Indexer .. expr.Ident.Data

		elseif expr.AstType == 'Function' then
			expr.Scope:ObfuscateLocals()
			out = out .. "function("
			if #expr.Arguments > 0 then
				for i = 1, #expr.Arguments do
					out = out .. expr.Arguments[i].Name
					if i ~= #expr.Arguments then
						out = out .. ","
					elseif expr.VarArg then
						out = out .. ",..."
					end
				end
			elseif expr.VarArg then
				out = out .. "..."
			end
			out = out .. ")"
			out = joinStatements(out, formatStatlist(expr.Body))
			out = joinStatements(out, "end")

		elseif expr.AstType == 'ConstructorExpr' then
			out = out .. "{"
			for i = 1, #expr.EntryList do
				local entry = expr.EntryList[i]
				if entry.Type == 'Key' then
					out = out .. "[" .. formatExpr(entry.Key) .. "]=" .. formatExpr(entry.Value)
				elseif entry.Type == 'Value' then
					out = out .. formatExpr(entry.Value)
				elseif entry.Type == 'KeyString' then
					out = out .. entry.Key .. "=" .. formatExpr(entry.Value)
				end
				if i ~= #expr.EntryList then
					out = out .. ","
				end
			end
			out = out .. "}"

		elseif expr.AstType == 'Parentheses' then
			out = out .. "(" .. formatExpr(expr.Inner) .. ")"
		end
		if not skipParens then
			out = string.rep('(', expr.ParenCount or 0) .. out
			out = out .. string.rep(')', expr.ParenCount or 0)
		end
		count = count + #out
		return out
	end

	local formatStatement = function(statement)
		local out = ''
		if statement.AstType == 'AssignmentStatement' then
			for i = 1, #statement.Lhs do
				out = out .. formatExpr(statement.Lhs[i])
				if i ~= #statement.Lhs then
					out = out .. ","
				end
			end
			if #statement.Rhs > 0 then
				out = out .. "="
				for i = 1, #statement.Rhs do
					out = out .. formatExpr(statement.Rhs[i])
					if i ~= #statement.Rhs then
						out = out .. ","
					end
				end
			end

		elseif statement.AstType == 'CallStatement' then
			out = formatExpr(statement.Expression)

		elseif statement.AstType == 'LocalStatement' then
			out = out .. "local "
			for i = 1, #statement.LocalList do
				out = out .. statement.LocalList[i].Name
				if i ~= #statement.LocalList then
					out = out .. ","
				end
			end
			if #statement.InitList > 0 then
				out = out .. "="
				for i = 1, #statement.InitList do
					out = out .. formatExpr(statement.InitList[i])
					if i ~= #statement.InitList then
						out = out .. ","
					end
				end
			end

		elseif statement.AstType == 'IfStatement' then
			out = joinStatements("if", formatExpr(statement.Clauses[1].Condition))
			out = joinStatements(out, "then")
			out = joinStatements(out, formatStatlist(statement.Clauses[1].Body))
			for i = 2, #statement.Clauses do
				local st = statement.Clauses[i]
				if st.Condition then
					out = joinStatements(out, "elseif")
					out = joinStatements(out, formatExpr(st.Condition))
					out = joinStatements(out, "then")
				else
					out = joinStatements(out, "else")
				end
				out = joinStatements(out, formatStatlist(st.Body))
			end
			out = joinStatements(out, "end")

		elseif statement.AstType == 'WhileStatement' then
			out = joinStatements("while", formatExpr(statement.Condition))
			out = joinStatements(out, "do")
			out = joinStatements(out, formatStatlist(statement.Body))
			out = joinStatements(out, "end")

		elseif statement.AstType == 'DoStatement' then
			out = joinStatements(out, "do")
			out = joinStatements(out, formatStatlist(statement.Body))
			out = joinStatements(out, "end")

		elseif statement.AstType == 'ReturnStatement' then
			out = "return"
			for i = 1, #statement.Arguments do
				out = joinStatements(out, formatExpr(statement.Arguments[i]))
				if i ~= #statement.Arguments then
					out = out .. ","
				end
			end

		elseif statement.AstType == 'BreakStatement' then
			out = "break"

		elseif statement.AstType == 'RepeatStatement' then
			out = "repeat"
			out = joinStatements(out, formatStatlist(statement.Body))
			out = joinStatements(out, "until")
			out = joinStatements(out, formatExpr(statement.Condition))

		elseif statement.AstType == 'Function' then
			statement.Scope:ObfuscateLocals()
			if statement.IsLocal then
				out = "local"
			end
			out = joinStatements(out, "function ")
			if statement.IsLocal then
				out = out .. statement.Name.Name
			else
				out = out .. formatExpr(statement.Name)
			end
			out = out .. "("
			if #statement.Arguments > 0 then
				for i = 1, #statement.Arguments do
					out = out .. statement.Arguments[i].Name
					if i ~= #statement.Arguments then
						out = out .. ","
					elseif statement.VarArg then
						out = out .. ",..."
					end
				end
			elseif statement.VarArg then
				out = out .. "..."
			end
			out = out .. ")"
			out = joinStatements(out, formatStatlist(statement.Body))
			out = joinStatements(out, "end")

		elseif statement.AstType == 'GenericForStatement' then
			statement.Scope:ObfuscateLocals()
			out = "for "
			for i = 1, #statement.VariableList do
				out = out .. statement.VariableList[i].Name
				if i ~= #statement.VariableList then
					out = out .. ","
				end
			end
			out = out .. " in"
			for i = 1, #statement.Generators do
				out = joinStatements(out, formatExpr(statement.Generators[i]))
				if i ~= #statement.Generators then
					out = joinStatements(out, ',')
				end
			end
			out = joinStatements(out, "do")
			out = joinStatements(out, formatStatlist(statement.Body))
			out = joinStatements(out, "end")

		elseif statement.AstType == 'NumericForStatement' then
			statement.Scope:ObfuscateLocals()
			out = "for "
			out = out .. statement.Variable.Name .. "="
			out = out .. formatExpr(statement.Start) .. "," .. formatExpr(statement.End)
			if statement.Step then
				out = out .. "," .. formatExpr(statement.Step)
			end
			out = joinStatements(out, "do")
			out = joinStatements(out, formatStatlist(statement.Body))
			out = joinStatements(out, "end")
		elseif statement.AstType == 'LabelStatement' then
			out = "::" .. statement.Label .. "::"
		elseif statement.AstType == 'GotoStatement' then
			out = "goto " .. statement.Label
		elseif statement.AstType == 'Comment' then
			-- ignore
		elseif statement.AstType == 'Eof' then
			-- ignore
		else
			error("Unknown AST Type: " .. statement.AstType)
		end
		count = count + #out
		return out
	end

	formatStatlist = function(statList)
		local out = ''
		statList.Scope:ObfuscateLocals()
		for _, stat in pairs(statList.Body) do
			out = joinStatements(out, formatStatement(stat), ';')
		end
		return out
	end

	return formatStatlist(ast)
end

--- Minify a string
-- @tparam string input The input string
-- @treturn string The minifyied string
local function MinifyString(input)
	local lex = Parse.LexLua(input)
	Helpers.refreshYield()

	lex = Parse.ParseLua(lex)
	Helpers.refreshYield()

	return Minify(lex)
end

--- Minify a file
-- @tparam string cd Current directory
-- @tparam string inputFile File to read from
-- @tparam string outputFile File to write to (Defaults to inputFile)
local function MinifyFile(cd, inputFile, outputFile)
	outputFile = outputFile or inputFile

	local input = fs.open(fs.combine(cd, inputFile), "r")
	local contents = input.readAll()
	input.close()

	contents = MinifyString(contents)

	local result = fs.open(fs.combine(cd, outputFile), "w")
	result.write(contents)
	result.close()
end

--- @export
return {
	JoinStatements = JoinStatements,
	Minify = Minify,
	MinifyString = MinifyString,
	MinifyFile = MinifyFile,
}
end)
do
--- Tasks for the lexer
-- @module lexer.Tasks
local minifyFile = Rebuild.MinifyFile
local minifyDiscard = function(self, env, i, o)
	return minifyFile(env.CurrentDirectory, i, o)
end

--- A task that minifies a source file
-- @tparam string name Name of the task
-- @tparam string inputFile The input file
-- @tparam string outputFile The file to save to
-- @tparam table taskDepends A list of @{tasks.Task.Task|tasks} this task requires
-- @treturn Runner.Runner The task runner (for chaining)
-- @see tasks.Runner.Runner
function Runner.Runner:Minify(name, inputFile, outputFile, taskDepends)
	return self:AddTask(name, taskDepends, function(task, env)
		if type(inputFile) == "table" then
			assert(type(outputFile) == "table", "Output File must be a table too")

			local lenIn = #inputFile
			assert(lenIn == #outputFile, "Tables must be the same length")

			for i = 1, lenIn do
				minifyFile(env.CurrentDirectory, inputFile[i], outputFile[i])
			end
		else
			minifyFile(env.CurrentDirectory, inputFile, outputFile)
		end
	end)
		:Description("Minifies '" .. fs.getName(inputFile) .. "' into '" .. fs.getName(outputFile) .. "'")
		:Requires(inputFile)
		:Produces(outputFile)
end

--- A task that minifies to a pattern instead
-- @tparam string name Name of the task
-- @tparam string inputPattern The pattern to read in
-- @tparam string outputPattern The pattern to produce
-- @treturn tasks.Runner.Runner The task runner (for chaining)
function Runner.Runner:MinifyAll(name, inputPattern, outputPattern)
	name = name or "_minify"
	return self:AddTask(name, {}, minifyDiscard)
		:Description("Minifies files")
		:Maps(inputPattern or "wild:*.lua", outputPattern or "wild:*.min.lua")
end

Mediator.Subscribe({ "HowlFile", "env" }, function(env)
	env.Minify = minifyFile
end)
end
do
--- Tasks for the lexer
-- @module external.Busted

local combine, exists, isDir, loadfile, verbose = fs.combine, fs.exists, fs.isDir, loadfile, Utils.Verbose
local busted = busted

local names = { "busted.api.lua", "../lib/busted.api.lua", "busted.api", "../lib/busted.api", "busted", "../lib/busted" }

local function loadOneBusted(path)
	verbose("Busted at " .. path)
	local file = loadfile(path)
	if file then
		verbose("Busted loading at " .. path)
		local bst = setfenv(file, getfenv())()
		bst = bst.api or bst
		if bst.run then
			verbose("Busted found at " .. path)
			return bst
		end
	end
end

local function findOneBusted(folder)
	if not exists(folder) then return end
	if not isDir(folder) then
		return loadOneBusted(folder)
	end

	local path
	for _, name in ipairs(names) do
		path = combine(folder, name)
		if exists(path) then
			local bst = loadOneBusted(path)
			if bst then return bst end
		end
	end
end

local function findBusted()
	-- If busted exists already then don't worry
	if busted then return busted end

	-- Try to find a busted file in the root directory
	local bst = findOneBusted("/")
	if bst then
		busted = bst
		return busted
	end

	-- Try to find it on the shell path
	for path in string.gmatch(shell.path(), "[^:]+") do
		local bst = findOneBusted(path)
		if bst then
			busted = bst
			return busted
		end
	end
end

local function getDefaults(cwd)
	return {
		cwd = cwd,
		output = 'colorTerminal',
		seed = os.time(),
		verbose = Utils.IsVerbose(),
		root = 'spec',
		tags = {},
		['exclude-tags'] = {},
		pattern = '_spec',
		loaders = { 'lua' },
		helper = '',
	}
end

--- A task that minifies a source file
-- @tparam string name Name of the task
-- @tparam string inputFile The input file
-- @tparam string outputFile The file to save to
-- @tparam table taskDepends A list of @{tasks.Task.Task|tasks} this task requires
-- @treturn Runner.Runner The task runner (for chaining)
-- @see tasks.Runner.Runner
function Runner.Runner:Busted(name, options, taskDepends)
	return self:AddTask(name, taskDepends, function(task, env)
		local busted
		if options and options.busted then
			busted = findOneBusted(options.busted)
		else
			busted = findBusted()
		end
		if not busted then error("Cannot find busted") end

		local newOptions = getDefaults(env.CurrentDirectory)
		for k, v in pairs(options or {}) do
			newOptions[k] = v
		end

		local count, errors = busted.run(newOptions, getDefaults(env.CurrentDirectory))
		if count ~= 0 then
			Utils.VerboseLog(errors)
			error("Not all tests passed")
		end
	end)
		:Description("Runs tests")
end
end
local Files=_W(function(_ENV, ...)
--- Handles a list of files
-- @module files.Files

--- Handles a list of files
-- @type Files
local Files = {}

--- Include a series of files/folders
-- @tparam string match The match to include
-- @treturn Files The current object (allows chaining)
function Files:Add(match)
	if type(match) == "table" then
		for _, v in ipairs(match) do
			self:Add(v)
		end
	else
		table.insert(self.include, self:_Parse(match))
		self.files = nil
	end
	return self
end

--- Exclude a file
-- @tparam string match The file/wildcard to exclude
-- @treturn Files The current object (allows chaining)
function Files:Remove(match)
	if type(match) == "table" then
		for _, v in ipairs(match) do
			self:Remove(v)
		end
	else
		table.insert(self.exclude, self:_Parse(match))
		self.files = nil
	end

	return self
end

Files.Include = Files.Add
Files.Exclude = Files.Remove

--- Path to the startup file
-- @tparam string file The file to startup with
-- @treturn Files The current object (allows chaining)
function Files:Startup(file)
	self.startup = file
	return self
end

--- Find all files
-- @treturn table List of files, the keys are their names
function Files:Files()
	if not self.files then
		self.files = {}

		for _, match in ipairs(self.include) do
			if match.Type == "Normal" then
				self:_Include(match.Text)
			else
				self:_Include("", match)
			end
		end
	end

	return self.files
end

--- Handles the grunt work. Includes recursivly
-- @tparam string path The path to include
-- @tparam string pattern Pattern to match
-- @local
function Files:_Include(path, pattern)
	if path ~= "" then
		for _, pattern in pairs(self.exclude) do
			if pattern.Match(path) then return end
		end
	end

	local realPath = fs.combine(self.path, path)
	assert(fs.exists(realPath), "Cannot find path " .. path)

	if fs.isDir(realPath) then
		for _, file in ipairs(fs.list(realPath)) do
			self:_Include(fs.combine(path, file), pattern)
		end
	elseif not pattern or pattern.Match(path) then
		self.files[path] = true
	end
end

--- Parse a pattern
-- @tparam string match The pattern to parse
-- @treturn Utils.Pattern The created pattern
-- @tlocal
function Files:_Parse(match)
	match = Utils.ParsePattern(match)
	local text = match.Text

	if match.Type == "Normal" then
		function match.Match(toMatch) return text == toMatch end
	else
		function match.Match(toMatch) return toMatch:match(text) end
	end
	return match
end

--- Create a new @{Files|files object}
-- @tparam string path The path
-- @treturn Files The resulting object
local function Factory(path)
	return setmetatable({
		path = path,
		include = {},
		exclude = {},
		startup = 'startup'
	}, { __index = Files })
		:Remove { ".git", ".idea", "Howlfile.lua", "Howlfile", "build" }
end

Mediator.Subscribe({ "HowlFile", "env" }, function(env)
	env.Files = function(path)
		return Factory(path or env.CurrentDirectory)
	end
end)

--- @export
return {
	Files = Files,
	Factory = Factory,
}
end)
do
--- [Compilr](https://github.com/oeed/Compilr) by Oeed ported to Howl by SquidDev
-- Combines files and emulates the fs API
-- @module files.Compilr

local header = [=[--[[Hideously Smashed Together by Compilr, a Hideous Smash-Stuff-Togetherer, (c) 2014 oeed
	This file REALLLLLLLY isn't suitable to be used for anything other than being executed
	To extract all the files, run: "<filename> --extract" in the Shell
]]
]=]

local footer = [[
local function run(tArgs)
	local fnFile, err = loadstring(files[%q], %q)
	if err then error(err) end

	local function split(str, pat)
		 local t = {}
		 local fpat = "(.-)" .. pat
		 local last_end = 1
		 local s, e, cap = str:find(fpat, 1)
		 while s do
				if s ~= 1 or cap ~= "" then
		 table.insert(t,cap)
				end
				last_end = e+1
				s, e, cap = str:find(fpat, last_end)
		 end
		 if last_end <= #str then
				cap = str:sub(last_end)
				table.insert(t, cap)
		 end
		 return t
	end

	local function resolveTreeForPath(path, single)
		local _files = files
		local parts = split(path, '/')
		if parts then
			for i, v in ipairs(parts) do
				if #v > 0 then
					if _files[v] then
						_files = _files[v]
					else
						_files = nil
						break
					end
				end
			end
		elseif #path > 0 and path ~= '/' then
			_files = _files[path]
		end
		if not single or type(_files) == 'string' then
			return _files
		end
	end

	local oldFs = fs
	local env
	env = {
		fs = {
			list = function(path)
							local list = {}
							if fs.exists(path) then
						list = fs.list(path)
							end
				for k, v in pairs(resolveTreeForPath(path)) do
					if not fs.exists(path .. '/' ..k) then
						table.insert(list, k)
					end
				end
				return list
			end,

			exists = function(path)
				if fs.exists(path) then
					return true
				elseif resolveTreeForPath(path) then
					return true
				else
					return false
				end
			end,

			isDir = function(path)
				if fs.isDir(path) then
					return true
				else
					local tree = resolveTreeForPath(path)
					if tree and type(tree) == 'table' then
						return true
					else
						return false
					end
				end
			end,

			isReadOnly = function(path)
				if not fs.isReadOnly(path) then
					return false
				else
					return true
				end
			end,

			getName = fs.getName,
			getSize = fs.getSize,
			getFreespace = fs.getFreespace,
			makeDir = fs.makeDir,
			move = fs.move,
			copy = fs.copy,
			delete = fs.delete,
			combine = fs.combine,

			open = function(path, mode)
				if fs.exists(path) then
					return fs.open(path, mode)
				elseif type(resolveTreeForPath(path)) == 'string' then
					local handle = {close = function()end}
					if mode == 'r' then
						local content = resolveTreeForPath(path)
						handle.readAll = function()
							return content
						end

						local line = 1
						local lines = split(content, '\n')
						handle.readLine = function()
							if line > #lines then
								return nil
							else
								return lines[line]
							end
							line = line + 1
						end
											return handle
					else
						error('Cannot write to read-only file (compilr archived).')
					end
				else
					return fs.open(path, mode)
				end
			end
		},

		loadfile = function( _sFile )
				local file = env.fs.open( _sFile, "r" )
				if file then
						local func, err = loadstring( file.readAll(), fs.getName( _sFile ) )
						file.close()
						return func, err
				end
				return nil, "File not found: ".._sFile
		end,

		dofile = function( _sFile )
				local fnFile, e = env.loadfile( _sFile )
				if fnFile then
						setfenv( fnFile, getfenv(2) )
						return fnFile()
				else
						error( e, 2 )
				end
		end
	}

	setmetatable( env, { __index = _G } )

	local tAPIsLoading = {}
	env.os.loadAPI = function( _sPath )
			local sName = fs.getName( _sPath )
			if tAPIsLoading[sName] == true then
					printError( "API "..sName.." is already being loaded" )
					return false
			end
			tAPIsLoading[sName] = true

			local tEnv = {}
			setmetatable( tEnv, { __index = env } )
			local fnAPI, err = env.loadfile( _sPath )
			if fnAPI then
					setfenv( fnAPI, tEnv )
					fnAPI()
			else
					printError( err )
					tAPIsLoading[sName] = nil
					return false
			end

			local tAPI = {}
			for k,v in pairs( tEnv ) do
					tAPI[k] =  v
			end

			env[sName] = tAPI
			tAPIsLoading[sName] = nil
			return true
	end

	env.shell = shell

	setfenv( fnFile, env )
	fnFile(unpack(tArgs))
end

local function extract()
		local function node(path, tree)
				if type(tree) == 'table' then
						fs.makeDir(path)
						for k, v in pairs(tree) do
								node(path .. '/' .. k, v)
						end
				else
						local f = fs.open(path, 'w')
						if f then
								f.write(tree)
								f.close()
						end
				end
		end
		node('', files)
end

local tArgs = {...}
if #tArgs == 1 and tArgs[1] == '--extract' then
	extract()
else
	run(tArgs)
end
]]

function Files.Files:Compilr(env, output, options)
	local path = self.path
	options = options or {}

	local files = self:Files()
	if not files[self.startup] then
		error('You must have a file called ' .. self.startup .. ' to be executed at runtime.')
	end

	local resultFiles = {}
	for file, _ in pairs(files) do
		local read = fs.open(fs.combine(path, file), "r")
		local contents = read.readAll()
		read.close()

		if options.minify and loadstring(contents) then -- This might contain non-lua files, ensure it doesn't
			contents = Rebuild.MinifyString(contents)
		end

		local root = resultFiles
		local nodes = { file:match((file:gsub("[^/]+/?", "([^/]+)/?"))) }
		nodes[#nodes] = nil
		for _, node in pairs(nodes) do
			local nRoot = root[node]
			if not nRoot then
				nRoot = {}
				root[node] = nRoot
			end
			root = nRoot
		end

		root[fs.getName(file)] = contents
	end

	local result = header .. "local files = " .. Helpers.serialize(resultFiles) .. "\n" .. string.format(footer, self.startup, self.startup)

	if options.minify then
		result = Rebuild.MinifyString(result)
	end

	local outputFile = fs.open(fs.combine(env.CurrentDirectory, output), "w")
	outputFile.write(result)
	outputFile.close()
end

function Runner.Runner:Compilr(name, files, outputFile, taskDepends)
	return self:AddTask(name, taskDepends, function(task, env)
		files:Compilr(env, outputFile)
	end)
		:Description("Combines multiple files using Compilr")
		:Produces(outputFile)
end
end
do
--- [Compilr](https://github.com/oeed/Compilr) by Oeed ported to Howl by SquidDev
-- Combines files and emulates the fs API
-- @module files.Compilr

local header = [=[
local loading = {}
local oldRequire, preload, loaded = require, {}, { startup = loading }

local function require(name)
	local result = loaded[name]

	if result ~= nil then
		if result == loading then
			error("loop or previous error loading module ' " .. name .. "'", 2)
		end

		return result
	end

	loaded[name] = loading
	local contents = preload[name]
	if contents then
		result = contents()
	elseif require then
		result = require(name)
	else
		error("cannot load '" + name + "'")
	end

	if result == nil then result = true end
	loaded[name] = result
	return result
end
]=]


function Files.Files:AsRequire(env, output, options)
	local path = self.path
	options = options or {}
	local link = options.Link

	local files = self:Files()
	if not files[self.startup] then
		error('You must have a file called ' .. self.startup .. ' to be executed at runtime.')
	end

	local result = {header}
	for file, _ in pairs(files) do
		Utils.Verbose("Including " .. file)
		local whole = fs.combine(path, file)
		result[#result + 1] = "preload[\"" .. file:gsub("%.lua$", ""):gsub("/", ".") .. "\"] = "
		if link then
			assert(fs.exists(whole), "Cannot find " .. file)
			result[#result + 1] = "loadfile(\"" .. whole .. "\")\n"
		else
			local read = fs.open(whole, "r")
			local contents = read.readAll()
			read.close()

			result[#result + 1] = "function(...)\n" .. contents .. "\nend\n"
		end
	end

	result[#result + 1] = "return preload[\"" .. self.startup:gsub("%.lua$", ""):gsub("/", ".") .. "\"](...)"

	local outputFile = fs.open(fs.combine(env.CurrentDirectory, output), "w")
	outputFile.write(table.concat(result))
	outputFile.close()
end

function Runner.Runner:AsRequire(name, files, outputFile, taskDepends)
	return self:InjectTask(Task.Factory(name, taskDepends, function(task, env)
		files:AsRequire(env, outputFile, task)
	end, Task.OptionTask))
		:Description("Packages files together to allow require")
		:Produces(outputFile)
end
end
--- Core script for Howl
-- @script Howl

local options = ArgParse.Options({ ... })

options
	:Option "verbose"
	:Alias "v"
	:Description "Print verbose output"
options
	:Option "time"
	:Alias "t"
	:Description "Display the time taken for tasks"
options
	:Option "trace"
	:Description "Print a stack trace on errors"
options
	:Option "help"
	:Alias "?"
	:Alias "h"
	:Description "Print this help"

-- Locate the howl file
local howlFile, currentDirectory = HowlFile.FindHowl()
if not howlFile then
	if options:Get("help") or (#taskList == 1 and taskList[1] == "help") then
		Utils.PrintColor(colors.yellow, "Howl")
		Utils.PrintColor(colors.lightGrey, "Howl is a simple build system for Lua")
		Utils.PrintColor(colors.grey, "You can read the full documentation online: https://github.com/SquidDev-CC/Howl/wiki/")

		Utils.PrintColor(colors.white, (([[
			The key thing you are missing is a HowlFile. This can be "Howlfile" or "Howlfile.lua".
			Then you need to define some tasks. Maybe something like this:
		]]):gsub("\t", "")))

		Utils.PrintColor(colors.pink, 'Tasks:Minify("minify", "Result.lua", "Result.min.lua")')

		Utils.PrintColor(colors.white, "Now just run `Howl minify`!")
	end
	error(currentDirectory, 0)
end

Utils.Verbose("Found HowlFile at " .. fs.combine(currentDirectory, howlFile))

-- SETUP TASKS
local taskList = options:Arguments()

Mediator.Subscribe({ "ArgParse", "changed" }, function(options)
	Utils.IsVerbose(options:Get("verbose") or false)
	if options:Get "help" then
		taskList = { "help" }
	end
end)

local tasks = HowlFile.SetupTasks(currentDirectory, howlFile, options)

-- Basic list tasks
tasks:Task "list" (function()
	tasks:ListTasks()
end):Description "Lists all the tasks"

tasks:Task "help" (function()
	Utils.Print("Howl [options] [task]")
	Utils.PrintColor(colors.orange, "Tasks:")
	tasks:ListTasks("  ")

	Utils.PrintColor(colors.orange, "\nOptions:")
	options:Help("  ")
end):Description "Print out a detailed usage for Howl"

-- If no other task exists run this
tasks:Default(function()
	Utils.PrintError("No default task exists.")
	Utils.Verbose("Use 'Tasks:Default' to define a default task")
	Utils.PrintColor(colors.orange, "Choose from: ")
	tasks:ListTasks("  ")
end)

-- Run the task
tasks:RunMany(taskList)
