-- Object Types
type Schema = {
    Name: string,
    Datastore: string,
    DataStructure: table,
}

local Schemas: {[string]: Schema} = {}
local MDS = {}

function MDS.CreateSchema(schemaDef: Schema): Schema
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

function MDS.GetSchema(name: String)
    return Schemas[name] or nil
end

function MDS.SetPlayerDefaults(plr: Player, schemaList: Table)
    if schemaList then
        for _, schema in pairs(schemaList) do
            if not Schemas[schema] then continue end
            Schemas[schema].Datastore:SetAsync(plr.UserId, {["data"]=schema["DataStructure"], ["version"]=1})
        end

        return true
    end

    for _, schema in pairs(Schemas) do
        schema.Datastore:SetAsync(plr.UserId, {["data"]=schema["DataStructure"], ["version"]=1})
    end
end

return MDS