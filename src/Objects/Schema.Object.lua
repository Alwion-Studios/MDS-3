--Operator Variables
local isStudio = false
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
    if not self.Session then return false end

    return Promise.new(function(resolve, reject, onCancel) 
        local user = self["Session"]["User"]
        local result = self.DataStore:GetAsync(user)

        if not result then 
            self.DataStore:SetAsync(user, {["data"]=self["Structure"], ["version"]=1})
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
    if not self.Session then return false end

    return Promise.new(function(resolve, reject, onCancel) 
        self.DataStore:UpdateAsync(self.Session["User"], function(oldData) 
            if oldData["version"] > self.Session["Structure"]["version"] then
                warn(`[{self.Name} - {MDS.Product}] WARNING: Data has been corrupted or lost!`)
                return oldData
            end

            if self.Session["Structure"] == oldData then return nil end

            self.Session["Structure"]["version"] = oldData["version"]+1

            print(`[{self.Name} ({self.Session["Structure"]["version"]}) - {MDS.Product}] Wrote changes to datastore`)

            return self.Session["Structure"]
        end)

        onCancel(function() 
            resolve(false)
        end)
    end)
end

--Session Code
function Schema:CreateSession(id) 
    return Promise.new(function(resolve, reject, onCancel) 
        self.Session = {}
        self.Session["User"] = id

        local _, data = self:GetData(id):await()
        self.Session["Structure"] = data

        return resolve(self)
    end)
end

return Schema