--!strict

------------------------------------------------------------------------------------------------------------------------

type Dictionary<T> = { [string]: T }

------------------------------------------------------------------------------------------------------------------------

export type SoundEffectDefinition = Dictionary<any>

export type SoundEffectDefinitions = Dictionary<SoundEffectDefinition>

export type SoundProperties = Dictionary<any>

export type SoundDefinition = {
	Properties: SoundProperties,
	Effects: SoundEffectDefinitions,
}

export type SoundDefinitions = Dictionary<SoundDefinition>

export type SoundGroups = Dictionary<SoundGroup>

export type SoundVariance = {
	PlaybackSpeed: () -> number,
	Volume: () -> number,
}

------------------------------------------------------------------------------------------------------------------------

export type SoundSchema = {
	UnattachedSounds: Configuration,
	SoundGroupContainer: Configuration,
	SoundGroups: SoundGroups,
	SoundDefinitions: SoundDefinitions,
}

return nil
