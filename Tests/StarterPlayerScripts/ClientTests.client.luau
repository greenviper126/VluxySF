--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VluxySF = require(ReplicatedStorage.VluxySF)

VluxySF._initClient()

--tests

--print(VluxySF._getSchema())
--print(VluxySF.GetSoundGroup("Game"), VluxySF.GetSoundGroups(), VluxySF.GetSoundGroupNames())
--print(VluxySF.GetSoundLocations(), VluxySF.GetSoundDefinitions())

--sound class
local endingMusic = VluxySF.Create("MUSIC/Ending/endingMusic")
	:SetLooped(true)
	:SetPlaybackSpeed(VluxySF.Variance()())
	:Fork(function(self)
		self:Play():Sleep(10):FadeTo(2, 5):Sleep(10):FadeOut(3):Sleep(3):Reset():SetVolume(0.5)
	end)

task.wait(5)

--direct sound manipulation
local ambience1 = VluxySF.ConstructSoundFromName("MUSIC/Mystification2")
if ambience1 then
	--print(VluxySF.GetEstimatedPlayLength(ambience1))
	ambience1:Play()

	task.wait(3)

	--print(VluxySF.GetEstimatedPlayLength(ambience1))
end

local h = endingMusic:Clone()
h._sound.Name = "Hello"

h:SetPlaybackSpeed(3):Play()

task.wait(5)

endingMusic:Cleanup()

task.wait(5)

local f = h:Extend()
f._sound.Name = "HellNO"
f:Play()

task.wait(5)

h:Cleanup()
