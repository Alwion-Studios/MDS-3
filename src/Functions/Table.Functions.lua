local RS = game:GetService("ReplicatedStorage")
local TblUtil = require(RS.Packages.TableUtil)

local TableFunctions = {}

function TableFunctions.FindAndEdit(path, data, key, value) 
    local toReturn = TblUtil.Copy(data, true)

    local function scan(tbl) 
        local scanReturn = TblUtil.Copy(tbl, true)

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

    return toReturn
end

return TableFunctions