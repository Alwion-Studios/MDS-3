local RS = game:GetService("ReplicatedStorage")
local MDS = require(RS.Packages.MDS.MDS)

game:GetService("Players").PlayerAdded:Connect(function(plr)
    local Schema = MDS.GetSchema("Test")

    if not Schema:UserDataExists(plr) then MDS.SetPlrDefaults(plr) end

    local x = Schema.Datastore:GetAsync(plr.UserId)["data"]["TestValueNum"]

    repeat wait(2)
        x += 1
        Schema:UpdateValue(plr.UserId, {["TestValueNum"]=x}) 
    until false
end)