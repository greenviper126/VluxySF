--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VluxySF = require(ReplicatedStorage.VluxySF)

VluxySF._initClient()

--tests

print(VluxySF.GetSoundGroup("Game"), VluxySF.GetSoundGroups(), VluxySF.GetSoundGroupNames())
print(VluxySF.GetSoundLocations(), VluxySF.GetSoundDefinitions())

--sound class
local endingMusic = VluxySF.Create("Music/Ending/EndingMusic")
	:SetLooped(true)
	:SetPlaybackSpeed(VluxySF.Variance()())
	:Fork(function(self)
		self:Play():Sleep(10):FadeTo(2, 5):Sleep(10):FadeOut(3):Sleep(3):Reset():SetVolume(0.5)
	end)

task.wait(5)
print(1)

--direct sound manipulation
local ambience1 = VluxySF.ConstructSoundFromName("Music/Mystification 2")
if ambience1 then
	print(VluxySF.GetEstimatedPlayLength(ambience1))
	ambience1:Play()

	task.wait(3)

	print(VluxySF.GetEstimatedPlayLength(ambience1))
end
print(2)

local h = endingMusic:Clone()
h._sound.Name = "Hello"

h:SetPlaybackSpeed(3):Play()

task.wait(5)
print(3)
endingMusic:Cleanup()

task.wait(5)
print(4)

local f = h:Extend()
f._sound.Name = "HellNO"
f:Play()

task.wait(5)
print(5)

h:Cleanup()
