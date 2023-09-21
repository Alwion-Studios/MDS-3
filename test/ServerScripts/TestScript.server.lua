local RS = game:GetService("ReplicatedStorage")
local MDS = require(RS.Packages.MDS.MDS)

game:GetService("Players").PlayerAdded:Connect(function(plr)
    MDS.SetPlrDefaults(plr)
    local Schema = MDS.GetSchema("Test")

    local x = 1

    repeat wait(2)
        x += 1
        Schema:UpdateValue(plr.UserId, {["TestValueNum"]=x}) 
        print(Schema.Datastore:GetAsync(plr.UserId))
    until false
end)