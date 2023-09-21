-- Imports
local RS = game:GetService("ReplicatedStorage")
local SchemaIndex = require(RS.Packages.MDS.Objects["Schema.Object"])

local TestSchema = SchemaIndex.New("Test", "TEST_1", {["TestValueNum"]=1}, true)

return TestSchema