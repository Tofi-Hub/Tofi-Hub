-- services --
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local replicatedStorage = game:GetService("ReplicatedStorage")
-- local player
local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
 -- fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "EFS HUB",
    SubTitle = "by @dandush on discord",
    TabWidth = 160,
    Size = UDim2.fromOffset(650, 500),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.K
})


local Tabs = {
    autoFarmTab = Window:AddTab({Title = "Auto Farm Tab" , Icon = "egg"})
}

local options = Fluent.Options

-- Static Directories

local farmsDir = workspace:WaitForChild("Farms")
local eventsDir = replicatedStorage:WaitForChild("Events")
local weaponEvent = eventsDir:WaitForChild("Weapon")
local progressEvent = eventsDir:WaitForChild("Progress")
local upgradeHeroEvent = eventsDir:WaitForChild("Heroes")
local abilitiesRE = eventsDir:WaitForChild("Abilities")

-- Modules

local dataHandler = require(game.ReplicatedStorage.Modules.DataHandler)
local heroData = require(replicatedStorage.Settings.HeroesData)

-- Flags

local gettingFood = false -- stop auto farm teleport while getting food

-- Variables For Auto Farm Safety( Not Get Stuck On Bosses )

local lastProgress = dataHandler.Get("data").level.progress
local queueFood = false
local lastTick = tick()
local stuckTime = 0
local lastLevel = dataHandler.Get("data").level.current
local lastSwitch = 0

local maxStuckTime = 75 -- time needed after getting stuck to go back in stages
local minTimeBeforeGoingNext = 600 --time needed to wait after going back to go back up again

-- death connections

player.CharacterAdded:Connect(function(char)
    character = char
end)

local function getPlayerFarm() : Model -- gets the local player's farm

    for _,farm in pairs(farmsDir:GetChildren()) do
        if farm.Owner.Value == player then

            return farm

        end
    end

    return nil

end

local function getChicken(base : Model) : BasePart -- gets the chicken in the local player's farm (used for auto attack)

    for _,v in pairs(base:GetChildren()) do
        if v.Name == "Chicken" and v:IsA("BasePart") then
            return v
        end
    end

    return nil

end

local playerFarm = getPlayerFarm() -- loads farm dynamically

if not playerFarm then -- claims a farm if farm not found (needs fixing)
    for _,v in pairs(farmsDir:GetChildren()) do
        if not v.Owner.Value then
            character:PivotTo(v.Door.CFrame)
            repeat 
                task.wait()
                playerFarm = getPlayerFarm()
            until playerFarm
        end
    end
end

local function nextLevelAvailable() : boolean -- if the next level is available (completed current level)
    local data = dataHandler.Get("data")

    return ( (data.level.maxprogress <= data.level.progress)
             or (data.level.progress == 1 and data.level.current % 5 == 0)
             or (data.level.current < data.level.highest) )
end

local function upgradeHero(heroIndex : string) : () -- upgrade hero helper
    upgradeHeroEvent:FireServer("Train",heroIndex,nil,1)
end

local function getHeroTrainCost(heroIndex : string) : number -- gets the train cost for a specific hero considering level , hero etc
    local heroStats = heroData.Stats[heroIndex]
    local basePrice = heroStats.BaseCost

    local level = dataHandler.Get("data").heroes[heroIndex].level
    local wantedLevel = level + 1

    local idfk = dataHandler.Get("data").eastereggs["4"]

    return heroData.Cost(basePrice,level,wantedLevel,idfk)
end

local function bigNumGreater(a, b) -- chatgpt ahh
    if not a or not b then return false end
    local aValue, aExp = a[1], a[2]
    local bValue, bExp = b[1], b[2]

    if aExp > bExp then
        return true
    elseif aExp < bExp then
        return false
    else
        return aValue > bValue
    end
end

local function getHeroDPSIncrease(heroIndex : string) : table

end

local function getCheapestHero() : (string,table) -- gets the cheapest hero to upgrade

    local cheapestPrice = {99999 , 9999}
    local cheapestIndex = nil

    for _,v in pairs(playerFarm.Placeholders:GetChildren()) do
        local price = getHeroTrainCost(v.Name)
        local dpsIncrease = getHeroDPSIncrease(v.Name)
        if bigNumGreater(cheapestPrice, price) then
            cheapestPrice = price
            cheapestIndex = v.Name
        end
    end

    return cheapestIndex , cheapestPrice
end

local function hireNextHero() : () -- hires the next non hired hero if enough money

    local count = 0
    for _,_ in pairs(dataHandler.Get("data").heroes) do
        count += 1
    end
    local nextHeroIndex = count + 1
    local nextHeroPrice = heroData.Cost(heroData.Stats[tostring(nextHeroIndex)].BaseCost, 0, 1, dataHandler.Get("data").eastereggs["4"])

    if bigNumGreater(dataHandler.Get("data").eggs,nextHeroPrice) then

        upgradeHeroEvent:FireServer("Train" , tostring(nextHeroIndex) , nil , 1)

    end

end

local function upgradeHeroAbility(heroIndex : string, abilityIndex : number) : () -- helper to get hero ability
    upgradeHeroEvent:FireServer("Upgrade" , heroIndex , abilityIndex)
end

local function getCheapestHeroToUpgrade() : (string , number , table) -- gets the cheapest hero to get it's ability and the price
    local cheapestUpgradeHero = nil
    local cheapestUpgradeIndex = nil
    local cheapestUpgradeCost = {999999,999999}

    local playerData = dataHandler.Get("data")
    for heroIndex, heroInfo in pairs(playerData.heroes) do
        for upgradeIndex, upgrade in pairs(heroData.Stats[heroIndex].Upgrades) do

            if heroInfo.upgrades[tostring(upgradeIndex)] then continue end
            local requiredLevel = upgrade.requiredLevel or math.max(10, (upgradeIndex - 1) * 25)
            if heroInfo.level < requiredLevel then continue end

            local cost = heroData.UpgradeCost(heroData.Stats[heroIndex].BaseCost, upgradeIndex)
            if bigNumGreater(cheapestUpgradeCost, cost) then
                cheapestUpgradeCost = cost
                cheapestUpgradeHero = heroIndex
                cheapestUpgradeIndex = upgradeIndex
            end
        end
    end

    return cheapestUpgradeHero, cheapestUpgradeIndex, cheapestUpgradeCost
end

local function activateAbilities() : ()
    for i,cooldown in pairs(dataHandler.Get("data").cooldowns) do
        if cooldown < 1 then
            abilitiesRE:FireServer(i)
        end
    end
end

local function isBoss() : boolean
    local data = dataHandler.Get("data")
    return (data.level.progress == 0 and data.level.current % 5 == 0)
end

 -- gui
Tabs.autoFarmTab:AddToggle("AutoFarmToggle", {Title = "Auto Farm Toggle" , Default = false})
Tabs.autoFarmTab:AddSection("Meelee Toggles")
Tabs.autoFarmTab:AddToggle("AutoAttackChicken", {Title = "Auto Attack Chicken" , Default = false})
Tabs.autoFarmTab:AddToggle("AutoGetFoodToggle", {Title = "Auto Get Food" , Default = false})
Tabs.autoFarmTab:AddSection("Hero Upgrade Toggles")
Tabs.autoFarmTab:AddToggle("AutoUpgradeHeroes", {Title = "Auto Upgrade Heroes" , Default = false})
Tabs.autoFarmTab:AddToggle("AutoBuyHeroes", {Title = "Auto Buy Heroes" , Default = false})

local p1 = Tabs.autoFarmTab:AddParagraph({
    Title = "Stuck Time At Current Stage MAX: " .. maxStuckTime,
    Content = tostring(stuckTime)
})

local p2 =Tabs.autoFarmTab:AddParagraph({
    Title = "Time Since Last Stage Switch MAX: " .. minTimeBeforeGoingNext,
    Content = tostring(tick() - lastSwitch)
})

task.spawn(function() -- upgrade gui loop
    while true do
        task.wait(0.1)
        p1:SetDesc(tostring(math.floor(stuckTime)))
        p2:SetDesc(tostring(math.floor(tick() - lastSwitch)))
    end
end)



local weaponHitArgs = { -- arguments that the server expects (constant)
    [1] = "self",
    [2] = "219629d5067eddcdce55ed7968e9b53f"
}

local first = false -- a little variable to reset stuckTime each time the loop triggers

-- auto farm loop

task.spawn(function()
    while true do
        if options.AutoFarmToggle.Value then
            if not first then
                lastTick = tick()
            end
            task.wait()

            if not character then continue end

            if dataHandler.Get("data").level.current == lastLevel and not (dataHandler.Get("data").level.progress >= dataHandler.Get("data").level.maxprogress) and dataHandler.Get("data").level.progress == lastProgress then
                stuckTime += tick() - lastTick
                lastTick = tick()
            else
                lastProgress = dataHandler.Get("data").level.progress
                lastLevel = dataHandler.Get("data").level.current
                stuckTime = 0
            end

            if stuckTime > maxStuckTime  then
                queueFood = true
                lastSwitch = tick()
                local cfr = playerFarm:FindFirstChild("Prev") and playerFarm.Prev:GetPivot() or nil

                    character:PivotTo(cfr)

                    task.wait(0.5)

                    progressEvent:FireServer(
                        "\229\155\158\229\176\143\228\189\143\228\189\141\229\166\187\229\155\158\229\185\179\229\166\187\232\166\129\230\138\132\227\129\139\228\189\143\227\131\139\227\129\140\229\185\179\227\130\130\229\176\143\227\131\141\227\131\141\229\155\158\227\131\141\230\138\132\230\191\128\227\129\166\227\130\130",
                        "Previous Level"
                    )
                    stuckTime = 0
                    queueFood = false
            end

            if options.AutoAttackChicken.Value then 
                if not gettingFood then

                    local cfr = getChicken(playerFarm) and getChicken(playerFarm).CFrame or nil

                    if cfr then
                        character:PivotTo(cfr)
                        if isBoss() then activateAbilities() end
                    else
                        print("Chicken CFrame not found")
                    end

                end
            end

            weaponEvent:FireServer(unpack(weaponHitArgs))
            if not gettingFood then 
                if nextLevelAvailable() then
                    if tick() - lastSwitch > minTimeBeforeGoingNext then
                        queueFood = true
                        local cfr = playerFarm:FindFirstChild("Next") and playerFarm.Next:GetPivot() or nil

                        character:PivotTo(cfr)

                        task.wait(0.1)

                        progressEvent:FireServer(
                            "\229\155\158\229\176\143\228\189\143\228\189\141\229\166\187\229\155\158\229\185\179\229\166\187\232\166\129\230\138\132\227\129\139\228\189\143\227\131\139\227\129\140\229\185\179\227\130\130\229\176\143\227\131\141\227\131\141\229\155\158\227\131\141\230\138\132\230\191\128\227\129\166\227\130\130",
                            "Next Level"
                        )
                        queueFood = false
                    end
                end
            end

        else
            first = false
            task.wait(1)
        end
    end
end)

task.spawn(function()
    while true do
        if options.AutoUpgradeHeroes.Value then
            task.wait()

            local cheapestHeroAbility , upgradeIndex , bigNumPrice1 = getCheapestHeroToUpgrade()

            local cheapestHeroUpgrade, bigNumPrice2 = getCheapestHero()

            local doubleCheapestUpgrade = {bigNumPrice2[1] * 2 , bigNumPrice2[2]}

            if bigNumGreater(doubleCheapestUpgrade , bigNumPrice1) then
                if bigNumGreater(dataHandler.Get("data").eggs , bigNumPrice1) then
                    upgradeHeroAbility(cheapestHeroAbility , upgradeIndex)
                else
                    continue
                end
            end

            if bigNumGreater(bigNumPrice1,bigNumPrice2) then
                if bigNumGreater(dataHandler.Get("data").eggs , bigNumPrice2) then
                    upgradeHero(cheapestHeroUpgrade)
                end
            end

        else
            task.wait(1)
        end

        if options.AutoBuyHeroes.Value then
            hireNextHero()
        end

    end
end)

-- auto get food connections

playerFarm:WaitForChild("Meat"):GetPropertyChangedSignal("Position"):Connect(function()
    if not options.AutoGetFoodToggle.Value then return end
    if not character then return end

    repeat task.wait() until not queueFood

    repeat task.wait() until playerFarm.Meat.Transparency == 0

    gettingFood = true

    character:PivotTo(CFrame.new(playerFarm.Meat.Position))

    task.wait()

    gettingFood = false
end)
