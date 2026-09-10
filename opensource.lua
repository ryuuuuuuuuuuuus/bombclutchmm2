local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

local GUI_NAME = "BombClutchGUI"
local FIRERATE = 22
local POWER = 50

local cooldown = false
local locked = false
local bombUnavailable = false
local internalThrow = false
local dragging = false
local dragStart
local startPos
local connections = {}

local CoreGui = game:GetService("CoreGui")

local old1 = CoreGui:FindFirstChild(GUI_NAME)
if old1 then old1:Destroy() end

local old2 = player:WaitForChild("PlayerGui"):FindFirstChild(GUI_NAME)
if old2 then old2:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
	gui.Parent = CoreGui
end)

if not gui.Parent then
	gui.Parent = player:WaitForChild("PlayerGui")
end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 165, 0, 115)
main.Position = UDim2.new(0.5, -82, 0.5, -57)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 27)
title.BackgroundTransparency = 1
title.Text = "BOMB CLUTCH"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = main

local by = Instance.new("TextLabel")
by.Size = UDim2.new(1, 0, 0, 18)
by.Position = UDim2.new(0, 0, 0, 24)
by.BackgroundTransparency = 1
by.Text = "By Farxly"
by.TextColor3 = Color3.fromRGB(150, 150, 150)
by.TextSize = 11
by.Font = Enum.Font.Gotham
by.Parent = main

local clutch = Instance.new("TextButton")
clutch.Size = UDim2.new(0, 145, 0, 30)
clutch.Position = UDim2.new(0.5, -72, 0, 45)
clutch.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
clutch.BorderSizePixel = 0
clutch.Text = "CLUTCH"
clutch.TextColor3 = Color3.fromRGB(255, 255, 255)
clutch.TextSize = 13
clutch.Font = Enum.Font.GothamBold
clutch.Parent = main

local clutchCorner = Instance.new("UICorner")
clutchCorner.CornerRadius = UDim.new(0, 7)
clutchCorner.Parent = clutch

local lock = Instance.new("TextButton")
lock.Size = UDim2.new(0, 68, 0, 25)
lock.Position = UDim2.new(0, 9, 1, -34)
lock.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
lock.BorderSizePixel = 0
lock.Text = "LOCKED"
lock.TextColor3 = Color3.fromRGB(255, 255, 255)
lock.TextSize = 11
lock.Font = Enum.Font.GothamBold
lock.Parent = main

local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(0, 6)
lockCorner.Parent = lock

local delete = Instance.new("TextButton")
delete.Size = UDim2.new(0, 68, 0, 25)
delete.Position = UDim2.new(1, -77, 1, -34)
delete.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
delete.BorderSizePixel = 0
delete.Text = "DELETE"
delete.TextColor3 = Color3.fromRGB(255, 255, 255)
delete.TextSize = 11
delete.Font = Enum.Font.GothamBold
delete.Parent = main

local deleteCorner = Instance.new("UICorner")
deleteCorner.CornerRadius = UDim.new(0, 6)
deleteCorner.Parent = delete

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getFakeBomb()
	local character = player.Character

	if character then
		local tool = character:FindFirstChild("FakeBomb")
		if tool and tool:IsA("Tool") then
			return tool
		end
	end

	local backpack = player:FindFirstChildOfClass("Backpack")

	if backpack then
		local tool = backpack:FindFirstChild("FakeBomb")
		if tool and tool:IsA("Tool") then
			return tool
		end
	end

	return nil
end

local function getHandle(tool)
	if not tool then
		return nil
	end

	local handle = tool:FindFirstChild("Handle")

	if handle and handle:IsA("BasePart") then
		return handle
	end

	return nil
end

local function setBombVisible(tool, visible)
	local handle = getHandle(tool)

	if handle then
		handle.Transparency = visible and 0 or 1
	end
end

local function updateButton()
	if not gui.Parent then
		return
	end

	if cooldown then
		return
	end

	if bombUnavailable then
		clutch.Text = "BOMB OUT"
	else
		clutch.Text = "CLUTCH"
	end
end

local function watchBomb(tool)
	if not tool then
		return
	end

	local handle = getHandle(tool)

	if not handle then
		return
	end

	if handle.Transparency >= 1 and not internalThrow then
		bombUnavailable = true
		updateButton()
	end

	if connections[tool] then
		connections[tool]:Disconnect()
	end

	connections[tool] = handle:GetPropertyChangedSignal("Transparency"):Connect(function()
		if internalThrow then
			return
		end

		if handle.Transparency >= 1 then
			bombUnavailable = true
			updateButton()
		else
			bombUnavailable = false
			updateButton()
		end
	end)
end

local function scanBomb()
	local tool = getFakeBomb()

	if not tool then
		return
	end

	watchBomb(tool)

	local handle = getHandle(tool)

	if handle and handle.Transparency >= 1 then
		bombUnavailable = true
	else
		bombUnavailable = false
	end

	updateButton()
end

local function startCooldown()
	cooldown = true
	bombUnavailable = true

	for remaining = FIRERATE, 1, -1 do
		if not gui.Parent then
			return
		end

		clutch.Text = "COOLDOWN "..remaining.."s"
		task.wait(1)
	end

	local tool = getFakeBomb()

	if tool then
		internalThrow = true
		setBombVisible(tool, true)
		task.wait()
		internalThrow = false

		bombUnavailable = false
		watchBomb(tool)
	else
		bombUnavailable = true
	end

	cooldown = false
	updateButton()
end

local function bombClutch()
	if cooldown or bombUnavailable then
		return
	end

	local character = getCharacter()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	local tool = getFakeBomb()

	if not tool then
		bombUnavailable = true
		updateButton()
		return
	end

	local handle = getHandle(tool)

	if handle and handle.Transparency >= 1 then
		bombUnavailable = true
		updateButton()
		return
	end

	if tool.Parent ~= character then
		humanoid:EquipTool(tool)

		local timeout = os.clock() + 0.6

		while tool.Parent ~= character and os.clock() < timeout do
			task.wait()
		end
	end

	local remote = tool:FindFirstChild("Remote")

	if not remote then
		return
	end

	local target = root.Position - Vector3.new(0, 3, 0)

	internalThrow = true
	remote:FireServer(CFrame.new(target), POWER)
	setBombVisible(tool, false)
	task.wait()
	internalThrow = false

	bombUnavailable = true

	humanoid.Jump = true
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	task.spawn(startCooldown)
end

clutch.MouseButton1Click:Connect(bombClutch)

lock.MouseButton1Click:Connect(function()
	locked = not locked

	if locked then
		lock.Text = "UNLOCK"
	else
		lock.Text = "LOCKED"
	end
end)

delete.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

title.InputBegan:Connect(function(input)
	if locked then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPos = main.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if locked or not dragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

player.CharacterAdded:Connect(function()
	task.wait(1)
	bombUnavailable = false
	cooldown = false
	scanBomb()
end)

task.spawn(function()
	while gui.Parent do
		scanBomb()
		task.wait(0.5)
	end
end)

scanBomb()
