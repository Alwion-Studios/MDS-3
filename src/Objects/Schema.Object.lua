--Operator Variables
local isStudio = false
--Types
export type Schema = {
    Name: String,
    AutoSaveInterval: Number,
    DataStore: DataStore,
    Structure: table,
    Options: table
}

-- Variable Types to DataValues
local dataTypes = {
    ["number"] = "NumberValue",
    ["string"] = "StringValue",
    ["boolean"] = "BoolValue"
}

local datastoreNamePrefix = {
    [true] = "DEV",
    [false] = "PROD"
}

-- Imports
local DS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local PS = game:GetService("Players")
local MDS = require(script.Parent.Parent.Core)
local RunService = game:GetService("RunService")
local Promise = require(RS.Packages.Promise)

if RunService:IsStudio() then isStudio = true end

local Schema = {
    autoSaveIteral = 30,
    dataQueue = {},
}
Schema.__index = Schema

function Schema.Create(name, structure, opts): Schema
    return setmetatable({
        Name = name,
        Structure = structure,
        DataStore = DS:GetDataStore(`{name}-{datastoreNamePrefix[isStudio]}`)
    }, Schema)
end

function Schema:GetData()
    if not self.User then return false end

    return Promise.new(function(resolve, reject, onCancel) 
        local user = self["User"]
        local result = self.DataStore:GetAsync(user)

        if not result then 
            self.DataStore:SetAsync(user, self["Structure"])
            result = self["Structure"]
        end

        resolve(result)

        onCancel(function() 
            resolve(false)
        end)
    end)
end

function Schema:Update()
    if not self.Session then return false end

    return Promise.new(function(resolve, reject, onCancel) 
        onCancel(function() 
            resolve(false)
        end)
    end)
end

function Schema:Save()
    if not self.User then return false end

    return Promise.new(function(resolve, reject, onCancel) 
        self.DataStore:UpdateAsync(self.User, function(oldData) 
            if self["Structure"] == oldData then return nil end
            print(`[{self.Name} - {MDS.Product}] Wrote changes to datastore`)

            return self.Structure
        end)

        onCancel(function() 
            resolve(false)
        end)
    end)
end

--Session Code
function Schema:CreateSession(id) 
    return Promise.new(function(resolve, reject, onCancel) 
        self["User"] = id

        local _, data = self:GetData(id):await()

        if data["version"] then 
            print(`[{self.Name} - {MDS.Product}] MDS v2 format detected. Converting to v3.`)
            data = data["data"]
        end

        self["Structure"] = data

        return resolve(self)
    end)
end

function Schema:CloseSession()
    return Promise.new(function(resolve, reject, onCancel) 
        local status, _ = self:Save():await()
        if not status then return reject(false) end
        return resolve(true)
    end)
end

return Schema