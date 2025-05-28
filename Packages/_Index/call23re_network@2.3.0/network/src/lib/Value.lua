local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Parent.Signal)
local Symbol = require(script.Parent.Parent.Symbols.Value)
local None = require(script.Parent.Parent.Symbols.None)

local CONTEXT = if RunService:IsServer() then "Server" elseif RunService:IsClient() then "Client" else nil
local VALID_CLASS_TYPES = {"Bool", "BrickColor", "CFrame", "Color3", "Int", "Number", "Object", "Ray", "String", "Vector3"}

local Value = {}
Value.__index = Value

function Value.new(ValueType)
	assert(ValueType, "Value is nil")
	assert(type(ValueType) == "string", "Value must be a string")

	ValueType = ValueType:gsub("%Value", "")
	local MatchingType = table.find(VALID_CLASS_TYPES, ValueType)
	assert(MatchingType, ("Value must be one of: %s"):format(table.concat(VALID_CLASS_TYPES, ", ")))

	local self = setmetatable({}, Value)

	self.ClassName = Symbol
	self._ClassType = ValueType .. "Value"

	return self
end

function Value:__Init(Name, Object)
	if self.Instantiated then return end
	self.Instantiated = true

	self.Name = Name

	if CONTEXT == "Server" then
		function self:Update(newValue)
			if Object.Value == newValue then return end
			Object.Value = newValue
		end
	end

	if CONTEXT == "Client" then
		local newSignal = Signal.new()

		self.Changed = {
			Connect = function(_, ...)
				return newSignal:Connect(...)
			end,
			Wait = function()
				return newSignal:Wait()
			end,
			DisconnectAll = function()
				return newSignal:DisconnectAll()
			end
		}

		Object:GetPropertyChangedSignal("Value"):Connect(function()
			newSignal:Fire(Object.Value)
		end)
	end
end

return Value