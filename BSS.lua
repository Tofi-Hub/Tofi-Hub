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
local humanoid = character:WaitForChild("Humanoid")

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

local monstersDir = workspace:WaitForChild("Monsters")
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

    collectedPollen = 0
}

-- A State Table To Keep Track Of What The Player Is Doing

local playerState =
{
    -- If Collecting Bubble/Tokens Currently , True

    collectingToken = false,
    collectingBubble = false,

    -- If Converting Backpack Currently, True

    convertingBackpack = false,

    -- If Walking Via Auto Farm Currently , True

    autoFarmWalking = false,

}

-- Variable To Handle Stopping Current Walk, If 2 Walks Collide In Time

local cancelWalk = false

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

    if flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown and options.FlowerSelectDropdown.Value or "Isn't it so cool that tofi hub is open source? join our discord at https://discord.gg/zMjqmUmZ ") then
        return flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value)
    end

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

    if not pos then return end
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

                if playerState.convertingBackpack then return end

                if cancelWalk then
                    cancelWalk = false
                    return
                end

                task.wait()

            until (character:GetPivot().Position - waypoint.Position).Magnitude < 4

        end

    elseif movementMethod == "Tween" then

        local distance = (character:GetPivot().Position - pos.Position).Magnitude
        local speed = options.tweenSpeed and options.tweenSpeed.Value or 70

        tweenProxy.Value = character:GetPivot()

        local duration = distance / speed

        local tween = TS:Create(tweenProxy, TweenInfo.new(duration , Enum.EasingStyle.Linear), {Value = pos})

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

-- Get The New Character After Death

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")

    if options.AutoFarmToggle.Value then
        goTo(flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value) and flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value).CFrame + Vector3.new(0,5,0) , "Tween")
    end

end)

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

local function getNewOptionsAfterSearch(tbl : table, search : string) : table -- for field searching

    local result = {}

    for _,v in pairs(tbl) do

        local strippedValue = v:lower():gsub(" ", "")

        if string.find(strippedValue , search) then
            table.insert(result , v)
        end
    end

    return result

end

local function isPlayerAttacked() : boolean -- returns true if the player is currently being hunted down by a mob

    if not character then return false end

    for _,monster in pairs(monstersDir:GetChildren()) do
        if monster:FindFirstChild("Target") then

            if monster.Target.Value == character then return true end
            
        else

            print("Target Not Found In: " .. monster:GetFullName())

        end
    end

    return false

end

-- GUI

-- Auto Farm Tab

local autoFarmToggle = Tabs.autoFarmTab:AddToggle("AutoFarmToggle",{Title = "Auto Farm Toggle" , Default = false})

local flowerFieldsDropdown

local flowerZonesTable = getStringsOfFolder(flowerZonesDir)
table.insert(flowerZonesTable ,1 , "None")

Tabs.autoFarmTab:AddInput("searchInput" ,
{
    Title = "Search Flower Fields",
    Default = "",
    Placeholder = "Pine Tree Forest",
    Numeric = false,
    Finished = false,
    Callback = function(Value)

        print("Search: " .. Value .. "Got Results: " .. table.concat(getNewOptionsAfterSearch(flowerZonesTable , Value:lower() , " , ")))

        local strippedSearch = Value:lower():gsub(" " , "")

        flowerFieldsDropdown:SetValues(getNewOptionsAfterSearch(flowerZonesTable , strippedSearch))
    end,
})



flowerFieldsDropdown = Tabs.autoFarmTab:AddDropdown(
    "FlowerSelectDropdown",
    {
        Title = "Select Flower Zone To Auto Farm In",
        Values = flowerZonesTable,
        Multi = false,
        Default = 1,
})

flowerFieldsDropdown:OnChanged(function()

    flowerFieldsDropdown:Close() -- minimize dropdown

    if not options.AutoFarmToggle.Value then return end
    if options.FlowerSelectDropdown.Value == "None" then return end

    goTo(flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value) and flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value).CFrame + Vector3.new(0,5,0) , "Tween")

end)

autoFarmToggle:OnChanged(function()
    
    if not options.AutoFarmToggle.Value then return end
    if options.FlowerSelectDropdown.Value == "None" then return end

    goTo(flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value) and flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value).CFrame + Vector3.new(0,5,0) , "Tween")

end)

Tabs.autoFarmTab:AddSection("Settings")

Tabs.autoFarmTab:AddToggle("AutoTool" , {Title = "Auto Use Tool" , Default = true})
Tabs.autoFarmTab:AddToggle("AutoConvert" , {Title = "Auto Convert Toggle" , Default = true})
Tabs.autoFarmTab:AddToggle("AutoFarmBubblesCollect",{Title = "Auto Collect Bubbles", Default = false})
Tabs.autoFarmTab:AddToggle("AutoFarmTokensCollect",{Title = "Auto Collect Tokens", Default = false})
Tabs.autoFarmTab:AddToggle("IgnoreHoneyTokens" , {Title = "Ignore Honey Token Collection When Collecting Tokens" , Default = true})
Tabs.autoFarmTab:AddToggle("AutoFarmMyFieldOnly", {Title = "Only Collect Tokens From Current Farming Field" , Default = true})

Tabs.autoFarmTab:AddSection("Config")

Tabs.autoFarmTab:AddDropdown(
    "SelectedMovementOption",
    {
        Title = "Select Preferred Movement Option",
        Values = { "Tween" , "Walk" , "Teleport" },
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

local lastWalk = tick() -- Variable To Not Change The Walk Route Too Much

local Anim = Instance.new("Animation")
Anim.AnimationId = "rbxassetid://522635514"

local playing = true

local track = humanoid:LoadAnimation(Anim)
track.Looped = true
track:Play() -- loading the animation so that people dont cry


local lastToolCall = tick() -- ik this is innefficent and bad code but i dont wanna actually get the tool cooldown using require so ill just make it collect every like 0.1 seconds

task.spawn(function()
    while true do

        if options.AutoFarmToggle.Value then

            task.wait()

            -- Checks To See If The User Should Auto Farm

            if not humanoid then continue end
            if not character then continue end
            if playerState.collectingBubble then continue end
            if playerState.collectingToken then continue end

            if playerState.convertingBackpack then
                if playing then
                    playing = false
                    track:Stop()
                end

                continue
            end

            -- Auto Use Tool + Handle Tool Animations

            if options.AutoTool.Value then

                if tick() - lastToolCall > 0.1 then -- if more than 0.1 seconds have passed since the last tool toggle

                    if not playing then

                        playing = true
                        track:Play()

                    end

                    toolCollectRE:FireServer()

                    lastToolCall = tick()

                end

            else
                if playing then
                    playing = false
                    track:Stop()
                end
            end

            -- So The Player Doesnt Get Killed Instantly Upon Going To Field

            if isPlayerAttacked() then
                humanoid.Jump = true
            end

            -- Make The Player Walk A Bit

            local playerField = getPlayerField()

            if playerField then

                if tick() - lastWalk > 3 then

                    local randomFieldX = math.random(playerField.Position.X - playerField.Size.X / 2 , playerField.Position.X + playerField.Size.X / 2)
                    local randomFieldZ = math.random(playerField.Position.Z - playerField.Size.Z / 2 , playerField.Position.Z + playerField.Size.Z / 2)

                    local randomFieldPosition = Vector3.new(randomFieldX , playerField.Position.Y , randomFieldZ)

                    humanoid.WalkToPoint = randomFieldPosition -- will always walk here since i dont wanna use goTo since it does unnecesarry pathfiniding + yields
                    lastWalk = tick()

                end
            end

        else
            task.wait(1)

                if playing then
                    playing = false
                    track:Stop()
                end

        end

    end

end)

-- Auto Convert Loop

task.spawn(function()
    while true do
        if options.AutoConvert.Value then
            task.wait(0.5)

            if not character then continue end

            if coreStats.Pollen.Value >= coreStats.Capacity.Value then

                print("Converting Backpack")

                playerState.convertingBackpack = true
                humanoid:Move(Vector3.new(0,0,0))

                goTo(playerHive.SpawnPos.Value + Vector3.new(0,5,0) , options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)

                task.wait(0.5)

                playerHiveCommandRE:FireServer("ToggleHoneyMaking")

                repeat
                    task.wait(1) 

                    if player.PlayerGui.ScreenGui.ActivateButton.Position.Y.Offset < -100 then
                        print("Going To Hive")
                        goTo(playerHive.SpawnPos.Value + Vector3.new(0,5,0) , options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value) 
                    end
                    if player.PlayerGui.ScreenGui.ActivateButton.TextBox.Text == "Make Honey" then 
                        print("Toggling Honey Making")
                        playerHiveCommandRE:FireServer("ToggleHoneyMaking") 
                    end
                    
                until coreStats.Pollen.Value == 0

                local balloon = getPlayerBalloon()

                if balloon then
                    repeat task.wait() until not balloon or not balloon.Parent
                end

                playerState.convertingBackpack = false

                if options.AutoFarmToggle.Value then
                    goTo(flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value) and flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value).CFrame + Vector3.new(0,5,0) , options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)
                    print("Returned To Field")
                end

            end

        else
            task.wait(2)
        end
    end
end)

-- Auto Collect Tokens / Bubbles

local trackedTokens = setmetatable({}, { __mode = "k" })

task.spawn(function()
    while true do
        task.wait()

        if not character or playerState.collectingBubble or playerState.collectingToken or playerState.convertingBackpack or not options.AutoFarmToggle.Value then
            continue
        end

        local charPos = character:GetPivot().Position
        local playerField = getPlayerField()
        if not playerField then continue end

        local closestBubble, closestToken
        local bubbleDist, tokenDist = math.huge, math.huge

        if options.AutoFarmBubblesCollect.Value then

            for _, bubble in pairs(particlesDir:GetChildren()) do

                if bubble.Name == "Bubble" and isPointInPart2D(playerField, bubble.Position) then

                    local dist = (bubble.Position - charPos).Magnitude

                    if dist < bubbleDist then

                        bubbleDist = dist
                        closestBubble = bubble

                    end
                end
            end
        end

        if options.AutoFarmTokensCollect.Value then

            for _, token in pairs(collectiblesDir:GetChildren()) do
                if not trackedTokens[token] and not table.find(collectiblesSnapshot, token) then

                    if options.AutoFarmMyFieldOnly.Value then
                    
                        if not isPointInPart2D(playerField, token.Position) then continue end

                    end

                    if options.IgnoreHoneyTokens.Value then

                        if token.FrontDecal.Texture ~= "rbxassetid://1472135114" then

                            local dist = (token.Position - charPos).Magnitude

                            if dist < tokenDist then

                                    tokenDist = dist
                                    closestToken = token

                            end

                        end
                        
                    else

                        local dist = (token.Position - charPos).Magnitude

                        if dist < tokenDist then

                            tokenDist = dist
                            closestToken = token

                        end

                    end
                end
            end

        end

        local shouldGet, kind
        if closestBubble and closestToken then

            if bubbleDist < tokenDist then

                shouldGet, kind = closestBubble, "Bubble"

            else

                shouldGet, kind = closestToken, "Token"

            end

        elseif closestBubble then

            shouldGet, kind = closestBubble, "Bubble"

        elseif closestToken then

            shouldGet, kind = closestToken, "Token"

        else

            continue

        end

        if kind == "Bubble" then

            playerState.collectingBubble = true

            goTo(CFrame.new(shouldGet.Position), options.SelectedMovementOption.Value)

            repeat task.wait() until not shouldGet.Parent

            playerState.collectingBubble = false

        else

            playerState.collectingToken = true

            goTo(CFrame.new(shouldGet.Position), options.SelectedMovementOption.Value)
            task.wait(0.1)

            trackedTokens[shouldGet] = true
            playerState.collectingToken = false
        end
    end
end)
