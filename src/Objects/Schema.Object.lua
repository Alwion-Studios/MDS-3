--Operator Variables
local isStudio = false
--Types
export type settings = {
    assumeDeadSessionLock: number,
    autoSaveInteral: number
}

export type Schema = {
    Name: String,
    Settings: settings,
    DataStore: DataStore,
    Structure: table,
    Options: table,
}

--Middleware Types
export type Middleware = {
    Inbound: {MiddleWareFn}?,
    Outbound: {MiddleWareFn}?
}

export type MFunction = (player: Player, args: {any}) -> (boolean, ...any)

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

--Schema Object with Defaults
local Schema = {
    Options = {
        Settings = {
            assumeDeadSessionLock = 30 * 60,
            autoSaveInteral = 1 * 60,
        },

        --[[
        FOR FUTURE USE -MK
        Middleware = {
            Inbound = {},
            Outbound = {}
        }]]
    }
}

--[[
    Returns: SELF

Gets the default schema template and adds the user's customisations
    !!! Must be created before calling Core initialisation !!!

    -- Parameters:
    name: String -- Declares the name of the schema. !!! MUST BE UNIQUE !!!
    structure: Table 
    options: Table

    -- Example:
    local MySchema = Schema.Create(
        "My Schema", ! Name !
        {["SchemaName"]=schemaValue}, ! Structure !
        {["CustomSetting"]={true, "OtherInfo"} ! Options !
    })
]]

function Schema.Create(name: String, structure: table, options: table): Schema
    local self = Schema
    self.Name = name
    self.Structure = structure
    self.DataStore = DS:GetDataStore(`{name}-{datastoreNamePrefix[isStudio]}`)

    if options then
        self.Options.Settings["Custom"] = options
    end

    return self
end

--[[
    Returns: PROMISE (table)

    Gets the user's data and loads into memory for future use

    !!! To prevent data loss, data can only be serialised on one server. 
    Attempts to serialise on multiple may lead to issues. !!!

    -- Parameters
    None. Handled Automatically by aDS.
]]

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

--[[
    Returns: PROMISE (table)

    This function compares two tables. The first table is checked to see if has the same set of keys as the template. Missing keys are inserted.

    -- Parameters
    data: table ! Current Dataset. Usually self.structure !
    template: table ! Template to compare. !

    -- Example:
    self:Sync(self.Structure, self.Template)
]]

function Schema:Sync(data, template) 
    return Promise.new(function(resolve, reject, onCancel) 
        if type(data) ~= "table" or type(template) ~= "table" then warn(`[{self.Name} - {Core.Product}] provided paramater(s) are not tables`) end
        return resolve(TableFunctions.Sync(data, template))
    end)
end

--[[
    Returns: PROMISE (true)

    This function allows you to set or insert custom keys based on its path in the data structure

    -- Parameters
    path: table ! Defines the path to find or insert a key ! - !!! Does not work if you use keys that do not exist. Patch coming soon !!!
    key: string ! Name of key to set !
    value: any ! Value to set key to !

    -- Example:
    self:SetKey({"Path", "to", "table"}, "Key", "Value")
]]

function Schema:SetKey(path, key, value)
    return Promise.new(function(resolve, reject, onCancel) 
        self.IsLocked = true
        self.Structure = TableFunctions.FindAndEdit(path, self.Structure, key, value) 
        Core.Events.KeyChanged:Fire(self.Id, key, value)
        return resolve(true)
    end)
end

--[[
    Returns: PROMISE (key, value)

    This function allows you to get a key and its value based on its path in the data structure

    -- Parameters
    path: table ! Defines the path to find or insert a key ! - !!! Does not work if you use keys that do not exist. Patch coming soon !!!
    key: string ! Name of key to set !
    value: any ! Value to set key to !

    -- Example:
    self:GetKey({"Path", "to", "key"}, "Key")
]]

function Schema:GetKey(path, key)
    return Promise.new(function(resolve, reject, onCancel) 
        return resolve(TableFunctions.Find(path, self.Structure, key))
    end)
end

--[[
    Returns: PROMISE

    This function allows you to completely delete a session datastore. 

    -- Calls
    CloseSession(id, self.Name)

    -- Parameters
    id: any ! ID of the key that the data is stored in !

    -- Example:
    self:Delete(1)
]]

function Schema:Delete(id)
    if not self.Id or not id then return false end
    local idToUse = self.Id or id
    warn(`[{self.Name} - {Core.Product}] Deleting Datastore with ID {self.Id}`)

    return Promise.new(function(resolve, reject, onCancel) 
        self.DataStore:RemoveAsync(idToUse)
        --self:RefreshCache()

        if self.Id then
            warn(`[{self.Name} - {Core.Product}] Closing Session`)
            Core:CloseSession(idToUse, self.Name)
        end
        
        onCancel(function() 
            resolve(false)
        end)
    end)
end

--[[
    Returns: PROMISE

    This function allows you to save the current session

    -- Example:
    self:Start(1)
]]

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

            if oldData["Metadata"]["Session"][1] ~= game.PlaceId or oldData["Metadata"]["Session"][2] ~= game.JobId and (oldData["Metadated"]["LastModified"] - currentUTCTime) < self.Options.Settings.assumeDeadSessionLock then 
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

--[[
    Returns: PROMISE

    This function allows you to start a schema session

    -- Calls
    Serialise()
    Save()

    -- Parameters
    id: any ! ID of the data structure in the datastore !

    -- Example:
    self:Start(1)
]]

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

        self:Save()
        self["Structure"]["Metadata"] = nil

        Core.Events.SessionOpen:Fire(self.Id) --Fire the SessionOpen Signal
        return resolve(self)
    end)
end

--[[
    Returns: PROMISE

    This function allows you to start a schema session

    -- Calls
    Save()

    -- Parameters
    refuseSave: boolean ! Unused at the moment !

    -- Example:
    self:Close(false)
]]

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