local SS = game:GetService("ServerScriptService")
local Schema = require(SS.MDS.Objects["Schema.Object"])

local TestSchema = Schema.Create("UserTest", 
    {
        ["Stats"]={
            ["Cash"]=0,
            ["Tokens"]=0,
            ["Experience"]={
                ["Level"]=1,
                ["Experience"]=0
            }
        }, 
        ["Inventory"]={}
    }
)

return TestSchema