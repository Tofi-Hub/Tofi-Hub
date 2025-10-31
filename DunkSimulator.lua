-- services --

local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- local player

local player = players.LocalPlayer
local pStats = player:WaitForChild("pStats")
local character = player.Character or player.CharacterAdded:Wait()
local HRP = character:WaitForChild("HumanoidRootPart")
local animLevel = player:WaitForChild("animLevel")
 
 -- fluent
local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau", true))()

local Window = Fluent:CreateWindow({
    Title = "Basketball Legends Hub",
    SubTitle = "by @dandush on discord",
    TabWidth = 160,
    Size = UDim2.fromOffset(650, 500),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.K
})

local options = Fluent.Options

local Tabs = {
    autoFarmTab = Window:AddTab({Title = "Auto Farm", Icon = "volleyball"}),
    autoBuyTab = Window:AddTab({Title = "Auto Buy", Icon = "shopping-cart"}),
    boostsTab = Window:AddTab({Title = "Boosts", Icon = "flash"}),
    rebirthTab = Window:AddTab({Title = "Rebirth", Icon = "repeat"}),
}

-- modules
local getClosestHoop
getClosestHoop = 
{
	["getHoop"] = function(_, p1, p2)
        local success,hoop,zone =  pcall(function()
		    local l_ServerZone_0 = game.ReplicatedStorage:FindFirstChild("ServerZone")
		    if l_ServerZone_0 then
		    	p2 = l_ServerZone_0.Value
		    elseif not p2 then
		    	for _, v3 in ipairs(p1:WaitForChild("RightFoot"):GetTouchingParts()) do
		    		if v3:IsDescendantOf(game.workspace.Zones.Main) then
		    			l_ServerZone_0 = "Main"
		    		elseif v3:IsDescendantOf(game.workspace.Zones.Moon) then
		    			l_ServerZone_0 = "Moon"
		    		elseif v3:IsDescendantOf(game.workspace.Zones.DunkCity) then
		    			l_ServerZone_0 = "DunkCity"
		    		elseif v3:IsDescendantOf(game.workspace.Zones.SkyCity) then
		    			l_ServerZone_0 = "SkyCity"
		    		elseif v3:IsDescendantOf(game.workspace.Zones.LibertyCourt) then
		    			l_ServerZone_0 = "LibertyCourt"
		    		elseif v3:IsDescendantOf(game.workspace.Zones.KerwinsCourt) then
		    			l_ServerZone_0 = "KerwinsCourt"
		    		elseif v3:IsDescendantOf(game.workspace.Zones.Beach) then
		    			l_ServerZone_0 = "Beach"
		    		elseif v3:IsDescendantOf(game.workspace.Zones.DarkCourt) then
		    			l_ServerZone_0 = "DarkCourt"
		    		elseif v3:IsDescendantOf(game.workspace.Zones.ApocalypseCourt) then
		    			l_ServerZone_0 = "ApocalypseCourt"
		    		elseif v3:IsDescendantOf(game.workspace.Zones.SnowyCourt) then
		    			l_ServerZone_0 = "SnowyCourt"
		    		end
		    	end
		    	p2 = l_ServerZone_0 or "Main"
		    end
		    local l_Tagged_0 = game:GetService("CollectionService"):GetTagged("Hoops")
		    local v4 = 0
		    local v5 = (1 / 0)
		    local v6 = nil
		    for _, v7 in ipairs(l_Tagged_0) do
		    	local l_Net_0 = v7:FindFirstChild("Net")
		    	if l_Net_0 then
		    		l_Net_0 = v7.Net:FindFirstChild("Wedge")
		    	end
		    	if l_Net_0 and (v7.Name == "TimeAttackDHoop" and (l_Net_0.Active.Value == true and ((l_Net_0.Position - p1.HumanoidRootPart.Position).Magnitude < 1000 and v7.CurrentHealth.Value > 0))) then
		    		v4 = v4 + 1
		    		break
		    	end
		    end
		    for _, v8 in ipairs(l_Tagged_0) do
		    	local l_Net_1 = v8:FindFirstChild("Net")
		    	if l_Net_1 then
		    		l_Net_1 = v8.Net:FindFirstChild("Wedge")
		    	end
		    	if l_Net_1 then
		    		local l_Magnitude_0 = (l_Net_1.Position - p1.HumanoidRootPart.Position).Magnitude
		    		if v5 > l_Magnitude_0 then
		    			if p2 == "Moon" then
		    				if v8.Name == "SpaceHoopL" or v8.Name == "SpaceHoopR" then
		    					v6 = v8
		    					v5 = l_Magnitude_0
		    				end
		    			elseif p2 == "DunkCity" then
		    				if v8.Name == "CityHoopShort" or v8.Name == "CityHoopTall" then
		    					v6 = v8
		    					v5 = l_Magnitude_0
		    				end
		    			elseif p2 == "SkyCity" then
		    				if v8.Name == "SkyHoopL" or v8.Name == "SkyHoopR" then
		    					v6 = v8
		    					v5 = l_Magnitude_0
		    				end
		    			elseif p2 == "LibertyCourt" then
		    				if v8.Name == "LibertyHoopL" or (v8.Name == "LibertyHoopR" or v8.Name == "HoopLibertyCourtCourt") then
		    					v6 = v8
		    					v5 = l_Magnitude_0
		    				end
		    			elseif p2 == "KerwinsCourt" then
		    				if v8.Name == "HarlemHoopFar" or (v8.Name == "HarlemHoopNear" or v8.Name == "HarlemProHoop") then
		    					v6 = v8
		    					v5 = l_Magnitude_0
		    				end
		    			elseif p2 == "Beach" then
		    				if v8.Name == "BeachHoopL" or v8.Name == "BeachHoopR" then
		    					v6 = v8
		    					v5 = l_Magnitude_0
		    				end
		    			elseif p2 == "DarkCourt" then
		    				if v8.Name == "DarkHoop1" or v8.Name == "DarkHoop2" then
		    					v6 = v8
		    					v5 = l_Magnitude_0
		    				end
		    			elseif p2 == "ApocalypseCourt" then
		    				if v8.Name == "ZCourt1" or v8.Name == "ZCourt2" then
		    					v6 = v8
		    					v5 = l_Magnitude_0
		    				end
		    			elseif p2 == "SnowyCourt" then
		    				if v8.Name == "WinterHoopL" or v8.Name == "WinterHoopR" then
		    					v6 = v8
		    					v5 = l_Magnitude_0
		    				end
		    			elseif v8.Name == "TimeAttackHoop" or (v8.Name == "TimeAttackDHoop" or v8.Name == "TimeAttackRHoop") then
		    				if l_Net_1.Active.Value == true and (v8.Name ~= "TimeAttackDHoop" or (v8.CurrentHealth.Value > 0 or v4 <= 0)) then
		    					v6 = v8
		    					v5 = l_Magnitude_0
		    				end
		    			else
		    				v6 = v8
		    				v5 = l_Magnitude_0
		    			end
		    		end
		    		break
		    	end
		    end
		    local v9 = (v6.Name == "SpaceHoopL" or v6.Name == "SpaceHoopR") and "Moon" or p2
		    local v10 = (v6.Name == "CityHoopShort" or v6.Name == "CityHoopTall") and "DunkCity" or v9
		    return v6.Hoop, v10
        end)
        return success and hoop or workspace.Zones.Main.Static.HoopL
	end
}

-- dirs

local shoesDir = replicatedStorage:WaitForChild("Shoes")
local statsShopDir = replicatedStorage:WaitForChild("UI"):WaitForChild("Shop"):WaitForChild("Shop")

-- weird thing

local buyStatsLayout = {
    [1] = "Accuracy",
    [2] = "Range",
    [3] = "Focus",
    [4] = "Speed"
}

-- Remotes
local upgradeStatsRE = replicatedStorage:WaitForChild("UpgradeStats")
local upgradeAnimationsRE = replicatedStorage:WaitForChild("UpgradeAnim")

local buyBallRE = replicatedStorage:WaitForChild("BuyBall")
local equipBallRE = replicatedStorage:WaitForChild("EquipBall")

local buyJerseyRE = replicatedStorage:WaitForChild("BuyJersey")
local equipJerseyRE = replicatedStorage:WaitForChild("EquipJersey")

local equipShoeRE = replicatedStorage:WaitForChild("Remote"):WaitForChild("Shoes"):WaitForChild("InventoryEquip")

local rebirthRE = replicatedStorage:WaitForChild("Rebirth")

local Shot = replicatedStorage:WaitForChild("Shot")
local Score = replicatedStorage:WaitForChild("Score")
local Green = replicatedStorage:WaitForChild("Green")
local OnFire = replicatedStorage:WaitForChild("OnFire")

local hoop = getClosestHoop.getHoop(nil,character)

-- get player character after death (on rebirth)
players.LocalPlayer.CharacterAdded:Connect(function(char)
    character = char
    HRP = character:WaitForChild("HumanoidRootPart")
end)

local function getMostExpensiveWithBudget(options : table, type : string) : table
    local balance = player:GetAttribute("Cash") or 0
    local bestOption = nil
    local bestPrice = 0

    if type == "Stats" then
        
        for i,v in pairs(options) do
            if v.Price < balance then
                if tostring(pStats:WaitForChild(v.Field).Value) ~= i.Name:gsub("Level","") then
                    if v.Price > bestPrice then
                        bestPrice = v.Price  
                        local str = i.Name:gsub("Level","")
                        bestOption = {Index = tonumber(str), Field = v.Field} -- remove "Level" from the string, keep only index
                    end
                end
            end
        end
    else
        for _,purchase in pairs(options) do
            if purchase.Price.Value < balance then
                if purchase.Price.Value > bestPrice then
                    bestPrice = purchase.Price.Value
                    bestOption = tonumber(purchase.Name)
                end
            end
        end
    end

    return bestOption

end

local function equipBest(type : string) : ()
    local str = "owned" .. type
    local highest = 0
    local highestStr = ""
    for _,v in pairs(player[str]:GetChildren()) do
        if v.Value and tonumber(v.Name) > highest then
            highest = tonumber(v.Name)
            highestStr = v.Name
        end
    end

    if type == "Balls" then
        if not character:FindFirstChild(highestStr) then
            equipBallRE:FireServer(highest)
        end
    else
        equipJerseyRE:FireServer(highest)
    end

end

local function getNextPurchase(type : string)
    if type == "Stats" then
        local statOptions = {} -- [instance] = {Price = price , Field = "Speed" or "Accuracy" etc}
        for _,statPriceFolder in pairs(statsShopDir:GetChildren()) do
            if string.find(statPriceFolder.Name,"Prices") then
                for _,statOption in pairs(statPriceFolder:GetChildren()) do
                    statOptions[statOption] = {Price = statOption.Value, Field = statPriceFolder.Name:gsub("Prices","")} -- remove "Prices" from the string, keep only field name
                end
            end
        end

        return getMostExpensiveWithBudget(statOptions, type)

    else
        local priceFolder = replicatedStorage:FindFirstChild(type)
        return getMostExpensiveWithBudget(priceFolder:GetChildren(), type)
    end

end

local function getRebirthCost()
    local rebirths = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Rebirth") and player.leaderstats.Rebirth.Value or 0
    local rebirthCost = 50000000 * 2.5 ^ rebirths

    return rebirthCost
end

local function getBall()
    return character:FindFirstChildWhichIsA("Tool") and character:FindFirstChildWhichIsA("Tool"):FindFirstChild("Handle") or nil
end

local function getShoeMultiplier(shoeName : string) : number
    for _,v in pairs(shoesDir:GetDescendants()) do
        if v.Name == shoeName and v:FindFirstChild("CashMultiplier") then
            return v.CashMultiplier.Value
        end
    end
end

local function equipBestShoe()
    local bestShoe = "1"
    local bestShoeMultiplier = 0

    for _,v in pairs(player.ownedShoes:GetChildren()) do
        if v.Value > 0 then
            if not string.find(v.Name,"Lvl") then
                local shoeMultiplier = getShoeMultiplier(v.Name)

                if shoeMultiplier > bestShoeMultiplier then
                    bestShoeMultiplier = shoeMultiplier
                    bestShoe = v.Name
                end
            end
        end
    end

    if player.equippedShoes.Value == bestShoe then return end

    equipShoeRE:FireServer(true,bestShoe)

end

local function getNearestHotspotPosition() : Vector3

    local toReturn = HRP.CFrame
    local closest = math.huge

    for _,zone in pairs(workspace.Zones:GetChildren()) do
        if zone:FindFirstChild("Hotspots") then
            for _,hotspot in pairs(zone.Hotspots:GetChildren()) do
                if hotspot:FindFirstChild("Hotspot") then
                    local magnitude = (HRP.Position - hotspot.Hotspot.Position).Magnitude

                    if magnitude < closest then
                        closest = magnitude
                        toReturn = hotspot.Hotspot.CFrame
                    end
                end
            end
        end
    end

    return toReturn.Position

end


Tabs.autoFarmTab:AddToggle("AutoFarmToggle",{ Title = "Auto Farm Toggle", Default = false})
Tabs.autoFarmTab:AddToggle("AutoTPHotSpots",{ Title = "Auto TP HotSpots", Default = false})
Tabs.autoFarmTab:AddToggle("autoEquipBestShoes",{ Title = "Auto Equip Best Shoes", Default = false})

Tabs.autoBuyTab:AddToggle("AutoBuyBalls",{ Title = "Auto Buy Balls", Default = false})
Tabs.autoBuyTab:AddToggle("AutoBuyShirts",{ Title = "Auto Buy Shirts", Default = false})

Tabs.autoBuyTab:AddToggle("AutoBuyStats",{ Title = "Auto Buy Stats", Default = false})
Tabs.autoBuyTab:AddToggle("autoBuyAnimationLevels",{ Title = "Auto Buy Animations Levels", Default = false})

Tabs.boostsTab:AddButton({
    Title = "Boost",
    Description = "Grants All Boosts",
    Callback = function()
        game.ReplicatedStorage.Remote.DailySpin.AddToInventory:FireServer("1000xCash",true)
        game.ReplicatedStorage.Remote.DailySpin.AddToInventory:FireServer("50xCash",true)
        game.ReplicatedStorage.Remote.DailySpin.AddToInventory:FireServer("5xCash",true)
        game.ReplicatedStorage.Remote.DailySpin.AddToInventory:FireServer("2xCash",true)
        game.ReplicatedStorage.Remote.DailySpin.AddToInventory:FireServer("100xCash",true)
    end,
})

Tabs.rebirthTab:AddToggle("AutoRebirth",{ Title = "Auto Rebirth", Default = false})


-- auto buy and auto rebirth
task.spawn(function()
    while true do
        if options.AutoBuyBalls.Value then
            local purchase = getNextPurchase("Balls")

            if purchase then
                if not character:FindFirstChild(tostring(purchase)) then
                    buyBallRE:FireServer(purchase)
                    task.wait(0.2)
                    equipBest("Balls")
                end
            end
        end
        if options.AutoBuyShirts.Value then
            local purchase = getNextPurchase("Jerseys")
            

            if purchase then
                buyJerseyRE:FireServer(purchase)
                task.wait(0.2)
                equipBest("Jerseys")
            end
        end
        if options.AutoBuyStats.Value then
            local purchase = getNextPurchase("Stats")

            local args = {}

            if purchase then
                for _,v in pairs(buyStatsLayout) do
                    if v == purchase.Field then
                        table.insert(args,purchase.Index)
                    else
                        table.insert(args,pStats:FindFirstChild(v).Value)
                    end
                end
            end
            
            upgradeStatsRE:FireServer(unpack(args))

        end

        if options.autoBuyAnimationLevels.Value then

            upgradeAnimationsRE:FireServer()

        end

        if options.AutoRebirth.Value then
            if getRebirthCost() < (player:GetAttribute("Cash") or 0) then
                print("Rebirthing")
                rebirthRE:FireServer()
            end
        end

        if options.autoEquipBestShoes.Value then
            equipBestShoe()
        end

        task.wait(0.5)
    end
    
end)
-- auto farm

local i = 0
task.spawn(function()
    local shotData = {
        v0 = Vector3.new(100000, 1000000, 100000),
        targetPos = Vector3.new(-119, 37, 711),
        willScore = true,
        duration = 0.1,
        x0 = HRP.Position,
        hoopDistance = 200,
        animLevel = animLevel.Value,
        orientation = Vector3.new(0, -91, 0),
        hoop = hoop,
        isGreen = true,
        percentage = 100
    }
    while true do
        if options.AutoFarmToggle.Value then
            if not character or not character.Parent or not HRP or not HRP.Parent then 
                task.wait()
                continue 
            end
            i+= 1
            task.wait()
            if not character then continue end
            Green:FireServer(true, shotData.hoopDistance)
            OnFire:FireServer(player, shotData.percentage)
            Shot:FireServer(getBall(), shotData)
            Score:FireServer()
            if i == 50 then
                i = 0
                shotData = 
                {
                    v0 = Vector3.new(100000, 1000000, 100000),
                    targetPos = Vector3.new(9999, 9999, 9999),
                    willScore = true,
                    duration = 0.1,
                    x0 = HRP.Position,
                    hoopDistance = 200,
                    animLevel = animLevel.Value,
                    orientation = Vector3.new(0, -91, 0),
                    hoop = getClosestHoop.getHoop(nil,character),
                    isGreen = true,
                    percentage = 100
                }
                if options.AutoTPHotSpots.Value then
                    character:PivotTo(CFrame.new(getNearestHotspotPosition() + Vector3.new(0,2,0)))
                end
            end
        else
            task.wait(1)
        end
    end
end)



