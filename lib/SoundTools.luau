--!strict

local Properties = require(script.Parent.Utility.Properties)
local Types = require(script.Parent.Types)

local blankSound = Instance.new("Sound", script)
blankSound.Name = "BlankSound"

local SoundTools = {}

--[[
	@param name string -- Name of the sound group

	@return SoundGroup? -- Matching sound group, if found

	Finds a sound group by name.
]]
function SoundTools.FindSoundGroup(soundSchema: Types.SoundSchema, name: string): SoundGroup?
	return soundSchema.SoundGroups[name]
end

--[[
	@return SoundDefinition -- A blank sound definition with default properties and no effects.

	Creates a blank sound definition that can be used as a base for creating new sounds programmatically.
]]
function SoundTools.CreateBlankSoundDefinition()
	return SoundTools.CreateSoundDefinition(blankSound)
end

--[[
	@param sound Sound -- Sound instance to convert into a sound definition

	@return SoundDefinition -- A sound definition representing the provided sound instance.

	Creates a sound definition from a Roblox `Sound` instance by serializing its properties and valid child effects.
]]
function SoundTools.CreateSoundDefinition(sound: Sound): Types.SoundDefinition
	local soundDefinition: Types.SoundDefinition

	pcall(function()
		soundDefinition = {
			Properties = Properties.InstanceToProperties(sound),
			Effects = {},
		}

		--this allows some sounds that shouldn't be registered to be used as templates without erroring, such as blankSound
		--needs to be fixed
		for _, child in pairs(sound:GetChildren()) do
			soundDefinition.Effects[child.ClassName] = Properties.InstanceToProperties(child)
		end

		soundDefinition.Properties.Name = sound.Name
	end)

	return soundDefinition
end

--[[
	@param soundSchema SoundSchema -- The sound schema containing sound definitions and groups
	@param soundDefinition SoundDefinition -- Serialized sound data to materialize

	@return Sound -- Newly created sound instance

	Converts serialized sound data into a playable `Sound` instance.
]]
function SoundTools.CreateSound(soundSchema: Types.SoundSchema, soundDefinition: Types.SoundDefinition): Sound
	local newSound = Instance.new("Sound")
	newSound:AddTag("VluxySFSound")

	if not soundSchema or not soundSchema.SoundDefinitions then
		warn("Sounds not loaded yet!")

		newSound.Name = "SoundsNotLoadedYet"
		return newSound
	end

	for property, value in pairs(soundDefinition.Properties) do --create new sound
		Properties.ApplyPropertyValueToInstance(newSound, property, value)
	end

	local realSoundGroup = SoundTools.FindSoundGroup(soundSchema, soundDefinition.Properties.SoundGroup)
	newSound.SoundGroup = realSoundGroup

	for class, properties in pairs(soundDefinition.Effects) do --create new sound children
		pcall(function()
			local newClass = Instance.new(class)

			for property, value in pairs(properties) do --create new child class
				Properties.ApplyPropertyValueToInstance(newClass, property, value)
			end

			newClass.Parent = newSound
		end)
	end
	newSound.Parent = soundSchema.UnattachedSounds

	return newSound
end

--[[
	@param soundSchema SoundSchema -- The sound schema containing sound definitions and groups
	@param name string -- Name of the sound definition to find

	@return SoundDefinition? -- Matching sound definition, if found

	Finds a sound definition by name within the provided sound schema.
]]
function SoundTools.FindSoundDefinition(soundSchema: Types.SoundSchema, name: string): Types.SoundDefinition?
	if not soundSchema.SoundDefinitions then
		warn("Sound data is currently nil, cannot pull sound named " .. name)
		return nil
	end

	local soundDefinition = soundSchema.SoundDefinitions[name]
	if not soundDefinition then
		warn("No sound definition found for sound named " .. name)
		return nil
	end

	return soundDefinition
end

--[[
	@param sound Sound -- Sound instance to inspect

	@return number -- Estimated remaining playback time in seconds

	Returns the most accurate remaining playtime estimate.
]]
function SoundTools.GetEstimatedPlayLength(sound: Sound | Types.SoundDefinition): number
	local padding = 0.05

	--Sound and SoundDefinition should have the same properties.
	local realSoundInfo: any = sound
	if typeof(sound) == "table" then
		realSoundInfo = sound.Properties
	end

	if realSoundInfo.Looped then
		return math.huge
	end

	local playbackSpeed = realSoundInfo.PlaybackSpeed
	if playbackSpeed <= 0 or playbackSpeed ~= playbackSpeed then
		return padding
	end

	local timeLength = realSoundInfo.TimeLength
	if timeLength <= 0 or timeLength ~= timeLength then
		return padding
	end

	local timePosition = realSoundInfo.TimePosition
	if timePosition ~= timePosition then
		timePosition = 0
	end
	timePosition = math.clamp(timePosition, 0, timeLength)

	local remaining = (timeLength - timePosition) / playbackSpeed
	if remaining ~= remaining then
		return padding
	end

	return math.max(remaining + padding, padding)
end

return SoundTools
