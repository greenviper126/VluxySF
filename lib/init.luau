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
local Types = require(utility.Types)

local soundData: Types.SoundData

local Random = Random.new()

----------------------------------------------------------------------------------------------------------------

--[=[
	@class VluxySF

	@client
	@server

	@tag Package

	Cross-context sound package for loading, creating, and playing registered sounds.
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

	soundData = Server.GetSoundData()
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

	soundData = Client.GetSoundData()
end

--[=[
	@within VluxySF

	@return Dictionary<SoundTable> -- All converted sound data

	Returns all serialized sound data.
]=]
function Sounds.Data(): Types.Dictionary<Types.SoundTable>
	return soundData.Sounds
end

--[=[
	@within VluxySF

	@return { string } -- All registered sound names

	Returns all sound names.
]=]
function Sounds.AllSoundNames(): { string }
	local names = {}

	for name, _ in pairs(soundData.Sounds) do
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
	return soundData.SoundGroups[name]
end

--[=[
	@within VluxySF

	@return { [string]: SoundGroup } -- Read-only map of sound groups

	Returns all sound groups.
	
	Read-only table; the instances themselves remain mutable.
]=]
function Sounds.GetSoundGroups(): Types.Dictionary<SoundGroup>
	local cloneOfSoundGroups = table.clone(soundData.SoundGroups)
	return table.freeze(cloneOfSoundGroups)
end

--[=[
	@within VluxySF

	@param soundTable SoundTable -- Serialized sound data to materialize

	@return Sound -- Newly created sound instance

	Converts serialized sound data into a playable `Sound` instance.
]=]
function Sounds.CreateSound(soundTable: Types.SoundTable): Sound
	local newSound = Instance.new("Sound")
	newSound:AddTag("FrameworkSound")

	if not soundData.Sounds then
		warn("Sounds not loaded yet!")

		newSound.Name = "SoundsNotLoadedYet"
		return newSound
	end

	for property, value in pairs(soundTable.Sound) do --create new sound
		Properties.ApplyPropertyValueToInstance(newSound, property, value)
	end

	local realSoundGroup = Sounds.FindSoundGroup(soundTable.Sound.SoundGroup)
	newSound.SoundGroup = realSoundGroup

	for class, properties in pairs(soundTable.Children) do --create new sound children
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
	@param variance VarianceTable? -- Optional variance callbacks
	@param parent Instance? -- Optional parent for the created sound

	@return Sound? -- Created sound, if found

	Finds a sound by name and materializes it as an instance.
]=]
function Sounds.FindSoundByName(name: string, variance: Types.VarianceTable?, parent: Instance?): Sound?
	local soundTables = soundData.Sounds[name]

	if not soundData.Sounds then
		warn("Sound data is currently nil, cannot pull sound named " .. name)
		return nil
	end
	if not soundData then
		warn("Could not find sound named " .. name)
		return nil
	end

	local newSound = Sounds.CreateSound(soundTables)
	if newSound then
		newSound.Parent = parent and parent or soundData.UnattachedSounds

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

	@param name string -- Name of the sound to play
	@param variance VarianceTable? -- Optional variance callbacks
	@param parent Instance? -- Optional parent for playback

	Plays a sound by name and destroys it after playback starts.
]=]
function Sounds.PlaySoundByName(name: string, variance: Types.VarianceTable?, parent: Instance?)
	task.spawn(function()
		local sound = Sounds.FindSoundByName(name, variance, parent)
		if not sound then
			return
		end

		--this should wait to destroy instead
		sound.PlayOnRemove = true
		sound:Destroy()
	end)
end

--[=[
	@within VluxySF

	@param minSpeed number? -- Minimum playback speed multiplier (default: 0.95)
	@param maxSpeed number? -- Maximum playback speed multiplier (default: 1.05)
	@param minVolume number? -- Minimum volume multiplier (default: 0.95)
	@param maxVolume number? -- Maximum volume multiplier (default: 1.05)

	@return VarianceTable -- Randomized variance callbacks

	Creates variance callbacks for sound playback speed and volume.
]=]
function Sounds.Variance(
	minSpeed: number?,
	maxSpeed: number?,
	minVolume: number?,
	maxVolume: number?
): Types.VarianceTable
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
