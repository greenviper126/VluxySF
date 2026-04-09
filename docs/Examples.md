---
sidebar_position: 5
---



# Examples

Explore practical usage patterns for VluxySF. These examples cover basic playback, group volume control, preloading, and advanced sound entity manipulation.

---

## Basic Playback (Client/Server)

Fetch and play a sound instance by name. This works on both client and server.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VluxySF = require(ReplicatedStorage.Packages.VluxySF)

VluxySF.WaitForSchema() -- Wait until schema is loaded

local sound = VluxySF.ConstructSoundFromName("MUSIC/LoFi/beat1") -- waits until sound is loaded
if sound then
    sound:Play()
end
```

*"Music/LoFi/Beat1" is just an example path in your SOUNDS folder.*


---

## Manipulating SoundGroup Volumes

Set the SoundGroup volumes at the start of a session. This can be done on server or client (client is recommended for user settings).


```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VluxySF = require(ReplicatedStorage.Packages.VluxySF)

VluxySF.WaitForSchema()

local masterVolume = 0.8
local subVolumes = {
    ["GAME"] = 0.7,
    ["MUSIC"] = 0.55,
    ["SFX"] = 0.64,
}

local function UpdateSoundGroupVolumes()
    for _, soundGroup in ipairs(VluxySF.GetSoundGroups()) do
        local rawVolume = subVolumes[soundGroup.Name] or 0.5
        local realVolume = rawVolume * masterVolume
        soundGroup.Volume = realVolume
    end
end

UpdateSoundGroupVolumes()
```

*Tip: You can call this function whenever a slider or setting changes to update volumes live.*


---

## Using the SoundEntity

### Simple Use

Create and play a looping sound using the SoundEntity API:


```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VluxySF = require(ReplicatedStorage.VluxySF)

VluxySF.WaitForSchema()

local endingMusic = VluxySF.Create("MUSIC/LoFi/beat1"):SetLooped(true):Play()
```


### _Preload Startup Example

Sometimes you need a sound to be loaded on startup or the first time it’s played. There is no difference in fetching the sound besides the extra child location.


```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VluxySF = require(ReplicatedStorage.VluxySF)

VluxySF.WaitForSchema()

local endingMusic = VluxySF.Create("SFX/Guns/_Preload/shotgunFired1"):PlayOnce()
```


### _Preload SoundEntity Example

Sometimes you don’t know if something needs to be preloaded until the game starts. In that case, you can preload your fetched sound manually:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VluxySF = require(ReplicatedStorage.VluxySF)

VluxySF.WaitForSchema()

-- Preload as soon as possible
local endingMusic = VluxySF.Create("MUSIC/LoFi/beat1"):Preload() -- yields

-- do stuff here

endingMusic:Play() -- this sound plays first try
```


### Yielding on a Separate Thread

If you want to deal with sounds on a separate thread, you can use `Fork`. To clean up any forks, use `RemoveForks`.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VluxySF = require(ReplicatedStorage.VluxySF)

VluxySF.WaitForSchema()

local endingMusic = VluxySF.Create("MUSIC/LoFi/beat1"):Fork(function(self)
    self:Sleep(10):Play() -- sleep method waits for 10 seconds
end)
```

*This waits for 10 seconds and then plays the sound on a separate thread.*

---
