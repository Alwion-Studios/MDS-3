-- Variable Types to DataValues
local dataTypes = {
    ["number"] = "NumberValue",
    ["string"] = "StringValue",
    ["boolean"] = "BoolValue"
}

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
        Options=opts,
    })

    return setmetatable(self, SchemaIndex)
end

function SchemaIndex:GetUserData(plrID)
    return self.Datastore:GetAsync(plrID) or nil
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

    local currentVersion = self:GetUserData(plrID)["version"]

    if self.Datastore:UpdateAsync(plrID, function(oldData)
        if oldData["version"] > currentVersion then
            warn(`[{self.Name}] WARNING: Data has been corrupted or lost!`)
            return oldData
        end

        local newData = oldData
        newData["version"] = oldData["version"]+1 or 1
        newData["data"][dataName] = dataValue

        print(`[{self.Name} ({newData["version"]})] Updated {dataName} with value {dataValue} ({type(dataValue)})`)
        return newData
    end) then return true end
    return false
end

function SchemaIndex:CreateDataValues(plr: Player)
    if self["Options"]["CreateValueInstances"] then
        local dir = plr:FindFirstChild("Data")
        if not dir then dir = Instance.new("Folder"); dir.Name = "Data"; dir.Parent = plr end
        
        local data = self:GetUserData(plr.UserId)["data"]
        for name, value in pairs(data) do
            if not dataTypes[type(value)] then continue end
            local dataValue = Instance.new(dataTypes[type(value)])

            --Assign the Instance its value and name
            dataValue.Value = value
            dataValue.Name = name
            dataValue.Parent = dir

            --Update Hnadler
            dataValue.Changed:Connect(function(newVal) 
                if newVal == self:GetUserData(plr.UserId)["data"][name] then print(`[{self.Name}] CANCELLED: Requested Change for {name} has been cancelled as its new value is the same as its current`) return false end
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

    if not success or store == nil then return false end
    return true
end

return SchemaIndex