-- Services

local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local replicatedStorage = game:GetService("ReplicatedStorage")
local pathfindingService = game:GetService("PathfindingService")
local TS = game:GetService("TweenService") -- ts is short for type shit btw 🤓
local RS = game:GetService("RunService") -- rs is short for right shit btw 🤓

-- Local Player

local player = players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

 -- Fluent UI Setup

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Tofi Hub",
    SubTitle = "by @dandush on discord",
    TabWidth = 160,
    Size = UDim2.fromOffset(650, 500),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.K
})

local Tabs = {
    autoFarmTab = Window:AddTab({Title = "Auto Farm Tab",Icon = "flower-2"}),
    lpTab = Window:AddTab({Title = "Player Modification Tab", Icon = "user"}),
    sessionStatsTab = Window:AddTab({Title = "Session Stats Tab" , Icon = "info"})
}

local options = Fluent.Options

-- Static Directories

local particlesDir = workspace:WaitForChild("Particles")
local flowerZonesDir = workspace:WaitForChild("FlowerZones")
local coreStats = player:WaitForChild("CoreStats")
local hivesDir = workspace:WaitForChild("Honeycombs")
local hiveBalloonsDir = workspace:WaitForChild("Balloons"):WaitForChild("HiveBalloons")

local collectiblesDir = workspace:WaitForChild("Collectibles")

local collectiblesSnapshot = collectiblesDir:GetChildren() -- At This Time, The Collectibles Will Only Hold Sutff Like Royal Jelly So This Is Like An "Ignore List" Snapshot

-- Remote Events

local eventsDir = replicatedStorage:WaitForChild("Events")
local playerHiveCommandRE = eventsDir:WaitForChild("PlayerHiveCommand")
local toolCollectRE = eventsDir:WaitForChild("ToolCollect")
local claimHiveRE = eventsDir:WaitForChild("ClaimHive")

-- A Table To Hold Session Information , Visual Only

local session = {

    poppedBubbles = 0,
    collectedTokens = 0,
    collectedPollen = 0
}

-- A State Table To Keep Track Of What The Player Is Doing

local playerState =
{
    autoFarming = false,
    collectingToken = false,
    collectingBubble = false,
    convertingBackpack = false,

}

-- Tables To Store Queued Tokens And Bubbles, These Are Bubbles And Tokens That Were Stored While Other Stuff Was Happening

local queued =
{
    queuedBubbles = {},
    queuedTokens = {},
}

-- Get The New Character After Death

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:FindFirstChildOfClass("Humanoid")
end)

-- Dynamic Variables

local playerHive

for _,hive in pairs(hivesDir:GetChildren()) do -- get the player hive
    if hive.Owner.Value == player then
        playerHive = hive
        break
    end
end

-- Settings for the getPlayerField() Function

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Whitelist
params.FilterDescendantsInstances = {flowerZonesDir}

local function getPlayerField() : BasePart -- will return the field instance inside flowerZonesDir
    if not character then return nil end

    local origin = character:GetPivot().Position -- get origin position
    local direction = Vector3.new(0,-20,0) -- cast the raycast 10 studs down

    local result = workspace:Raycast(origin , direction , params)

    return result and result.Instance or nil

end


local function getStringsOfFolder(folder : Folder) : table
    local toReturn = {}

    for _,child in pairs(folder:GetChildren()) do
        table.insert(toReturn,child.Name)
    end

    return toReturn

end

local function isPointInPart2D(part : BasePart, point : Vector3) : boolean -- this function return whether a point is on a part's XZ plane

	local sizeX = part.Size.X
	local sizeZ = part.Size.Z

	local posX = part.Position.X
	local posZ = part.Position.Z

	local left = posX - sizeX / 2
	local right = posX + sizeX / 2
	local top = posZ - sizeZ / 2
	local bottom = posZ + sizeZ / 2

	if point.X >= left and point.X <= right and point.Z >= top and point.Z <= bottom then
		return true
	else
		return false
	end
end

local tweenProxy = Instance.new("CFrameValue") -- makes a way to communicate between the tween and the pivotTo connections since only :PivotTo() works for teleporting character and tween does not support that

local function goTo(pos : CFrame, method : string) : () -- main function for movement , will support different movement methods

    if not character then return end

    local movementMethod = method

    if movementMethod == "Walk" then
        local path = pathfindingService:CreatePath()
        path:ComputeAsync(character:GetPivot().Position, pos.Position)

        if path.Status ~= Enum.PathStatus.Success then

            warn("Pathfinding failed!")
            return

        end

        local waypoints = path:GetWaypoints()

        for _,waypoint in ipairs(waypoints) do

            humanoid.WalkToPoint = waypoint.Position

            repeat

                humanoid.WalkToPoint = waypoint.Position

                task.wait()

            until (character:GetPivot().Position - waypoint.Position).Magnitude < 4

        end

    elseif movementMethod == "Tween" then

        local distance = (character:GetPivot().Position - pos.Position).Magnitude
        local speed = options.tweenSpeed and options.tweenSpeed.Value or 70

        tweenProxy.Value = character:GetPivot()

        local duration = distance / speed

        local tween = TS:Create(tweenProxy, TweenInfo.new(duration), {Value = pos})

        -- Update pivot each frame as the tween runs
        local connection
        connection = RS.Heartbeat:Connect(function()
        	character:PivotTo(tweenProxy.Value)
        end)

        tween:Play()

        tween.Completed:Wait()

        connection:Disconnect()

    elseif movementMethod == "Teleport" then

        character:PivotTo(pos)

    end

end

local function getClosestObjectInTable(tbl : table , position : Vector3) : BasePart

    local closestItem = nil
    local closestDistance = math.huge

    for _,item in pairs(tbl) do

        local itemPos = item.ClassName == "Model" and item:GetPivot().Position or item.Position

        local distance = (itemPos - position).Magnitude
        
        if distance < closestDistance then

            closestDistance = distance
            closestItem = item

        end

    end

    return closestItem

end

local function getPlayerBalloon() : Folder -- gets the player's balloon if it exists or nil

    for _,balloonInstance in pairs(hiveBalloonsDir:GetChildren()) do

        if getClosestObjectInTable(hivesDir:GetChildren() , balloonInstance.BalloonRoot.Position) == playerHive then

            return balloonInstance

        end

    end

    return nil

end

-- GUI

-- Auto Farm Tab

local autoFarmToggle = Tabs.autoFarmTab:AddToggle("AutoFarmToggle",{Title = "Auto Farm Toggle" , Default = false})

local flowerZonesTable = getStringsOfFolder(flowerZonesDir)
table.insert(flowerZonesTable ,1 , "None")

Tabs.autoFarmTab:AddDropdown(
    "FlowerSelectDropdown",
    {
        Title = "Select Flower Zone To Auto Farm In",
        Values = flowerZonesTable,
        Multi = false,
        Default = 1,
})

autoFarmToggle:OnChanged(function()
    
    if not options.AutoFarmToggle.Value then return end
    if options.FlowerSelectDropdown.Value == "None" then return end

    goTo(flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value) and flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value).CFrame , "Tween")

end)

Tabs.autoFarmTab:AddSection("Settings")

Tabs.autoFarmTab:AddToggle("AutoTool" , {Title = "Auto Use Tool" , Default = true})
Tabs.autoFarmTab:AddToggle("AutoConvert" , {Title = "Auto Convert Toggle" , Default = true})
Tabs.autoFarmTab:AddToggle("AutoFarmBubblesCollect",{Title = "Auto Collect Bubbles", Default = false})
Tabs.autoFarmTab:AddToggle("AutoFarmTokensCollect",{Title = "Auto Collect Tokens", Default = false})
Tabs.autoFarmTab:AddToggle("AutoFarmMyFieldOnly", {Title = "Only Collect Tokens From Current Farming Field" , Default = true})

Tabs.autoFarmTab:AddSection("Config")

Tabs.autoFarmTab:AddDropdown(
    "SelectedMovementOption",
    {
        Title = "Select Preferred Movement Option",
        Values = { "Teleport" , "Walk" , "Tween" },
        Multi = false,
        Default = 1
    }
)

Tabs.autoFarmTab:AddSlider("tweenSpeed",
    {
        Title = "Tween Speed",
        Description = "How Fast The Tween Will Be If Using The Tween Movement Setting",
        Default = 70,
        Min = 1,
        Max = 200,
        Rounding = 0,
    })

Tabs.autoFarmTab:AddSlider("maxTokenCollectTimeout",
    {
        Title = "Tokens Collect Timeout",
        Description = "Amount of Time To Wait Before Abandoning A Token's Collection",
        Default = 5,
        Min = 1,
        Max = 15,
        Rounding = 0,
    })

Tabs.autoFarmTab:AddSlider("maxBubbleCollectTimeout",
    {
        Title = "Bubbles Collect Timeout",
        Description = "Amount of Time To Wait Before Abandoning A Bubble's Collection",
        Default = 5,
        Min = 1,
        Max = 15,
        Rounding = 0,
    })


-- Local Player Tab

Tabs.lpTab:AddSlider("walkSpeedSlider",
    {
        Title = "Walk Speed Slider",
        Description = "Changes The Speed In Which You Walk!",
        Default = humanoid.WalkSpeed,
        Min = 1,
        Max = 300,
        Rounding = 0,
    })

Tabs.lpTab:AddSlider("jumpPowerSlider",
    {
        Title = "Jump Power Slider",
        Description = "Changes The Height Of Your Jumps!",
        Default = humanoid.JumpPower,
        Min = 1,
        Max = 500,
        Rounding = 0,
    })

task.spawn(function()
    while true do
        task.wait(0.1)

        if not humanoid then continue end

        humanoid.JumpPower = tonumber(options.jumpPowerSlider.Value)
        humanoid.WalkSpeed = tonumber(options.walkSpeedSlider.Value)
    end
end)

-- Session Statistics Tab

local sessionStatsParagraph = Tabs.sessionStatsTab:AddParagraph({Title = "Session Statistics" , Content = "Loading ..."})

local function updateStats() : ()

    local str = ""

    str = str .. "Gathered Pollen: " .. session.collectedPollen .. "\n"

    sessionStatsParagraph:SetDesc(str)

end

updateStats() -- update for the first time so its not loading anymore

-- Get Player Hive If Not Picked Up

if not playerHive then
    for _,v in pairs(hivesDir:GetChildren()) do
        if not v.Owner.Value then
            goTo(v:GetPivot() , "Tween")
            claimHiveRE:FireServer(v.HiveID.Value)
            playerHive = v
            break
        end
    end
end

-- Auto Farm Loop

local lastToolCall = tick() -- ik this is innefficent and bad code but i dont wanna actually get the tool cooldown using require so ill just make it collect every like 0.1 seconds

task.spawn(function()
    while true do

        if options.AutoFarmToggle.Value then

            task.wait()

            -- Checks To See If The User Should Auto Farm

            if not character then continue end
            if playerState.collectingBubble then continue end
            if playerState.collectingToken then continue end
            if playerState.convertingBackpack then continue end

            if options.AutoTool.Value then

                if tick() - lastToolCall > 0.1 then -- if more than 0.1 seconds have passed since the last tool toggle

                    toolCollectRE:FireServer()

                    lastToolCall = tick()

                end

            end

        else
            task.wait(1)
        end

    end

end)

-- Auto Convert Loop

task.spawn(function()
    while true do
        if options.AutoConvert.Value then
            task.wait(0.5)

            if coreStats.Pollen.Value >= coreStats.Capacity.Value then
                playerState.convertingBackpack = true

                goTo(playerHive.SpawnPos.Value , options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)

                task.wait(0.5)

                playerHiveCommandRE:FireServer("ToggleHoneyMaking")

                repeat task.wait() until coreStats.Pollen.Value == 0

                local balloon = getPlayerBalloon()

                if balloon then
                    repeat task.wait() until not balloon or not balloon.Parent
                end

                playerState.convertingBackpack = false

                if options.AutoFarmToggle.Value then
                    goTo(flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value) and flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value).CFrame , options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)
                end

            end

        else
            task.wait(2)
        end
    end
end)

-- Auto Collect Tokens / Bubbles

-- Chat GPT Is My Lord And Savor, This Is A "Weak" Table That Forgets Instances When They Get Deleted / Destroyed So That I Wont Have To Clear It Myself

local trackedTokens = setmetatable({}, { __mode = "k" })

task.spawn(function()
    while true do

        task.wait()

        if not character then continue end
        if playerState.collectingBubble then continue end
        if playerState.collectingToken then continue end
        if playerState.convertingBackpack then continue end

        local playerField = getPlayerField()

        if not playerField then continue end

        -- Get Closest Token And Bubble

        local closestBubble = nil
        local closestToken = nil

        -- GET CLOSEST BUBBLE

        if options.AutoFarmBubblesCollect.Value then

            local tbl = {}

            for _,bubble in pairs(particlesDir:GetChildren()) do

                if bubble.Name == "Bubble" then

                    if isPointInPart2D(playerField , bubble.Position) then

                        table.insert(tbl,bubble)

                    end

                end

            end

            closestBubble = getClosestObjectInTable(tbl , character:GetPivot().Position)

        end

        -- GET CLOSEST TOKEN

        if options.AutoFarmTokensCollect.Value then

            local tbl = {}

            for _,token in pairs(collectiblesDir:GetChildren()) do

                if trackedTokens[token] then continue end
                if table.find(collectiblesSnapshot , token) then continue end

                if isPointInPart2D(playerField , token.Position) then

                    table.insert(tbl,token)

                end

            end

            closestToken = getClosestObjectInTable(tbl , character:GetPivot().Position)

        end

        -- GET TOKEN / BUBBLE (based on whats closer)

        if closestBubble and closestToken then

            -- Get Closer (Bubble/Token) And Store It Into "shouldGet"

            local shouldGet, kind

            if (closestBubble.Position - character:GetPivot().Position).Magnitude < (closestToken.Position - character:GetPivot().Position).Magnitude then

                shouldGet, kind = closestBubble, "Bubble"

            else

                shouldGet, kind = closestToken, "Token"

            end

            if kind == "Bubble" then

                playerState.collectingBubble = true

                goTo(CFrame.new(shouldGet.Position) , options.SelectedMovementOption.Value)

                local start = tick()

                repeat task.wait() until tick() - start > tonumber(options.maxBubbleCollectTimeout.Value) or not shouldGet.Parent or not shouldGet

                playerState.collectingBubble = false

            else

                playerState.collectingToken = true

                goTo(CFrame.new(shouldGet.Position) , options.SelectedMovementOption.Value)

                task.wait(0.3)

                trackedTokens[shouldGet] = true

                playerState.collectingToken = false

            end

        elseif closestToken then

            playerState.collectingToken = true

            goTo(CFrame.new(closestToken.Position) , options.SelectedMovementOption.Value)

            task.wait(0.3)

            trackedTokens[closestToken] = true
            playerState.collectingToken = false

        elseif closestBubble then

            playerState.collectingBubble = true

            goTo(CFrame.new(closestBubble.Position) , options.SelectedMovementOption.Value)

            local start = tick()

            repeat task.wait() until tick() - start > tonumber(options.maxBubbleCollectTimeout.Value) or not closestBubble.Parent or not closestBubble

            playerState.collectingBubble = false

        end

    end
end)
