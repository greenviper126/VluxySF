--!strict

local utility = script.Utility
local internals = script.Internals

local Tables = require(utility.Tables)

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
	@interface SoundSchema
	@within VluxySF

	.UnattachedSounds Configuration -- A folder for storing unattached sounds.
	.SoundGroupContainer Configuration -- A folder for storing sound groups.
	.SoundGroups SoundGroups -- A dictionary of sound group instances, organized by name.
	.SoundDefinitions SoundDefinitions -- A dictionary of sound definitions, organized by sound name.
	.PreloadIds { string } -- A list of sound asset IDs to preload.

	Defines the overall schema for the sound system, containing all necessary data for sound creation and management.
]=]
export type SoundSchema = Types.SoundSchema

----------------------------------------------------------------------------------------------------------------

local soundSchema: Types.SoundSchema

local isInitialized = false -- stops the public functions from executing to early if the schema isn't ready.

local Random = Random.new()

----------------------------------------------------------------------------------------------------------------

local function schemaFailCheck()
	if isInitialized then
		return
	end
	error("VluxySF Sound schema is not initialized yet! You need to wait before you can use this function!", 2)
end

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

	isInitialized = true
end

--[=[
	@within VluxySF

	@private

	@client

	@param timeout number? -- optional timeout for preloading sounds, default is 5 seconds

	Sets up client-side structures and retrieves sound data from the server.
]=]
function Sounds._initClient(timeout: number?)
	local Client = require(internals.Client)
	Client._initClient(timeout)

	--fetch
	soundSchema = Client.GetSoundSchema()
	Tables.DeepFreeze(soundSchema)

	-- class for manipulating sounds
	SoundEntity._injectSoundSchema(soundSchema)

	isInitialized = true
end

--[=[
	@within VluxySF

	@return boolean -- Whether the sound system has been initialized.

	Checks if the sound system has been initialized.
]=]
function Sounds.IsInitialized(): boolean
	return isInitialized
end

--[=[ 
	@within VluxySF

	@yields

	@return boolean -- Whether the sound schema is ready for use.

	Waits until the sound schema is initialized and ready for use.
]=]
function Sounds.WaitForSchema()
	repeat
		task.wait()
	until isInitialized
end

--[=[
	@within VluxySF

	@tag RequiresSchema

	@private

	@return SoundSchema -- The internal sound schema used by the system.

	Provides access to the internal sound schema.
]=]
function Sounds._getSchema()
	schemaFailCheck()

	return soundSchema
end

--[=[
	@within VluxySF

	@tag RequiresSchema

	@return SoundDefinitions -- All converted sound data

	Returns all serialized sound data.
]=]
function Sounds.GetSoundDefinitions(): SoundDefinitions
	schemaFailCheck()
	return soundSchema.SoundDefinitions
end

--[=[
	@within VluxySF

	@tag RequiresSchema

	@return { string } -- All registered sound locations

	Returns all sound locations.
]=]
function Sounds.GetSoundLocations(): { string }
	schemaFailCheck()

	local locations = {}

	for location, _ in pairs(soundSchema.SoundDefinitions) do
		table.insert(locations, location)
	end

	return locations
end

--[=[
	@within VluxySF

	@tag RequiresSchema

	@param name string -- Name of the sound group

	@return SoundGroup? -- Matching sound group, if found

	Finds a sound group by name.
]=]
function Sounds.GetSoundGroup(name: string): SoundGroup?
	schemaFailCheck()

	return soundSchema.SoundGroups[name]
end

--[=[
	@within VluxySF

	@tag RequiresSchema

	@return SoundGroups -- All sound groups

	Returns all sound groups.
]=]
function Sounds.GetSoundGroups(): Types.SoundGroups
	schemaFailCheck()

	return soundSchema.SoundGroups
end

--[=[
	@within VluxySF

	@tag RequiresSchema

	@return { string } -- All registered sound group names

	Returns all sound group names.
]=]
function Sounds.GetSoundGroupNames(): { string }
	schemaFailCheck()

	local names = {}

	for name, _ in pairs(soundSchema.SoundGroups) do
		table.insert(names, name)
	end

	return names
end

--[=[
	@within VluxySF

	@tag SoundEntity
	@tag RequiresSchema

	@param sound string | SoundDefinition -- The sound location or a sound definition to attach to.

	@return SoundEntity -- Constructed class

	A constructor for manipulating your sounds.
]=]
function Sounds.Create(sound: string | Types.SoundDefinition): SoundEntity.SoundEntity
	schemaFailCheck()

	return SoundEntity.new(sound)
end

------------------------------------------------------------------------------------------------------------------

--[=[
	@within VluxySF

	@tag RequiresSchema

	@param soundDefinition SoundDefinition -- The sound definition to construct from.

	@return Sound -- Constructed sound instance based on the provided definition.

	Constructs a sound instance from a given sound definition, applying all specified properties and effects.
]=]
function Sounds.ConstructSoundFromDefinition(soundDefinition: SoundDefinition): Sound
	schemaFailCheck()

	return SoundTools.CreateSound(soundSchema, soundDefinition)
end

--[=[
	@within VluxySF

	@tag RequiresSchema

	@param sound Sound -- The sound instance to convert into a sound definition.

	@return SoundDefinition -- A sound definition representing the provided sound instance.

	Creates a sound definition from a Roblox `Sound` instance by serializing its properties and valid child effects.

	This does not get added to the definitions list.
]=]
function Sounds.CreateSoundDefinitionFromSound(sound: Sound): SoundDefinition
	schemaFailCheck()

	return SoundTools.CreateSoundDefinition(sound)
end

--[=[
	@within VluxySF

	@tag RequiresSchema

	@yields

	@param name string -- The name of the sound definition to construct from.

	@return Sound? -- Constructed sound instance if the definition is found, otherwise nil.

	Constructs a sound instance from a sound definition identified by its name.
]=]
function Sounds.ConstructSoundFromName(name: string): Sound?
	schemaFailCheck()

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

	@return () -> number -- variance result

	Calculates a random variance value within the specified range.
]=]
function Sounds.Variance(min: number?, max: number?): () -> number
	return function()
		return Random:NextNumber(min or 0.95, max or 1.05)
	end
end

return Sounds
