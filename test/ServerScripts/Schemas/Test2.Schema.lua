-- Imports
local RS = game:GetService("ReplicatedStorage")
local SchemaIndex = require(RS.Packages.MDS.Objects["Schema.Object"])

local testSchema = SchemaIndex.New("Test2", "TEST_2", {["Test2"]=1}, false)
print(testSchema)
return testSchema