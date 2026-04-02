--!strict

------------------------------------------------------------------------------------------------------------------------

export type Dictionary<T> = { [string]: T }

export type SoundChildren = Dictionary<Dictionary<any>>

------------------------------------------------------------------------------------------------------------------------

--[=[
	@interface SoundTable
	@within Sounds

	.Sound Dictionary<any> -- Serialized sound properties used to reconstruct the main `Sound` instance.
	.Children SoundChildren -- Serialized sound effect children used to reconstruct the main `Sound` instance.

	Serialized sound definition used to reconstruct a `Sound` instance and its effect children.
]=]
export type SoundTable = { Sound: Dictionary<any>, Children: SoundChildren }

--[=[
	@interface VarianceTable
	@within Sounds

	.PlaybackSpeed () -> number -- Callback that returns a randomized playback speed multiplier.
	.Volume () -> number -- Callback that returns a randomized volume multiplier.

	Variance callbacks used to randomize playback speed and volume.
]=]
export type VarianceTable = {
	PlaybackSpeed: () -> number,
	Volume: () -> number,
}

------------------------------------------------------------------------------------------------------------------------

export type SoundData = {
	UnattachedSounds: Configuration,
	SoundGroupContainer: Configuration,
	SoundGroups: Dictionary<SoundGroup>,
	Sounds: Dictionary<SoundTable>,
}

return nil
