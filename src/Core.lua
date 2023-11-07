--!nonstrict

--VERSION
local main = 3
local update = 0
local milestone = 0
local iteration = 6
local branch = "tb"

--Imports
local RS = game:GetService("ReplicatedStorage")
local PS = game:GetService("Players")
local Promise = require(RS.Packages.Promise)
local Signal = require(RS.Packages.Signal)

-- Object Types
export type Schema = {
    Name: String,
    AutoSaveInterval: Number,
    DataStore: DataStore,
    Session: table,
    Options: table
}

--Promise Type
export type Promise = typeof(Promise.new(function() end))

local MDS = {
    Schemas = {},
    Product = `aDS`,
    Version = `{branch}_{main}.{update}.{milestone}.{iteration}`,
    Events = {
        hasLoaded = Signal.new(),
    },
    Status = {
        hasInitialised = false
    },
    ActiveSessions = {}
}

function MDS.Initialise(directory: Instance)
    print(`👋 {game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name} is supported by {MDS.Product} ({MDS.Version})`)

    for _, schema in pairs(directory:GetChildren()) do 
        local reqSchema = require(schema)

        MDS.Schemas[reqSchema.Name] = reqSchema
        MDS.ActiveSessions[reqSchema.Name] = {}

        print(`[{MDS.Product}] Initialised {reqSchema.Name}`)
    end

    MDS.Status.hasInitialised = true
    MDS.Events.hasLoaded:Fire()
    return true
end

function MDS:GetSchema(name): Promise
    return Promise.resolve(self.Schemas[name])
end

--Session Code
function MDS:CreateSession(id, schema: Schema): Promise
    if not schema or not id or not PS:GetPlayerByUserId(id) then return Promise.reject(false) end
    
    local status, newSession = schema:Start(id):await()
    self.ActiveSessions[schema.Name][id] = newSession

    return Promise.resolve(newSession)
end

function MDS:GetSession(id, name): Promise 
    if not id or not name then return Promise.reject(false) end
    if not self.ActiveSessions[name] then return Promise.reject(false) end
    if not self.ActiveSessions[name][id] then return Promise.reject(false) end

    return Promise.resolve(self.ActiveSessions[name][id])
end

function MDS:CloseSession(id, session): Promise
    local status, _ = session:Close()
    if not status then warn(`[{self.Product}] Session ({id}) did not successfully save`) end
    session = nil

    return Promise.resolve(true)
end

function MDS:CloseSessions(): Promise
    print(`[{self.Product}] Closing Sessions`)

    for name, schema in pairs(self.ActiveSessions) do 
        for id, session in pairs(schema) do 
            self:CloseSession(id, session)
            print(`[{self.Product}] Closed Serialised Schema ({name}) Session ({id})`)
        end 
    end

    return Promise.resolve(true)
end

game:BindToClose(function() 
    MDS:CloseSessions():await()
end)

return MDS