-- Services

local HttpService = game:GetService("HttpService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local replicatedStorage = game:GetService("ReplicatedStorage")
local pathfindingService = game:GetService("PathfindingService")
local TS = game:GetService("TweenService") -- ts is short for type shit btw 🤓
local RS = game:GetService("RunService") -- rs is short for right shit btw 🤓
local VIM = game:GetService("VirtualInputManager") -- yes yes it like vim btw 🤓

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
    autoFarmTab = Window:AddTab({Title = "Auto Farm Tab",Icon = "droplet"}),
    bugRunTab = Window:AddTab({Title = "Bug Run Tab" , Icon = "bug"}),
    planterTab = Window:AddTab({Title = "Planters Tab" , Icon = "sprout"}),
    lpTab = Window:AddTab({Title = "Player Modification Tab", Icon = "user"}),
    sessionStatsTab = Window:AddTab({Title = "Session Stats Tab" , Icon = "info"}),
}

local options = Fluent.Options

-- Static Directories

local monstersDir = workspace:WaitForChild("Monsters")
local particlesDir = workspace:WaitForChild("Particles")
local flowerZonesDir = workspace:WaitForChild("FlowerZones")
local hivesDir = workspace:WaitForChild("Honeycombs")
local hiveBalloonsDir = workspace:WaitForChild("Balloons"):WaitForChild("HiveBalloons")
local monsterSpawnersDir = workspace:WaitForChild("MonsterSpawners")
local coreStats = player:WaitForChild("CoreStats")

local collectiblesDir = workspace:WaitForChild("Collectibles")

local collectiblesSnapshot = collectiblesDir:GetChildren() -- At This Time, The Collectibles Will Only Hold Sutff Like Royal Jelly So This Is Like An "Ignore List" Snapshot

-- Controllers For The Script

local PlanterController = {}
local FarmController = {}
local ConvertController = {}
local BugRunController = {}
local CollectorController = {}
local ToolController = {}
local MovementController = {}

-- Module Scripts

local function safeRequire(module)

	local success, result = pcall(require, module)

	if success then

		return result

	else

		warn("Failed to require module:", module:GetFullName(), result)
		return nil

	end

end

-- Bug Run Modules

local clientStatCache = safeRequire(replicatedStorage.ClientStatCache)
local osTime = safeRequire(replicatedStorage.OsTime)
local monsterTypes = safeRequire(replicatedStorage.MonsterTypes)

-- Planter Modules

local plantersModule = require(replicatedStorage.PlayerActives)
local localPlantersModule = require(replicatedStorage.LocalPlanters)
local buffsTileModule = require(replicatedStorage.Gui.TileDisplay.BuffTile)
local planterDataModule = require(replicatedStorage.PlanterTypes)

-- Remote Events


local eventsDir = replicatedStorage:WaitForChild("Events")
local playerHiveCommandRE = eventsDir:WaitForChild("PlayerHiveCommand")
local playerActivateRE = eventsDir:WaitForChild("PlayerActivesCommand")
local toolCollectRE = eventsDir:WaitForChild("ToolCollect")
local claimHiveRE = eventsDir:WaitForChild("ClaimHive")

-- planter remotes

local planterCollectRE = eventsDir:WaitForChild("PlanterModelCollect")

-- A Table To Hold Session Information , Visual Only

local session = {

    collectedPollen = 0
}

-- Custom Data For The Bug Run, Since Alot Of Monster's Territories are Directly On Top Of Where They Spawn, I Gotta Overwrite That

local customBugRunData = {
    ["MushroomBush"] = flowerZonesDir:WaitForChild("Mushroom Field"),
    ["WerewolfCave"] = flowerZonesDir:WaitForChild("Cactus Field"),
    ["Spider Cave"] = flowerZonesDir:WaitForChild("Spider Field")
}

-- Custom Data For What Nectar Type Each Field Gives

local fieldsNectar = {
    ["Pine Tree Forest"]   = "Comforting Nectar",
    ["Blue Flower Field"]  = "Refreshing Nectar",
    ["Spider Field"]       = "Motivating Nectar",
    ["Sunflower Field"]    = "Satisfying Nectar",
    ["Clover Field"]       = "Invigorating Nectar",
}


-- A State Table To Keep Track Of What The Player Is Doing

local playerState =
{
    -- Auto Collect Bubbles / Tokens

    collectingToken = false,
    collectingBubble = false,

    -- Auto Convert

    convertingBackpack = false,

    -- Auto Farm

    autoFarmingInField = false,

    -- Bug Run

    killingBugs = false,

    -- Current Field Used For Auto Farming, Bug Killing ETC

    currentField = nil,

    -- Current Overall State, Visual Only

    state = "Idling",

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

local function getFieldByPos(pos : Vector3) : BasePart

    local origin = pos
    local direction = Vector3.new(0,-20,0) -- cast the raycast 20 studs down

    local result = workspace:Raycast(origin , direction , params)

    return result and result.Instance or nil

end

local function getPlayerField() : BasePart -- will return the field instance inside flowerZonesDir

    if playerState.currentField then return playerState.currentField end

    if not character then return nil end

    return getFieldByPos(character:GetPivot().Position) -- if no field defined then cast a raycast down

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

local function getMonsterCooldown(spawner : BasePart) : number

    if not clientStatCache or not osTime or not monsterTypes then return 69420 end

    local spawnerName = spawner.Name

    local lastKill = clientStatCache:Get({ "MonsterTimes", spawnerName }) or 0
    local now = math.floor(osTime())
    local baseCooldown = monsterTypes.Get(spawner.MonsterType.Value).Stats.RespawnCooldown

    local elapsed = now - lastKill

    return baseCooldown - elapsed

end

local function getMonsterModel(monsterType : string) : Model

    for _,monster in pairs(monstersDir:GetChildren()) do

        if monster:FindFirstChild("MonsterType") and monster.MonsterType.Value or "" == monsterType then

            if monster:FindFirstChild("Target") and monster.Target.Value == character then

                return monster

            end
        end
    end
end

local function killBug(spawner : BasePart) : ()

    if not character then return end
    if playerState.convertingBackpack then return end

    if not spawner then warn("Spawner Instance Not For For: " .. spawner) return end

    playerState.currentField = nil
    playerState.autoFarmingInField = false

    local spawnerPos = (customBugRunData[spawner.Name] and customBugRunData[spawner.Name].CFrame) or (spawner:FindFirstChild("Territory") and spawner.Territory.Value.CFrame) or spawner.CFrame

    goTo(spawnerPos , options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)

    playerState.currentField = (customBugRunData[spawner.Name]) or (spawner.Territory.Value and spawner.Territory.Value:IsA("BasePart") and spawner.Territory.Value or getPlayerField())

    local monsterModel = nil

    local start = tick()

    repeat

        task.wait()
        
        monsterModel = getMonsterModel(spawner.MonsterType.Value)

        goTo(spawnerPos , options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)

        playerState.currentField = (customBugRunData[spawner.Name]) or (spawner.Territory.Value and spawner.Territory.Value:IsA("BasePart") and spawner.Territory.Value or getPlayerField())

        if not options.BugRunToggle.Value then return end
        if getMonsterCooldown(spawner) > 5 then return end

    until monsterModel or tick() - start > 10

    if not monsterModel then return end

    start = tick()

    repeat

        playerState.currentField = (customBugRunData[spawner.Name]) or (spawner.Territory.Value and spawner.Territory.Value:IsA("BasePart") and spawner.Territory.Value or getPlayerField())

        if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then

            humanoid.Jump = true

            task.wait(0.2)

            goTo(spawnerPos , options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)

        end

        task.wait()

    until not monsterModel or not monsterModel.Parent or tick() - start > 45

    task.wait(0.3)

    CollectorController.collectUntilNoTokens()

end

local function placeSprinker() : ()
    humanoid.Jump = true
    task.wait(0.1)
    playerActivateRE:FireServer({["Name"] = "Sprinkler Builder"})
end

local function formatNumberString(numString : string) : string
    local str = ""
    local count = 0

    for i = #numString, 1, -1 do
        str = numString:sub(i,i) .. str
        count = count + 1

        if count % 3 == 0 and i ~= 1 then
            str = "," .. str
        end
    end

    return str
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

end)

Tabs.autoFarmTab:AddSection("Settings")

Tabs.autoFarmTab:AddToggle("AutoTool" , {Title = "Auto Use Tool" , Default = true})
Tabs.autoFarmTab:AddToggle("AutoConvert" , {Title = "Auto Convert Toggle" , Default = true})
Tabs.autoFarmTab:AddToggle("AutoFarmBubblesCollect",{Title = "Auto Collect Bubbles", Default = false})
Tabs.autoFarmTab:AddToggle("AutoFarmTokensCollect",{Title = "Auto Collect Tokens", Default = false})
Tabs.autoFarmTab:AddToggle("IgnoreHoneyTokens" , {Title = "Ignore Honey Token Collection When Collecting Tokens" , Default = true})
Tabs.autoFarmTab:AddToggle("AutoFarmMyFieldOnly", {Title = "Only Collect Tokens From Current Field" , Default = true})

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

-- Bug Run Tab

Tabs.bugRunTab:AddToggle("BugRunToggle" , {Title = "Bug Run Toggle", Default = false})

Tabs.bugRunTab:AddDropdown("BugsIgnoreList",
{
    Title = "Select Bugs To *IGNORE* Automatic Killing For",
    Values = getStringsOfFolder(monsterSpawnersDir),
    Multi = true,
    Default = {"CaveMonster1","CaveMonster2" , "Commando Chick" , "CoconutCrab" , "StumpSnail","TunnelBear" , "King Beetle Cave" , ""}
})

-- Planters Tab

Tabs.planterTab:AddToggle("AutoPlanterToggle", {Title = "Auto Plant / Collect Planters" , Default = false})

Tabs.planterTab:AddSlider("PlanterGrowthPercentGoal", {
    Title = "Planter Percent Goal",
    Description = "How Much Does The Planter Need To be Grown In Order To Be Collected",
    Default = 25,
    Min = 0,
    Max = 100,
    Rounding = 0,
})

Tabs.planterTab:AddSlider("PlanterGrowthTimeGoal", {
    Title = "Planter Time Goal",
    Description = "How Many Hours Does The Planter Need Planted Before Collection",
    Default = 3,
    Min = 1,
    Max = 12,
    Rounding = 1,
})

Tabs.planterTab:AddSection("Nectar Goals")

Tabs.planterTab:AddSlider("ComfortingNectarGoal", {
    Title = "Comforting Nectar Goal",
    Description = "The % Of Comforting Nectar You Want (100% being 24 hours)",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0
})

Tabs.planterTab:AddSlider("MotivatingNectarGoal", {
    Title = "Motivating Nectar Goal",
    Description = "The % Of Motivating Nectar You Want (100% being 24 hours)",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0
})

Tabs.planterTab:AddSlider("SatisfyingNectarGoal", {
    Title = "Satisfying Nectar Goal",
    Description = "The % Of Satisfying Nectar You Want (100% being 24 hours)",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0
})

Tabs.planterTab:AddSlider("InvigoratingNectarGoal", {
    Title = "Invigorating Nectar Goal",
    Description = "The % Of Invigorating Nectar You Want (100% being 24 hours)",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0
})

Tabs.planterTab:AddSlider("RefreshingNectarGoal", {
    Title = "Refreshing Nectar Goal",
    Description = "The % Of Refreshing Nectar You Want (100% being 24 hours)",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0
})


Tabs.planterTab:AddSection("Nectar Amounts")

local nectarInfoPar = Tabs.planterTab:AddParagraph({Title = "", Content = "Loading..."})

Tabs.planterTab:AddSection("Planted")

local playerPlantersPar = Tabs.planterTab:AddParagraph({Title = "", Content = "Loading..."})

Tabs.planterTab:AddSection("Suggested Next")

local nextPlanterPar = Tabs.planterTab:AddParagraph({Title = "", Content = " Loading..."})

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

        if Fluent.Unloaded then break end

        if not humanoid then continue end

        humanoid.JumpPower = tonumber(options.jumpPowerSlider.Value)
        humanoid.WalkSpeed = tonumber(options.walkSpeedSlider.Value)
    end
end)

-- Session Statistics Tab

local sessionStatsParagraph = Tabs.sessionStatsTab:AddParagraph({Title = "Session Statistics" , Content = "Loading ..."})

-- keep track of session honey

local lastHoney = coreStats.Honey.Value
local curTween : Tween = nil
local polValue = Instance.new("NumberValue")

coreStats.Honey:GetPropertyChangedSignal("Value"):Connect(function()

    if coreStats.Honey.Value > lastHoney then

        session.collectedPollen += coreStats.Honey.Value - lastHoney

    end

    if curTween then curTween:Cancel() end

    curTween = TS:Create(polValue , TweenInfo.new(1,Enum.EasingStyle.Linear) , {Value = session.collectedPollen})

    curTween:Play()

    lastHoney = coreStats.Honey.Value

end)

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

local function updateVisuals() : ()

    local str = ""

    str = str .. "Gathered Pollen: " .. formatNumberString(tostring(math.floor(polValue.Value))) .. "\n"

    sessionStatsParagraph:SetDesc(str)
    
    str = ""

    for name,percentage in pairs(PlanterController.getActiveNectarPercentages()) do
        str ..= string.format("%s : %.1f%% \n" , name , percentage)
    end

    nectarInfoPar:SetDesc(str)

    str = ""

    for _ , planterData in pairs(PlanterController.getPlantedPlanters()) do

        str ..= string.format("Name: %s | Field: %s | Growth: %.1f%%\n" , planterData.PotModel.Name , getFieldByPos(planterData.Pos + Vector3.new(0,7,0)).Name , planterData.GrowthPercent * 100)

    end

    playerPlantersPar:SetDesc(str)

    str = ""

    local nextField = PlanterController.determineNextField()
    local nextPlanter = PlanterController.getPlanterForField(nextField)

    local planterText = nextPlanter and tostring(nextPlanter) or "No Planter Found"
    local fieldText = nextPlanter and nextField and nextField.Name or "No Field Found"
    local nectarText = nextPlanter and (nextField and fieldsNectar[nextField.Name]) or "Nectar Not Found"

    str = "Planter: " .. planterText .. " | Field: " .. fieldText .. " | Nectar: " .. nectarText

    nextPlanterPar:SetDesc(str)

    str = ""

    str = str .. "Gathered Pollen: " .. formatNumberString(tostring(math.floor(polValue.Value))) .. "\n"

    sessionStatsParagraph:SetDesc(str)


    local contentFrame = Window.TitleBar.Frame:FindFirstChildOfClass("Frame") -- inner frame
    if contentFrame then
        local subtitleLabel = contentFrame:GetChildren()[3] -- 1=UIListLayout, 2=Title, 3=Subtitle
        subtitleLabel.Text = "by @dandush on discord | STATE: " .. playerState.state
    end

end

task.spawn(function()

    while true do

        if Fluent.Unloaded then break end

        task.wait()

        updateVisuals()

    end
end)

local function getNextMonster() : Instance
    
    for _, spawner in pairs(monsterSpawnersDir:GetChildren()) do
        
        if options.BugsIgnoreList.Value[spawner.Name] == true then
            continue
        end

        if getMonsterCooldown(spawner) <= -60 then -- only get the monster if it shoulda respawned 60 seconds ago

            return spawner

        end
    end
end

local TICK_RATE = 0.05
local TOOL_COOLDOWN = 0.1

-- Animation setup preserved
local Anim = Instance.new("Animation")
Anim.AnimationId = "rbxassetid://522635514"
local playing = false
local track
if humanoid then
    track = humanoid:LoadAnimation(Anim)
    track.Looped = true
end

-- Internal state
local lastToolCall = 0
local lastWalk = tick()

local trackedTokens = setmetatable({}, { __mode = "k" })

-- MovementController: handle movement

function MovementController.randomWalk()
    if not character or not humanoid then return end
    if not playerState.autoFarmingInField then return end

    local field = playerState.currentField
    if not field then return end

    if tick() - lastWalk < 2 then return end -- only walk every 2 seconds, i cba to make it always walk when not collecting 
    lastWalk = tick()

    -- pick a random point inside the field's XZ bounds
    local randX = math.random(field.Position.X - field.Size.X/2, field.Position.X + field.Size.X/2)
    local randZ = math.random(field.Position.Z - field.Size.Z/2, field.Position.Z + field.Size.Z/2)
    local targetPos = Vector3.new(randX, field.Position.Y, randZ)

    humanoid.WalkToPoint = targetPos
end

function MovementController.toHiveAndToggleHoney()
    goTo(playerHive.SpawnPos.Value + Vector3.new(0,10,0), options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)
    task.wait(0.5)
    playerHiveCommandRE:FireServer("ToggleHoneyMaking")
end

-- ToolController: manages tool usage and animation state (so people dont cry about it "not collecting")

function ToolController.updateAnimation(shouldPlay)
    if not track then return end

    if shouldPlay and not playing then
        playing = true
        track:Play()
    elseif not shouldPlay and playing then
        playing = false
        track:Stop()
    end
end

function ToolController.tryUseTool()
    if not options.AutoTool.Value then
        ToolController.updateAnimation(false)
        return
    end

    ToolController.updateAnimation(true)

    if tick() - lastToolCall < TOOL_COOLDOWN then return end
    toolCollectRE:FireServer()
    lastToolCall = tick()
end

-- CollectorController: finds and collects bubbles/tokens

do

    function CollectorController.collectUntilNoTokens()
        if not character then return end

        local charPos = character:GetPivot().Position
        local playerField = getPlayerField()
        if not playerField then return end

        local tokens = {}
        local validCount = 0

        -- Snapshot all collectible tokens first
        for _, token in pairs(collectiblesDir:GetChildren()) do
            if token:IsA("BasePart") then
                if not trackedTokens[token] and not table.find(collectiblesSnapshot, token) then
                    if options.AutoFarmMyFieldOnly.Value and not isPointInPart2D(playerField, token.Position) then
                        continue
                    end

                    if options.IgnoreHoneyTokens.Value and token.FrontDecal and token.FrontDecal.Texture == "rbxassetid://1472135114" then
                        continue
                    end

                    table.insert(tokens, token)
                    validCount += 1
                end
            end
        end

        if validCount == 0 then return end

        table.sort(tokens, function(a, b)
            return (a.Position - charPos).Magnitude < (b.Position - charPos).Magnitude
        end)

        for _, token in pairs(tokens) do
            if not character or not token or not token.Parent then
                continue
            end

            trackedTokens[token] = true

            goTo(CFrame.new(token.Position), options.SelectedMovementOption.Value)
            task.wait(0.2)
        end
    end



    function CollectorController.findClosest(charPos, playerField)
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
                    if options.AutoFarmMyFieldOnly.Value and not isPointInPart2D(playerField, token.Position) then
                        continue
                    end

                    if options.IgnoreHoneyTokens.Value and token.FrontDecal and token.FrontDecal.Texture == "rbxassetid://1472135114" then
                        continue
                    end

                    local dist = (token.Position - charPos).Magnitude
                    if dist < tokenDist then
                        tokenDist = dist
                        closestToken = token
                    end
                end
            end
        end

        if closestBubble and closestToken then
            if bubbleDist < tokenDist then
                return closestBubble, "Bubble"
            else
                return closestToken, "Token"
            end
        elseif closestBubble then
            return closestBubble, "Bubble"
        elseif closestToken then
            return closestToken, "Token"
        end

        return nil, nil
    end

    function CollectorController.isTokenPossible() : boolean
        if not character then return false end
        local playerField = getPlayerField()
        if not playerField then return false end

        for _, token in pairs(collectiblesDir:GetChildren()) do
            -- Skip already collected
            if trackedTokens[token] or table.find(collectiblesSnapshot, token) then
                continue
            end

            -- Field restriction
            if options.AutoFarmMyFieldOnly.Value and not isPointInPart2D(playerField, token.Position) then
                continue
            end

            -- Optional honey ignore
            if options.IgnoreHoneyTokens.Value and token.FrontDecal and token.FrontDecal.Texture == "rbxassetid://1472135114" then
                continue
            end

            -- Found a token
            return true
        end

        return false
    end


    function CollectorController.step()
        if playerState.collectingBubble or playerState.collectingToken or playerState.convertingBackpack then return end
        if not character then return end
        if not (options.AutoFarmBubblesCollect.Value or options.AutoFarmTokensCollect.Value) then return end

        local charPos = character:GetPivot().Position
        local playerField = getPlayerField()
        if not playerField then return end

        local shouldGet, kind = CollectorController.findClosest(charPos, playerField)
        if not shouldGet then return end

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
end

-- BugRunController: Handle Bug Runs

function BugRunController.step()
    if not options.BugRunToggle.Value then return end
    if not character or playerState.autoFarmingInField or playerState.convertingBackpack then
        playerState.killingBugs = false
        return
    end

    local spawner = getNextMonster()
    if spawner then
        playerState.killingBugs = true
        playerState.currentField = spawner.Territory.Value and spawner.Territory.Value:IsA("BasePart") and spawner.Territory.Value or nil
        killBug(spawner)
        playerState.killingBugs = false
    else
        -- return to farming if nothing to kill
        playerState.killingBugs = false
    end
end

-- ConvertController: handles pollen conversion
do
    function ConvertController.step()
        if not options.AutoConvert.Value then return end
        if not character then return end
        if coreStats.Pollen.Value < coreStats.Capacity.Value then return end

        playerState.convertingBackpack = true
        humanoid:Move(Vector3.new(0,0,0))
        playerState.currentField = nil
        playerState.autoFarmingInField = false

        -- Move to hive and toggle honey making until pollen is 0
        goTo(playerHive.SpawnPos.Value + Vector3.new(0,10,0), options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)
        task.wait(0.5)
        playerHiveCommandRE:FireServer("ToggleHoneyMaking")

        repeat
            task.wait(1)
            if not options.AutoConvert.Value or Fluent.Unloaded then
                playerState.convertingBackpack = false
                return
            end

            -- keep ensuring we are at the hive (redundant safety)
            goTo(playerHive.SpawnPos.Value + Vector3.new(0,10,0), options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)
            if player.PlayerGui.ScreenGui.ActivateButton.Position.Y.Offset < -100 or player.PlayerGui.ScreenGui.ActivateButton.TextBox.Text == "Make Honey" then
                goTo(playerHive.SpawnPos.Value + Vector3.new(0,10,0), options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)
                playerHiveCommandRE:FireServer("ToggleHoneyMaking")
            end
        until coreStats.Pollen.Value == 0

        -- wait for balloon unload
        local balloon = getPlayerBalloon()
        if balloon then
            repeat task.wait() until not balloon or not balloon.Parent
        end

        playerState.convertingBackpack = false

    end
end

-- FarmController: when farming state is active

function FarmController.step()

    -- jump when attacked
    if isPlayerAttacked() then
        if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
            humanoid.Jump = true
        end
    else
        -- random walk to not stay in place
        MovementController.randomWalk()
    end

    -- tp to field if not in any active field

    if not playerState.autoFarmingInField then

        local field = flowerZonesDir:FindFirstChild(options.FlowerSelectDropdown.Value)

        if field then

            playerState.autoFarmingInField = true
            
            playerState.currentField = field
            goTo(field.CFrame + Vector3.new(0,5,0), options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)

            task.wait(1)

            humanoid.Jump = true

            placeSprinker()

        end
    end
end

-- PlanterController: handles planting planters , finding the most efficient one etc

function PlanterController.getUserPlanters() : table

    local userActivatablesTable = getupvalue(plantersModule["new"], 3)

    local planters = {}

    for name,stats in pairs(userActivatablesTable) do -- loops through all activatables

        if name:find("Planter") and stats.CountFetch then -- if the activatable has planter in it's name (is a planter) and has a CountFetch Function (sanity check)

            if stats.CountFetch() == 1 then -- if the countFetch function returns 1 (since i dont want it to break for planters that have more than 1 capcity and i am way tooo lazy to make it check in the planted fields for the planter)

                planters[name] = stats

            end
        end
    end

    return planters

end

function PlanterController.getPlantedPlanters() : table

    return getupvalue(localPlantersModule["CheckForNearbyHarvestablePlanters"], 1)

end

function PlanterController.getActiveNectarPercentages() : table
    local tbl = {
        ["Comforting Nectar"] = 0,
        ["Motivating Nectar"] = 0,
        ["Satisfying Nectar"] = 0,
        ["Refreshing Nectar"] = 0,
        ["Invigorating Nectar"] = 0
    }

    local TileByTag = getupvalue(buffsTileModule["GetBuffInfo"], 1).TilesByTag

    for name,info in TileByTag do

        if string.find(name,"Nectar") then
            
            local totalDur = info.TimerDur
            local startTime = info.TimerStart

            local now = os.time()

            local timeLeft = math.max(0, totalDur - (now - startTime))

            local durFull = math.clamp(timeLeft / totalDur, 0, 1)

            if tbl[name] then

                tbl[name] = durFull * 100

            end
        end
    end

    return tbl

end

function PlanterController.isTherePlanterInField(field : BasePart) : boolean

    for _,planterData in pairs(PlanterController.getPlantedPlanters()) do
        
        local planterField = getFieldByPos(planterData.Pos + Vector3.new(0,7,0))

        if planterField == field then return true end

    end

    return false

end

function PlanterController.getPlanterForField(field : BasePart) : string?

    if not field then return nil end

    local fieldNectarType = fieldsNectar[field.Name]

    if not fieldNectarType then
        print("How Did We Get Here")
        return nil
    end

    return PlanterController.getBestPlanterForNectar(fieldNectarType)

end

function PlanterController.getPlanterData(planterName : string) : table
    return planterDataModule.Get(planterName:gsub(" Planter" , ""))
end

function PlanterController.getBestPlanterForNectar(nectarType : string) : string

    local bestMultiplier = 0
    local bestName = nil

    for planterName, _ in pairs(PlanterController.getUserPlanters()) do

        local plantData = planterDataModule.Get(planterName:gsub(" Planter" , ""))

        if not plantData or not plantData.NectarMultipliers[nectarType:gsub(" Nectar", "")] then
            print("Failed To Get Plant Data / Nectar Boost Data For: " .. planterName .. "Tried Getting Nectar: " .. nectarType:gsub(" Nectar", "") .. " Or Planter: " .. planterName:gsub(" Planter" , ""))
        end

        if plantData.NectarMultipliers[nectarType:gsub(" Nectar", "")] or 1 > bestMultiplier then

            bestMultiplier = plantData.NectarMultipliers[nectarType:gsub(" Nectar", "")]
            bestName = planterName

        end

    end

    return bestName

end

function PlanterController.determineNextField() : BasePart?

    local currentPlanters = PlanterController.getPlantedPlanters()

    local count = 0

    for _,_ in pairs(currentPlanters) do
        count += 1
    end

    if count >= 3 then return nil end

    local nectarGoals = {
        ["Comforting Nectar"]  = options.ComfortingNectarGoal.Value,
        ["Motivating Nectar"]  = options.MotivatingNectarGoal.Value,
        ["Satisfying Nectar"]  = options.SatisfyingNectarGoal.Value,
        ["Invigorating Nectar"] = options.InvigoratingNectarGoal.Value,
        ["Refreshing Nectar"]  = options.RefreshingNectarGoal.Value
    }

    local currentNectar = PlanterController.getActiveNectarPercentages()

    local neededNectars = {}

    for nectarType, goal in pairs(nectarGoals) do

        if currentNectar[nectarType] < goal then

            table.insert(neededNectars, nectarType)

        end
    end

    for _, field in pairs(flowerZonesDir:GetChildren()) do

        local fieldNectar = fieldsNectar[field.Name]

        if fieldNectar and not PlanterController.isTherePlanterInField(field) then

            if table.find(neededNectars, fieldNectar) then
                return field
            end
        end
    end

    return nil

end

function PlanterController.isCollectAvailable() : boolean

    for _,v in pairs(PlanterController.getPlantedPlanters()) do

        if (v.GrowthPercent * 100 > options.PlanterGrowthPercentGoal.Value) or (v.GrowthPercent * PlanterController.getPlanterData(v.PotModel.Name).MaxGrowth / 3600 --[[in hours]]) > tonumber(options.PlanterGrowthTimeGoal.Value) then

            return true

        end
    end

    return false

end

function PlanterController.isPlantAvailable() : boolean

    return PlanterController.getPlanterForField(PlanterController.determineNextField()) and true or false

end

function PlanterController.collectPlanter(planter : table) : () -- collects a planter and it's tokens, planter is expected in the table form

    playerState.currentField = getFieldByPos(planter.Pos)

    goTo(CFrame.new(planter.Pos) , options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)

    task.wait(1)

    goTo(CFrame.new(planter.Pos) , options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)-- sometimes it flings a bit cuz of built up velocity etc, so go back again

    task.wait(0.2)

    planterCollectRE:FireServer(planter.ActorID)

    task.wait(1) -- wait a bit, make sure all the tokens load

    CollectorController.collectUntilNoTokens() -- collect all tokens

end

function PlanterController.plantPlanter(planterName : string , field : BasePart) : () -- takes the planter name as a string and plants it in the middle of the field

    playerState.currentField = field

    goTo(field.CFrame , options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value)

    task.wait(1)

    goTo(field.CFrame , options.SelectedMovementOption.Value == "Walk" and "Tween" or options.SelectedMovementOption.Value) -- sometimes it flings a bit cuz of built up velocity etc, so go back again

    task.wait(0.2)

    playerActivateRE:FireServer({["Name"] = planterName})

end

function PlanterController.step() : ()

    if PlanterController.isPlantAvailable() then -- only plant if planting is available

        local fieldToPlant = PlanterController.determineNextField()
        local planterName =  PlanterController.getPlanterForField(fieldToPlant)

        if planterName then

            PlanterController.plantPlanter(planterName , fieldToPlant)

        end

    end

    if PlanterController.isCollectAvailable() then -- only collect if collecting is avaialable
        
        for _,v in pairs(PlanterController.getPlantedPlanters()) do

            if (v.GrowthPercent * 100 > options.PlanterGrowthPercentGoal.Value) or (v.GrowthPercent * PlanterController.getPlanterData(v.PotModel.Name).MaxGrowth / 3600 --[[in hours]]) > tonumber(options.PlanterGrowthTimeGoal.Value) then

                PlanterController.collectPlanter(v)

            end
        end
    end

end

-- Determine state (priority-based)
local function determineState()
    
    -- converting has top priority if enabled and full
    if options.AutoConvert.Value and coreStats and coreStats.Pollen and coreStats.Capacity and coreStats.Pollen.Value >= coreStats.Capacity.Value then
        playerState.state = "Converting"
        return "Converting"
    end

    if options.AutoPlanterToggle.Value and (PlanterController.isCollectAvailable() or PlanterController.isPlantAvailable()) and not playerState.autoFarmingInField then
        
        playerState.state = "Planter"
        return "Planter"

    end

    -- bug run if toggled and a monster is available and not already farming (no gather interrupt)
    if options.BugRunToggle.Value and getNextMonster() and not playerState.autoFarmingInField then
        playerState.state = "BugRun"
        return "BugRun"
    end

    -- collecting (bubbles/tokens)
    if (options.AutoFarmBubblesCollect.Value or options.AutoFarmTokensCollect.Value) then
        -- use a fast local scan to see if there's something to collect

        local charPos = character and character:GetPivot().Position or nil
        local playerField = getPlayerField()

        if charPos and playerField and CollectorController.isTokenPossible() then
            playerState.state = "Collecting"
            return "Collecting"
        end
    end

    -- farming state, doesnt do much
    if options.AutoFarmToggle.Value then
        playerState.state = "Farming"
        return "Farming"
    end

    playerState.state = "Idle" -- doing nothing

    return "Idle"

end

-- Main brain loop
task.spawn(function()
    -- ensure animation track exists on spawn if humanoid available

    if humanoid and not track then
        track = humanoid:LoadAnimation(Anim)
        track.Looped = true
    end

    while true do

        if Fluent.Unloaded then break end

        task.wait(TICK_RATE)

        -- basic safety
        if not player or not player.Character or not character or not humanoid then continue end

        -- Decide what to do
        local state = determineState()

        if state == "Farming" or state == "Collecting" then -- use tool if farming / collecting
            ToolController.tryUseTool()
            ToolController.updateAnimation(true)
        else
            ToolController.updateAnimation(false)
        end

        -- main stuff

        if state == "Converting" then
            ConvertController.step()
        elseif state == "BugRun" then
            BugRunController.step()
        elseif state == "Collecting" then
            CollectorController.step()
        elseif state == "Farming" then
            FarmController.step()
        elseif state == "Planter" then
            PlanterController.step()
        end
    end
end)

-- character added connection

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")

    track = humanoid:LoadAnimation(Anim)
    track.Looped = true
    track:Play()
    playing = true

    playerState.currentField = nil
    playerState.autoFarmingInField = false

end)

-- anti afk, and no, im not going to make it toggle-able

task.spawn(function()
    while task.wait(300) do
        if Fluent.Unloaded then break end
        VIM:SendKeyEvent(true, Enum.KeyCode.Tilde, false, nil)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.Tilde, false, nil)
    end
end)
