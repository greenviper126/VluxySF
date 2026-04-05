---
sidebar_position: 1
---

# Getting Started

VluxySF can be acquired using [Wally](https://wally.run/), a package manager for Roblox.

## Wally Configuration
Once Wally is installed, run `wally init` on your project directory, and then add VluxySF as a dependency. For example, the following could be a `wally.toml` file for a project that includes a few of these modules:
```toml
[package]
name = "your_name/your_project"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
VluxySF = "greenviper126/VluxySF@^1"
```

To install this dependency, run `wally install` within your project. Wally will create a Package folder in your directory with the installed dependency.

## Rojo Configuration
The Package folder created by Wally should be synced into Roblox Studio through your Rojo configuration. For instance, a Rojo configuration might have the following entry to sync the Packages folder into ReplicatedStorage:
```json
{
	"name": "vluxysf",
	"tree": {
		"$className": "DataModel",
		"ReplicatedStorage": {
			"$className": "ReplicatedStorage",
			"Packages": {
				"$path": "Packages"
			}
		}
	}
}
```

## Setup
In order to start using VluxySF you need to initialize the package on both the server and client.

### SoundFolder

In order to setup the soundFolder see this page [Configuring Sounds](/docs/soundSetup)

### Server

On the server you are required to inject the config/folder location of all your instanced sounds. This Folder should be located on the server.

```lua
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VluxySF = require(ReplicatedStorage.Packages.VluxySF)

--folder/config of the actual sounds you want to use.
local soundFolder = ServerStorage:FindFirstChild("SOUNDS")

--initialize the server
VluxySF._initServer(soundFolder)
```

### Client

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VluxySF = require(ReplicatedStorage.Packages.VluxySF)

--initialize the client
VluxySF._initClient()
```
