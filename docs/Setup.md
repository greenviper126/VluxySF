---
sidebar_position: 3
---


# Initialization

To start using VluxySF, you must initialize the package on both the server and the client. This ensures all sound data is available and ready for use.

---

## 1. Setting Up the Sound Folder

First, create a Configuration (commonly named `SOUNDS`) containing all your sound instances. For details on organizing this folder, see [Folder Setup](/docs/FolderSetup).

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
VluxySF.Startup.InitServer(soundFolder)

-- <--schema can be used here
```

---

## 3. Client Initialization

On the client, simply call the initialization function:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VluxySF = require(ReplicatedStorage.Packages.VluxySF)

-- Initialize the client
VluxySF.Startup.InitClient()

-- <--schema can be used here
```

## 4. Basic Use

When using this library in another module from where it was initialized from you need to wait for the schema

```lua
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local VluxySF = require(ReplicatedStorage.Packages.VluxySF)

    -- wait for schema to be ready
    VluxySF.Startup.WaitForSchema()

    -- <--schema can be used here
```

## 4. Advanced Use

You can also use this library in a more Unity styled way.

This method doesnt need `WaitForSchema()` to function as long as all Inits fully run before all Starts run.
*You will have to make your own system to achieve this, this is commonly done through a module loader!*

*server init module*
```lua
    local ServerStorage = game:GetService("ServerStorage")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local VluxySF = require(ReplicatedStorage.Packages.VluxySF)

    -- Reference to the folder/config of the actual sounds you want to use
    local soundFolder = ServerStorage:FindFirstChild("SOUNDS")

    local Orchestrator = {}

    Orchestrator.Init = function()
        VluxySF.Startup.InitServer(SOUNDS)
    end

    Orchestrator.Start = function()
        -- <--schema can be used here
    end

    return Orchestrator
```

*client init module*
```lua
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local VluxySF = require(ReplicatedStorage.Packages.VluxySF)

    local Orchestrator = {}

    Orchestrator.Init = function()
        VluxySF.Startup.InitClient() <--yeilds until ready
    end

    Orchestrator.Start = function()
        -- <--schema can be used here
    end

    return Orchestrator
```

*new client module*
```lua
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local VluxySF = require(ReplicatedStorage.Packages.VluxySF)

    local Orchestrator = {}

    Orchestrator.Start = function()
        -- <--schema can be used here
    end

    return Orchestrator
```

---
