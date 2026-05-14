--!strict

local libarary = script.Parent.Parent

local FormatMessage = require(libarary.Utility.FormatMessage)

local Types = require(libarary.Types)

--[[
    Module responsible for fetching sound definitions based on various criteria such as name, sound group, or direct location.
]]
local Fetching = {}

--[[
	Creates a sound definition location string based on the sound's position within the folder hierarchy.

	@param sound Sound -- The Sound instance to create a location for.
	@param baseFolder Instance -- The base folder that serves as the root for the location string.

	@return string -- The created location string.
]]
function Fetching.CreateLocation(sound: Sound, baseFolder: Instance): string
	local location = ""
	local parents = {}

	--get parents
	local function backtrack(folder: Instance)
		table.insert(parents, folder.Name)

		if folder ~= baseFolder and folder.Parent then
			backtrack(folder.Parent)
		end
	end
	backtrack(sound)

	--convert to string
	for i = #parents, 1, -1 do
		location ..= parents[i]

		if i == 1 then
			break
		end

		location ..= "/"
	end

	return location
end

--[[
    Fetches a `SoundDefinition` directly by its location in the schema.

    @param schema SoundSchema -- The `SoundSchema` to search within.
    @param location string -- The location of the sound definition to fetch.

    @return string? -- The sound location.
]]
function Fetching.Direct(schema: Types.SoundSchema, location: string): string?
	return schema.SoundDefinitions[location] and location or nil
end

--[[
    Fetches a `SoundDefinition` by its name across all sound groups in the schema. first wins!

    @param schema SoundSchema -- The `SoundSchema` to search within.
    @param name string -- The name of the sound definition to fetch.

    @return string? -- The location.
]]
function Fetching.FromName(schema: Types.SoundSchema, name: string): string?
	for _, v in pairs(schema.DefinitionsGroupHash) do
		local location = v[name]
		if not location then
			continue
		end

		return location
	end

	return nil
end

--[[
    Fetches a `SoundDefinition` by its name within a specific sound group in the schema.

    @param schema SoundSchema -- The `SoundSchema` to search within.
    @param soundGroup string -- The `SoundGroup` to look within.
    @param name string -- The name of the sound definition to fetch.

    @return string? -- The location.
]]
function Fetching.FromSoundGroup(schema: Types.SoundSchema, soundGroup: string, name: string): string?
	local groupHash = schema.DefinitionsGroupHash[soundGroup]
	if not groupHash then
		FormatMessage.Warn(`No sound definitions found for sound group {soundGroup}!`)
		return nil
	end

	local location = groupHash[name]
	if not location then
		FormatMessage.Warn(`No sound definition found for sound named {name} in sound group {soundGroup}!`)
		return nil
	end

	return location
end

return Fetching
