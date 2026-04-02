--!strict

------------------------------------------------------------------------------------------------------------------------

local RunService = game:GetService("RunService")

local utility = script.Parent.Parent.Utility

local RemoteFunction = require(utility.RemoteFunction)
local Types = require(utility.Types)

------------------------------------------------------------------------------------------------------------------------

local soundData: Types.SoundData

----------------------------------------------------------------------------------------------------------------

--[[
	Requests SoundData from server.

	@yields

	@return Types.SoundData - The sound data containing unattached sounds, sound groups, and sound tables.
]]
local function getDataForClient(): Types.SoundData
	local remoteFunction = RemoteFunction.new("SoundRequest")
	local response = remoteFunction:Fire()

	if response then
		return response
	else
		warn("Server did not return sounds to local player, re-attempting!")

		task.wait(0.5)

		return getDataForClient()
	end
end

------------------------------------------------------------------------------------------------------------------------

--[[
	ClientSide of the sound system. Handles sound data storage and retrieval for the client.
]]
local ClientData = {}

--[[
    Initializes the client sound system.

	@yields
]]
function ClientData._initClient()
	if RunService:IsServer() then
		error("Cannot initialize client on server!")
	end

	soundData = getDataForClient()
end

--[[
	Retrieves the SoundData.

	@return Types.SoundData - The sound data containing unattached sounds, sound groups, and sound tables.
]]
function ClientData.GetSoundData(): Types.SoundData
	return soundData
end

return ClientData
