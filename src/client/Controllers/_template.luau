local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Shared.Framework)

-- local Global = Framework.Use("Global")

local template = {}

template.Priority = 0

function template:Init()
    warn("init template client")
end

function template:Start()
    warn("start template client")
end

return template
