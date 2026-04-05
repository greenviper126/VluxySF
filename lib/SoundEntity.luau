--!strict

local TweenService = game:GetService("TweenService")

local Trove = require(script.Parent.Utility.Trove)
local Types = require(script.Parent.Types)

local SoundTools = require(script.Parent.SoundTools)

--[=[
	@class SoundEntity

	@server
	@client

	SoundEntity is a class that represents a sound defined in the sound schema. It provides methods for materializing the sound as a Roblox `Sound` instance, applying properties and effects, and managing its lifecycle.
]=]
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

--[=[
	@within SoundEntity

	@private

	@param soundSchema SoundSchema -- The sound schema to inject.

	Injects the sound schema from the server into the SoundEntity module for use in materializing sounds.
]=]
function SoundEntity._injectSoundSchema(soundSchema: Types.SoundSchema)
	SoundEntity.SoundSchema = soundSchema
end

--[=[
	@function new
	@within SoundEntity

	@param sound string | SoundDefinition -- The name of the sound definition to use or a full sound definition table.

	@return SoundEntity -- A new instance of SoundEntity initialized with the specified sound.

	Constructor
]=]
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

--[=[
	@method Clone
	@within SoundEntity

	@return SoundEntity -- A new SoundEntity instance with the same properties and effects as the original, but with a new underlying Sound instance.

	Creates a clone of the SoundEntity, allowing you to create multiple instances of the same sound definition without modifying the original.
]=]
function SoundEntity.Clone(self: SoundEntity)
	local clonedSoundDefinition = SoundTools.CreateSoundDefinition(self._sound)
	clonedSoundDefinition.Properties.Playing = false
	clonedSoundDefinition.Properties.isPlaying = false
	clonedSoundDefinition.Properties.IsPlaying = false

	return SoundEntity.new(clonedSoundDefinition)
end

--[=[
	@method GetRawSound
	@within SoundEntity

	@return Sound -- The raw Sound instance created by this SoundEntity.

	Provides access to the underlying Sound instance for advanced manipulation or retrieval of properties.]=]
function SoundEntity.GetRawSound(self: SoundEntity): Sound
	return self._sound
end

-------------------------------------------------------------------------------------------------------------------------

--[=[
	@method FadeTo
	@within SoundEntity

	@param volume number -- The target volume to fade to.
	@param tweenInfo TweenInfo -- The TweenInfo object defining the duration and easing style of the fade.

	@return SoundEntity -- The SoundEntity instance after starting the fade.

	Fades the sound's volume to the specified level over time using a tween. If a fade is already in progress, it will be cleaned up before starting the new fade.
]=]
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

--[=[
	@method FadeIn
	@within SoundEntity

	@param time number -- The duration of the fade in seconds.
	@param style Enum.EasingStyle? -- Optional easing style for the fade. Defaults to Sine.

	@return SoundEntity -- The SoundEntity instance after starting the fade in.

	Fades the sound's volume up from 0 to its defined volume over the specified duration using a tween. If a fade is already in progress, it will be cleaned up before starting the new fade.
]=]
function SoundEntity.FadeIn(self: SoundEntity, time: number, style: Enum.EasingStyle?): SoundEntity
	local volume = self._soundDefinition.Properties.Volume --the real sound can have a different volume if it was already fading
	local tweenInfo = TweenInfo.new(time, style or Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	self._sound.Volume = 0
	self:FadeTo(volume, tweenInfo)

	return self
end

--[=[
	@method FadeOut
	@within SoundEntity

	@param time number -- The duration of the fade out in seconds.
	@param style Enum.EasingStyle? -- Optional easing style for the fade out. Defaults to Sine.

	@return SoundEntity -- The SoundEntity instance after starting the fade out.

	Fades the sound's volume down to 0 over the specified duration using a tween. If a fade is already in progress, it will be cleaned up before starting the new fade.
]=]
function SoundEntity.FadeOut(self: SoundEntity, time: number, style: Enum.EasingStyle?): SoundEntity
	local volume = self._sound.Volume --the real sound can have a different volume if it was already fading
	local tweenInfo = TweenInfo.new(time, style or Enum.EasingStyle.Sine, Enum.EasingDirection.In)

	self._sound.Volume = volume
	self:FadeTo(0, tweenInfo)

	return self
end

--[=[
	@method FadeStop
	@within SoundEntity

	@return SoundEntity -- The SoundEntity instance after stopping the fade.

	Stops any active volume tween and retains the current volume level. This allows you to interrupt a fade in progress without resetting the volume to its original level.
]=]
function SoundEntity.FadeStop(self: SoundEntity): SoundEntity
	if self._fadeCleaner then
		self._fadeCleaner:Clean()
		self._fadeCleaner = nil :: any
	end

	return self
end

--[=[
	@method ResetToDefinition
	@within SoundEntity

	@return SoundEntity -- The SoundEntity instance after resetting.

	Resets the sound instance to match the original sound definition. This is useful if you want to discard any changes made to the sound's properties or effects and return it to its default state as defined in the sound schema.
]=]
function SoundEntity.ResetToDefinition(self: SoundEntity): SoundEntity
	--This should adjust the existing instances incase anything is attached. for now this does nothing!

	return self
end

-------------------------------------------------------------------------------------------------------------------------

--[=[
	@method Await
	@within SoundEntity

	@param timeout number? -- Optional timeout in seconds to wait before automatically cleaning up the sound. If not provided, it will wait indefinitely until the sound finishes playing.

	@yields

	Waits for the sound to finish playing or for the specified timeout to elapse before cleaning up the sound instance.
]=]
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

--[=[
	@method Fork
	@within SoundEntity

	@param thread function(self: SoundEntity) -- The function to run in a new thread, which receives the SoundEntity instance as an argument.

	@return SoundEntity -- The SoundEntity instance after starting the new thread.

	Starts a new thread to run the provided function, allowing you to perform concurrent operations on the sound while it is playing. The thread will be automatically cleaned up when the sound is cleaned up.	
]=]
function SoundEntity.Fork(self: SoundEntity, thread: (self: SoundEntity) -> ()): SoundEntity
	self._cleaner:Add(task.spawn(function()
		thread(self)
	end))

	return self
end

--[=[
	@method Sleep
	@within SoundEntity

	@yields

	@param time number -- The amount of time in seconds to wait.

	@return SoundEntity -- The SoundEntity instance after waiting.

	Waits for the specified amount of time before resuming. This can be used to create delays in sound sequences or effects.
]=]
function SoundEntity.Sleep(self: SoundEntity, time: number): SoundEntity
	task.wait(time)

	return self
end

--[=[
	@method Reset
	@within SoundEntity

	@return SoundEntity -- The SoundEntity instance after resetting.

	Stops and Replays the sound from the beginning. This is useful for quickly restarting a sound without having to create a new SoundEntity instance.
]=]
function SoundEntity.Reset(self: SoundEntity): SoundEntity
	self:Stop():Play()

	return self
end

--[=[
	@method PlayOnce
	@within SoundEntity

	Plays the sound and automatically cleans it up after it finishes. This is useful for one-off sound effects that don't need to be reused.
]=]
function SoundEntity.PlayOnce(self: SoundEntity)
	task.spawn(function()
		self:Play():Await()

		self:Cleanup()
	end)
end

--[=[
	@method Cleanup
	@within SoundEntity

	Cleans up the Instance.
]=]
function SoundEntity.Cleanup(self: SoundEntity)
	self._cleaner:Clean()
end

------------------------------------------------------------------------------------------------------------------------
--[Regular Sound Methods]-----------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--[=[
	@method Play
	@within SoundEntity
	@tag SoundMethod

	@return SoundEntity -- The SoundEntity instance after playing.

	Plays the sound.
]=]
function SoundEntity.Play(self: SoundEntity): SoundEntity
	self._sound:Play()
	return self
end

--[=[
	@method Pause
	@within SoundEntity
	@tag SoundMethod

	@return SoundEntity -- The SoundEntity instance after pausing.

	Pauses the sound.
]=]
function SoundEntity.Pause(self: SoundEntity): SoundEntity
	self._sound:Pause()
	return self
end

--[=[
	@method Resume
	@within SoundEntity
	@tag SoundMethod

	@return SoundEntity -- The SoundEntity instance after resuming.

	Resumes the sound if it was paused.
]=]
function SoundEntity.Resume(self: SoundEntity): SoundEntity
	self._sound:Resume()
	return self
end

--[=[
	@method Stop
	@within SoundEntity
	@tag SoundMethod

	@return SoundEntity -- The SoundEntity instance after stopping.

	Stops the sound.
]=]
function SoundEntity.Stop(self: SoundEntity): SoundEntity
	self._sound:Stop()
	return self
end

--[=[
	@method Listen
	@within SoundEntity
	@tag SoundEvent

	@param type "Ended" | "" -- The type of event to listen for. Currently supports "Ended" for when the sound finishes playing.

	@return SoundEntity -- The SoundEntity instance after setting up the listener.

	Sets up an event listener for the specified event type on the sound. This allows you to trigger actions in response to sound events, such as when the sound ends.
]=]
function SoundEntity.Listen(self: SoundEntity, type: "Ended" | ""): SoundEntity
	--for all the events for sounds.

	return self
end

------------------------------------------------------------------------------------------------------------------------
--[Regular Sound Properties]--------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--[=[
	@method SetParent
	@within SoundEntity
	@tag SoundProperty

	@param parent Instance -- The new parent for the sound.

	@return SoundEntity -- The SoundEntity instance after setting the parent.

	Sets the parent of the underlying Sound instance. This allows you to move the sound within the Roblox hierarchy, which can affect how it is heard based on its position relative to the listener and other factors.
]=]
function SoundEntity.SetParent(self: SoundEntity, parent: Instance): SoundEntity
	self._sound.Parent = parent
	return self
end

--[=[
	@method SetLooped
	@within SoundEntity
	@tag SoundProperty

	@param looped boolean -- Whether the sound should loop or not.

	@return SoundEntity -- The SoundEntity instance after setting the looped state.

	Sets whether the sound should loop when it reaches the end. If `true`, the sound will automatically restart from the beginning when it finishes playing.
]=]
function SoundEntity.SetLooped(self: SoundEntity, looped: boolean): SoundEntity
	self._sound.Looped = looped
	return self
end

--[=[
	@method SetArchivable
	@within SoundEntity
	@tag SoundProperty

	@param archivable boolean -- Whether the sound should be archivable.

	@return SoundEntity -- The SoundEntity instance after setting the archivable state.

	Sets whether the sound instance can be archived.
]=]
function SoundEntity.SetArchivable(self: SoundEntity, archivable: boolean): SoundEntity
	self._sound.Archivable = archivable
	return self
end

--[=[
	@method SetPlayOnRemove
	@within SoundEntity
	@tag SoundProperty

	@param playOnRemove boolean -- Whether the sound should play when removed.

	@return SoundEntity -- The SoundEntity instance after setting the play on remove state.

	Sets whether the sound will play when the Sound instance is removed (destroyed or parent set to nil).
]=]
function SoundEntity.SetPlayOnRemove(self: SoundEntity, playOnRemove: boolean): SoundEntity
	self._sound.PlayOnRemove = playOnRemove
	return self
end

--[=[
	@method SetLoopRegion
	@within SoundEntity
	@tag SoundProperty

	@param loopRegion NumberRange -- The loop region range in seconds.

	@return SoundEntity -- The SoundEntity instance after setting the loop region.

	Sets the region of the sound that should loop when Looped is true. This property is only effective when PlaybackRegionsEnabled is true.
]=]
function SoundEntity.SetLoopRegion(self: SoundEntity, loopRegion: NumberRange): SoundEntity
	self._sound.LoopRegion = loopRegion
	return self
end

--[=[
	@method SetPlaybackRegion
	@within SoundEntity
	@tag SoundProperty

	@param region NumberRange -- The playback region range in seconds.

	@return SoundEntity -- The SoundEntity instance after setting the playback region.

	Sets the region of the sound that is allowed to be played. This property is only effective when PlaybackRegionsEnabled is true.
]=]
function SoundEntity.SetPlaybackRegion(self: SoundEntity, region: NumberRange): SoundEntity
	self._sound.PlaybackRegion = region
	return self
end

--[=[
	@method SetPlaybackRegionsEnabled
	@within SoundEntity
	@tag SoundProperty

	@param enabled boolean -- Whether playback regions should be enabled.

	@return SoundEntity -- The SoundEntity instance after setting the playback regions enabled state.

	Enables or disables the use of PlaybackRegion and LoopRegion properties for more granular control over sound playback.
]=]
function SoundEntity.SetPlaybackRegionsEnabled(self: SoundEntity, enabled: boolean): SoundEntity
	self._sound.PlaybackRegionsEnabled = enabled
	return self
end

--[=[
	@method SetPlaybackSpeed
	@within SoundEntity
	@tag SoundProperty

	@param speed number -- The playback speed multiplier.

	@return SoundEntity -- The SoundEntity instance after setting the playback speed.

	Sets the playback speed of the sound. Values higher than 1 play faster, lower values play slower.
]=]
function SoundEntity.SetPlaybackSpeed(self: SoundEntity, speed: number): SoundEntity
	self._sound.PlaybackSpeed = speed
	return self
end

--[=[
	@method SetRollOffMaxDistance
	@within SoundEntity
	@tag SoundProperty

	@param maxDistance number -- The maximum distance in studs.

	@return SoundEntity -- The SoundEntity instance after setting the max distance.

	Sets the maximum distance at which the sound can still be heard. Only applies to sounds parented to a BasePart or Attachment.
]=]
function SoundEntity.SetRollOffMaxDistance(self: SoundEntity, maxDistance: number): SoundEntity
	self._sound.RollOffMaxDistance = maxDistance
	return self
end

--[=[
	@method SetRollOffMinDistance
	@within SoundEntity
	@tag SoundProperty

	@param minDistance number -- The minimum distance in studs.

	@return SoundEntity -- The SoundEntity instance after setting the min distance.

	Sets the minimum distance at which the sound begins to attenuate (decrease in volume). Only applies to sounds parented to a BasePart or Attachment.
]=]
function SoundEntity.SetRollOffMinDistance(self: SoundEntity, minDistance: number): SoundEntity
	self._sound.RollOffMinDistance = minDistance
	return self
end

--[=[
	@method SetRollOffMode
	@within SoundEntity
	@tag SoundProperty

	@param rollOffMode Enum.RollOffMode -- The roll off mode to use.

	@return SoundEntity -- The SoundEntity instance after setting the roll off mode.

	Sets how the sound's volume attenuates based on distance from the listener. Only applies to sounds parented to a BasePart or Attachment.
]=]
function SoundEntity.SetRollOffMode(self: SoundEntity, rollOffMode: Enum.RollOffMode): SoundEntity
	self._sound.RollOffMode = rollOffMode
	return self
end

--[=[
	@method SetSoundGroup
	@within SoundEntity
	@tag SoundProperty

	@param soundGroup SoundGroup -- The sound group to assign.

	@return SoundEntity -- The SoundEntity instance after setting the sound group.

	Assigns the sound to a SoundGroup, which allows grouped volume control and effects management.
]=]
function SoundEntity.SetSoundGroup(self: SoundEntity, soundGroup: SoundGroup): SoundEntity
	self._sound.SoundGroup = soundGroup
	return self
end

--[=[
	@method SetTimePosition
	@within SoundEntity
	@tag SoundProperty

	@param timePosition number -- The time position in seconds.

	@return SoundEntity -- The SoundEntity instance after setting the time position.

	Sets the current playback position of the sound in seconds. Can be used to seek to a specific point in the audio.
]=]
function SoundEntity.SetTimePosition(self: SoundEntity, timePosition: number): SoundEntity
	self._sound.TimePosition = timePosition
	return self
end

--[=[
	@method SetVolume
	@within SoundEntity
	@tag SoundProperty

	@param volume number -- The volume level (0-10).

	@return SoundEntity -- The SoundEntity instance after setting the volume.

	Sets the volume of the sound. Values should be between 0 and 10, where 0 is silent and 10 is maximum volume.
]=]
function SoundEntity.SetVolume(self: SoundEntity, volume: number): SoundEntity
	self._sound.Volume = volume
	return self
end

------------------------------------------------------------------------------------------------------------------------

return SoundEntity
