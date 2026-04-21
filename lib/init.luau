--!strict

local Debris = game:GetService("Debris")

local tools = script.Tools
local utility = script.Utility
local internals = script.Internals

local Tables = require(utility.Tables)

local Conversions = require(tools.Conversions)
local Fetching = require(tools.Fetching)
local Preload = require(tools.Preload)
local SoundMisc = require(tools.SoundMisc)

local Types = require(script.Types)

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

--[=[
	@interface SoundSchema
	@within VluxySF

	@tag Schema

	.UnattachedSounds Configuration -- A folder for storing unattached sounds.
	.SoundGroupContainer Configuration -- A folder for storing sound groups.
	.SoundGroups SoundGroups -- A dictionary of sound group instances, organized by name.
	.SoundDefinitions SoundDefinitions -- A dictionary of sound definitions, organized by sound name.
	.DefinitionsGroupHash Dictionary<Dictionary<string>> -- Set of hashmaps for fast searching.
	.PreloadIds { string } -- A list of sound asset IDs to preload.

	Defines the overall schema for the sound system, containing all necessary data for sound creation and management.
]=]
export type SoundSchema = Types.SoundSchema

----------------------------------------------------------------------------------------------------------------

--[=[
	@type SoundDefinitionInstanced Sound & SoundChildrenInstanced
	@within VluxySF

	@tag Instanced

	Defines a sound group, which is a collection of sounds that can be managed together, allowing for collective volume control and organization.
]=]
export type SoundDefinitionInstanced = Types.SoundDefinitionInstanced

--[=[
	@interface SoundChildrenInstanced
	@within VluxySF

	@tag Instanced
	
	.TremoloSoundEffect TremoloSoundEffect?
	.ReverbSoundEffect ReverbSoundEffect?
	.PitchShiftSoundEffect PitchShiftSoundEffect?
	.FlangeSoundEffect FlangeSoundEffect?
	.EqualizerSoundEffect EqualizerSoundEffect?
	.EchoSoundEffect EchoSoundEffect?
	.DistortionSoundEffect DistortionSoundEffect?
	.CompressorSoundEffect CompressorSoundEffect?
	.ChorusSoundEffect ChorusSoundEffect?
	
	Defines the possible child sound effects that can be attached to a sound instance, allowing for enhanced audio manipulation and variation.
]=]
export type SoundChildrenInstanced = Types.SoundChildrenInstanced

------------------------------------------------------------------------------------------------------------------------

--[=[
	@type SoundGroups {[string]: SoundGroup}
	@within VluxySF

	@tag Instanced

	Defines the type of a sound group instance.
]=]
export type SoundGroups = Types.SoundGroups

----------------------------------------------------------------------------------------------------------------

--[=[
	@type SoundDefinitions {[string]: SoundDefinition}
	@within VluxySF

	@tag Serialized

	Defines the sound definitions of the system as a dictionary of sound names to their corresponding sound data.
]=]
export type SoundDefinitions = Types.SoundDefinitions

--[=[
	@interface SoundDefinition
	@within VluxySF

	@tag Serialized

	.Properties SoundSerialized -- The properties of the sound itself, such as SoundId, Volume, etc.
	.Effects SoundChildrenSerialized -- The sound effects of the sound, organized by class name.

	Defines the properties and sound effects of a sound.
]=]
export type SoundDefinition = Types.SoundDefinition

------------------------------------------------------------------------------------------------------------------------

--[=[
	@interface SoundChildrenSerialized
	@within VluxySF

	@tag Serialized

	.ChorusSoundEffect ChorusSoundEffectSerialized?
	.CompressorSoundEffect CompressorSoundEffectSerialized?
	.DistortionSoundEffect DistortionSoundEffectSerialized?
	.EchoSoundEffect EchoSoundEffectSerialized?
	.EqualizerSoundEffect EqualizerSoundEffectSerialized?
	.FlangeSoundEffect FlangeSoundEffectSerialized?
	.PitchShiftSoundEffect PitchShiftSoundEffectSerialized?
	.ReverbSoundEffect ReverbSoundEffectSerialized?
	.TremoloSoundEffect TremoloSoundEffectSerialized?

	Defines the sound effects of a sound as a dictionary of class names to their corresponding properties.
]=]
export type SoundChildrenSerialized = Types.SoundChildrenSerialized

------------------------------------------------------------------------------------------------------------------------

--[=[
	@type SoundSerialized {[string]: any}
	@within VluxySF

	@tag Serialized

	Defines the properties of a sound as a dictionary of property names and values.
]=]
export type SoundSerialized = Types.SoundSerialized

--[=[
	@type ChorusSoundEffectSerialized {[string]: any}
	@within VluxySF

	@tag Serialized

	Defines the properties of a ChorusSoundEffect as a dictionary of property names and values.
]=]
export type ChorusSoundEffectSerialized = Types.ChorusSoundEffectSerialized

--[=[
	@type CompressorSoundEffectSerialized {[string]: any}
	@within VluxySF

	@tag Serialized

	Defines the properties of a CompressorSoundEffect as a dictionary of property names and values.
]=]
export type CompressorSoundEffectSerialized = Types.CompressorSoundEffectSerialized

--[=[
	@type DistortionSoundEffectSerialized {[string]: any}
	@within VluxySF

	@tag Serialized

	Defines the properties of a DistortionSoundEffect as a dictionary of property names and values.
]=]
export type DistortionSoundEffectSerialized = Types.DistortionSoundEffectSerialized

--[=[
	@type EchoSoundEffectSerialized {[string]: any}
	@within VluxySF

	@tag Serialized

	Defines the properties of an EchoSoundEffect as a dictionary of property names and values.
]=]
export type EchoSoundEffectSerialized = Types.EchoSoundEffectSerialized

--[=[
	@type EqualizerSoundEffectSerialized {[string]: any}
	@within VluxySF

	@tag Serialized

	Defines the properties of an EqualizerSoundEffect as a dictionary of property names and values.
]=]
export type EqualizerSoundEffectSerialized = Types.EqualizerSoundEffectSerialized

--[=[
	@type FlangeSoundEffectSerialized {[string]: any}
	@within VluxySF
	
	@tag Serialized

	Defines the properties of a FlangeSoundEffect as a dictionary of property names and values.
]=]
export type FlangeSoundEffectSerialized = Types.FlangeSoundEffectSerialized

--[=[
	@type PitchShiftSoundEffectSerialized {[string]: any}
	@within VluxySF

	@tag Serialized

	Defines the properties of a PitchShiftSoundEffect as a dictionary of property names and values.
]=]
export type PitchShiftSoundEffectSerialized = Types.PitchShiftSoundEffectSerialized

--[=[
	@type ReverbSoundEffectSerialized {[string]: any}
	@within VluxySF

	@tag Serialized

	Defines the properties of a ReverbSoundEffect as a dictionary of property names and values.
]=]
export type ReverbSoundEffectSerialized = Types.ReverbSoundEffectSerialized

--[=[
	@type TremoloSoundEffectSerialized {[string]: any}
	@within VluxySF

	@tag Serialized

	Defines the properties of a TremoloSoundEffect as a dictionary of property names and values.
]=]
export type TremoloSoundEffectSerialized = Types.TremoloSoundEffectSerialized

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

----------------------------------------------------------------------------------------------------------------
--INITIALIZATION------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

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

	isInitialized = true
end

----------------------------------------------------------------------------------------------------------------
--SCHEMA_STARTUP------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

--[=[
	@within VluxySF

	@tag Startup

	@return boolean -- Whether the sound schema has been initialized.

	Checks if the sound schema has been initialized.

	```lua
	if Sounds.IsInitialized() then
		print("Sound schema is ready to use!")
	else
		print("Sound schema is not initialized yet. Please wait!")
	end
	```
]=]
function Sounds.IsInitialized(): boolean
	return isInitialized
end

--[=[ 
	@within VluxySF

	@tag Startup

	@yields

	@return boolean -- Whether the sound schema is ready for use.

	Waits until the sound schema is initialized and ready for use.

	If you know that your code will execute after the schema is loaded then this is not needed.

	```lua
	print("Waiting for sound system to initialize...")

	Sounds.WaitForSchema()

	print("Sound system is now initialized and ready to use!")

	--now you can use functions and methods that require the schema!
	```
]=]
function Sounds.WaitForSchema()
	repeat
		task.wait()
	until isInitialized
end

----------------------------------------------------------------------------------------------------------------
--SOUND_DEFINITIONS_TABLES--------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

--[=[
	@within VluxySF

	@tag DefinitionData
	@tag RequiresSchema

	@return SoundDefinitions -- All converted sound data

	Returns all serialized sound data.

	```lua
	local definitions = Sounds.GetSoundDefinitions()

	for location, data in pairs(definitions) do
		print("Sound location:", location)
		print("Sound properties:", data.Properties)
		print("Sound effects:", data.Effects)
	end
	```
]=]
function Sounds.GetSoundDefinitions(): SoundDefinitions
	schemaFailCheck()
	return soundSchema.SoundDefinitions
end

--[=[
	@within VluxySF

	@tag DefinitionData
	@tag RequiresSchema

	@return { string } -- All registered sound locations

	Returns all sound locations.

	```lua
	local locations = Sounds.GetSoundLocations()

	for _, location in ipairs(locations) do
		print("Sound location:", location)
	end
	```
]=]
function Sounds.GetSoundLocations(): { string }
	schemaFailCheck()

	local locations = {}

	for location, _ in pairs(soundSchema.SoundDefinitions) do
		table.insert(locations, location)
	end

	return locations
end

----------------------------------------------------------------------------------------------------------------
--SOUND_GROUP_FUNCTIONS-----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

--[=[
	@within VluxySF

	@tag SoundGroups
	@tag RequiresSchema

	@return SoundGroups -- All sound groups defined in the schema.

	Returns all sound groups defined in the schema.
]=]
function Sounds.GetSoundGroups(): Types.SoundGroups
	schemaFailCheck()

	return soundSchema.SoundGroups
end

--[=[
	@within VluxySF

	@tag SoundGroups
	@tag RequiresSchema

	@param name string -- The name of the sound group to retrieve.

	@return SoundGroup? -- The sound group instance if found, otherwise nil.

	Retrieves a sound group instance by its name.
]=]
function Sounds.GetSoundGroup(name: string): SoundGroup?
	schemaFailCheck()

	return soundSchema.SoundGroups[name]
end

--[=[
	@within VluxySF

	@tag SoundGroups
	@tag RequiresSchema

	@return { string } -- A list of all sound group names defined in the schema.

	Returns a list of all sound group names defined in the schema.
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

	@tag SoundGroups
	@tag RequiresSchema

	@param volumes { [string]: number } -- A dictionary mapping sound group names to their desired volume levels.

	Sets the volume levels for multiple sound groups at once based on the provided dictionary of group names and volume values.
]=]
function Sounds.SetSoundGroupVolumes(volumes: { [string]: number })
	schemaFailCheck()

	for groupName, volume in pairs(volumes) do
		local group = Sounds.GetSoundGroup(groupName)

		if not group then
			warn(`VluxySF: Attempted to set volume for sound group '{groupName}', but it does not exist in schema!`)
			continue
		end

		group.Volume = volume
	end
end

----------------------------------------------------------------------------------------------------------------
--SOUND_FETCHING------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

--[=[
	@within VluxySF

	@tag Fetcher
	@tag RequiresSchema

	@param location string -- The direct location of the `SoundDefinition` or the name of the `SoundDefinition`.
	@param preset (Sound) -> ()? -- function to preconfigure the sound.

	@return Sound? -- The fetched sound instance if found, otherwise nil.
	
	Finds the specified `SoundDefinition` and gives back a playable `Sound` if it exists.
]=]
function Sounds.Fetch(location: string, preset: (Sound) -> ()?): Types.SoundDefinitionInstanced?
	schemaFailCheck()

	local isDirect = #location:split("/") ~= 1
	local realLocation: string?

	if isDirect then
		realLocation = Fetching.Direct(soundSchema, location)
	else
		realLocation = Fetching.FromName(soundSchema, location)
	end

	if not realLocation then
		warn(`VluxySF: Sound with location or name '{location}' was not found in schema!`)
		return nil
	end

	local definition = soundSchema.SoundDefinitions[realLocation]
	if not definition then
		warn(`VluxySF: SoundDefinition for location '{realLocation}' was not found in schema!`)
		return nil
	end

	local sound = Conversions.DefinitionToSound(definition)
	if preset then
		preset(sound)
	end

	return sound
end

--[=[
	@within VluxySF

	@tag Fetcher
	@tag RequiresSchema

	@param groupName string -- The name of the sound group to search within.
	@param name string -- The name of the `SoundDefinition` to find within the specified sound group.
	@param preset (Sound) -> ()? -- function to preconfigure the sound.

	@return Sound? -- The fetched sound instance if found, otherwise nil.

	Similar to `Fetch`, but is more accurate than fetching by name but less accurate then the full location. A middle ground so you can write less and still somewhat specify!
]=]
function Sounds.FetchFromGroup(groupName: string, name: string, preset: (Sound) -> ()?): Types.SoundDefinitionInstanced?
	schemaFailCheck()

	local location = Fetching.FromSoundGroup(soundSchema, groupName, name)
	if not location then
		warn(`VluxySF: Sound with name '{name}' was not found in sound group '{groupName}'!`)
		return nil
	end

	local definition = soundSchema.SoundDefinitions[location]
	if not definition then
		warn(`VluxySF: SoundDefinition for location '{location}' was not found in schema!`)
		return nil
	end

	local sound = Conversions.DefinitionToSound(definition)
	if preset then
		preset(sound)
	end

	return sound
end

--[=[
	@within VluxySF

	@tag Fetcher
	@tag RequiresSchema

	@param name string -- The name of the sound definition to fetch.
	@param preset (Sound) -> ()? -- A callback function to execute before the sound plays.
	@param waitOnLoad boolean? -- Whether to wait for the sound to load before playing (default: false).

	@return Sound? -- The fetched sound instance if found, otherwise nil.

	Fetches a sound, sets it up for one-time playback, and optionally waits for it to load before playing. The sound will be automatically cleaned up after it finishes playing.
]=]
function Sounds.FetchPlayOnce(name: string, preset: (Sound) -> ()?, waitOnLoad: boolean?)
	schemaFailCheck()

	local sound = Sounds.Fetch(name, preset)

	if not sound then
		return nil
	end
	sound.Looped = false

	task.spawn(function()
		if waitOnLoad and not sound.IsLoaded then
			sound.Loaded:Wait()
		end

		if not sound.Parent then
			return
		end

		sound:Play()

		if not sound.Parent then
			return
		end

		local playLength = Sounds.GetPlayLength(sound) or 1
		Debris:AddItem(sound, playLength)
	end)

	return nil
end

----------------------------------------------------------------------------------------------------------------
--SOUND_CONVERSIONS---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

--[=[
	@within VluxySF

	@tag Conversions

	@param sound -- The Sound instance to convert.

	@return SoundDefinition -- The resulting SoundDefinition based on the properties and effects of the provided Sound instance.

	Converts a Roblox Sound instance into a SoundDefinition.
]=]
function Sounds.ToDefinition(sound: Sound): SoundDefinition
	return Conversions.SoundToDefinition(sound)
end

--[=[
	@within VluxySF

	@tag Conversions

	@param definition SoundDefinition -- The SoundDefinition to convert.

	@return Sound -- The resulting Sound instance based on the properties and effects defined in the provided SoundDefinition.

	Converts a SoundDefinition back into a playable Roblox Sound instance.
]=]
function Sounds.FromDefinition(definition: SoundDefinition): Types.SoundDefinitionInstanced
	return Conversions.DefinitionToSound(definition)
end

----------------------------------------------------------------------------------------------------------------
--PRELOAD_FUNCTIONS---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

--[=[
	@within VluxySF

	@tag Preload

	@param ... string | Sound | SoundDefinition -- A variable number of sound identifiers, which can be sound locations, Sound instances, or SoundDefinitions.

	Preloads through ContentProvider.
]=]
function Sounds.PreloadSelected(...: string | Sound | SoundDefinition)
	return Preload.Selected(...)
end

----------------------------------------------------------------------------------------------------------------
--MISC----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

--[=[
	@within VluxySF

	@tag RequiresSchema

	@private

	@return SoundSchema -- The internal sound schema used by the system.

	Provides access to the internal sound schema.

	```lua
	local schema = Sounds._getSchema()

	print("Unattached sounds folder:", schema.UnattachedSounds)
	```
]=]
function Sounds._getSchema()
	schemaFailCheck()

	return soundSchema
end

--[=[
	@within VluxySF

	@tag Misc

	@param sound Sound -- The sound instance to analyze.

	@return number -- The estimated play length of the sound, including any variations in playback speed.

	Calculates the estimated play length of a sound instance by considering its SoundId and any attached sound effects that may influence its duration.

	```lua
	local soundInstance: Sound = --[[ reference to an existing Sound instance ]]
	local estimatedLength = Sounds.GetPlayLength(soundInstance)

	print("Play length:", estimatedLength, "seconds")
	```
]=]
function Sounds.GetPlayLength(sound: Sound): number
	return SoundMisc.GetEstimatedPlayLength(sound)
end

----------------------------------------------------------------------------------------------------------------
--JITTER_FUNCTIONS----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

--[=[
	@within VluxySF

	@tag Jitter

	@param center number -- The central value around which the jitter will occur.
	@param spread number -- The maximum deviation from the center value.

	@return () -> number -- A function that generates a random jitter value when called.

	Jitter function for sound properties.
]=]
function Sounds.Jitter(center: number, spread: number): () -> number
	return function()
		local j = (Random:NextNumber() * 2 - 1) * spread

		return math.clamp(center + j, 0, 10)
	end
end

--[=[
	@within VluxySF

	@tag Jitter

	@param min number -- The minimum value for the jitter range.
	@param max number -- The maximum value for the jitter range.

	@return () -> number -- A function that generates a random jitter value within the specified range when called.

	Jitter function that generates a random value within a specified range.
]=]
function Sounds.JitterRange(min: number, max: number): () -> number
	return function()
		local j = Random:NextNumber(min, max)

		return math.clamp(j, 0, 10)
	end
end

--[=[
	@within VluxySF

	@tag Jitter

	@param spread number -- The maximum percentage deviation from the base value (e.g., 0.1 for ±10% jitter).

	@return () -> number -- A function that generates a random jitter multiplier when called.

	Jitter function that generates a random multiplier around 1, allowing for percentage-based variation.
]=]
function Sounds.JitterScale(spread: number): () -> number
	return function()
		local j = (Random:NextNumber() * 2 - 1) * spread

		return math.clamp(1 + j, 0, 10)
	end
end

--[=[
	@within VluxySF

	@tag Jitter

	@param center number -- The central value around which the jitter will occur.
	@param spread number -- The maximum deviation from the center value.

	@return () -> number -- A function that generates a random jitter value with a shaped distribution when called.

	Jitter function that produces values with a shaped distribution, creating more natural variations around the center value.
]=]
function Sounds.JitterUnitLog(center: number, spread: number): () -> number
	return function()
		local r = (Random:NextNumber() * 2 - 1) * spread
		local shaped = r / (1 + math.abs(r) * 3)

		return math.clamp(center + shaped, 0, 10)
	end
end

----------------------------------------------------------------------------------------------------------------

return Sounds
