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

local soundData: Types.SoundData = {
	UnattachedSounds = unattachedSoundsFolder,
	SoundGroupContainer = soundGroupContainerFolder,
	SoundGroups = {},
	Sounds = {},
}

------------------------------------------------------------------------------------------------------------------------

--[[
    Retrieves the children of a sound instance that are valid sound effects and converts them into tables.

    @param sound Sound - The sound instance to retrieve children from.

    @return Types.SoundChildren - A dictionary of the sound's valid children converted into tables, organized by class name.
]]
local function GetSoundChildren(sound: Sound): Types.SoundChildren
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
    Registers a sound and its children into the sound table.

    @param soundTable Types.Dictionary<Types.SoundTable> - The sound table to add the sound to.
    @param sound Sound - The sound instance to register.
    @param childFolder Instance - The folder containing the sound for grouping purposes.
]]
local function registerSound(soundTable: Types.Dictionary<Types.SoundTable>, sound: Sound, childFolder: Instance)
	return pcall(function()
		soundTable[sound.Name] = { --create sound and its children
			Sound = Properties.InstanceToProperties(sound),
			Children = GetSoundChildren(sound),
		}

		soundTable[sound.Name].Sound.Name = sound.Name --add to sound group
		soundTable[sound.Name].Sound.SoundGroup = childFolder.Name --add to sound group
	end)
end

--[[
    Sets grouped sounds from a folder into the sound table.

    @param soundTable Types.Dictionary<Types.SoundTable> - The sound table to add the sounds to.
    @param childFolder Instance - The folder containing the sounds to add.
]]
local function setGroupedSounds(soundTable: Types.Dictionary<Types.SoundTable>, childFolder: Instance)
	for _, sound in pairs(childFolder:GetDescendants()) do
		if not sound:IsA("Sound") then
			continue
		end

		local success, errorMessage = registerSound(soundTable, sound, childFolder)

		if not success then
			warn(errorMessage)
		end
	end
end

--[[
    Creates sound tables for all sounds in the given folder and organizes them by group.

    @param soundFolder Configuration - The folder containing sound group folders and unattached sounds.

    @return Types.Dictionary<Types.SoundTable> - The created sound table dictionary.
]]
local function createSoundTable(soundFolder: Configuration)
	local soundTable: Types.Dictionary<Types.SoundTable> = {}

	--first set of children defines sound groups
	for _, childFolder in pairs(soundFolder:GetChildren()) do
		local soundGroup = Instance.new("SoundGroup")
		soundGroup.Name = childFolder.Name
		soundGroup.Parent = soundData.SoundGroupContainer

		soundData.SoundGroups[childFolder.Name] = soundGroup

		setGroupedSounds(soundTable, childFolder)
	end

	soundData.Sounds = soundTable
end

------------------------------------------------------------------------------------------------------------------------

--[[
	Initializes the server sound system.

	Creates unattached sound folder and converts all sounds into tables.

	@param soundFolder Configuration - The folder containing sound group folders and unattached sounds.
]]
local function initializeServerSoundSystem(soundFolder: Configuration)
	--convert Sounds
	createSoundTable(soundFolder)

	--send conversion to client
	local soundRequestLimit = Ratelimit(5, 5)
	RemoteFunction.new("SoundRequest", function(player: Player)
		if not soundRequestLimit(player) then
			warn("Sound data was requested too many times by " .. player.Name .. "!")
			return nil
		end

		return soundData
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
	Retrieves the SoundData.

	@return Types.SoundData - The sound data containing unattached sounds, sound groups, and sound tables.
]]
function ServerData.GetSoundData(): Types.SoundData
	return soundData
end

return ServerData
