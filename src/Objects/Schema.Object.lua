--Operator Variables
local isStudio = false
--Types
export type Schema = {
    Name: String,
    AutoSaveInterval: Number,
    DataStore: DataStore,
    Structure: table,
    Options: table,

    --Booleans
    IsResetting: boolean
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
local TableFunctions = require(script.Parent.Parent.Functions["Table.Functions"])
local MDS = require(script.Parent.Parent.Core)
local RunService = game:GetService("RunService")
local Promise = require(RS.Packages.Promise)
local TblUtil = require(RS.Packages.TableUtil)

if RunService:IsStudio() then isStudio = true end

local Schema = {
    autoSaveIteral = 30,
    dataQueue = {}
}
Schema.__index = Schema

function Schema.Create(name, structure, opts): Schema
    return setmetatable({
        Name = name,
        Structure = structure,
        DataStore = DS:GetDataStore(`{name}-{datastoreNamePrefix[isStudio]}`)
    }, Schema)
end

--Session Serialisation Functions
function Schema:GetStructure()
    return self["Structure"]
end

function Schema:Serialise()
    if not self.Id then return false end

    return Promise.new(function(resolve, reject, onCancel) 
        local result = self.DataStore:GetAsync(self.Id)
        local toReturn

        if not result then 
            self.DataStore:SetAsync(self.Id, self["Structure"])
            result = self["Structure"]
            toReturn = result
        end

        if not toReturn then
            _, toReturn = self:Sync(result, self["Structure"]):await()
        end
        
        resolve(toReturn)

        onCancel(function() 
            resolve(false)
        end)
    end)
end

--Sync Functions
function Schema:Sync(data, template) 
    return Promise.new(function(resolve, reject, onCancel) 
        if type(data) ~= "table" or type(template) ~= "table" then warn(`[{self.Name} - {MDS.Product}] provided paramater(s) are not tables`) end
        return resolve(TblUtil.Reconcile(data, template))
    end)
end

--Key-value Functions
function Schema:SetKey(path, key, value)
    return Promise.new(function(resolve, reject, onCancel) 
        self.Structure = TableFunctions.FindAndEdit(path, self.Structure, key, value) 
        return resolve(true)
    end)
end

-- Datastore Functions
function Schema:DeleteStore()
    if not self.Id then return false end
    warn(`[{self.Name} - {MDS.Product}] Deleting Datastore with ID {self.Id}`)

    return Promise.new(function(resolve, reject, onCancel) 
        self.DataStore:RemoveAsync(self.Id)
        --self:RefreshCache()
        warn(`[{self.Name} - {MDS.Product}] Closing Session`)
        MDS:CloseSession(self.Id, self.Name)
        
        onCancel(function() 
            resolve(false)
        end)
    end)
end

function Schema:SaveStore()
    if not self.Id then return false end

    return Promise.new(function(resolve, reject, onCancel) 
        self.DataStore:UpdateAsync(self.Id, function(oldData) 
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
        self.Id = id

        local _, data = self:Serialise(id):await()
        
        if data["version"] then 
            print(`[{self.Name} - {MDS.Product}] MDS v2 format detected. Converting to v3.`)
            data = data["data"]
        end

        self["Structure"] = data

        return resolve(self)
    end)
end

function Schema:CloseSession(refuseSave)
    if refuseSave then return false end
    return Promise.new(function(resolve, reject, onCancel) 
        local status, _ = self:SaveStore():await()
        if not status then return reject(false) end
        return resolve(true)
    end)
end

return Schema