--!strict

--[[
	This Is designed to make playing sounds and setting them to sound groups much easier.
	There Is also a Variance Function to help make sounds less repetitive.
	Use cases for Variance include footsteps, interacting with objects, etc.
]]

type Dictionary<T> = { [string]: T }
type SoundChildren = Dictionary<Dictionary<any>>

export type SoundTable = { Sound: Dictionary<any>, Children: SoundChildren }
export type VarianceTable = {
	PlaybackSpeed: () -> number,
	Volume: () -> number,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")

local Guard = require(ReplicatedStorage.Packages._Index["red-blox_guard@1.0.1"].guard)
local Ratelimit = require(ReplicatedStorage.Packages.ratelimit)
local Red = require(ReplicatedStorage.Packages.red)

local Properties = require(ReplicatedStorage.Utility.Properties)

local Random = Random.new()

local unattachedSounds: Folder = nil
local soundGroupContainer: Configuration = nil

local _soundGroups: Dictionary<SoundGroup> = {}
local _sounds: Dictionary<SoundTable> = nil

----------------------------------------------------------------------------------------------------------------

--excepts class names only
local allowedSoundChildren = {
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

----------------------------------------------------------------------------------------------------------------

local SoundsRequest = Red.Function(
	"SoundsRequest",
	function() end,
	function(Table) --send sound table to client on request
		return Guard.Map(Guard.String, Guard.Any)(Table)
	end
)

----------------------------------------------------------------------------------------------------------------

--//Server
local function GetSoundChildren(sound: Sound): SoundChildren
	local children = {}

	for _, child in pairs(sound:GetChildren()) do
		if not table.find(allowedSoundChildren, child.ClassName) then
			continue
		end

		children[child.ClassName] = Properties.InstanceToProperties(child)
	end

	return children
end

local function CreateSoundTable()
	local soundFolder: Folder = ServerStorage:FindFirstChild("Sounds") :: Folder

	local soundTable: Dictionary<SoundTable> = {}

	local function RegisterSound(sound: Sound, childFolder)
		return pcall(function()
			soundTable[sound.Name] = { --create sound and its children
				Sound = Properties.InstanceToProperties(sound),
				Children = GetSoundChildren(sound),
			}

			soundTable[sound.Name].Sound.Name = sound.Name --add to sound group
			soundTable[sound.Name].Sound.SoundGroup = childFolder.Name --add to sound group
		end)
	end

	local function SetGroupedSounds(childFolder: Instance)
		for _, sound in pairs(childFolder:GetDescendants()) do
			if not sound:IsA("Sound") then
				continue
			end

			local success, errorMessage = RegisterSound(sound, childFolder)

			if not success then
				warn(errorMessage)
			end
		end
	end

	soundGroupContainer = Instance.new("Configuration")
	soundGroupContainer.Name = "SoundGroups"

	--first set of children defines sound groups
	for _, childFolder in pairs(soundFolder:GetChildren()) do
		local soundGroup = Instance.new("SoundGroup")
		soundGroup.Name = childFolder.Name
		soundGroup.Parent = soundGroupContainer

		_soundGroups[childFolder.Name] = soundGroup

		SetGroupedSounds(childFolder)
	end

	soundGroupContainer.Parent = SoundService

	_sounds = soundTable
end

--//Client
local function GetSoundForClient()
	local success, sounds = SoundsRequest:Call():Await()
	if success then
		_sounds = sounds
	else
		warn("Server did not return sounds to local player, re-attempting!")

		task.wait(0.5)

		GetSoundForClient()
	end
end

----------------------------------------------------------------------------------------------------------------

if RunService:IsServer() then
	--base
	unattachedSounds = Instance.new("Folder")
	unattachedSounds.Name = "UnattachedSounds"
	unattachedSounds.Parent = SoundService

	--convert Sounds
	CreateSoundTable()

	--send conversion to client
	local soundRequestLimit = Ratelimit(5, 5)
	SoundsRequest:SetCallback(function(_player)
		if not soundRequestLimit(_player) then
			warn("Sound data was requested too many times by", _player)
			return {}
		end

		return _sounds
	end)
elseif RunService:IsClient() then
	GetSoundForClient() --yielding

	unattachedSounds = SoundService:WaitForChild("UnattachedSounds") :: Folder
	soundGroupContainer = SoundService:WaitForChild("SoundGroups") :: Configuration

	for _, soundGroup in pairs(soundGroupContainer:GetChildren()) do
		_soundGroups[soundGroup.Name] = soundGroup :: SoundGroup
	end
end

----------------------------------------------------------------------------------------------------------------

--[[
	Custom Sound Player.

	Keeps all sound data in a table and loads it when called.
	All sounds should be requested from this system on server and client.
]]
local Sounds = {}

--[[
	Returns name of sound group if it exists.

	@param name string - Name of the SoundGroup.

	@return SoundGroup? - The SoundGroup you were looking for.
]]
function Sounds.FindSoundGroup(name: string): SoundGroup?
	return _soundGroups[name]
end

--[[
	Returns all sound groups that exist.
	
	Read-Only, Instance properties can be changed.

	@return { [string]: SoundGroup } - A list of all SoundGroups.
]]
function Sounds.GetSoundGroups(): Dictionary<SoundGroup>
	local cloneOfSoundGroups = table.clone(_soundGroups)
	return table.freeze(cloneOfSoundGroups)
end

--[[
	Converts SoundTable Data into a real sound Instance.
	Can also remember child modifiers for manipulating sound.

	@param soundData SoundTable - Table storing all the data to make a sound Instance.

	@return Sound - The sound Instance you requested to be made from a SoundTable.
]]
function Sounds.CreateSound(soundData: SoundTable): Sound
	local newSound = Instance.new("Sound")
	newSound:AddTag("FrameworkSound")

	if not _sounds then
		newSound.Name = "SoundsNotLoadedYet"
		return newSound
	end

	for property, value in pairs(soundData.Sound) do --create new sound
		Properties.ApplyPropertyValueToInstance(newSound, property, value)
	end

	local realSoundGroup = Sounds.FindSoundGroup(soundData.Sound.SoundGroup)
	newSound.SoundGroup = realSoundGroup

	for class, properties in pairs(soundData.Children) do --create new sound children
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

--[[
	Searches through all the saved sounds and makes an Instance of it.

	@param name string - The name of the sound you want to play.
	@param variance VarianceTable? - A table for varying the sound to make it less repetitive.
	@param parent Instance? - The instance you want to parent the sound too.

	@return Sound? - Returns a Sound if it exists.
]]
function Sounds.FindSoundByName(name: string, variance: VarianceTable?, parent: Instance?): Sound?
	local soundData = _sounds[name]

	if not _sounds then
		warn("Sound data is currently nil, cannot pull sound named " .. name)
		return
	end
	if not soundData then
		warn("Could not find sound named " .. name)
		return
	end

	local newSound = Sounds.CreateSound(soundData)
	if newSound then
		newSound.Parent = parent and parent or unattachedSounds

		if variance then
			newSound.PlaybackSpeed = newSound.PlaybackSpeed * (variance.PlaybackSpeed() or 1)
			newSound.Volume = newSound.Volume * (variance.Volume() or 1)
		end
	else
		warn("Could not create sound named " .. name)
	end

	return newSound
end

--[[
	Will automatically play the sound and clean it up when called.

	@param name string - The name of the sound you want to play.
	@param variance VarianceTable? - A table for varying the sound to make it less repetitive.
	@param parent Instance? - The instance you want to parent the sound too.

	@return nil
]]
function Sounds.PlaySoundByName(name: string, variance: VarianceTable?, parent: Instance?)
	local sound = Sounds.FindSoundByName(name, variance, parent)
	if not sound then
		return
	end

	sound.PlayOnRemove = true
	sound:Destroy()
end

--[[
	Creates random variance values for sound playback.
	
	@param minSpeed number? - Minimum playback speed multiplier (default: 0.95).
	@param maxSpeed number? - Maximum playback speed multiplier (default: 1.05).
	@param minVolume number? - Minimum volume multiplier (default: 0.95).
	@param maxVolume number? - Maximum volume multiplier (default: 1.05).

	@return VarianceTable - Random options decided from the given params.
]]
function Sounds.Variance(minSpeed: number?, maxSpeed: number?, minVolume: number?, maxVolume: number?): VarianceTable
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
