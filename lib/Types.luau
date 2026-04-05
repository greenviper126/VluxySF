--!strict

------------------------------------------------------------------------------------------------------------------------

type Dictionary<T> = { [string]: T }

------------------------------------------------------------------------------------------------------------------------

export type SoundEffectDefinition = Dictionary<any>

export type SoundEffectDefinitions = Dictionary<SoundEffectDefinition>

export type SoundProperties = Sound

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

------------------------------------------------------------------------------------------------------------------------

type Sound = {
	AcousticSimulationEnabled: boolean,
	AudioContent: string,
	ChannelCount: number,
	EmitterSize: number,
	IsLoaded: boolean,
	IsMutedForCapture: boolean,
	IsPaused: boolean,
	IsPlaying: boolean,
	IsSpatial: boolean,
	LoopRegion: number,
	Looped: boolean,
	MaxDistance: number,
	MinDistance: number,
	Pitch: number,
	PlayOnRemove: boolean,
	PlaybackLoudness: number,
	PlaybackRegion: number,
	PlaybackRegionsEnabled: boolean,
	PlaybackSpeed: number,
	Playing: boolean,
	PlayingReplicator: any,
	RollOffGain: number,
	RollOffMaxDistance: number,
	RollOffMinDistance: number,
	RollOffMode: Enum.RollOffMode,
	SoundGroup: string,
	SoundId: string,
	TimeLength: number,
	TimePosition: number,
	TimePositionReplicator: any,
	UsageContextPermission: any,
	Volume: number,
	isPlaying: boolean,
	xmlRead_MaxDistance_3: number,
	xmlRead_MinDistance_3: number,
	Archivable: boolean,
	Attributes: Dictionary<any>,
	AttributesReplicate: Dictionary<any>,
	AttributesSerialize: Dictionary<any>,
	Capabilities: Dictionary<any>,
	DataCost: number,
	DefinesCapabilities: Dictionary<any>,
	HistoryId: string,
	Name: string,
	Parent: Instance,
	PredictionMode: Enum.PredictionMode,
	PropertyStatusStudio: any,
	RobloxLocked: boolean,
	Sandboxed: boolean,
	SourceAssetId: string,
	Tags: { [string]: any },
	UniqueId: string,
	archivable: boolean,
	numExpectedDirectChildren: number,
	ClassName: string,
	className: string,
}

return nil
