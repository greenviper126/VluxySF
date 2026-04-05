--!strict

--[[
	This Is designed to make playing sounds and setting them to sound groups much easier.
	There Is also a Variance Function to help make sounds less repetitive.
	Use cases for Variance include footsteps, interacting with objects, etc.

	PlayOnRemove doesn't change the sound position once removed. we should wait to destroy it instead.
]]

local utility = script.Utility
local internals = script.Internals

local Properties = require(utility.Properties)
local Trove = require(utility.Trove)
local Types = require(script.Types)

local SoundEntity = require(script.SoundEntity)

----------------------------------------------------------------------------------------------------------------

--[=[
	@type SoundEffectDefinition Dictionary<any>
	@within VluxySF

	Defines the properties of a sound effect as a dictionary of property names and values.
]=]
export type SoundEffectDefinition = Types.SoundEffectDefinition

--[=[
	@type SoundEffectDefinitions Dictionary<SoundEffectDefinition>
	@within VluxySF

	Defines the sound effects of a sound as a dictionary of class names to their corresponding properties.
]=]
export type SoundEffectDefinitions = Types.SoundEffectDefinitions

--[=[
	@type SoundProperties Dictionary<any>
	@within VluxySF

	Defines the properties of a sound as a dictionary of property names and values.
]=]
export type SoundProperties = Types.SoundProperties

--[=[
	@interface SoundDefinition
	@within VluxySF

	.Properties SoundProperties -- The properties of the sound itself, such as SoundId, Volume, etc.
	.Effects SoundEffectDefinitions -- The sound effects of the sound, organized by class name.

	Defines the properties and sound effects of a sound.
]=]
export type SoundDefinition = Types.SoundDefinition

--[=[
	@type SoundDefinitions Dictionary<SoundDefinition>
	@within VluxySF

	Defines the sound definitions of the system as a dictionary of sound names to their corresponding sound data.
]=]
export type SoundDefinitions = Types.SoundDefinitions

--[=[
	@type SoundGroups Dictionary<SoundGroup>
	@within VluxySF

	Defines the type of a sound group instance.
]=]
export type SoundGroups = Types.SoundGroups

--[=[
	@interface SoundVariance
	@within VluxySF

	.PlaybackSpeed () -> number -- A callback that returns a multiplier for the sound's playback speed.
	.Volume () -> number -- A callback that returns a multiplier for the sound's volume.

	Defines the variance for sound properties, allowing for dynamic changes to playback speed and volume.
]=]
export type SoundVariance = Types.SoundVariance

--[=[
	@interface SoundSchema
	@within VluxySF

	.UnattachedSounds Configuration -- A folder for storing unattached sounds.
	.SoundGroupContainer Configuration -- A folder for storing sound groups.
	.SoundGroups SoundGroups -- A dictionary of sound group instances, organized by name.
	.SoundDefinitions SoundDefinitions -- A dictionary of sound definitions, organized by sound name.

	Defines the overall schema for the sound system, containing all necessary data for sound creation and management.
]=]
export type SoundSchema = Types.SoundSchema

----------------------------------------------------------------------------------------------------------------

local soundSchema: Types.SoundSchema

local Random = Random.new()

----------------------------------------------------------------------------------------------------------------

--[=[
	@class VluxySF

	@client
	@server

	VluxySoundFactory is a sound management system designed to simplify the process of creating, organizing, and playing sounds in Roblox.
	
	It allows developers to define sounds and their properties in a structured way, supports sound groups for better organization, and includes functionality for adding variance to sound playback to make it less repetitive.
]=]
local Sounds = {}

--[=[
	@within VluxySF

	@private

	@server

	@param soundFolder Configuration | Folder -- Folder containing all sound data

	Injects the source folder used to build sound data and sets up server-side structures.
]=]
function Sounds._initServer(soundFolder: Configuration | Folder)
	local Server = require(internals.Server)
	Server._initServer(soundFolder)

	soundSchema = Server.GetSoundSchema()
end

--[=[
	@within VluxySF

	@private

	@client

	Sets up client-side structures and retrieves sound data from the server.
]=]
function Sounds._initClient()
	local Client = require(internals.Client)
	Client._initClient()

	soundSchema = Client.GetSoundSchema()
end

--[=[
	@within VluxySF

	@return SoundDefinitions -- All converted sound data

	Returns all serialized sound data.
]=]
function Sounds.SoundDefinitions(): SoundDefinitions
	return soundSchema.SoundDefinitions -- this needs to be deep frozen or cloned
end

--[=[
	@within VluxySF

	@return { string } -- All registered sound names

	Returns all sound names.
]=]
function Sounds.AllSoundNames(): { string }
	local names = {}

	for name, _ in pairs(soundSchema.SoundDefinitions) do
		table.insert(names, name)
	end

	return names
end

--[=[
	@within VluxySF

	@param name string -- Name of the sound group

	@return SoundGroup? -- Matching sound group, if found

	Finds a sound group by name.
]=]
function Sounds.FindSoundGroup(name: string): SoundGroup?
	return soundSchema.SoundGroups[name]
end

--[=[
	@within VluxySF

	@return { [string]: SoundGroup } -- Read-only map of sound groups

	Returns all sound groups.
	
	Read-only table; the instances themselves remain mutable.
]=]
function Sounds.GetSoundGroup(): SoundGroups
	local cloneOfSoundGroups = table.clone(soundSchema.SoundGroups)
	return table.freeze(cloneOfSoundGroups)
end

--[[
	@within VluxySF

	@param sound string | SoundDefinition -- The name of the sound to create or a sound definition to create from

	@return SoundEntity - A SoundEntity instance representing the created sound.

	Creates a SoundEntity instance from a sound name or definition. If a name is provided, it looks up the corresponding sound definition and creates the sound accordingly.
]]
function Sounds.Create(sound: string | Types.SoundDefinition): SoundEntity.SoundEntity
	return SoundEntity.new(sound)
end

--[=[
	@within VluxySF

	@param soundDefinition SoundDefinition -- Serialized sound data to materialize

	@return Sound -- Newly created sound instance

	Converts serialized sound data into a playable `Sound` instance.
]=]
function Sounds.CreateRawSound(soundDefinition: SoundDefinition): Sound
	local newSound = Instance.new("Sound")
	newSound:AddTag("FrameworkSound")

	if not soundSchema or not soundSchema.SoundDefinitions then
		warn("Sounds not loaded yet!")

		newSound.Name = "SoundsNotLoadedYet"
		return newSound
	end

	for property, value in pairs(soundDefinition.Properties) do --create new sound
		Properties.ApplyPropertyValueToInstance(newSound, property, value)
	end

	local realSoundGroup = Sounds.FindSoundGroup(soundDefinition.Properties.SoundGroup)
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

	return newSound
end

--[=[
	@within VluxySF

	@yields

	@param name string -- Name of the sound to find
	@param variance SoundVariance? -- Optional variance callbacks
	@param parent Instance? -- Optional parent for the created sound

	@return Sound? -- Created sound, if found

	Finds a sound by name and materializes it as an instance.
]=]
function Sounds.FindSoundByName(name: string, variance: SoundVariance?, parent: Instance?): Sound?
	local soundTables = soundSchema.SoundDefinitions[name]

	if not soundSchema.SoundDefinitions then
		warn("Sound data is currently nil, cannot pull sound named " .. name)
		return nil
	end
	if not soundSchema then
		warn("Could not find sound named " .. name)
		return nil
	end

	local newSound = Sounds.CreateSound(soundTables)
	if newSound then
		newSound.Parent = parent and parent or soundSchema.UnattachedSounds

		if variance then
			newSound.PlaybackSpeed = newSound.PlaybackSpeed * (variance.PlaybackSpeed() or 1)
			newSound.Volume = newSound.Volume * (variance.Volume() or 1)
		end

		if not newSound.IsLoaded then
			newSound.Loaded:Wait()
		end
	else
		warn("Could not create sound named " .. name)
	end

	return newSound
end

--[=[
	@within VluxySF

	@param sound Sound -- Sound instance to inspect

	@return number -- Estimated remaining playback time in seconds

	Returns the most accurate remaining playtime estimate.
]=]
function Sounds.GetEstimatedPlayLength(sound: Sound): number
	local padding = 0.05

	if sound.Looped then
		return math.huge
	end

	local playbackSpeed = sound.PlaybackSpeed
	if playbackSpeed <= 0 or playbackSpeed ~= playbackSpeed then
		return padding
	end

	local timeLength = sound.TimeLength
	if timeLength <= 0 or timeLength ~= timeLength then
		return padding
	end

	local timePosition = sound.TimePosition
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

--[=[
	@within VluxySF

	@param name string -- Name of the sound to play
	@param variance SoundVariance? -- Optional variance callbacks
	@param parent Instance? -- Optional parent for playback

	Plays a sound by name and destroys it after playback starts.
]=]
function Sounds.PlaySoundByName(name: string, variance: SoundVariance?, parent: Instance?)
	local cleaner = Trove.new()

	local sound = Sounds.FindSoundByName(name, variance, parent)
	if not sound then
		return
	end
	cleaner:AttachToInstance(sound)

	--backup
	local playtime = Sounds.GetEstimatedPlayLength(sound)
	cleaner:Add(task.delay(playtime, function()
		sound:Destroy()
	end))

	--cleanupSound after it plays
	cleaner:Add(task.spawn(function()
		sound:Play()

		sound.Ended:Wait()

		sound:Destroy()
	end))

	return cleaner
end

--[=[
	@within VluxySF

	@param minSpeed number? -- Minimum playback speed multiplier (default: 0.95)
	@param maxSpeed number? -- Maximum playback speed multiplier (default: 1.05)
	@param minVolume number? -- Minimum volume multiplier (default: 0.95)
	@param maxVolume number? -- Maximum volume multiplier (default: 1.05)

	@return SoundVariance -- Randomized variance callbacks

	Creates variance callbacks for sound playback speed and volume.
]=]
function Sounds.Variance(minSpeed: number?, maxSpeed: number?, minVolume: number?, maxVolume: number?): SoundVariance
	return {
		PlaybackSpeed = function()
			return Random:NextNumber(minSpeed or 0.95, maxSpeed or 1.05)
		end,
		Volume = function()
			return Random:NextNumber(minVolume or 0.95, maxVolume or 1.05)
		end,
	}
end

return Sounds
