--!strict

local TweenService = game:GetService("TweenService")

local Trove = require(script.Parent.Utility.Trove)
local Types = require(script.Parent.Types)

local SoundTools = require(script.Parent.SoundTools)

--[[
	@class SoundEntity

	@server
	@client

	SoundEntity is a class that represents a sound defined in the sound schema. It provides methods for materializing the sound as a Roblox `Sound` instance, applying properties and effects, and managing its lifecycle.
]]
local SoundEntity = {}
SoundEntity.__index = SoundEntity

SoundEntity.SoundSchema = {} :: Types.SoundSchema

type self = {
	soundName: string,

	_soundDefinition: Types.SoundDefinition,
	_sound: Sound,

	_fadeCleaner: Trove.Trove,
	_cleaner: Trove.Trove,
}

export type SoundEntity = typeof(setmetatable({} :: self, SoundEntity))

--[[
	@within SoundEntity

	@private

	@param soundSchema SoundSchema -- The sound schema to inject.

	Injects the sound schema from the server into the SoundEntity module for use in materializing sounds.
]]
function SoundEntity._injectSoundSchema(soundSchema: Types.SoundSchema)
	SoundEntity.SoundSchema = soundSchema
end

--[[
	@within SoundEntity

	@param sound string | SoundDefinition -- The name of the sound definition to use or a full sound definition table.

	@return SoundEntity -- A new instance of SoundEntity initialized with the specified sound.

	Constructor
]]
function SoundEntity.new(sound: string | Types.SoundDefinition): SoundEntity
	local self = setmetatable({} :: self, SoundEntity)
	self._cleaner = Trove.new() :: any

	if typeof(sound) == "string" then
		self.soundName = sound
		local soundDefinition = SoundTools.FindSoundDefinition(SoundEntity.SoundSchema, sound)

		if not soundDefinition then
			warn("No SoundDefinition found for sound named " .. sound)

			self._soundDefinition = SoundTools.CreateBlankSoundDefinition()
		else
			self._soundDefinition = soundDefinition
		end

		self._sound = SoundTools.CreateSound(SoundEntity.SoundSchema, self._soundDefinition)
	else
		self.soundName = sound.Properties.Name
		self._soundDefinition = sound
		self._sound = SoundTools.CreateSound(SoundEntity.SoundSchema, sound)
	end

	return self
end

--[[
	@method Clone
	@within SoundEntity

	@return SoundEntity - A new SoundEntity instance with the same properties and effects as the original, but with a new underlying Sound instance.

	Creates a clone of the SoundEntity, allowing you to create multiple instances of the same sound definition without modifying the original.
]]
function SoundEntity.Clone(self: SoundEntity)
	local clonedSoundDefinition = SoundTools.CreateSoundDefinition(self._sound)
	clonedSoundDefinition.Properties.Playing = false
	clonedSoundDefinition.Properties.isPlaying = false
	clonedSoundDefinition.Properties.IsPlaying = false

	return SoundEntity.new(clonedSoundDefinition)
end

--[[
	@method GetRawSound
	@within SoundEntity

	@return Sound - The raw Sound instance created by this SoundEntity.

	Provides access to the underlying Sound instance for advanced manipulation or retrieval of properties.]]
function SoundEntity.GetRawSound(self: SoundEntity): Sound
	return self._sound
end

-------------------------------------------------------------------------------------------------------------------------

--[[
	@method FadeTo
	@within SoundEntity

	@param volume number -- The target volume to fade to.
	@param tweenInfo TweenInfo -- The TweenInfo object defining the duration and easing style of the fade.

	@return SoundEntity - The SoundEntity instance after starting the fade.

	Fades the sound's volume to the specified level over time using a tween. If a fade is already in progress, it will be cleaned up before starting the new fade.
]]
function SoundEntity.FadeTo(self: SoundEntity, volume: number, tweenInfo: TweenInfo): SoundEntity
	volume = math.clamp(volume, 0, 10)

	self:FadeStop()

	local cleaner = self._cleaner:Extend()

	local numberValue = cleaner:Add(Instance.new("NumberValue"))
	numberValue.Value = self._sound.Volume

	local tween = cleaner:Add(TweenService:Create(numberValue, tweenInfo, { Value = volume }))

	cleaner:Connect(numberValue.Changed, function()
		self._sound.Volume = numberValue.Value
	end)

	tween:Play()

	cleaner:Add(task.spawn(function()
		tween.Completed:Wait()
		cleaner:Clean()
	end))

	self._fadeCleaner = cleaner

	return self
end

--[[
	@method FadeIn
	@within SoundEntity

	@param time number -- The duration of the fade in seconds.
	@param style Enum.EasingStyle? -- Optional easing style for the fade. Defaults to Sine.

	@return SoundEntity - The SoundEntity instance after starting the fade in.

	Fades the sound's volume up from 0 to its defined volume over the specified duration using a tween. If a fade is already in progress, it will be cleaned up before starting the new fade.
]]
function SoundEntity.FadeIn(self: SoundEntity, time: number, style: Enum.EasingStyle?): SoundEntity
	local volume = self._soundDefinition.Properties.Volume --the real sound can have a different volume if it was already fading
	local tweenInfo = TweenInfo.new(time, style or Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	self._sound.Volume = 0
	self:FadeTo(volume, tweenInfo)

	return self
end

--[[
	@method FadeOut
	@within SoundEntity

	@param time number -- The duration of the fade out in seconds.
	@param style Enum.EasingStyle? -- Optional easing style for the fade out. Defaults to Sine.

	@return SoundEntity - The SoundEntity instance after starting the fade out.

	Fades the sound's volume down to 0 over the specified duration using a tween. If a fade is already in progress, it will be cleaned up before starting the new fade.
]]
function SoundEntity.FadeOut(self: SoundEntity, time: number, style: Enum.EasingStyle?): SoundEntity
	local volume = self._sound.Volume --the real sound can have a different volume if it was already fading
	local tweenInfo = TweenInfo.new(time, style or Enum.EasingStyle.Sine, Enum.EasingDirection.In)

	self._sound.Volume = volume
	self:FadeTo(0, tweenInfo)

	return self
end

--[[
	@method FadeStop
	@within SoundEntity

	@return SoundEntity - The SoundEntity instance after stopping the fade.

	Stops any active volume tween and retains the current volume level. This allows you to interrupt a fade in progress without resetting the volume to its original level.
]]
function SoundEntity.FadeStop(self: SoundEntity): SoundEntity
	if self._fadeCleaner then
		self._fadeCleaner:Clean()
		self._fadeCleaner = nil :: any
	end

	return self
end

--[[
	@method ResetToDefinition
	@within SoundEntity

	@return SoundEntity - The SoundEntity instance after resetting.

	Resets the sound instance to match the original sound definition. This is useful if you want to discard any changes made to the sound's properties or effects and return it to its default state as defined in the sound schema.
]]
function SoundEntity.ResetToDefinition(self: SoundEntity): SoundEntity
	--This should adjust the existing instances incase anything is attached. for now this does nothing!

	return self
end

-------------------------------------------------------------------------------------------------------------------------

--[[
	@method Await
	@within SoundEntity

	@param timeout number? -- Optional timeout in seconds to wait before automatically cleaning up the sound. If not provided, it will wait indefinitely until the sound finishes playing.

	@yields

	Waits for the sound to finish playing or for the specified timeout to elapse before cleaning up the sound instance.
]]
function SoundEntity.Await(self: SoundEntity, timeout: number?)
	if not self._sound.Playing then
		return
	end

	local cleaner = self._cleaner:Extend()
	local waitEvent = cleaner:Add(Instance.new("BindableEvent"))

	--timeout
	cleaner:Add(task.delay(timeout or math.huge, function()
		waitEvent:Fire()
	end))

	--if it ends before the estimated length.
	cleaner:Connect(self._sound.Ended, function()
		waitEvent:Fire()
	end)

	--wait
	waitEvent.Event:Wait()

	cleaner:Clean()
end

--[[
	@method Fork
	@within SoundEntity

	@param thread function(self: SoundEntity) -- The function to run in a new thread, which receives the SoundEntity instance as an argument.

	@return SoundEntity - The SoundEntity instance after starting the new thread.

	Starts a new thread to run the provided function, allowing you to perform concurrent operations on the sound while it is playing. The thread will be automatically cleaned up when the sound is cleaned up.	
]]
function SoundEntity.Fork(self: SoundEntity, thread: (self: SoundEntity) -> ()): SoundEntity
	self._cleaner:Add(task.spawn(function()
		thread(self)
	end))

	return self
end

--[[
	@method Sleep
	@within SoundEntity

	@yields

	@param time number -- The amount of time in seconds to wait.

	@return SoundEntity - The SoundEntity instance after waiting.

	Waits for the specified amount of time before resuming. This can be used to create delays in sound sequences or effects.
]]
function SoundEntity.Sleep(self: SoundEntity, time: number): SoundEntity
	task.wait(time)

	return self
end

--[[
	@method Reset
	@within SoundEntity

	@return SoundEntity - The SoundEntity instance after resetting.

	Stops and Replays the sound from the beginning. This is useful for quickly restarting a sound without having to create a new SoundEntity instance.
]]
function SoundEntity.Reset(self: SoundEntity): SoundEntity
	self:Stop():Play()

	return self
end

--[[
	@method PlayOnce
	@within SoundEntity

	Plays the sound and automatically cleans it up after it finishes. This is useful for one-off sound effects that don't need to be reused.
]]
function SoundEntity.PlayOnce(self: SoundEntity)
	task.spawn(function()
		self:Play():Await()

		self:Cleanup()
	end)
end

--[[
	@method Cleanup
	@within SoundEntity

	Cleans up the Instance.
]]
function SoundEntity.Cleanup(self: SoundEntity)
	self._cleaner:Clean()
end

------------------------------------------------------------------------------------------------------------------------
--[Regular Sound Methods]-----------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function SoundEntity.Play(self: SoundEntity): SoundEntity
	self._sound:Play()
	return self
end

function SoundEntity.Pause(self: SoundEntity): SoundEntity
	self._sound:Pause()
	return self
end

function SoundEntity.Resume(self: SoundEntity): SoundEntity
	self._sound:Resume()
	return self
end

function SoundEntity.Stop(self: SoundEntity): SoundEntity
	self._sound:Stop()
	return self
end

------------------------------------------------------------------------------------------------------------------------
--[Regular Sound Properties]--------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function SoundEntity.SetParent(self: SoundEntity, parent: Instance): SoundEntity
	self._sound.Parent = parent
	return self
end

function SoundEntity.SetLooped(self: SoundEntity, looped: boolean): SoundEntity
	self._sound.Looped = looped
	return self
end

function SoundEntity.SetArchivable(self: SoundEntity, archivable: boolean): SoundEntity
	self._sound.Archivable = archivable
	return self
end

function SoundEntity.SetPlayOnRemove(self: SoundEntity, playOnRemove: boolean): SoundEntity
	self._sound.PlayOnRemove = playOnRemove
	return self
end

function SoundEntity.SetLoopRegion(self: SoundEntity, loopRegion: NumberRange): SoundEntity
	self._sound.LoopRegion = loopRegion
	return self
end

function SoundEntity.SetPlaybackRegion(self: SoundEntity, region: NumberRange): SoundEntity
	self._sound.PlaybackRegion = region
	return self
end

function SoundEntity.SetPlaybackRegionsEnabled(self: SoundEntity, enabled: boolean): SoundEntity
	self._sound.PlaybackRegionsEnabled = enabled
	return self
end

function SoundEntity.SetPlaybackSpeed(self: SoundEntity, speed: number): SoundEntity
	self._sound.PlaybackSpeed = speed
	return self
end

function SoundEntity.SetRollOffMaxDistance(self: SoundEntity, maxDistance: number): SoundEntity
	self._sound.RollOffMaxDistance = maxDistance
	return self
end

function SoundEntity.SetRollOffMinDistance(self: SoundEntity, minDistance: number): SoundEntity
	self._sound.RollOffMinDistance = minDistance
	return self
end

function SoundEntity.SetRollOffMode(self: SoundEntity, rollOffMode: Enum.RollOffMode): SoundEntity
	self._sound.RollOffMode = rollOffMode
	return self
end

function SoundEntity.SetSoundGroup(self: SoundEntity, soundGroup: SoundGroup): SoundEntity
	self._sound.SoundGroup = soundGroup
	return self
end

function SoundEntity.SetTimePosition(self: SoundEntity, timePosition: number): SoundEntity
	self._sound.TimePosition = timePosition
	return self
end

function SoundEntity.SetVolume(self: SoundEntity, volume: number): SoundEntity
	self._sound.Volume = volume
	return self
end

------------------------------------------------------------------------------------------------------------------------

return SoundEntity
