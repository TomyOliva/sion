--// Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

--// Modules
local Lapis = require(RS.Packages.Lapis)
local DEFAULT_DATA = require(script.DataTemplate)

--// Variables
local DataService = {}
local documents = {}

--// Methods
local collection = Lapis.createCollection("PlayerData", {
	defaultData = DEFAULT_DATA,
	validate = t.strictInterface({ coins = t.integer }),
})

local function onPlayerAdded(player: Player)
	collection
		:load(`Player{player.UserId}`, { player.UserId })
		:andThen(function(document)
			if player.Parent == nil then
				document:close():catch(warn)
				return
			end

			documents[player] = document
			warn("documents:", documents)
		end)
		:catch(function(message)
			warn(`Player {player.Name}'s data failed to load: {message}`)
			player:Kick("Data failed to load.")
		end)
end

local function onPlayerRemoving(player: Player)
	local document = documents[player]

	if document ~= nil then
		documents[player] = nil
		document:close():catch(warn)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

function DataService.Init()
	print("DataService: Init")
end

function DataService.Start()
	print("DataService: Start")
end

return DataService