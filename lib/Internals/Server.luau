--!strict
--!native

------------------------------------------------------------------------------------------------------------------------

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local library = script.Parent.Parent

local FormatMessage = require(library.Utility.FormatMessage)
local Ratelimit = require(library.Utility.RateLimit)
local RemoteFunction = require(library.Utility.RemoteFunction)

local Conversions = require(library.Tools.Conversions)
local Fetching = require(library.Tools.Fetching)
local Hasher = require(library.Tools.Hasher)

local Types = require(library.Types)

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

	PreloadIds = {},
	DefinitionsGroupHash = {},
}

local usesStrictNaming = true

------------------------------------------------------------------------------------------------------------------------

--[[
    Sets grouped sounds from a folder into the sound definitions.

    @param soundDefinitions SoundDefinitions -- The sound definitions dictionary to add the sounds to.
    @param childFolder Instance -- The folder containing the sounds to add.
]]
local function setGroupedSounds(soundDefinitions: Types.SoundDefinitions, childFolder: Instance)
	local names = {}

	for _, sound in pairs(childFolder:GetDescendants()) do
		if not sound:IsA("Sound") then
			continue
		end

		--to enforce more traditional naming style of sounds
		if names[sound.Name] and usesStrictNaming then
			FormatMessage.Warn(
				`Duplicate sound name of {sound.Name} was found in {childFolder.Name} group!, {sound:GetFullName()}`
			)
		end
		names[sound.Name] = true

		--creates a sound definition
		local success, result = pcall(function()
			local newDefinition = Conversions.SoundToDefinition(sound)
			newDefinition.Properties.SoundGroup = childFolder.Name --add to sound group

			return newDefinition
		end)

		if success then
			local soundLocation = Fetching.CreateLocation(sound, childFolder)
			soundDefinitions[soundLocation] = result
		else
			FormatMessage.Warn(result)
		end
	end
end

--[[
    Creates sound definitions for all sounds in the given folder and organizes them by group.

    @param soundFolder Configuration -- The folder containing sound group folders and unattached sounds.

    @return SoundDefinitions -- The created sound definitions dictionary.
]]
local function createSoundDefinitions(soundFolder: Configuration): Types.SoundDefinitions
	local soundDefinitions: Types.SoundDefinitions = {}

	for _, childFolder in pairs(soundFolder:GetChildren()) do
		setGroupedSounds(soundDefinitions, childFolder)
	end

	return soundDefinitions
end

------------------------------------------------------------------------------------------------------------------------

--[[
	Initializes the server sound system.

	Creates unattached sound folder and converts all sounds into sound definitions organized by group, then sets up a RemoteFunction for clients to request the sound schema.

	@param soundFolder Configuration -- The folder containing sound group folders and unattached sounds.
]]
local function initializeServerSoundSystem(soundFolder: Configuration)
	--set groups
	soundSchema.SoundGroups = Conversions.SoundConfigToSoundGroups(soundFolder, soundSchema.SoundGroupContainer)

	--convert Sounds
	soundSchema.SoundDefinitions = createSoundDefinitions(soundFolder)

	--set group hash
	soundSchema.DefinitionsGroupHash = Hasher.HashGroups(soundSchema)

	--set preload
	soundSchema.PreloadIds = Conversions.SoundConfigToPreloadIds(soundFolder)

	soundFolder:Destroy() --destroy folder after converting sounds to definitions to save memory

	--send conversion to client
	local soundRequestLimit = Ratelimit(5, 5)
	local dataLimitThunk = FormatMessage.WarnThunk("Sound data was requested too many times by a client!")

	RemoteFunction.new("SoundRequest", function(player: Player)
		if not soundRequestLimit(player) then
			dataLimitThunk()

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
	
	@param soundFolder Configuration -- The folder containing sound group folders and unattached sounds.
	@param strictNaming boolean -- Optional parameter to enforce strict naming of sounds within groups, default is true. If true, duplicate sound names within the same group will trigger a warning.
]]
function ServerData._initServer(soundFolder: Configuration | Folder, strictNaming: boolean?)
	if RunService:IsClient() then
		FormatMessage.Error(`Cannot initialize server on client! {soundFolder:GetFullName()}`)
	end
	if typeof(soundFolder) ~= "Instance" then
		FormatMessage.Error(`Invalid sound folder injected! {soundFolder:GetFullName()}`)
	end

	if strictNaming ~= nil then
		usesStrictNaming = strictNaming
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
