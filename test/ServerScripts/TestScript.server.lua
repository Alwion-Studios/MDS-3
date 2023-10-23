local RS = game:GetService("ReplicatedStorage")
local MDS = require(RS.Packages.MDS.Core)

game:GetService("Players").PlayerAdded:Connect(function(plr)
    local Schema = MDS.GetSchema("Test")
    MDS:InitialisePlayer(plr)
    --[[if not Schema:UserDataExists(plr) then MDS.SetPlayerDefaults(plr) end

    local x = Schema.Datastore:GetAsync(plr.UserId)["data"]["TestValueNum"]

    repeat wait(2)
        x -= 1
        print(x)
        Schema:AddOneToTestValue(plr.UserId, x) 
    until false]]
end)