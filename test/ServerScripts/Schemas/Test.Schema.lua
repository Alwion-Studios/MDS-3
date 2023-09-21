-- Imports
local DS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local MDS = require(RS.Packages.MDS.MDS)

local TestSchema = MDS.CreateSchema({
    Name = "Test",
    Datastore = DS:GetDataStore("TEST_1"),
    DataStructure = {
        ["TestValueNum"]=1
    }
})

--[[function TestSchema:AddToTest(plrId) 
    self.Datastore:UpdateAsync(plrId, function(oldData)
        local newData = {}
        newData["data"] = self["DataTbl"]
        newData["TestValueNum"] += 1
        newData["version"] = oldData["version"]+1 or 1
        return newData
    end)
end]]

return TestSchema