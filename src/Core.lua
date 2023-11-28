--VERSION CONTROL
local main = 3
local update = 0
local milestone = 1
local iteration = 2
local branch = "tb"

--Imports
local RS = game:GetService("ReplicatedStorage")
local PS = game:GetService("Players")
local Promise = require(RS.Packages.Promise)
local Signal = require(RS.Packages.Signal)

--Schema Type
export type Schema = {
    Name: String,
    Id: Number,
    Settings: table,
    DataStore: DataStore,
    Structure: table,
    Options: table
}

--Promise Type
export type Promise = typeof(Promise.new(function() end))

local Core = {
    Schemas = {},
    Product = `aDS`,
    Version = `{branch}_{main}.{update}.{milestone}.{iteration}`,
    Events = {
        hasLoaded = Signal.new(),
        KeyChanged = Signal.new(),
        SessionOpen = Signal.new(),
        SessionClosed = Signal.new()
    },
    Status = {
        hasInitialised = false
    },
    ActiveSessions = {},
    Debug = {
        PerformanceCheck = true,
    }, -- Alwion Only
}

function Core.Initialise(directory: Instance): Promise
    if Core.Status.hasInitialised then return Promise.reject() end 
    print(`👋 {game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name} is supported by {Core.Product} ({Core.Version})`)

    return Promise.new(function(resolve) 
        for _, schema in pairs(directory:GetChildren()) do 
            local reqSchema = require(schema)
    
            Core.Schemas[reqSchema.Name] = reqSchema
            Core.ActiveSessions[reqSchema.Name] = {}
    
            print(`[{Core.Product}] Initialised {reqSchema.Name}`)
        end
    
        Core.Status.hasInitialised = true
        Core.Events.hasLoaded:Fire()
        resolve(true)
    end)
end

function Core:GetSchema(name): Promise
    return Promise.resolve(self.Schemas[name])
end

--Session Code
function Core:CreateSession(id, schema: Schema): Promise
    if not schema or not id or not PS:GetPlayerByUserId(id) then return Promise.reject(false) end
    
    local status, newSession = schema:Start(id):await()
    self.ActiveSessions[schema.Name][id] = newSession

    return Promise.resolve(newSession)
end

function Core:GetSession(id, name): Promise 
    if not id or not name then return Promise.reject(false) end
    if not self.ActiveSessions[name] then return Promise.reject(false) end
    if not self.ActiveSessions[name][id] then return Promise.reject(false) end

    return Promise.resolve(self.ActiveSessions[name][id])
end

function Core:GetSessionData(id, name): Promise 
    if not id or not name then return Promise.reject(false) end
    if not self.ActiveSessions[name] then return Promise.reject(false) end
    if not self.ActiveSessions[name][id] then return Promise.reject(false) end

    return Promise.resolve(self.ActiveSessions[name][id]["Structure"])
end

function Core:Shutdown(): Promise
    print(`[{self.Product}] Closing Sessions`)

    for name, schema in pairs(self.ActiveSessions) do 
        for id, session in pairs(schema) do 
            session:Close()
            session = nil
            print(`[{self.Product}] Closed Serialised Schema ({name}) Session ({id})`)
        end 
    end

    return Promise.resolve(true)
end

game:BindToClose(function() 
    Core:Shutdown():await()
end)

return Core