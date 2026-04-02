--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Sounds = require(ReplicatedStorage.VluxySF)

local soundConfig = ServerStorage:FindFirstChild("SOUNDS")

Sounds._initServer(soundConfig)
