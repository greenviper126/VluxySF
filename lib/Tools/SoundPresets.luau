--!strict

------------------------------------------------------------------------------------------------------------------------

local library = script.Parent.Parent

local Jitter = require(library.Utility.Jitter)

--[=[
    @class SoundPresets

	A collection of preset functions for applying common sound effects, such as jitter, to Sound instances. These presets can be easily applied to sounds to achieve dynamic and natural variations in sound playback.
]=]
local SoundPresets = {}

--[=[
	@within SoundPresets

	@param center number? -- The central value around which the jitter will occur (default: 1).
	@param spread number? -- The maximum deviation from the center value (default: 0.1).
	@param parent Instance? -- The parent instance to which the sound will be attached after applying the preset.

	@return (Sound) -> () -- A preset function that applies natural jitter to a sound's volume and playback speed, creating more dynamic and less repetitive audio effects.

	applys a unitLog jitter to volume and pitch with an option to set the parent.
]=]
function SoundPresets.NaturalJitter(center: number?, spread: number?, parent: Instance?): (Sound) -> ()
	local jitter = Jitter.UnitLog(center or 1, spread or 0.1)

	return function(sound: Sound)
		sound.Volume *= jitter()
		sound.PlaybackSpeed *= jitter()

		sound.Parent = parent
	end
end

--[=[
	@within SoundPresets

	@param center number? -- The central value around which the jitter will occur (default: 1).
	@param spread number? -- The maximum deviation from the center value (default: 0.1).
	@param parent Instance? -- The parent instance to which the sound will be attached after applying the preset.

	@return (Sound) -> () -- A preset function that applies random jitter to a sound's volume and playback speed, creating more dynamic and less repetitive audio effects.

	applys a random jitter to volume and pitch with an option to set the parent.
]=]
function SoundPresets.RandomJitter(center: number?, spread: number?, parent: Instance?): (Sound) -> ()
	local jitter = Jitter.Default(center or 1, spread or 0.1)

	return function(sound: Sound)
		sound.Volume *= jitter()
		sound.PlaybackSpeed *= jitter()

		sound.Parent = parent
	end
end

return SoundPresets
