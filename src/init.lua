local Chew = {}

type TableMarker = {
	creator: string,
	value: any,
}

type Map<K, V> = { [K]: V };
type Array<T> = { T };

type ChewPathMarker = any;
type ChewTableMarker = any;

local pathMarkers: Map<any, Instance> = {}
local attachedTableMarkers: Map<any, Array<TableMarker>> = {}

-- Chew functions --
function Chew.import(marker: ChewPathMarker, ...: string): Instance
	-- validating marker
	assert(marker ~= nil, "Expected marker is not nil")
	local base: Instance? = pathMarkers[marker]
	if base == nil then
		error(("Unknown path marker: %s"):format(tostring(marker)))
	end

	-- looking for that specific child, by looping
	-- the varidiac arguments. one by one
	local destination = base
	for i = 1, select("#", ...) do
		local segment = select(i, ...)
		assert(
			type(segment) == "string",
			("Invalid argument #%d (expected string)"):format(i)
		)
		destination = destination:WaitForChild(segment)
	end

	return destination
end

function Chew.preload(markers: { ChewPathMarker })
	assert(type(markers) == "table", "Expected table of path markers")
	for i, marker in ipairs(markers) do
		local base: Instance? = pathMarkers[marker]
		if not typeof(base) == "Instance" then
			error(("Unregistered marker in argument #%d (%s)"):format(i, tostring(marker)))
		end
		for _, descendant in ipairs(base:GetDescendants()) do
			if descendant.ClassName == "ModuleScript" then
				require(descendant)
			end
		end
	end
end

function Chew.pathMarker(marker: ChewPathMarker, destination: Instance)
	assert(type(marker) ~= "nil", "Expected marker is not nil")
	assert(typeof(destination) == "Instance", "Expected destination")
	if pathMarkers[marker] ~= nil then
		error(("Attempt to register existing path marker (%s from destination: %s)"):format(
			tostring(marker), destination:GetFullName()
			))
	end
	pathMarkers[marker] = destination
end

function Chew.tableMarker(name: string): ChewTableMarker
	assert(type(name) == "string", "Expected name")

	local marker = newproxy(true)
	attachedTableMarkers[marker] = {}

	getmetatable(marker).__tostring = function()
		return name
	end

	return marker
end

local function getNonIgnitables()
	local nonIgnitables: Map<any, boolean> = {}
	for _, tuple in pairs(Chew.getAttachedTableMarkers(Chew.ignitable)) do
		if tuple.value[Chew.ignitable] ~= true then
			nonIgnitables[tuple.value] = true
		end
	end
	return nonIgnitables
end

function Chew.ignite()
	-- get all of the non-ignitables
	local nonIgnitables = getNonIgnitables()

	-- onInit and onStart process
	for _, obj in pairs(Chew.getAttachedTableMarkers(Chew.singleton)) do
		local value = obj.value
		local creator = obj.creator
		if not nonIgnitables[value] then
			local call = value["onInit"]
			if type(call) ~= "function" and call ~= nil then
				error(("%s has onInit but it is not a function!"):format(creator))
			end
			if call ~= nil then
				call(value)
			end
		end
	end

	-- onStart marker
	for _, obj in pairs(Chew.getAttachedTableMarkers(Chew.singleton)) do
		local value = obj.value
		local creator = obj.creator
		if not nonIgnitables[value] then
			local call = value["onStart"]
			if type(call) ~= "function" and call ~= nil then
				error(("%s has onStart but it is not a function!"):format(creator))
			end
			if call ~= nil then
				task.spawn(call, value)
			end
		end
	end

	table.clear(nonIgnitables)
end

function Chew.createSingleton<T>(initial: T?, ignitable: boolean?): T
	assert(type(initial) == "table" or initial == nil, "Expected table or nil")
	initial = initial == nil and {} or initial
	initial[Chew.ignitable] = ignitable or true
	initial[Chew.singleton] = true
	return Chew.table(initial, 1)
end

function Chew.table<T>(initial: T?, depth: number?): T
	assert(type(initial) == "table" or initial == nil, "Expected table or nil")
	assert(type(depth) == "number" or depth == nil, "Expected depth to be number or nil")
	initial = initial == nil and {} or initial

	-- awkward way to do this heheheheh
	local creator = debug.traceback():split("\n")[2 + (depth or 0)]
	assert(creator, "Unknown creator source")

	-- initialize table markers
	for marker in pairs(attachedTableMarkers) do
		if initial[marker] ~= nil then
			local info: TableMarker = { creator = creator, value = initial }
			table.insert(attachedTableMarkers[marker], info)
		end
	end

	return initial
end

function Chew.getAttachedTableMarkers(marker: any): Array<TableMarker>
	assert(marker ~= nil, "Expected table marker")

	local attaches = attachedTableMarkers[marker]
	if attaches == nil then
		error(("%s is not a valid table marker!"):format(tostring(marker)))
	end

	return attaches
end

Chew.ignitable = Chew.tableMarker("chew.ignitable")
Chew.singleton = Chew.tableMarker("chew.singleton")

-- protect from users to modify the entire module
local FakeChew = newproxy(true)

getmetatable(FakeChew).__index = function(_, key)
	local proto = Chew[key]
	if proto == nil then
		error(("%s is not property of Chew"):format(tostring(key)))
	end
	return proto
end

return FakeChew :: typeof(Chew)
