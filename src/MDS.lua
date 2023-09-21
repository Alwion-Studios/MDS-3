-- Object Types
type Schema = {
    Name: string,
    Datastore: string,
    DataStructure: table,
}

local Schemas: {[string]: Schema} = {}
local MDS = {}

function MDS.CreateSchema(schemaDef: Schema): Schema
    assert(type(schemaDef) == "table", "Defined Schema must be a table")
    assert(type(schemaDef.Name) == "string", "Schema.Name must be a string")
    assert(#schemaDef.Name > 0, "Schema.Name must have a character")
    assert(not Schemas[schemaDef.Name], `Schema "{schemaDef.Name}" already exists`)

    local name = schemaDef.Name
    local schema = schemaDef

    Schemas[name] = schema

    --Functions for Schemas
    function schema:UpdateValue(plr: Player, dataToUpdate) 
        self.Datastore:UpdateAsync(plr, function(oldData)
            local newData = oldData
            newData["version"] = oldData["version"]+1 or 1

            for dataName, dataValue in pairs(dataToUpdate) do 
                newData["data"][dataName] = dataValue
            end

            return newData
        end)
    end

    return schema
end

function MDS.GetSchema(name: String)
    return Schemas[name] or nil
end

function MDS.SetPlrDefaults(plr: Player, schemaList: Table)
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