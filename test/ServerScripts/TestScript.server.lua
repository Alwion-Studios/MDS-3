local SS = game:GetService("ServerScriptService")
local MDS = require(SS.MDS.Core)

game:GetService("Players").PlayerAdded:Connect(function(plr)
    local result, schema = MDS:GetSchema("Test"):await()

    print(schema)
    --[[if not Schema:UserDataExists(plr) then MDS.SetPlayerDefaults(plr) end

    local x = Schema.Datastore:GetAsync(plr.UserId)["data"]["TestValueNum"]

    repeat wait(2)
        x -= 1
        print(x)
        Schema:AddOneToTestValue(plr.UserId, x) 
    until false]]
end)