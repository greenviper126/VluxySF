---
sidebar_position: 4
---



# Folder Setup

VluxySF makes it easy to manage all your game’s sounds with a simple, powerful folder structure. This guide will walk you through the best practices for organizing, grouping, and preloading your audio assets—no manual registration required!

---

## Why Structure Matters

A well-organized sound folder means:

- Instantly accessible sounds by name or group
- Automatic grouping for volume/effect control
- Easy preloading for lag-free playback
- Cleaner, more maintainable projects

---



## The Basics: Folder Structure & SoundGroups

VluxySF uses your folder structure to automatically group and identify sounds.  
**You do not need to manually assign SoundGroups.**

**Legend:**
```
⚙️ = Configuration Instance (Folder/Config at root, becomes a SoundGroup)
📁 = Folder Instance (for organization only)
🔊 = Sound Instance
```

**Example:**
```
SOUNDS⚙️
  ├─ MUSIC⚙️    ← SoundGroup
  │    ├─ mainTheme🔊
  │    └─ battle🔊
  └─ SFX⚙️      ← SoundGroup
        ├─ click🔊
        └─ explosion🔊
```
*Music and SFX become SoundGroups, and their children are grouped accordingly.*

---



### Organizing with Subfolders

You can use additional folders (📁) inside SoundGroups to keep your sounds organized.  
Doing so will effect the location of the sound when fetching.

**Example:**
```
SOUNDS⚙️
  └─ SFX⚙️
      ├─ UI📁
      │    └─ click🔊
      └─ Game📁
          └─ explosion🔊
```

---

---



## Preloading Sounds Automatically

Want certain sounds to be ready instantly?  
Any folder named `_Preload` (with the underscore) will have all its sounds (and subfolders) preloaded automatically on the client.

**How to use:**
```
SOUNDS⚙️
  ├─ MUSIC⚙️
  │    ├─ mainTheme🔊
  │    └─ battle🔊
  └─ SFX⚙️
        ├─ click🔊
        ├─ explosion🔊
        └─ _Preload📁  <-- all children will be preloaded
             ├─ importantSound1🔊
             └─ importantSound2🔊
```
*You can have multiple `_Preload` folders in different SoundGroups if needed.*

**Preload Timeout:**  
You can set an optional timeout (in seconds) for preloading. If preloading takes too long, it will continue in the background. Default is 5 seconds.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VluxySF = require(ReplicatedStorage.Packages.VluxySF)
local preloadTimeout = 10
VluxySF._initClient(preloadTimeout)
```

---


## End Result
![Folder Structure Example](https://github.com/greenviper126/VluxySF/tree/main/static/assets/SoundsConfigExample.png)

## Naming Conventions

- Use UPPER_CASE for SoundGroups
- Use PascalCase for Folders
- Use camelCase  for Sounds
- Avoid spaces and special characters for best compatibility.
- Sound locations are used as keys for programmatic access (e.g., `Sounds.Create("MUSIC/Explosions/explosion1")`).

---


## Configuring Sound Instances

Each Sound instance can be customized with any Roblox sound properties and child sound effects:

- **Properties:** Set properties like `SoundId`, `Volume`, `PlaybackSpeed`, etc., directly on the Sound instance.
- **Effects:** Add child instances such as `EqualizerSoundEffect`, `ReverbSoundEffect`, etc, to the Sound for automatic serialization and reconstruction.

*Adding any children that are not Roblox SoundEffects to a Sound in the SOUNDS config will not be serialized.*

---
