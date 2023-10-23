--VERSION
local main = 3
local update = 0
local milestone = 1
local iteration = 2
local branch = "tb"

--Imports
local RS = game:GetService("ReplicatedStorage")
local Promise = require(RS.Packages.Promise)

-- Object Types

--Promise Type
export type Promise = typeof(Promise.new(function() end))

local MDS = {
    Schemas = {},
    Product = `MDS`,
    Version = `{branch}_{main}.{update}.{milestone}.{iteration}`
}
MDS.__index = MDS

function MDS.Initialise(directory: Instance): Promise
    print(`Initialising {MDS.Product} {MDS.Version}`)

    for _, schema in pairs(directory:GetChildren()) do 
        MDS.Schemas[schema]
    end

    return Promise.resolve(MDS.Version)
end

return MDS

--[[function MDS.CreateSchema(schemaDef: Schema): Schema
    if not type(schemaDef) == "table" then error("Defined Schema must be a table") end
    if not type(schemaDef.Name) == "string" then error("Schema.Name must be a string") end
    if #schemaDef.Name <= 0 then error("Schema.Name must have a character") end
    if Schemas[schemaDef.Name] then error(`Schema "{schemaDef.Name}" already exists`) end

    Schemas[schemaDef.Name] = schemaDef

    return schemaDef
end

function MDS.InitialiseSchemaDirectory(flr: Instance): { Schema }
    local scannedScripts = {}
    if not typeof(flr) == "Instance" then warn(`The provided folder ({flr}) is not an instance!`) end
    if #flr:GetChildren() <= 0 then warn(`The provided folder ({flr.Name}) has no children`) end

    for _, script in pairs(flr:GetChildren()) do
        print(`Scanning {script.Name}`)
        if not script:IsA("ModuleScript") then warn(`Scanned file ({script.Name}) is not a script`) end
        table.insert(scannedScripts, require(script))
        print(`Initialised Schema Layout for {script.Name}`)
    end

    print(`Scanned {#flr:GetChildren()} Script(s) | Initialised {#scannedScripts} Schema(s)`)
    return scannedScripts
end

function MDS:GetAllSchemas()
    return Schemas
end

function MDS:GetSchema(name: String)
    return Schemas[name] or nil
end

function MDS:SetPlayerDefaults(plr: Player, schemaList: Table)
    if schemaList then
        for _, schema in pairs(schemaList) do
            if not Schemas[schema] then continue end
            schema = Schemas[schema]
            local tbl = {["data"]=schema["DataStructure"], ["version"]=1}
            schema.Datastore:SetAsync(plr.UserId, {["data"]=schema["DataStructure"], ["version"]=1})
            schema:SetPlayerData(plr.UserId, tbl)
        end

        return true
    end

    for _, schema in pairs(Schemas) do
        local tbl = {["data"]=schema["DataStructure"], ["version"]=1}
        schema.Datastore:SetAsync(plr.UserId, tbl)
        schema:SetPlayerData(plr.UserId, tbl)
    end
end

function MDS:DeletePlayerData(plr: Player, schemaList: Table)
    if schemaList then
        for _, schema in pairs(schemaList) do
            if not Schemas[schema] then continue end
            Schemas[schema].Datastore:RemoveAsync(plr.UserId)
            print(`[{Schemas[schema].Name}] Deleted {plr.Name}'s data`)
        end

        return true
    end

    for _, schema in pairs(Schemas) do
        schema.Datastore:RemoveAsync(plr.UserId)
        print(`[{schema.Name}] Deleted {plr.Name}'s data`)
    end
end

function MDS:InitialisePlayer(plr: Player)
    for name, schema in pairs(Schemas) do
        if not schema:UserDataExists(plr) then self:SetPlayerDefaults(plr, {name}) end
        schema:CreateDataValues(plr)
    end

    return true
end]]