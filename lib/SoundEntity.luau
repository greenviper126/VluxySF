--!strict

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Properties = require(ReplicatedStorage.VluxySF.Utility.Properties)
local Tables = require(script.Parent.Utility.Tables)
local Trove = require(script.Parent.Utility.Trove)
local Types = require(script.Parent.Types)

local SoundTools = require(script.Parent.SoundTools)

--[=[
	@within SoundEntity
	@type PreloadCallback (assetId: string, assetFetchStatus: Enum.AssetFetchStatus) -> ()

	Callback function that PreLoadAsync uses.
]=]
type PreloadCallback = (assetId: string, assetFetchStatus: Enum.AssetFetchStatus) -> ()

--[=[
	@within SoundEntity
	@type EventCallback (v1: any, v2: any) -> ()

	Generic callback function for events. The parameters passed to the callback will depend on the specific event being listened to.
]=]
type EventCallback = (v1: any, v2: any) -> ()

--[=[
	@within SoundEntity
	@type InstanceEventTypes "Changed" | "AncestryChanged" | "AttributeChanged" | "ChildAdded" | "ChildRemoved" | "DescendantAdded" | "DescendantRemoving" | "Destroying" | "StyledPropertiesChanged"

	List of instance event types.
]=]
type InstanceEventTypes =
	"Changed"
	| "AncestryChanged"
	| "AttributeChanged"
	| "ChildAdded"
	| "ChildRemoved"
	| "DescendantAdded"
	| "DescendantRemoving"
	| "Destroying"
	| "StyledPropertiesChanged"

--[=[
	@within SoundEntity
	@type SoundEventTypes "DidLoop" | "Ended" | "Loaded" | "Paused" | "Played" | "Resumed" | "Stopped"

	List of sound event types.
]=]
type SoundEventTypes = "DidLoop" | "Ended" | "Loaded" | "Paused" | "Played" | "Resumed" | "Stopped"

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
		self._soundDefinition = Tables.DeepClone(sound)

		self.soundName = self._soundDefinition.Properties.Name
		self._sound = SoundTools.CreateSound(SoundEntity.SoundSchema, self._soundDefinition)
	end

	self._cleaner:AttachToInstance(self._sound)

	return self
end

--[=[
	@method GetRawSound
	@within SoundEntity

	@return Sound -- The raw Sound instance created by this SoundEntity.

	Provides access to the underlying Sound instance for advanced manipulation or retrieval of properties.]=]
function SoundEntity.GetRawSound(self: SoundEntity): Sound
	return self._sound
end

--[=[
	@method ResetToDefinition
	@within SoundEntity

	@return SoundEntity

	Resets the sound instance to match the original sound definition.
]=]
function SoundEntity.ResetToDefinition(self: SoundEntity): SoundEntity
	for property, value in pairs(self._soundDefinition.Properties) do
		Properties.ApplyPropertyValueToInstance(self._sound, property, value)
	end

	self._sound:ClearAllChildren()

	for class, properties in pairs(self._soundDefinition.Effects) do
		local newClass = Instance.new(class)

		for property, value in pairs(properties) do --create new child class
			Properties.ApplyPropertyValueToInstance(newClass, property, value)
		end

		newClass.Parent = self._sound
	end

	return self
end

--[=[
	@method Fork
	@within SoundEntity

	@param thread function(self: SoundEntity) -- The function to run in a new thread, which receives the SoundEntity instance as an argument.

	@return SoundEntity

	Starts a new thread to run the provided function, allowing you to perform concurrent operations on the sound while it is playing.	
]=]
function SoundEntity.Fork(self: SoundEntity, thread: (self: SoundEntity) -> ()): SoundEntity
	self._cleaner:Add(task.spawn(function()
		thread(self)
	end))

	return self
end

--[=[
	@method Preload
	@within SoundEntity

	@yields

	@param callback PreloadCallback? -- Optional callback to handle the sound successfully preloading or failing to preload.

	@return SoundEntity

	Preloads the sound's audio asset to reduce latency when it is first played. This applies to all future sounds with the same assetId.

	Doing this increases memory usage on the client and is not reversible. Only use if needed!
]=]
function SoundEntity.Preload(self: SoundEntity, callback: PreloadCallback?): SoundEntity
	local realCallback = callback
		or function(assetId, assetFetchStatus)
			if assetFetchStatus == Enum.AssetFetchStatus.Success then
				return
			end

			warn(`Sound with assetId {assetId} failed to preload with status {assetFetchStatus} !`)
		end

	ContentProvider:PreloadAsync({ self._sound }, realCallback)

	return self
end

--[=[
	@method Sleep
	@within SoundEntity

	@yields

	@param time number -- The amount of time in seconds to wait.

	@return SoundEntity

	Waits for the specified amount of time before resuming. This can be used to create delays in sound sequences or effects.
]=]
function SoundEntity.Sleep(self: SoundEntity, time: number): SoundEntity
	task.wait(time)

	return self
end

--[=[
	@method RunCustom
	@within SoundEntity

	@yields

	@param func function(self: SoundEntity) -- The custom function to run.

	Runs a custom function of your choice if code needs to run in a certain sequence.
]=]
function SoundEntity.RunCustom(self: SoundEntity, func: (self: SoundEntity) -> ()): SoundEntity
	func(self)

	return self
end

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
	@method PlayWhenLoaded
	@within SoundEntity

	@yields

	@return SoundEntity

	Plays the sound when it is fully loaded.
]=]
function SoundEntity.PlayWhenLoaded(self: SoundEntity): SoundEntity
	if self._sound.IsLoaded then
		self:Play()
		return self
	end

	self._cleaner:Add(function()
		self._sound.Loaded:Wait()

		self:Play()
	end)

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
	@method Reset
	@within SoundEntity

	@return SoundEntity

	Stops and Replays the sound from the beginning. This is useful for quickly restarting a sound without having to create a new SoundEntity instance.
]=]
function SoundEntity.Reset(self: SoundEntity): SoundEntity
	self:Stop():Play()

	return self
end

--[=[
	@method Clone
	@within SoundEntity

	@return SoundEntity -- A new SoundEntity instance with the same properties and effects as the original.

	Creates a clone of the SoundEntity, allowing you to create multiple instances of the same sound definition without modifying the original.
]=]
function SoundEntity.Clone(self: SoundEntity): SoundEntity
	return SoundEntity.new(self._soundDefinition)
end

--[=[
	@method Extend
	@within SoundEntity

	@return SoundEntity -- A new SoundEntity instance with the same properties and effects as the original.

	Makes a clone that is connected to the original SoundEntity. If the original is cleaned up so is this instance.
]=]
function SoundEntity.Extend(self: SoundEntity): SoundEntity
	local clone = self:Clone()

	self._cleaner:Add(function()
		clone:Cleanup()
	end)

	return clone
end

--[=[
	@method Cleanup
	@within SoundEntity

	Cleans up the Instance.
]=]
function SoundEntity.Cleanup(self: SoundEntity)
	self._sound:Destroy() --trove is attached
end

--[=[
	@method Destroy
	@within SoundEntity

	Alias for Cleanup. Cleans up the Instance.
]=]
function SoundEntity.Destroy(self: SoundEntity)
	self:Cleanup()
end

------------------------------------------------------------------------------------------------------------------------
--[Volume Transitions]--------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--[=[
	@method FadeToRaw
	@within SoundEntity

	@tag VolumeFade

	@param volume number -- The target volume to fade to.
	@param tweenInfo TweenInfo -- The TweenInfo object defining the duration and easing style of the fade.

	@return SoundEntity

	Fades the sound's volume to the specified level over time using a tween.
]=]
function SoundEntity.FadeToRaw(self: SoundEntity, volume: number, tweenInfo: TweenInfo): SoundEntity
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
	@method FadeTo
	@within SoundEntity

	@tag VolumeFade

	@param volume number -- The target volume to fade to.
	@param time number? -- The duration of the fade in seconds. Defaults to 1 second if not provided.
	@param style Enum.EasingStyle? -- Optional easing style for the fade. Defaults to Sine if not provided.
	@param direction Enum.EasingDirection? -- Optional easing direction for the fade. Defaults to Out if not provided.

	@return SoundEntity

	Similar to FadeToRaw but does not need tweenInfo to be passed in.
]=]
function SoundEntity.FadeTo(
	self: SoundEntity,
	volume: number,
	time: number?,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
): SoundEntity
	local tweenInfo = TweenInfo.new(time or 1, style or Enum.EasingStyle.Sine, direction or Enum.EasingDirection.Out)
	self:FadeToRaw(volume, tweenInfo)

	return self
end

--[=[
	@method FadeIn
	@within SoundEntity

	@tag VolumeFade

	@param time number -- The duration of the fade in seconds.
	@param style Enum.EasingStyle? -- Optional easing style for the fade. Defaults to Sine.

	@return SoundEntity

	Fades the sound's volume up from 0 to its defined volume over the specified duration using a tween.
]=]
function SoundEntity.FadeIn(self: SoundEntity, time: number, style: Enum.EasingStyle?): SoundEntity
	local volume = self._soundDefinition.Properties.Volume --the real sound can have a different volume if it was already fading
	local tweenInfo = TweenInfo.new(time, style or Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	self._sound.Volume = 0
	self:FadeToRaw(volume, tweenInfo)

	return self
end

--[=[
	@method FadeOut
	@within SoundEntity

	@tag VolumeFade

	@param time number -- The duration of the fade out in seconds.
	@param style Enum.EasingStyle? -- Optional easing style for the fade out. Defaults to Sine.

	@return SoundEntity

	Fades the sound's volume down to 0 over the specified duration using a tween.
]=]
function SoundEntity.FadeOut(self: SoundEntity, time: number, style: Enum.EasingStyle?): SoundEntity
	local volume = self._sound.Volume --the real sound can have a different volume if it was already fading
	local tweenInfo = TweenInfo.new(time, style or Enum.EasingStyle.Sine, Enum.EasingDirection.In)

	self._sound.Volume = volume
	self:FadeToRaw(0, tweenInfo)

	return self
end

--[=[
	@method FadeStop
	@within SoundEntity

	@tag VolumeFade

	@return SoundEntity

	Stops any active volume tween and retains the current volume level.
]=]
function SoundEntity.FadeStop(self: SoundEntity): SoundEntity
	if self._fadeCleaner then
		self._fadeCleaner:Clean()
		self._fadeCleaner = nil :: any
	end

	return self
end

------------------------------------------------------------------------------------------------------------------------
--[Regular Sound Methods]-----------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--[=[
	@method Play
	@within SoundEntity
	@tag SoundMethod

	@return SoundEntity

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

	@return SoundEntity

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

	@return SoundEntity

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

	@return SoundEntity

	Stops the sound.
]=]
function SoundEntity.Stop(self: SoundEntity): SoundEntity
	self._sound:Stop()
	return self
end

--[=[
	@method ListenToSound
	@within SoundEntity

	@param eventType SoundEventTypes -- The type of sound event to listen to.
	@param func SoundEventCallback -- The callback function to execute when the event occurs.

	@return Trove

	Listens to a specific event on the Sound instance and executes the provided callback function when the event occurs.
]=]
function SoundEntity.Listen(
	self: SoundEntity,
	eventType: SoundEventTypes | InstanceEventTypes,
	func: EventCallback
): Trove.Trove
	local cleaner = self._cleaner:Extend()

	local soundInstance = self._sound :: any --fix type error
	cleaner:Connect(soundInstance[eventType], func)

	return cleaner
end

------------------------------------------------------------------------------------------------------------------------
--[Regular Sound Properties]--------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--[=[
	@method SetParent
	@within SoundEntity
	@tag SoundProperty

	@param parent Instance -- The new parent for the sound.

	@return SoundEntity

	Sets the parent property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the Looped property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the Archivable property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the PlayOnRemove property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the LoopRegion property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the PlaybackRegion property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the PlaybackRegionsEnabled property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the PlaybackSpeed property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the RollOffMaxDistance property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the RollOffMinDistance property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the RollOffMode property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the SoundGroup property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the TimePosition property of the underlying Sound instance.
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

	@return SoundEntity

	Sets the Volume property of the underlying Sound instance.
]=]
function SoundEntity.SetVolume(self: SoundEntity, volume: number): SoundEntity
	self._sound.Volume = volume
	return self
end

------------------------------------------------------------------------------------------------------------------------

return SoundEntity
