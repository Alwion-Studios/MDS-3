-- Imports
local SS = game:GetService("ServerScriptService")
local PS = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Promise = require(RS.Packages.Promise)

local MDS = require(SS.MDS.Core)

PS.PlayerAdded:Connect(function(plr)
    MDS.Events.hasLoaded:Wait()

    local loaded, session, _ = MDS:GetSchema("Test"):andThen(function(schema) 
        return Promise.resolve(schema:CreateSession(plr.UserId))
    end):await()
    print(session)
end)
