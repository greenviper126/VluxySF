--!strict
local ContentProvider = game:GetService("ContentProvider")

local libarary = script.Parent.Parent

local Types = require(libarary.Types)

--[[
    Module responsible for preloading sounds based on various identifiers such as sound locations, Sound instances, or SoundDefinitions. Utilizes ContentProvider for efficient preloading.
]]
local Preload = {}

--[[
    Preloads sounds based on a variable number of sound identifiers, which can be sound locations, Sound instances, or SoundDefinitions. Uses ContentProvider for efficient preloading.

    @param ... string | Sound | SoundDefinition -- A variable number of sound identifiers to preload.
]]
function Preload.Selected(...: string | Sound | Types.SoundDefinition)
	local selected = { ... }

	local soundsToPreload = {}
	local soundsToCleanUp = {}

	local function logNonSounds(item: any)
		local sound = Instance.new("Sound")
		sound.Name = "PreloadTempSound"
		sound.Parent = script

		if typeof(item) == "string" then
			sound.SoundId = item
		elseif typeof(item) == "table" then
			sound.SoundId = item.Properties.SoundId
		end

		table.insert(soundsToPreload, sound)
		table.insert(soundsToCleanUp, sound)
	end

	for _, item in ipairs(selected) do
		if typeof(item) == "Instance" and item:IsA("Sound") then
			table.insert(soundsToPreload, item)
		else
			logNonSounds(item)
		end
	end

	ContentProvider:PreloadAsync(soundsToPreload)

	for _, sound in ipairs(soundsToCleanUp) do
		sound:Destroy()
	end
end

return Preload
