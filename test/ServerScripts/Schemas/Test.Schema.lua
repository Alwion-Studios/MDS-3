-- Imports
--[[local RS = game:GetService("ReplicatedStorage")
local SchemaIndex = require(RS.Packages.MDS.Objects["Schema.Object"])

local TestSchema = SchemaIndex.New("Test", "TEST_1", {["TestValueNum"]=1}, {["CreateValueInstances"]=true, ["DataStructureLimits"]={["TestValueNum"]={type="number", max=100, min=0}}})

function TestSchema:AddOneToTestValue(plr, x)
    self:UpdateValue(plr, "TestValueNum", x) 
end

return TestSchema]]