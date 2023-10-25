-- Imports
local DS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerScriptService")
local MDS = require(SS.MDS.Core)

--MDS.InitialiseSchemaDirectory(script.Parent.Schemas)

MDS.Initialise(script.Parent.Schemas)