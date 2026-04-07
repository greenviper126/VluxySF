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
local Tables = require(utility.Tables)
local Trove = require(utility.Trove)

local SoundEntity = require(script.SoundEntity)
local SoundTools = require(script.SoundTools)
local Types = require(script.Types)

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

	--fetch
	soundSchema = Server.GetSoundSchema()
	Tables.DeepFreeze(soundSchema)

	-- class for manipulating sounds
	SoundEntity._injectSoundSchema(soundSchema)
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

	--fetch
	soundSchema = Client.GetSoundSchema()
	Tables.DeepFreeze(soundSchema)

	-- class for manipulating sounds
	SoundEntity._injectSoundSchema(soundSchema)
end

--[=[
	@within VluxySF

	@return SoundDefinitions -- All converted sound data

	Returns all serialized sound data.
]=]
function Sounds.GetSoundDefinitions(): SoundDefinitions
	return soundSchema.SoundDefinitions
end

--[=[
	@within VluxySF

	@return { string } -- All registered sound locations

	Returns all sound locations.
]=]
function Sounds.GetSoundLocations(): { string }
	local locations = {}

	for location, _ in pairs(soundSchema.SoundDefinitions) do
		table.insert(locations, location)
	end

	return locations
end

--[=[
	@within VluxySF

	@param name string -- Name of the sound group

	@return SoundGroup? -- Matching sound group, if found

	Finds a sound group by name.
]=]
function Sounds.GetSoundGroup(name: string): SoundGroup?
	return soundSchema.SoundGroups[name]
end

--[=[
	@within VluxySF

	@return SoundGroups -- All sound groups

	Returns all sound groups.
]=]
function Sounds.GetSoundGroups(): Types.SoundGroups
	return soundSchema.SoundGroups
end

--[=[
	@within VluxySF

	@return { string } -- All registered sound group names

	Returns all sound group names.
]=]
function Sounds.GetSoundGroupNames(): { string }
	local names = {}

	for name, _ in pairs(soundSchema.SoundGroups) do
		table.insert(names, name)
	end

	return names
end

--[=[
	@within VluxySF

	@tag SoundEntity

	@param sound string | SoundDefinition -- The sound location or a sound definition to attach to.

	@return SoundEntity -- Constructed class

	A constructor for manipulating your sounds.
]=]
function Sounds.Create(sound: string | Types.SoundDefinition): SoundEntity.SoundEntity
	return SoundEntity.new(sound)
end

------------------------------------------------------------------------------------------------------------------

--[=[
	@within VluxySF

	@param soundDefinition SoundDefinition -- The sound definition to construct from.

	@return Sound -- Constructed sound instance based on the provided definition.

	Constructs a sound instance from a given sound definition, applying all specified properties and effects.
]=]
function Sounds.ConstructSoundFromDefinition(soundDefinition: SoundDefinition): Sound
	return SoundTools.CreateSound(soundSchema, soundDefinition)
end

--[=[
	@within VluxySF

	@yields

	@param name string -- The name of the sound definition to construct from.

	@return Sound? -- Constructed sound instance if the definition is found, otherwise nil.

	Constructs a sound instance from a sound definition identified by its name.
]=]
function Sounds.ConstructSoundFromName(name: string): Sound?
	local soundDefinition = SoundTools.FindSoundDefinition(soundSchema, name)
	if not soundDefinition then
		return nil
	end

	local newSound = SoundTools.CreateSound(soundSchema, soundDefinition)
	if not newSound then
		return nil
	end

	if not newSound.IsLoaded then
		newSound.Loaded:Wait()
	end

	return newSound
end

--[=[
	@within VluxySF

	@param sound Sound -- The sound instance to analyze.

	@return number -- The estimated play length of the sound, including any variations in playback speed.

	Calculates the estimated play length of a sound instance by considering its SoundId and any attached sound effects that may influence its duration.
]=]
function Sounds.GetEstimatedPlayLength(sound: Sound): number
	return SoundTools.GetEstimatedPlayLength(sound)
end

--[=[
	@within VluxySF

	@param min number? -- Minimum multiplier for variance (default: 0.95)
	@param max number? -- Maximum multiplier for variance (default: 1.05)

	@return number -- variance result

	Calculates a random variance value within the specified range.
]=]
function Sounds.Variance(min: number?, max: number?): () -> number
	return function()
		return Random:NextNumber(min or 0.95, max or 1.05)
	end
end

return Sounds
