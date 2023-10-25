--VERSION
local main = 3
local update = 0
local milestone = 0
local iteration = 5
local branch = "tb"

--Imports
local RS = game:GetService("ReplicatedStorage")
local PS = game:GetService("Players")
local Promise = require(RS.Packages.Promise)
local Signal = require(RS.Packages.Signal)

-- Object Types

--Promise Type
export type Promise = typeof(Promise.new(function() end))

local MDS = {
    Schemas = {},
    Product = `aDS`,
    Version = `{branch}_{main}.{update}.{milestone}.{iteration}`,
    Events = {
        hasLoaded = Signal.new()
    },
    Status = {
        hasInitialised = false
    }
}
MDS.__index = MDS

function MDS.Initialise(directory: Instance)
    print(`👋 {game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name} is supported by {MDS.Product} ({MDS.Version})`)

    for _, schema in pairs(directory:GetChildren()) do 
        local reqSchema = require(schema)
        MDS.Schemas[reqSchema.Name] = reqSchema

        print(`[{MDS.Product}] Initialised {reqSchema.Name}`)
    end

    MDS.Status.hasInitialised = true
    MDS.Events.hasLoaded:Fire()
    return true
end

function MDS:GetSchema(name): Promise
    return Promise.resolve(self.Schemas[name])
end

function MDS:CreateSession(schema, id): Promise
    schema["user"] = id
    return Promise.resolve(schema)
end

return MDS