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
local Core = require(script.Parent.Parent.Core)
local RunService = game:GetService("RunService")
local Promise = require(RS.Packages.Promise)

if RunService:IsStudio() then isStudio = true end

local Schema = {
    assumeDeadSessionLock = 30 * 60,
    autoSaveIteral = 30,
    isLocked = false,
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
        if type(data) ~= "table" or type(template) ~= "table" then warn(`[{self.Name} - {Core.Product}] provided paramater(s) are not tables`) end
        return resolve(TableFunctions.Sync(data, template))
    end)
end

--Key-value Functions
function Schema:SetKey(path, key, value)
    return Promise.new(function(resolve, reject, onCancel) 
        self.IsLocked = true
        self.Structure = TableFunctions.FindAndEdit(path, self.Structure, key, value) 
        Core.Events.KeyChanged:Fire(self.Id, key, value)
        return resolve(true)
    end)
end

function Schema:GetKey(path, key)
    return Promise.new(function(resolve, reject, onCancel) 
        return resolve(TableFunctions.Find(path, self.Structure, key))
    end)
end

-- Datastore Functions
function Schema:Delete()
    if not self.Id then return false end
    warn(`[{self.Name} - {Core.Product}] Deleting Datastore with ID {self.Id}`)

    return Promise.new(function(resolve, reject, onCancel) 
        self.DataStore:RemoveAsync(self.Id)
        --self:RefreshCache()
        warn(`[{self.Name} - {Core.Product}] Closing Session`)
        Core:CloseSession(self.Id, self.Name)
        
        onCancel(function() 
            resolve(false)
        end)
    end)
end

function Schema:Save()
    if not self.Id then return false end

    return Promise.new(function(resolve, reject, onCancel) 
        self.DataStore:UpdateAsync(self.Id, function(oldData)
            local currentUTCTime = os.time(os.date("!*t"))

            local toSave = {}

            toSave = self["Structure"] 

            if self["Metadata"] then
                toSave["Metadata"] = self["Metadata"]
            end

            if not oldData["Metadata"] then 
                warn(`[{self.Name} - {Core.Product}] No metadata detected - saving`)
                return toSave 
            end

            if oldData["Metadata"]["Session"][1] ~= game.PlaceId or oldData["Metadata"]["Session"][2] ~= game.JobId and (oldData["Metadated"]["LastModified"] - currentUTCTime) < self.assumeDeadSessionLock then 
                warn(`[{self.Name} - {Core.Product}] UpdateAsync cancelled as session is currently in-use on another server`) return nil 
            end

            if toSave == oldData then
                warn(`[{self.Name} - {Core.Product}] Data remains unchanged. Save process aborted.`) 
                return nil 
            end

            print(`[{self.Name} - {Core.Product}] Wrote changes to datastore`)

            if toSave["Metadata"] then
                toSave["Metadata"]["LastModified"] = currentUTCTime
                self["Metadata"]["LastModified"] = currentUTCTime
            end

            return toSave
        end)

        onCancel(function() 
            resolve(false)
        end)
    end)
end

--Session Code
function Schema:Start(id) 
    if self.Id then warn(`[{self.Name} - {Core.Product}] Session is currently active`) return false end

    return Promise.new(function(resolve, reject, onCancel) 
        self.Id = id

        local _, data = self:Serialise(id):await()

        if not data["Metadata"] then 
            data["Metadata"] = {}
            data["Metadata"]["Session"] = {game.PlaceId, game.JobId or 0}
        end

        if data["Metadata"] and data["Metadata"]["Session"][1] ~= game.PlaceId or data["Metadata"]["Session"][2] ~= game.JobId then
            warn(`[{self.Name} - {Core.Product}] Datastore with ID {id} is locked as it's in use on another server`)
            return reject(false)
        end

        if data["version"] then 
            print(`[{self.Name} - {Core.Product}] Core v2 format detected. Converting to v3.`)
            data = data["data"]
        end

        self["Metadata"] = data["Metadata"]
        self["Structure"] = data

        --self["Structure"]["Metadata"] = {}
        --self["Structure"]["Metadata"]["Session"] = {game.PlaceId, game.JobId or 0}
        
        self:Save()
        self["Structure"]["Metadata"] = nil

        Core.Events.SessionOpen:Fire(self.Id) --Fire the SessionOpen Signal
        return resolve(self)
    end)
end

function Schema:Close(refuseSave)
    if refuseSave then return false end
    
    return Promise.new(function(resolve, reject, onCancel) 
        self["Metadata"] = nil
        local status, _ = self:Save():await()
        if not status then return resolve(false) end

        Core.Events.SessionClosed:Fire(self.Id) --Fire the SessionClosed Signal

        return resolve(true)
    end)
end

return Schema