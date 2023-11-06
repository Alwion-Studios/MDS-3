local RS = game:GetService("ReplicatedStorage")

local TableFunctions = {}

local function FindAndEdit(path, data, key, value) 
    local toReturn = table.clone(data)

    local function scan(tbl) 
        local scanReturn = table.clone(tbl)

        for scannedName, _ in tbl do 
            local source = tbl[scannedName]

            if source[key] then 
               -- print(`{key} Found`)
                source[key] = value
                --print(`{key} Set to {value}`)
                return true
            end

            for _, directory in path do 
                if source[directory] and type(source[directory]) == "table" then 
                    scanReturn[scannedName] = scan(source)
                end
            end
        end
    end
    scan(toReturn)

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

local function Find(path, data, key) 
    local function scan(tbl) 
        for scannedName, _ in tbl do 
            local source = tbl[scannedName]

            if source[key] then 
                --print(`{key} Found`)
                return source[key]
            end

            for _, directory in path do 
                if source[directory] and type(source[directory]) == "table" then 
                    tbl[scannedName] = scan(source)
                end
            end
        end

        return false
    end

    return scan(data)
end

TableFunctions.DeepCopy = DeepCopy
TableFunctions.Sync = Sync
TableFunctions.FindAndEdit = FindAndEdit
TableFunctions.Find = Find

return TableFunctions