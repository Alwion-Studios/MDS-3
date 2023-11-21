local RS = game:GetService("ReplicatedStorage")
local Promise = require(RS.Packages.Promise)

local TableFunctions = {}

--Promise Type
export type Promise = typeof(Promise.new(function() end))

local function FindAndEdit(data, key, value) 
    local toReturn = table.clone(data)

    for name, keyValue in toReturn do 
        if name == key then toReturn[name] = value return true end
        if typeof(value) == "table" then return FindAndEdit(keyValue, key, value) end
    end

    return toReturn
end

--[[ CREDIT TO SLEITNICK AND HIS TableUtil Module 
    Review @ https://github.com/Sleitnick/RbxUtil/]]
local function DeepCopy(t)
    local copy = table.clone(t)
    for name, value in copy do 
        if type(value) == "table" then copy[name] = DeepCopy(value) end
    end
    return copy
end

--[[ CREDIT TO SLEITNICK AND HIS TableUtil Module 
    Review @ https://github.com/Sleitnick/RbxUtil/]]
local function Sync(data, template) 
    local toReturn = table.clone(data)

    for name, value in template do
		local source = data[name]
		if source == nil then
			if type(value) == "table" then
				toReturn[name] = DeepCopy(value)
			else
				toReturn[name] = value
			end
		elseif type(source) == "table" then
			if type(value) == "table" then
				toReturn[name] = Sync(source, value)
			else
				toReturn[name] = DeepCopy(source)
			end
		end
	end

    return toReturn
end

local function Find(data, key) 
    local toReturn = table.clone(data)

    for name, value in toReturn do 
        if name == key then return toReturn[name]
        elseif typeof(value) == "table" then return Find(value, key) end
    end

    return toReturn
end

TableFunctions.DeepCopy = DeepCopy
TableFunctions.Sync = Sync
TableFunctions.FindAndEdit = FindAndEdit
TableFunctions.Find = Find

return TableFunctions