--!strict

local ReflectionService = game:GetService("ReflectionService")

--selene: allow(undefined_variable)
local allCapabilities = SecurityCapabilities.new(table.unpack(Enum.SecurityCapability:GetEnumItems()))

------------------------------------------------------------------------------------------------------------------------

--[[
	For setting and fetching Instance properties by table and attributes
]]
local Class = {}

--[[
	Reads an Instance and converts its properties to a table

	@param instance Instance - The instance to pull its properties from

	@return { [string]: any } - Table of all pulled properties
]]
function Class.InstanceToProperties(instance: Instance): { [string]: any }
	local properties = ReflectionService:GetPropertiesOfClass(instance.ClassName, { Security = allCapabilities })

	local tblProperties = {}
	for _, v in ipairs(properties) do
		if not v.Permits.Write or not v.Permits.Read then
			continue
		end

		pcall(function()
			local inst = instance :: any --fix type error
			tblProperties[v.Name] = inst[v.Name]
		end)
	end

	return tblProperties
end

--[[
	Reads attributes from an instance and converts it to a table
	
	@param instance Instance - The instance to pull its attributes from

	@return { [string]: any } - Table of all pulled properties
]]
function Class.AttributesToProperties(instance: Instance): { [string]: any }
	return instance:GetAttributes()
end

--[[
	Applies a value to a property of the instance if one exists
	
	@param instance Instance - The instance to pull its properties from
	@param property string - The name of the property you want to change
	@param value any - The value you want to change the property too

	@return boolean - was applying successful
	@return any - error message
]]
function Class.ApplyPropertyValueToInstance(instance: Instance, property: string, value: any): (boolean, any)
	return pcall(function()
		local inst = instance :: any --fix type error
		inst[property] = value
	end)
end

return Class
