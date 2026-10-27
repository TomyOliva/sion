local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Shared.Framework)

-- local OtroService = Framework.Use("OtroService")

local template = {}

template.Priority = 0

function template:Init()
    warn("init template server")
end

function template:Start()
    warn("start template server")
end