--!strict

------------------------------------------------------------------------------------------------------------------------

local RunService = game:GetService("RunService")

local utility = script.Parent.Parent.Utility

local RemoteFunction = require(utility.RemoteFunction)
local Types = require(utility.Types)

------------------------------------------------------------------------------------------------------------------------

local soundSchema: Types.SoundSchema

----------------------------------------------------------------------------------------------------------------

--[[
	Requests SoundSchema from server.

	@yields

	@return Types.SoundSchema - The sound schema containing unattached sounds, sound groups, and sound definitions.
]]
local function getDataForClient(): Types.SoundSchema
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

	soundSchema = getDataForClient()
end

--[[
	Retrieves the SoundSchema.

	@return Types.SoundSchema - The sound schema containing unattached sounds, sound groups, and sound definitions.
]]
function ClientData.GetSoundSchema(): Types.SoundSchema
	return soundSchema
end

return ClientData
