---
sidebar_position: 3
---


# Initialization

To start using VluxySF, you must initialize the package on both the server and the client. This ensures all sound data is available and ready for use.

---

## 1. Setting Up the Sound Folder

First, create a Configuration (commonly named `SOUNDS`) containing all your sound instances. For details on organizing this folder, see [Folder Setup](/docs/soundSetup).

---

## 2. Server Initialization

On the server, inject the folder or configuration containing your instanced sounds. This folder should be located in a service like `ServerStorage`.

```lua
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VluxySF = require(ReplicatedStorage.Packages.VluxySF)

-- Reference to the folder/config of the actual sounds you want to use
local soundFolder = ServerStorage:FindFirstChild("SOUNDS")

-- Initialize the server
VluxySF._initServer(soundFolder)
```

---

## 3. Client Initialization

On the client, simply call the initialization function:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VluxySF = require(ReplicatedStorage.Packages.VluxySF)

-- Initialize the client
VluxySF._initClient()
```

---
