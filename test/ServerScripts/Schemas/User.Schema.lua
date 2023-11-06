local SS = game:GetService("ServerScriptService")
local Schema = require(SS.MDS.Objects["Schema.Object"])

local TestSchema: Schema = {}

--Data Components
local inventory: Table = {
    ["Cash"]=0,
    ["Tokens"]=0,
    ["Backpack"]={}
}
local level: Table = {
    ["Level"]=1,
    ["Experience"]=0,
}
local stats: Table = {
    ["Level"]=level
}

TestSchema = Schema.Create("UserTest", 
    {
        ["Stats"]=stats, 
        ["Inventory"]=inventory
    }
)

function TestSchema:SetCoins(newAmount) 
    if not self.Id then return false end

    local _, value = self:GetKey({"Inventory"}, "Cash"):await()
    newAmount += value
    self:SetKey({"Inventory"}, "Cash", newAmount)
end

return TestSchema