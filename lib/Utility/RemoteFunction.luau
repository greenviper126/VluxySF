--!nocheck

--suphi's RemoteFunction module.

------------------------------------------------------------------------------------------------------------------------

local constructor, remoteFunction, remoteFunctions = {}, {}, {}
remoteFunction.__index = remoteFunction

-- Types
export type Constructor = {
	new: (name: string, event: (...any) -> ()?) -> RemoteFunction,
}

export type RemoteFunction = {
	Event: (...any) -> ()?,
	Fire: (self: RemoteFunction, ...any) -> any...,
	Destroy: (self: RemoteFunction) -> (),
}

if game:GetService("RunService"):IsServer() == true then
	-- Server Functions
	local function Fire(event, player, parameter, ...)
		if parameter == nil then
			return
		end
		event:FireClient(player, parameter, ...)
	end

	local function Timeout(self, player)
		local playerThreads = self.Threads[player]
		local thread = table.remove(playerThreads)[2]
		if #playerThreads == 0 then
			self.Threads[player] = nil
		end
		coroutine.resume(thread)
	end

	-- Server Constructor
	function constructor.new(name, event)
		local self = remoteFunctions[name]
		if self == nil then
			self = {}
			self.Name = name
			self.Event = event
			self.Threads = {}
			self.Server = Instance.new("RemoteEvent")
			self.Server.Name = name .. "Server"
			self.Server.Parent = script
			self.Server.OnServerEvent:Connect(function(player, ...)
				local playerThreads = self.Threads[player]
				if playerThreads == nil then
					return
				end
				local threads = table.remove(playerThreads)
				if #playerThreads == 0 then
					self.Threads[player] = nil
				end
				task.cancel(threads[1])
				coroutine.resume(threads[2], ...)
			end)
			self.Client = Instance.new("RemoteEvent")
			self.Client.Name = name .. "Client"
			self.Client.Parent = script
			self.Client.OnServerEvent:Connect(function(player, ...)
				if self.Event ~= nil then
					Fire(self.Client, player, self.Event(player, ...))
				end
			end)
			remoteFunctions[name] = self
			return setmetatable(self, remoteFunction)
		else
			if event ~= nil then
				self.Event = event
			end
			return self
		end
	end

	-- Server RemoteFunction
	function remoteFunction:Fire(player, ...)
		local playerThreads = self.Threads[player]
		if playerThreads == nil then
			playerThreads = {}
			self.Threads[player] = playerThreads
		end
		table.insert(playerThreads, 1, { task.delay(10, Timeout, self, player), coroutine.running() })
		self.Server:FireClient(player, ...)
		return coroutine.yield()
	end

	function remoteFunction:Destroy()
		remoteFunctions[self.Name] = nil
		self.Server:Destroy()
		self.Client:Destroy()
		for player, playerThreads in self.Threads do
			while true do
				local threads = table.remove(playerThreads)
				if threads == nil then
					break
				end
				task.cancel(threads[1])
				task.defer(threads[2])
			end
			self.Threads[player] = nil
		end
	end
else
	-- Client Functions
	local function Fire(event, parameter, ...)
		if parameter == nil then
			return
		end
		event:FireServer(parameter, ...)
	end

	local function Timeout(self)
		coroutine.resume(table.remove(self.Threads)[2])
	end

	-- Client Constructor
	function constructor.new(name, event)
		local self = remoteFunctions[name]
		if self == nil then
			self = {}
			self.Name = name
			self.Event = event
			self.Threads = {}
			self.Server = script:WaitForChild(name .. "Server")
			self.ServerConnection = self.Server.OnClientEvent:Connect(function(...)
				if self.Event ~= nil then
					Fire(self.Server, self.Event(...))
				end
			end)
			self.Client = script:WaitForChild(name .. "Client")
			self.ClientConnection = self.Client.OnClientEvent:Connect(function(...)
				local threads = table.remove(self.Threads)
				if threads == nil then
					return
				end
				task.cancel(threads[1])
				coroutine.resume(threads[2], ...)
			end)
			remoteFunctions[name] = self
			return setmetatable(self, remoteFunction)
		else
			if event ~= nil then
				self.Event = event
			end
			return self
		end
	end

	-- Client RemoteFunction
	function remoteFunction:Fire(...)
		table.insert(self.Threads, 1, { task.delay(10, Timeout, self), coroutine.running() })
		self.Client:FireServer(...)
		return coroutine.yield()
	end

	function remoteFunction:Destroy()
		remoteFunctions[self.Name] = nil
		self.ServerConnection:Disconnect()
		self.ClientConnection:Disconnect()
		while true do
			local threads = table.remove(self.Threads)
			if threads == nil then
				break
			end
			task.cancel(threads[1])
			task.defer(threads[2])
		end
	end
end

return table.freeze(constructor) :: Constructor
