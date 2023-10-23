--[[
  _____
 /     \
| () () |
 \  ^  /
  |||||
  |||||
  EVIL EXPLOIT
  (Disclaimer: I thought this'd be funny. It's just a way to test for potential exploits)
]]
local RS = game:GetService("ReplicatedStorage")
local MDS = require(RS.Packages.MDS.Core)

repeat
    wait(1)
    local plrDir = game:GetService("Players").LocalPlayer:WaitForChild("Data")
    plrDir:WaitForChild("TestValueNum").Value = 99999999999999999
until false