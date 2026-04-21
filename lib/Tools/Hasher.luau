--!strict

local libarary = script.Parent.Parent

local Types = require(libarary.Types)

local Hasher = {}

--[[
    Hashes `SoundDefinitions` into a nested dictionary for efficient lookup by sound group and name.

    @param schema SoundSchema -- The `SoundSchema`.

    @return { [string]: { [string]: string } } -- A nested dictionary where the first key is the sound group name, the second key is the sound name, and the value is the sound definition location.
]]
function Hasher.HashGroups(schema: Types.SoundSchema): { [string]: { [string]: string } }
	local groupHash = {}

	for location, _definition in pairs(schema.SoundDefinitions) do
		local splitLocation = location:split("/")

		if not splitLocation[1] then
			warn(`Invalid sound definition location: {location}`)
			continue
		end

		if not splitLocation[#splitLocation] then
			warn(`Invalid sound definition location: {location}`)
			continue
		end

		local groupName = splitLocation[1]
		local soundName = splitLocation[#splitLocation]

		if not groupHash[groupName] then
			groupHash[groupName] = {}
		end

		local innerGroupHash = groupHash[groupName]
		if innerGroupHash[soundName] then
			warn(`Duplicate sound definition location: {location}`)
			continue
		end

		innerGroupHash[soundName] = location
	end

	return groupHash
end

return Hasher
