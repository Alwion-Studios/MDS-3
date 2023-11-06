local RS = game:GetService("ReplicatedStorage")

local TableFunctions = {}

function TableFunctions.FindAndEdit(path, data, key, value) 
    local toReturn = table.clone(data)

    local function scan(tbl) 
        local scanReturn = table.clone(tbl)

        for scannedName, _ in tbl do 
            local source = tbl[scannedName]

            if source[key] then 
                print(`{key} Found`)
                source[key] = value
                print(`{key} Set to {value}`)
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
function TableFunctions.DeepCopy(t)
    local copy = table.clone(t)
    for name, value in copy do 
        if type(value) == "table" then copy[name] = TableFunctions.DeepCopy(value) end
    end
    return copy
end

--[[ CREDIT TO SLEITNICK AND HIS TableUtil Module 
    Review @ https://github.com/Sleitnick/RbxUtil/]]
function TableFunctions.Sync(data, template) 
    local toReturn = table.clone(data)

    for name, value in template do
		local source = data[name]
		if source == nil then
			if type(value) == "table" then
				toReturn[name] = TableFunctions.DeepCopy(value)
			else
				toReturn[name] = value
			end
		elseif type(source) == "table" then
			if type(value) == "table" then
				toReturn[name] = TableFunctions.Sync(source, value)
			else
				toReturn[name] = TableFunctions.DeepCopy(source)
			end
		end
	end

    return toReturn
end

function TableFunctions.Find(path, data, key) 
    local function scan(tbl) 
        for scannedName, _ in tbl do 
            local source = tbl[scannedName]

            if source[key] then 
                print(`{key} Found`)
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

return TableFunctions