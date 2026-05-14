--!strict

local library = script.Parent.Parent

local Converters = require(library.Tools.Converters)

local Types = require(library.Types)

------------------------------------------------------------------------------------------------------------------------

--[=[
	@class Conversions
	
	Functions for converting between Sound instances and SoundDefinitions.
]=]
local Conversions = {}

--[=[
	@within Conversions

	@param sound -- The Sound instance to convert.

	@return SoundDefinition -- The resulting SoundDefinition based on the properties and effects of the provided Sound instance.

	Converts a Roblox Sound instance into a SoundDefinition.
]=]
function Conversions.ToDefinition(sound: Sound): Types.SoundDefinition
	return Converters.SoundToDefinition(sound)
end

--[=[
	@within Conversions

	@param definition SoundDefinition -- The SoundDefinition to convert.

	@return Sound -- The resulting Sound instance based on the properties and effects defined in the provided SoundDefinition.

	Converts a SoundDefinition back into a playable Roblox Sound instance.
]=]
function Conversions.FromDefinition(definition: Types.SoundDefinition): Types.SoundDefinitionInstanced
	return Converters.DefinitionToSound(definition)
end

return Conversions
