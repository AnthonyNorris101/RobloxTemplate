local RunService = game:GetService("RunService")

local Symbols = script.Parent.Symbols

local EventSymbol = require(Symbols.Event)
local FunctionSymbol = require(Symbols.Function)
local ValueSymbol = require(Symbols.Value)

local DIR = script.Parent
local DIR_NAME_EVENTS = "RemoteEvents"
local DIR_NAME_FUNCTIONS = "RemoteFunctions"
local DIR_NAME_BASE_VALUES = "Values"

local ERROR_NO_EVENT = "RemoteEvent `%s` was not registered"
local ERROR_NO_FUNCTION = "RemoteFunction `%s` was not registered"
local ERROR_NO_BASE_VALUE = "Value `%s` was not registered"
local ERROR_INVALID_KIND = "Invalid remote type registered for key `%s`"

local REMOTES = {
	EVENTS = {},
	FUNCTIONS = {},
	VALUES = {}
}

--[=[
	Registers a dictionary of remotes where the key is the name of the remote and the value is a RemoteEvent or RemoteFunction class.

	```lua
		-- ReplicatedStorage/Remotes.lua
		local Network = require(...Network)
		return Network.Register({
			FooEvent = Network.Event.new(),
			BarFunction = Network.Function.new(),
			BazValue = Network.Value.new("String")
		})
	```

	@class Register
]=]
local function Register(Remotes)
	local RemoteEventsFolder
	local RemoteFunctionsFolder
	local ValuesFolder

	if RunService:IsServer() then

		RemoteEventsFolder = DIR:FindFirstChild(DIR_NAME_EVENTS)
		RemoteFunctionsFolder = DIR:FindFirstChild(DIR_NAME_FUNCTIONS)
		ValuesFolder = DIR:FindFirstChild(DIR_NAME_BASE_VALUES)

		if not RemoteEventsFolder then
			RemoteEventsFolder = Instance.new("Folder")
			RemoteEventsFolder.Name = DIR_NAME_EVENTS
			RemoteEventsFolder.Parent = DIR
		end

		if not RemoteFunctionsFolder then
			RemoteFunctionsFolder = Instance.new("Folder")
			RemoteFunctionsFolder.Name = DIR_NAME_FUNCTIONS
			RemoteFunctionsFolder.Parent = DIR
		end

		if not ValuesFolder then
			ValuesFolder = Instance.new("Folder")
			ValuesFolder.Name = DIR_NAME_BASE_VALUES
			ValuesFolder.Parent = DIR
		end

		for name, class in pairs(Remotes) do
			if class.ClassName == EventSymbol then
				if not REMOTES.EVENTS[name] then
					local remote = Instance.new("RemoteEvent")
					remote.Name = name
					remote.Parent = RemoteEventsFolder

					class:__Init(name, remote)
					REMOTES.EVENTS[name] = class
				end
			elseif class.ClassName == FunctionSymbol then
				if not REMOTES.FUNCTIONS[name] then
					local RequestRemote = Instance.new("RemoteEvent")
					RequestRemote.Name = "Request" .. name
					RequestRemote.Parent = RemoteFunctionsFolder

					local ResponseRemote = Instance.new("RemoteEvent")
					ResponseRemote.Name = "Response" .. name
					ResponseRemote.Parent = RemoteFunctionsFolder

					class:__Init(name, RequestRemote, ResponseRemote)
					REMOTES.FUNCTIONS[name] = class
				end
			elseif class.ClassName == ValueSymbol then
				if not REMOTES.VALUES[name] then
					local remote = Instance.new(class._ClassType)
					remote.Name = name
					remote.Parent = ValuesFolder

					class:__Init(name, remote)
					REMOTES.VALUES[name] = class
				end
			else
				error(ERROR_INVALID_KIND:format(name))
			end
		end
	elseif RunService:IsClient() then
		RemoteEventsFolder = DIR:WaitForChild(DIR_NAME_EVENTS)
		RemoteFunctionsFolder = DIR:WaitForChild(DIR_NAME_FUNCTIONS)
		ValuesFolder = DIR:WaitForChild(DIR_NAME_BASE_VALUES)

		for name, class in pairs(Remotes) do
			if class.ClassName == EventSymbol then
				local remote = RemoteEventsFolder:WaitForChild(name)

				if not REMOTES.EVENTS[name] then
					class:__Init(name, remote)
					REMOTES.EVENTS[name] = class
				end
			elseif class.ClassName == FunctionSymbol then
				local RequestRemote = RemoteFunctionsFolder:WaitForChild("Request" .. name)
				local ResponseRemote = RemoteFunctionsFolder:WaitForChild("Response" .. name)

				if not REMOTES.FUNCTIONS[name] then
					class:__Init(name, RequestRemote, ResponseRemote)
					REMOTES.FUNCTIONS[name] = class
				end
			elseif class.ClassName == ValueSymbol then
				local remote = ValuesFolder:WaitForChild(name)

				if not REMOTES.VALUES[name] then
					class:__Init(name, remote)
					REMOTES.VALUES[name] = class
				end
			else
				error(ERROR_INVALID_KIND:format(name))
			end
		end
	end

	--[=[
		@function GetEvent
		@within Register
		@param name string -- The name of the remote event.
		@return RemoteEvent
	]=]
	local function GetEvent(name)
		local remote = REMOTES.EVENTS[name]
		if not remote then
			error(ERROR_NO_EVENT:format(name))
		end
		return remote
	end

	--[=[
		@function GetFunction
		@within Register
		@param name string -- The name of the remote function.
		@return RemoteFunction
	]=]
	local function GetFunction(name)
		local remote = REMOTES.FUNCTIONS[name]
		if not remote then
			error(ERROR_NO_FUNCTION:format(name))
		end
		return remote
	end

	--[=[
		@function GetValue
		@within Register
		@param name string -- The name of the value.
		@return Value
	]=]
	local function GetValue(name)
		local remote = REMOTES.VALUES[name]
		if not remote then
			error(ERROR_NO_BASE_VALUE:format(name))
		end
		return remote
	end

	return {
		GetEvent = GetEvent,
		GetFunction = GetFunction,
		GetValue = GetValue
	}
end

return Register