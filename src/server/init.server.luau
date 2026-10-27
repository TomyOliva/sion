--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Shared.Framework)

Framework.LoadFolder(script.Services)
Framework.Start()
