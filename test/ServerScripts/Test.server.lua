-- Imports
local SS = game:GetService("ServerScriptService")
local PS = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Promise = require(RS.Packages.Promise)

local MDS = require(SS.MDS.Core)

PS.PlayerAdded:Connect(function(plr)
    if not MDS.Status.hasInitialised then MDS.Events.hasLoaded:Wait() end
    
    local loaded, session, _ = MDS:GetSchema("UserTest"):andThen(function(schema) 
        local status, createdSession = MDS:CreateSession(plr.UserId, schema):await()
        
        if not status then plr:Kick("Failed to initialise a datastore session!") return Promise.reject(false) end

        return Promise.resolve(createdSession)
    end):await()

    print(`Loaded Session for {plr.Name}`)
    print(session)

    MDS.Events.KeyChanged:Connect(function(id, key, value) 
        print(`Value changed! {id} {key} to {value}`)
    end)

    wait(1)
    session:SetCoins(10) 

    session:GetSettings():andThen(function(res) 
        print(res)
    end)

    --session:DeleteStore()
end)