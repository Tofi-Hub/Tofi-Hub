-- services --
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local replicatedStorage = game:GetService("ReplicatedStorage")
local vim = game:GetService("VirtualInputManager")
-- local player
local player = players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
local HRP = character:WaitForChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid")
 -- fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Merge Simulator Hub",
    SubTitle = "by @dandush on discord",
    TabWidth = 160,
    Size = UDim2.fromOffset(650, 500),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.K
})

local Tabs = {
    autoMergeTab = Window:AddTab({Title = "Auto Merge Tab" , Icon = "git-merge"}),
    upgradesTab = Window:AddTab({Title = "Auto Upgrade Tab" , Icon = "arrow-up"}),
    tapTab = Window:AddTab({Title = "Auto Tap Tab" , Icon = "mouse-pointer-click"}),
    rebirthTab = Window:AddTab({Title = "Auto Rebirth Toggle", Icon = "repeat"}),
}

local options = Fluent.Options

-- Remotes

local tapRE = replicatedStorage:WaitForChild("Functions"):WaitForChild("Tap")
local rebirthRE = replicatedStorage:WaitForChild("Functions"):WaitForChild("Rebirth")
local takeBlockRE = replicatedStorage:WaitForChild("Functions"):WaitForChild("TakeBlock")
local dropBlockRE = replicatedStorage:WaitForChild("Functions"):WaitForChild("DropBlock")

-- Modules

local infoModule = require(replicatedStorage:WaitForChild("Info"))

-- Static Directories

local plotsDir = workspace:WaitForChild("Plots")

-- Flags

local merging = false

-- Dynamic Variables

local playerPlot

for _,v in pairs(plotsDir:GetChildren()) do -- dynamically find the player's base
    if v.Name == player.Name then playerPlot = v break end
end

-- Functions

local function mergeBlocks(block1 : BasePart , block2:BasePart) : () -- function to merge blocks (easy since the network ownership is set to player ...)

    block1.CFrame = block2.CFrame

    local start = tick()
    repeat task.wait() until tick() - start > 2 or not block1.Parent or not block2.Parent

    if block1.Parent and block2.Parent then
        character:PivotTo(block1.CFrame + Vector3.new(3,2,0))
        task.wait(0.5)
        takeBlockRE:FireServer(block1)
        task.wait(0.5)
        dropBlockRE:FireServer()
        task.wait(0.25)
    end

end

local function getBlockLevel(block : BasePart) : number -- helper function to the the level of a block
    return block:GetAttribute("level")
end

local function mergeAllPossible() -- recursive function the merges all possible merges until none are available
    merging = true
    if not options.AutoMerge.Value then return end
    local merged = false
    local blocks = playerPlot.Blocks:GetChildren()

    for i = 1, #blocks do
        if merged then break end
        for j = 1, #blocks do
            local block1 = blocks[i]
            local block2 = blocks[j]

            if block1 == block2 then continue end

            local level1 = getBlockLevel(block1)
            local level2 = getBlockLevel(block2)

            if level1 == level2 then

                warn("Merged 2 Blocks")
                mergeBlocks(block1, block2)
                merged = true
                break
            end
        end
    end

    if merged then
        task.wait()
        return mergeAllPossible()
    end

    merging = false
end

local function getPlayerCash() : number -- returns the player's money
    return player:GetAttribute("Cash")
end

local function buyUpgrade(upgrade : Frame) : () -- buy upgrade helper
    firesignal(upgrade.Buy.Activated)
end

local function getCheapestUpgrade() : (Frame , number) -- returns the cheapest upgrade and it's cost

    local cheapestUpgrade = nil
    local cheapestCost = math.huge

    for _,upgrade in pairs(player.PlayerGui.World.Upgrades.Main:GetChildren()) do
        if upgrade:GetAttribute("level") then
            local level = upgrade:GetAttribute("level")
            local maxLevel = #infoModule.UpgradeCost[upgrade.Name] + 1
            if level >= maxLevel then continue end
            local cost = infoModule.UpgradeCost[upgrade.Name][level]

            if cost < cheapestCost then
                cheapestCost = cost
                cheapestUpgrade = upgrade
            end
        end
    end

    return cheapestUpgrade , cheapestCost

end

local function getBestBlock() : BasePart

    local bestBlock = nil
    local bestBlockLevel = 0

    for _, block in pairs(playerPlot.Blocks:GetChildren()) do

        if getBlockLevel(block) > bestBlockLevel then

            bestBlockLevel = getBlockLevel(block)
            bestBlock = block

        end

    end

    return bestBlock

end

local function getNextRebirthCost() : ()
    return 65000000 * (1 + player:GetAttribute("Rebirths") * 0.4)
end

-- Gui

Tabs.autoMergeTab:AddToggle("AutoMerge",{Title = "Auto Merge Toggle" , Default = false})

Tabs.upgradesTab:AddToggle("AutoUpgrade",{Title = "Auto Upgrade Toggle" , Default = false})

Tabs.tapTab:AddToggle("AutoTapBest",{Title = "Auto Tap Best Block" , Default = false})

Tabs.rebirthTab:AddToggle("AutoRebirth" ,{Title = "Auto Rebirth Toggle", Default = false})

-- Auto Tap Best Block

local bestBlock = getBestBlock()

local outline = Instance.new("SelectionBox") -- outline around the best block
outline.Adornee = nil
outline.LineThickness = 0.15
outline.SurfaceTransparency = 1
outline.Color3 = Color3.fromRGB(255, 0, 0)
outline.Parent = workspace

local billboard = Instance.new("BillboardGui")
billboard.Adornee = nil
billboard.Size = UDim2.new(0, 200, 0, 100)
billboard.StudsOffset = Vector3.new(0, 5, 0)
billboard.AlwaysOnTop = true
billboard.Parent = workspace

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundTransparency = 1
frame.Parent = billboard

local text = Instance.new("TextLabel")
text.Size = UDim2.new(1, 0, 0, 40)
text.Position = UDim2.new(0, 0, 0, 0)
text.BackgroundTransparency = 1
text.Text = "Tapping This Block"
text.TextColor3 = Color3.fromRGB(255, 255, 255)
text.TextScaled = true
text.Font = Enum.Font.GothamBold
text.Parent = frame


local arrow = Instance.new("ImageLabel")
arrow.Size = UDim2.new(0, 40, 0, 40)
arrow.Position = UDim2.new(0.5, -20, 0, 40)
arrow.BackgroundTransparency = 1
arrow.Image = "rbxassetid://6034818372" -- down arrow
arrow.ImageColor3 = Color3.fromRGB(255, 255, 255)
arrow.Parent = frame

task.spawn(function()
    while true do
        if options.AutoTapBest.Value then
            task.wait()
            outline.Adornee = bestBlock
            billboard.Adornee = bestBlock
            billboard.StudsOffset = Vector3.new(0, bestBlock.Size.Y/2 + 3, 0)
        else
            task.wait(1)
            outline.Adornee = nil
            billboard.Adornee = nil
        end
    end
end)

task.spawn(function()
    while true do
        if options.AutoTapBest.Value then
            task.wait()
            for _ = 1,25 do
                task.spawn(function()
                    tapRE:FireServer(bestBlock)
                end)
            end
        else
            task.wait(1)
        end
    end
end)

-- Auto Merge Connection

playerPlot.Blocks.ChildAdded:Connect(function()

    bestBlock = getBestBlock() -- set new best block

    if options.AutoMerge.Value then
        if not merging then
            mergeAllPossible()
        end
    end

end)

-- Auto Upgrade Loop

task.spawn(function()
    while true do
        if options.AutoUpgrade.Value then
            task.wait(0.1)

            local cheapestUpgrade, cheapestUpgradeCost = getCheapestUpgrade()

            if getPlayerCash() > cheapestUpgradeCost then
                print("Buying Upgrade: " .. cheapestUpgrade.Name .. "With Cost: " .. cheapestUpgradeCost)
                buyUpgrade(cheapestUpgrade)
            end

        else
            task.wait(1)
        end
    end
end)

-- Auto Rebirth Loop

task.spawn(function()
    while true do
        if options.AutoRebirth.Value then
            task.wait(0.1)
            if getNextRebirthCost() < getPlayerCash() then
                rebirthRE:InvokeServer(1)
            end
        else
            task.wait(1)
        end
    end
end)

-- Anti Afk

task.spawn(function()
    while task.wait(100) do
        vim:SendKeyEvent(true, Enum.KeyCode.Tilde, false, nil)
        task.wait(0.1)
        vim:SendKeyEvent(false, Enum.KeyCode.Tilde, false, nil)
    end
end)
