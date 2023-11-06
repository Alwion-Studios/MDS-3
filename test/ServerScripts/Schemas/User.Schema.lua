local SS = game:GetService("ServerScriptService")
local Schema = require(SS.MDS.Objects["Schema.Object"])
local RS = game:GetService("ReplicatedStorage")
local Promise = require(RS.Packages.Promise)

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

function TestSchema:SetCoins(toAdd) 
    if not self.Id then return false end

    --Get the User's current cash value
    self:GetKey({"Inventory"}, "Cash"):andThen(function(res) 
        if not typeof(res) == "number" then return false end
        res += toAdd
        --Set the cash key to the new value
        self:SetKey({"Inventory"}, "Cash", res):await()
    end)
end

return TestSchema