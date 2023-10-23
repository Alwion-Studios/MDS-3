--Types
export type Schema = {
    Name: String,
    AutoSaveInterval: Number,
    DataStore: DataStore,
    Cache: table,
    Options: table
}

-- Variable Types to DataValues
local dataTypes = {
    ["number"] = "NumberValue",
    ["string"] = "StringValue",
    ["boolean"] = "BoolValue"
}

-- Imports
local DS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local MDS = require(script.Parent.Parent.Core)
local Promise = require(script.Parent.Parent.Packages.Promise)

local Schema = {
    autoSaveIteral = 30,
    dataQueue = {},
}
Schema.__index = Schema

function Schema.Create(name, structure, opts): Schema
    return setmetatable({
        Name = name,
        Structure = structure
    }, Schema)
end

return Schema

--[[function SchemaIndex.New(name, datastore, structure, opts)
    if not type(structure) == "table" then error("Defined Data Structure must be a table") end
    if not type(name) == "string" then error("Schema Name must be a string") end
    if #name <= 0 then error("Schema Name must have a character") end

    local self = {}

    self = MDS.CreateSchema({
        Name = name,
        Datastore = DS:GetDataStore(datastore),
        DataStructure = structure,
        Options=opts,
    })

    self.Data = {}

    return setmetatable(self, SchemaIndex)
end

function SchemaIndex:GetUserData(plrID): Promise
    return Promise.new(function(resolve, reject) 
        if not plrID then reject(false) end
        resolve(self.Datastore:GetAsync(plrID))
    end)
end

function SchemaIndex:SetPlayerData(plrID, dataTbl)
    if not self.Data[plrID] then self.Data[plrID] = {} end
    self.Data[plrID] = dataTbl
end

function SchemaIndex:UpdateValue(plrID, dataName, dataValue)
    if self["Options"]["DataStructureLimits"] and self["Options"]["DataStructureLimits"][dataName] then 
        local limits = self["Options"]["DataStructureLimits"][dataName]
        if limits["type"] and type(dataValue) ~= limits["type"] then warn(`[{self.Name}] WARNING: {dataName}'s value type is not valid`) return false end
        if limits["max"] and type(dataValue) == "number" and dataValue >= limits["max"] then warn(`[{self.Name}] WARNING: {dataName} has reached its maximum value`) return false end
        if limits["min"] and type(dataValue) == "number" and dataValue <= limits["min"] then warn(`[{self.Name}] WARNING: {dataName} has reached its minimum value`) return false end
        if limits["max"] and type(dataValue) == "string" and #dataValue >= limits["max"] then warn(`[{self.Name}] WARNING: {dataName} has reached its maximum length`) return false end
        if limits["min"] and type(dataValue) == "string" and #dataValue <= limits["min"] then warn(`[{self.Name}] WARNING: {dataName} has reached its minimum length`) return false end
    end

    if not self.Data[plrID] then self.Data[plrID] = {} end
    if not self.Data[plrID]["data"] then self.Data[plrID]["data"] = {} end

    self.Data[plrID]["data"][dataName] = dataValue

    return true
end

function SchemaIndex:_save(plrID): Promise
    return Promise.new(function(resolve, reject) 
        local currentVersion = self:GetUserData(plrID)["version"]
        self.Datastore:UpdateAsync(plrID, function(oldData)
            if oldData["version"] > currentVersion then
                warn(`[{self.Name}] WARNING: Data has been corrupted or lost!`)
                return oldData
            end

            local newData = oldData
            newData["version"] = oldData["version"]+1 or 1
            newData["data"] = self.Data[plrID]["data"]

            print(`[{self.Name} ({newData["version"]})] Wrote changes to datastore`)
            return newData
        end)
    end)
end

function SchemaIndex:CreateDataValues(plr: Player)
    self:SetPlayerData(plr.UserId, self:GetUserData(plr.UserId))
    if self["Options"]["CreateValueInstances"] then
        local dir = plr:FindFirstChild("PlayerData")
        if not dir then dir = Instance.new("Folder"); dir.Name = "PlayerData"; dir.Parent = plr end
        
        local data = self.Data[plr.UserId]["data"]

        for name, defaultVal in pairs(self.DataStructure) do 
            if not data[name] then 
                print(`[{self.Name} Player's DataStructure has been updated with missing data {name} ({defaultVal})`)
                data[name] = defaultVal 
            end
            continue 
        end
        
        for name, value in pairs(data) do
            if not dataTypes[type(value)] then continue end
            local dataValue = Instance.new(dataTypes[type(value)])

            --Assign the Instance its value and name
            dataValue.Value = value
            dataValue.Name = name
            dataValue.Parent = dir

            --Update Hnadler
            dataValue.Changed:Connect(function(newVal) 
                if self.Data[plr.UserId][name] and newVal == self.Data[plr.UserId][name] then print(`[{self.Name}] CANCELLED: Requested Change for {name} has been cancelled as its new value is the same as its current`) return false end
                if not self:UpdateValue(plr.UserId, name, newVal) then dataValue.Value = value end -- Call built-in Function to Update t
            end)
        end
    end
end

function SchemaIndex:UserDataExists(plr: Player)
    local store

    local success, _ = pcall(function()
        store = self:GetUserData(plr.UserId)
    end)

    if not success or store == nil and self.Data["data"] == nil then return false end
    return true
end

return SchemaIndex]]