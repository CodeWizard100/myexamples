--serverHandler.lua
--SHOWCASE VIDEO: https://youtu.be/t4e9NqFGIK8
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local workspace = game.Workspace
local remotes = replicatedStorage:WaitForChild("Remotes")
local pets = replicatedStorage:WaitForChild("Pets")
local players = game:GetService("Players")
local dataStoreService = game:GetService("DataStoreService")
local dataStoreName = "PetsV4"
local dataStore = dataStoreService:GetDataStore(dataStoreName)
local multis = {"Coins","Gems"}
local area = workspace.Area
local spawned = workspace.Spawned
local coinSize = game.ReplicatedStorage.Coin.Size.Y 
local max = 20

local function randomPet(chancesTable)
	local rand = math.random(0, 100)
	local chance = 0

	for petName, petChance in pairs(chancesTable) do
		chance = chance + petChance
		if rand <= chance then
			return petName
		end
	end
end
local function setupprompt(eggname,price)
	-- return function that will be connected
	return function(player : Player)
		assert(player.leaderstats, "No Leaderstats!")
		assert(player.leaderstats.Coins, "No Coins!")
		if player.leaderstats.Coins.Value >= price then
			player.leaderstats.Coins.Value -= price
			local petsChances = {}
			for i,v in pairs(game.ReplicatedStorage.Pets:FindFirstChild(eggname):GetChildren()) do
				if not v:IsA("Configuration") then continue end
				petsChances[v.Name] = v.Chance.Value
			end
			local randomname = randomPet(petsChances)
			player.PlayerGui.HatchUI.Show:FireClient(player,randomname)
			player:FindFirstChild("Pets"):FindFirstChild(randomname).Value += 1
		end
	end
end
-- saving and loading data
local function loadData(player : Player)
	local success, data = pcall(function()
		return game:GetService("HttpService"):JSONDecode(dataStore:GetAsync(player.UserId))
	end)
	if success and data then
		for i,v in pairs(data) do
			player:FindFirstChild("Pets"):FindFirstChild(i).Value = v
			
			
		end
	end
	warn(data)
end
local function saveData(player : Player)
	local pets = {}
	for i,v in pairs(player:WaitForChild("Pets"):GetChildren()) do
		if v:IsA("NumberValue") then
			pets[v.Name] = v.Value
		end
	end
	local success,err = pcall(function()
		dataStore:SetAsync(player.UserId,game:GetService("HttpService"):JSONEncode(pets))
	end)
	if not success then warn("Error Saving data!") return else warn("Saved Data: " .. game:GetService("HttpService"):JSONEncode(pets) .. " For Player: " .. player.Name) end 
end
-- general setup
local function setup()
	for i,v in pairs(pets:GetChildren()) do
		if workspace:FindFirstChild(v.Name) then
			assert(workspace:FindFirstChild(v.Name):IsA("BasePart"),"The Egg Needs to be meshpart or part")
			workspace:FindFirstChild(v.Name).Anchored = true
			assert(v:FindFirstChild("Cost"),"Please Insert Cost Into Pet Config")
			local prompt = Instance.new("ProximityPrompt")
			prompt.Parent = workspace:FindFirstChild(v.Name)
			prompt.Enabled = true
			prompt.ActionText = "Hatch!"
			prompt.ObjectText = "Costs " .. v:FindFirstChild("Cost").Value .. " Coins"	
			prompt.Triggered:Connect(setupprompt(v.Name,v:FindFirstChild("Cost").Value))
		else
			warn("To use new configs copy the ServerStorage.Egg to workspace and rename it to your config")
			return	
		end
	end
end
-- player functions
local function playerAdded(player : Player)
	print("player added")
	local petnames = {}
	local peteggs = {}
	local petchances = {}
	local petmultis = {}
	for i,v in pairs(pets:GetDescendants()) do
	
		if v:IsA("Configuration") then
	
			table.insert(petnames,v.Name)
			table.insert(peteggs,v.Parent.Name)
			table.insert(petchances,v.Chance.Value)
			for j,k in ipairs(multis) do
	
				if not petmultis[k] then
					petmultis[k] = {}
				end
				petmultis[k][v.Name] = v:FindFirstChild(k .. "Multi").Value
			
			end
			
		end
	end

	local playerPets = Instance.new("Folder")
	playerPets.Name = "Pets"
	playerPets.Parent = player
	for i,v in ipairs(petnames) do
		local numbervalue = Instance.new("NumberValue")
		numbervalue.Name = v
		numbervalue.Value = 0
		numbervalue.Parent = playerPets
		numbervalue:SetAttribute("Egg",peteggs[i])
		numbervalue:SetAttribute("Chance",petchances[i])
		for j,k in petmultis do
			numbervalue:SetAttribute(j,k[v])
		end
	end
	loadData(player)
end
local function playerRemoving(player : Player)
	print("player removing")
	saveData(player)
end
local function getMulti(player : Player, multi : string)
	assert(player and multi,"Incorrect Arguments")
	local max = 1
	for i,v in pairs(player:WaitForChild("PetsEquipped"):GetChildren()) do
		if v.Name ~= "Max" and v.Value ~= 0 then
			local multi = player:WaitForChild("Pets"):FindFirstChild(v.Name):GetAttribute(multi)
			
			max += (multi - 1) * v.Value
		end
	end
	return max
end
local function coinPrompt(amount)
	return function(player : Player)
		player.leaderstats.Coins.Value +=amount.Value * getMulti(player,"Coins")
		amount.Parent.Parent:Destroy()
	end
end
--random area position
local function randomPosition()
	return Vector3.new(area.Position.X + math.random(-area.Size.X / 2,area.Size.X / 2),area.Position.Y + coinSize,area.Position.Z + math.random(-area.Size.Z / 2,area.Size.Z / 2))
end
local function spawnCoin()
	task.spawn(function()
		local coin = game.ReplicatedStorage.Coin:Clone()
		coin.Parent = spawned
		coin.Position = randomPosition()
		assert(coin:FindFirstChildOfClass("ProximityPrompt"),"No Prompt!")
		coin:FindFirstChildOfClass("ProximityPrompt").Triggered:Connect(coinPrompt(coin:FindFirstChildOfClass("ProximityPrompt").Amount))
		coin.Destroying:Connect(function()
			task.delay(3,function()
				if #spawned:GetChildren() < max then
					spawnCoin()
				end
			end)
		end)
	end)
end

players.PlayerAdded:Connect(function(player)
	task.spawn(function() -- schedule function on engine
		playerAdded(player)
	end)
end)

players.PlayerRemoving:Connect(function(player)
	task.spawn(function() -- schedule function on engine
		playerRemoving(player)
	end)
end)

task.spawn(setup)

game:BindToClose(function()
	for i,v in game.Players:GetPlayers() do
		saveData(v)
		v:Kick("The Game Server Has Been Closed, Your Data Have been saved")
	end
end)

task.spawn(function()
	for i=1,max do
		spawnCoin()
	end
end)
