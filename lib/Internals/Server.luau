--!strict

------------------------------------------------------------------------------------------------------------------------

--excepts class names only
local ALLOWED_SOUND_CHILDREN = {
	"ChorusSoundEffect",
	"CompressorSoundEffect",
	"DistortionSoundEffect",
	"EchoSoundEffect",
	"EqualizerSoundEffect",
	"FlangeSoundEffect",
	"PitchShiftSoundEffect",
	"ReverbSoundEffect",
	"TremoloSoundEffect",
}

------------------------------------------------------------------------------------------------------------------------

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local utility = script.Parent.Parent.Utility

local Properties = require(utility.Properties)
local Ratelimit = require(utility.RateLimit)
local RemoteFunction = require(utility.RemoteFunction)
local Types = require(utility.Types)

------------------------------------------------------------------------------------------------------------------------

local unattachedSoundsFolder = Instance.new("Configuration")
unattachedSoundsFolder.Name = "UnattachedSounds"
unattachedSoundsFolder.Parent = SoundService

local soundGroupContainerFolder = Instance.new("Configuration")
soundGroupContainerFolder.Name = "SoundGroups"
soundGroupContainerFolder.Parent = SoundService

local soundSchema: Types.SoundSchema = {
	UnattachedSounds = unattachedSoundsFolder,
	SoundGroupContainer = soundGroupContainerFolder,
	SoundGroups = {},
	SoundDefinitions = {},
}

------------------------------------------------------------------------------------------------------------------------

--[[
    Retrieves the sound effects of a sound instance that are valid sound effects and converts them into tables.

    @param sound Sound - The sound instance to retrieve children from.

    @return Types.SoundEffectDefinitions - A dictionary of the sound's valid children converted into tables, organized by class name.
]]
local function GetSoundEffectDefinitions(sound: Sound): Types.SoundEffectDefinitions
	local children = {}

	for _, child in pairs(sound:GetChildren()) do
		if not table.find(ALLOWED_SOUND_CHILDREN, child.ClassName) then
			continue
		end

		children[child.ClassName] = Properties.InstanceToProperties(child)
	end

	return children
end

------------------------------------------------------------------------------------------------------------------------

--[[
    Registers a sound and its effects into the sound definitions.

    @param soundDefinition Types.SoundDefinition - The sound definition to add the sound to.
    @param sound Sound - The sound instance to register.
    @param childFolder Instance - The folder containing the sound for grouping purposes.
]]
local function registerSound(soundDefinition: Types.SoundDefinition, sound: Sound, childFolder: Instance)
	return pcall(function()
		soundDefinition[sound.Name] = { --create sound and its effects
			Properties = Properties.InstanceToProperties(sound),
			Effects = GetSoundEffectDefinitions(sound),
		}

		soundDefinition[sound.Name].Properties.Name = sound.Name --add to sound group
		soundDefinition[sound.Name].Properties.SoundGroup = childFolder.Name --add to sound group
	end)
end

--[[
    Sets grouped sounds from a folder into the sound definitions.

    @param soundDefinition Types.SoundDefinition - The sound definition to add the sounds to.
    @param childFolder Instance - The folder containing the sounds to add.
]]
local function setGroupedSounds(soundDefinition: Types.SoundDefinition, childFolder: Instance)
	for _, sound in pairs(childFolder:GetDescendants()) do
		if not sound:IsA("Sound") then
			continue
		end

		local success, errorMessage = registerSound(soundDefinition, sound, childFolder)

		if not success then
			warn(errorMessage)
		end
	end
end

--[[
    Creates sound definitions for all sounds in the given folder and organizes them by group.

    @param soundFolder Configuration - The folder containing sound group folders and unattached sounds.

    @return Types.SoundDefinitions - The created sound definitions dictionary.
]]
local function createSoundDefinitions(soundFolder: Configuration)
	local soundDefinitions: Types.SoundDefinitions = {}

	--first set of children defines sound groups
	for _, childFolder in pairs(soundFolder:GetChildren()) do
		local soundGroup = Instance.new("SoundGroup")
		soundGroup.Name = childFolder.Name
		soundGroup.Parent = soundSchema.SoundGroupContainer

		soundSchema.SoundGroups[childFolder.Name] = soundGroup

		setGroupedSounds(soundDefinitions, childFolder)
	end

	soundSchema.SoundDefinitions = soundDefinitions
end

------------------------------------------------------------------------------------------------------------------------

--[[
	Initializes the server sound system.

	Creates unattached sound folder and converts all sounds into sound definitions organized by group, then sets up a RemoteFunction for clients to request the sound schema.

	@param soundFolder Configuration - The folder containing sound group folders and unattached sounds.
]]
local function initializeServerSoundSystem(soundFolder: Configuration)
	--convert Sounds
	createSoundDefinitions(soundFolder)

	--send conversion to client
	local soundRequestLimit = Ratelimit(5, 5)
	RemoteFunction.new("SoundRequest", function(player: Player)
		if not soundRequestLimit(player) then
			warn("Sound data was requested too many times by " .. player.Name .. "!")
			return nil
		end

		return soundSchema
	end)
end

------------------------------------------------------------------------------------------------------------------------

--[[
	ServerSide of the sound system. Handles sound data storage and sending to clients.
]]
local ServerData = {}

--[[
    Initializes the server sound system.

	soundFolder should be on the server side.

    @param folder Configuration | Folder -- The folder containing sound group folders and unattached sounds.
]]
function ServerData._initServer(soundFolder: Configuration | Folder)
	if RunService:IsClient() then
		error(`Cannot initialize server on client! {soundFolder:GetFullName()}`)
	end
	if typeof(soundFolder) ~= "Instance" then
		error(`Invalid sound folder injected! {soundFolder:GetFullName()}`)
	end

	initializeServerSoundSystem(soundFolder :: Configuration)
end

--[[
	Retrieves the SoundSchema.

	@return Types.SoundSchema - The sound schema containing unattached sounds, sound groups, and sound definitions.
]]
function ServerData.GetSoundSchema(): Types.SoundSchema
	return soundSchema
end

return ServerData
