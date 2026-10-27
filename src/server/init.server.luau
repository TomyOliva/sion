local RS = game:GetService("ReplicatedStorage")
local Loader = require(RS.Shared.loader)

local services = Loader.LoadFolder(script.Services)
Loader.Start(services)