-- Imports
local DS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local MDS = require(RS.Packages.MDS.MDS)

local SchemaIndex = {}
SchemaIndex.__index = SchemaIndex

function SchemaIndex.New(name, datastore, structure, opts)
    if not type(structure) == "table" then error("Defined Data Structure must be a table") end
    if not type(name) == "string" then error("Schema Name must be a string") end
    if #name <= 0 then error("Schema Name must have a character") end

    local self = {}

    self = MDS.CreateSchema({
        Name = name,
        Datastore = DS:GetDataStore(datastore),
        DataStructure = structure,
        DataStructureLimits=opts[2],
        CreateInstanceValues=opts[1],
    })

    return setmetatable(self, SchemaIndex)
end

function SchemaIndex:UpdateValue(plr: Player, dataName, dataValue)
    if self["DataStructureLimits"] and self["DataStructureLimits"][dataName] then 
        local limits = self["DataStructureLimits"][dataName]
        if limits["type"] and type(dataValue) ~= limits["type"] then return warn(`[{self.Name}] WARNING: {dataName}'s value type is not valid`) end
        if limits["max"] and type(dataValue) == "number" and dataValue >= limits["max"] then return warn(`[{self.Name}] WARNING: {dataName} has reached its maximum value`) end
        if limits["min"] and type(dataValue) == "number" and dataValue <= limits["min"] then return warn(`[{self.Name}] WARNING: {dataName} has reached its minimum value`) end
        if limits["max"] and type(dataValue) == "string" and #dataValue >= limits["max"] then return warn(`[{self.Name}] WARNING: {dataName} has reached its maximum length`) end
        if limits["min"] and type(dataValue) == "string" and #dataValue <= limits["min"] then return warn(`[{self.Name}] WARNING: {dataName} has reached its minimum length`) end
    end

    self.Datastore:UpdateAsync(plr, function(oldData)
        local currentVersion = self.Datastore:GetAsync(plr)["version"]

        if oldData["version"] > currentVersion then
            warn(`[{self.Name}] WARNING: Data has been corrupted or lost!`)
            return oldData
        end

        local newData = oldData
        newData["version"] = oldData["version"]+1 or 1
        newData["data"][dataName] = dataValue

        print(`[{self.Name} ({newData["version"]})] Updated {dataName} with value {dataValue} ({type(dataValue)})`)
        return newData
    end)
end

function SchemaIndex:UserDataExists(plr: Player)
    local store

    local success, _ = pcall(function()
        store = self.Datastore:GetAsync(plr.UserId) or nil
    end)

    if not success or store == nil then return false end
    return true
end

return SchemaIndex