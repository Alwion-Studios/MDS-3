-- Imports
local SS = game:GetService("ServerScriptService")
local PS = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Promise = require(RS.Packages.Promise)

local MDS = require(SS.MDS.Core)

PS.PlayerAdded:Connect(function(plr)
    if not MDS.Status.hasInitialised then MDS.Events.hasLoaded:Wait() end
    wait(2)
    local loaded, session, _ = MDS:GetSession(plr.UserId, "Test"):await()
end)