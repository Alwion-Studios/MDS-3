-- Imports
local DS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local MDS = require(RS.Packages.MDS.MDS)

local SchemaIndex = {}
SchemaIndex.__index = SchemaIndex

function SchemaIndex.New(name, datastore, structure, createInstances)
    local self = {}

    self = MDS.CreateSchema({
        Name = name,
        Datastore = DS:GetDataStore(datastore),
        DataStructure = structure,
        CreateInstanceValues=createInstances
    })

    return setmetatable(self, SchemaIndex)
end

function SchemaIndex:UpdateValue(plr: Player, dataName, dataValue) 
    self.Datastore:UpdateAsync(plr, function(oldData)
        local newData = oldData
        print(`Updating {dataName} with value {dataValue} ({type(dataValue)})`)
        newData["version"] = oldData["version"]+1 or 1
        newData["data"][dataName] = dataValue
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

--[[function TestSchema:AddToTest(plrId) 
    self.Datastore:UpdateAsync(plrId, function(oldData)
        local newData = {}
        newData["data"] = self["DataTbl"]
        newData["TestValueNum"] += 1
        newData["version"] = oldData["version"]+1 or 1
        return newData
    end)
end]]

return SchemaIndex