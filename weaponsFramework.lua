--SHOWCASE VID: https://youtu.be/1dMH1QRkVYY
local player = game.Players.LocalPlayer
local character =  player.Character or player.CharacterAdded:Wait()
local humanoid =  character:FindFirstChildOfClass("Humanoid")
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local charactermodule = require(script.Parent.CharacterModule)
local isAiming = false
local walkSpeed = 16
local sprintSpeed = 20
local swayAMT = -.3
local aimSwayAMT = -.2
local currentSwayAMT = swayAMT
local swayCF = CFrame.new( )
local lastCameraCF = CFrame.new()
local aimCF = CFrame.new()
local framework = {
	viewmodel = nil;
	module = nil;	
	Loudout = {
		"AK47";
		"M9";
	};
	currentweapon = -1;
}
local timeFromLastShoot = 0;
local fireAnim = nil
local isReloading = false
local canShoot = true
local reloadAnim = nil
local aimFireAnim = nil
local isShooting = false
local fireSound : Sound = nil
local takeDownAnim
local hasWeapon = false
local function Shoot()
	if framework.module.ammo == 0 or not canShoot then return end
	if isAiming then
		if aimFireAnim then
			aimFireAnim:Play()
		else
			fireAnim:Play()
		end
	else
		fireAnim:Play()

	end
	local torso = character:FindFirstChild("Torso")
	if not torso then
		torso = character:FindFirstChild("UpperTorso")
	end
	fireSound = torso:FindFirstChild("Fire")
	fireSound:Play()
	framework.module.ammo -= 1
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {camera,player.Character,player}
	local ray = Ray.new(camera.CFrame.Position,camera.CFrame.LookVector * 100000)
	local part = workspace:Raycast(camera.CFrame.Position,camera.CFrame.LookVector * 100000,params)
	if part and part.Instance then
		
		game.ReplicatedStorage.Events.DamageHumanoid:FireServer(part.Instance,math.random(framework.module.minDamage,framework.module.maxDamage))
	end
	
end
script.Parent.GetWeaponData.OnClientInvoke = function()
	local data = {}
	table.insert("Shooting",isShooting)
	table.insert("Reloading",isReloading)
	table.insert("Aiming",isAiming)
	return data
end
local function FullAuto(delta)
	if not hasWeapon then return end
	if framework.viewmodel == nil then return end
	if framework.module.ammo == 0 then return end
	if not canShoot then return end
	if not isShooting then return end
	if timeFromLastShoot >= 60 / framework.module.RPM then
		timeFromLastShoot = 0
		Shoot()
	else
		timeFromLastShoot += delta
	end
end
script.Parent.GetFramework.OnInvoke = function()
	return framework
end
local function changeWeapon(newweapon)

	game.ReplicatedStorage.Events.EquipTool:FireServer(humanoid,player.Backpack:FindFirstChild(framework.Loudout[newweapon]))
	local torso = character:FindFirstChild("Torso")
	if not torso then
		torso = character:FindFirstChild("UpperTorso")
	end
	if torso:FindFirstChild("Fire") then
		torso.Fire:Destroy()
	end
	framework.currentweapon = newweapon
	if framework.viewmodel then
		framework.viewmodel:Destroy()
	end
	framework.module = require(game.ReplicatedStorage.Modules:FindFirstChild(framework.Loudout[newweapon]))
	framework.viewmodel = game.ReplicatedStorage.Viewmodels:FindFirstChild(framework.Loudout[newweapon]):Clone()
	framework.viewmodel.Parent = camera
	local animator : Animator = framework.viewmodel:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator")
	fireAnim = Instance.new("Animation")
	fireAnim.Parent = framework.viewmodel
	fireAnim.Name = "Fire"
	fireAnim.AnimationId = "rbxassetid://" .. framework.module.fireAnim
	fireAnim = animator:LoadAnimation(fireAnim)
	reloadAnim = Instance.new("Animation")
	reloadAnim.Parent = framework.viewmodel
	reloadAnim.Name = "Reload"
	reloadAnim.AnimationId = "rbxassetid://" .. framework.module.reloadAnim
	reloadAnim = animator:LoadAnimation(reloadAnim)
	if framework.module.aimFireAnim then
		local animator : Animator = framework.viewmodel:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator")
		aimFireAnim = Instance.new("Animation")
		aimFireAnim.Parent = framework.viewmodel
		aimFireAnim.Name = "AimFire"
		aimFireAnim.AnimationId = "rbxassetid://" .. framework.module.aimFireAnim
		
		aimFireAnim = animator:LoadAnimation(aimFireAnim)
	else
		aimFireAnim = nil
	end
	game.ReplicatedStorage.Events.CreateSound:FireServer(framework.module.fireSound,"Fire")
	takeDownAnim = Instance.new("Animation")
	takeDownAnim.Parent = framework.viewmodel
	takeDownAnim.Name = "TakeDown"
	takeDownAnim.AnimationId = "rbxassetid://" .. framework.module.takeDownAnim
	takeDownAnim = animator:LoadAnimation(takeDownAnim)
end


RunService.RenderStepped:Connect(function(delta)
	local weaponhud = player.PlayerGui:WaitForChild("WeaponHUD").MainFrame
	weaponhud.FireMode.Visible = hasWeapon
	weaponhud.GunName.Visible = hasWeapon
	weaponhud.ReserveAmmo.Visible = hasWeapon
	weaponhud.Ammo.Visible = hasWeapon
	script.Parent.HasWeapon_Client.Value = hasWeapon
	if not hasWeapon then return end
	
	weaponhud.Ammo.Text = framework.module.ammo .. "/" .. framework.module.maxAmmo
	weaponhud.ReserveAmmo.Text = framework.module.reservedAmmo .. "/" .. framework.module.reservedMaxAmmo
	weaponhud.GunName.Text = framework.Loudout[framework.currentweapon]
	weaponhud.FireMode.Text = framework.module.fireMode
	sprintSpeed = charactermodule.sprintspeed
	walkSpeed = charactermodule.walkspeed
	if isAiming then
		currentSwayAMT = math.lerp(currentSwayAMT, aimSwayAMT,0.1)
	else
		currentSwayAMT = math.lerp(swayAMT, aimSwayAMT,0.1)
	end
	local rot = camera. CFrame: ToObjectSpace(lastCameraCF)
	local X, Y,Z = rot : ToOrientation( )
	swayCF = swayCF: Lerp(CFrame.Angles(math.sin(X)* currentSwayAMT, math.sin(Y) * currentSwayAMT, 0), .1)
	lastCameraCF = camera. CFrame

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		local aim = CFrame.new()

		local bobOffset = CFrame.new()
		if humanoid.MoveDirection.Magnitude > 0 then

			if humanoid.WalkSpeed == walkSpeed then

				bobOffset =  bobOffset:Lerp(CFrame.new(math.cos(tick() * 5) * .4,-humanoid.CameraOffset.Y,-humanoid.CameraOffset.Z/3) * CFrame.Angles(0,math.cos(tick() * -4) * -.5,math.sin(tick() * -4) * 0.5),0.1)
			end
			if humanoid.WalkSpeed == sprintSpeed then
				bobOffset =  bobOffset:Lerp(CFrame.new(math.cos(tick() * 9) * .5,-humanoid.CameraOffset.Y,-humanoid.CameraOffset.Z/3) * CFrame.Angles(0,math.cos(tick() * -8) * -1,math.sin(tick() * -8) * 1),0.1)
			end
		else
			bobOffset = CFrame.new(0,-humanoid.CameraOffset.Y/3,0)
		end		
		for i, v in pairs(camera:GetChildren()) do
			if v:IsA("Model") then
				v:PivotTo(camera.CFrame * swayCF * aimCF * bobOffset * require(framework.viewmodel.offset))

			end

		end

	end
	if isAiming and framework.viewmodel ~= nil then
		local offset = require(framework.viewmodel.aimOffset)
		aimCF = aimCF:Lerp(offset, framework.module.aimSmoothness)
	else
		local offset = CFrame.new()
		aimCF = aimCF:Lerp(offset, framework.module.aimSmoothness)

	end
end)
UserInputService.InputBegan:Connect(function(input,proc)
	if input.KeyCode == Enum.KeyCode.One then
		if framework.currentweapon == 1 then return end
		changeWeapon(1)
		hasWeapon = true
	end
	if input.KeyCode == Enum.KeyCode.Two then
		if framework.currentweapon == 2 then return end
		changeWeapon(2)
		hasWeapon =true
	end
	if input.KeyCode == Enum.KeyCode.Three then
		if not hasWeapon then return end
		framework.currentweapon = -1
		hasWeapon = false
		framework.viewmodel:Destroy()
		game.ReplicatedStorage.Events.DestroyTool:FireServer()
	end
	if not hasWeapon then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = true
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if framework.module.fireMode == "Semi" then
			Shoot()
		else
			isShooting = true
		end
	end
	
	if input.KeyCode == Enum.KeyCode.R then
		if isReloading then return end
		if framework.module.reservedAmmo < framework.module.maxAmmo then return end
		if framework.module.ammo == framework.module.maxAmmo then return end
		isReloading = true
		canShoot = false
		fireAnim:Stop()
		reloadAnim:Play()
		task.wait(framework.module.reloadTime)
		canShoot = true
		isReloading = false
		local tominus = framework.module.maxAmmo - framework.module.ammo
		framework.module.ammo = framework.module.maxAmmo
		framework.module.reservedAmmo -= tominus
	end
	if input.KeyCode == Enum.KeyCode.V then
		if not canShoot then return end
		canShoot = false
		takeDownAnim:Play()
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {camera,player.Character,player}
		local ray = Ray.new(camera.CFrame.Position,camera.CFrame.LookVector * 10)
		local part = workspace:Raycast(camera.CFrame.Position,camera.CFrame.LookVector * 10,params)
		if part and part.Instance then

			game.ReplicatedStorage.Events.DamageHumanoid:FireServer(part.Instance,0,true)
		end
		task.wait(.5)
		canShoot = true
	end
end)
UserInputService.InputEnded:Connect(function(input,proc)
	if not hasWeapon then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = false
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if framework.module.fireMode == "Semi" then
		
		else
			isShooting = false
		end
	end
end)
RunService.Heartbeat:Connect(FullAuto)
