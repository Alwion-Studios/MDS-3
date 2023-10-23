local SS = game:GetService("ServerScriptService")
local Schema = require(SS.MDS.Objects["Schema.Object"])

local TestSchema = Schema.Create("Test", {["TestValueNum"]=1}, {["CreateValueInstances"]=true, ["DataStructureLimits"]={["TestValueNum"]={type="number", max=100, min=0}}})
return TestSchema