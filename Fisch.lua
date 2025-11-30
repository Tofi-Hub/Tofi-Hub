-- OPEN SOURCE FISCH SCRIPT -- 

--game id: 131716211654599

-- made by @dandush on discrd

-- you can freely dm me if the script doesnt work / need help with scripting

-- services --
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local replicatedStorage = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
-- local player
local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local HRP = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
 -- fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Fisch Hub",
    SubTitle = "by @dandush on discord",
    TabWidth = 160,
    Size = UDim2.fromOffset(650, 650),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.K
})

local Tabs = 
{
    autoFarmTab = Window:AddTab({Title = "Auto Farm", Icon = "repeat"}),
    upgradeTab = Window:AddTab({Title = "Appraise / Enchant", Icon = "star"}),
    lpTab = Window:AddTab({Title = "Local Player", Icon = "user"}),
    boatTab = Window:AddTab({Title = "Boat Controls", Icon = "sailboat"}),
    optionsTab = Window:AddTab({Title = "Options", Icon = "settings"})
}

local options = Fluent.Options

-- on player death
player.CharacterAdded:Connect(function(char)
    character = char
    HRP = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
end)
-- Static Remotes
local reelFinished = replicatedStorage:WaitForChild("events"):WaitForChild("reelfinished")
-- data control module (for invetory fetching)
local dataControllerModule = require(replicatedStorage:WaitForChild("client"):WaitForChild("legacyControllers"):WaitForChild("DataController"))
-- map directory(for the islands)
local spawnsDir = workspace:WaitForChild("world"):WaitForChild("spawns")
-- remote for dialog
local dialogRF = replicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RF/DialogInteract")
-- directory for for the rods
local playerStats = workspace:WaitForChild("PlayerStats")
local rodStats = playerStats:WaitForChild(player.Name):WaitForChild("T"):WaitForChild(player.Name):WaitForChild("Rods")
-- directory for interactables(proximity prompts)
local interactables = workspace.world:WaitForChild("interactables")
-- User Input
local autoShakeToggle = true
local autoFarmToggle = false
local autoReelToggle = true
local savedPosition = nil
local wantedEnchant = ""
local wantedAppraise = ""

local function notify(warning : boolean,titley : string,messegey : string,durationy : number) : ()

    if not options.InfoNotifyToggle then return end 
    if options.InfoNotifyToggle.Value == false and warning == false then return end 
    local messege = messegey or ""
    local title = titley or ""
    local duration = durationy or 5

    print("Notified about title: "..title .. " and messege: "..messege)
    
    Fluent:Notify({
        Title = warning and "WARNING" or "Info",
        Content = title,
        SubContent = messege,
        Duration = duration,
    }) 

end

local function equipTool(tool : Tool)
    if not tool then
        notify(true, "Attempt to equip nonexistent tool","equipTool function")
    end
    local equipped = character:FindFirstChildOfClass("Tool")
    if equipped then
        equipped.Parent = player.Backpack
        task.wait()
    end
    tool.Parent = character
end

local function getRod() : Tool
    local tool
    tool = character:FindFirstChildOfClass("Tool")
    if tool then
        if tool:FindFirstChild("events") then
            if tool.events:FindFirstChild("castAsync") then
                return tool
            end
        end
    end

    for _,tool in pairs(player.Backpack:GetChildren()) do
        if tool:FindFirstChild("events") then
            if tool.events:FindFirstChild("castAsync") then
                return tool
            end
        end
    end
    return nil
end

local function castRod(rod : Tool)
    if not rod then
        notify(true,"Rod Not Found in castRod function", "thats weird..")
        return
    end
    if rod.Parent ~= character then
        equipTool(rod)
    end
    local remote = rod.events.castAsync
    local args = {
        [1] = 99,
        [2] = 1
    }
    repeat
        remote:InvokeServer(unpack(args))
        task.wait(0.25)
    until rod:FindFirstChild("bobber")

end

local function finishCast(rod : Tool, autoFarmToggle : boolean ,  playerBar : Frame, fish : Frame) : ()
    local reel = player.PlayerGui:FindFirstChild("reel")
    if not reel then
        notify(true,"Finish Cast Error", "Attempt To Finish Cast When Not In Reeling Phase")
        castRod(getRod())
        return
    end
    if not rod then
        notify(true,"Rod Not Found in finishCast function", "thats weird..")
        return
    end
    if rod.Parent ~= character then
        equipTool(rod)
    end

    local breakVar = false

    fish.Parent:GetPropertyChangedSignal("Visible"):Wait()
    fish.Parent:GetPropertyChangedSignal("Visible"):Wait() -- wait until actually visible

    print("Visiblity Changed")

    local sum = nil

    for _, connection in pairs(getconnections(replicatedStorage.packages.Net["RE/ProgressModifier"].OnClientEvent)) do
        if connection.Function then
            local upval = getupvalue(connection.Function, 1)
            if upval then
                if type(upval) == "table" then
                    sum = upval
                    break
                end
            end
        end
    end

    print("Bar Size: " .. sum.barSize)

    task.spawn(function()
        while not breakVar do
            if playerBar then
                sum.barSize = 1e8 -- big size me go wow
                task.wait()
            else break end
        end
    end)

    fish:GetPropertyChangedSignal("Position"):Wait()
    fish:GetPropertyChangedSignal("Position"):Wait() -- wait until fish position changes

    task.wait(0.5)

    reelFinished:FireServer(100, false)

    print("Reel finished fired")

    breakVar = true

    if autoFarmToggle then 
        notify(false,"Finished Reel", "Casting Rod")
        castRod(getRod())
    end

end

local function shake(button : ImageButton) : ()
    local event = button:FindFirstChild("shake")
    if event then
        event:FireServer()
    else
        notify(true, "Shake Button has no shake remote")
    end
end

local function getSpawnNames(parent)
    local names = {"None"}
    for _, child in ipairs(parent:GetChildren()) do
        if child:FindFirstChild("spawn") then
            table.insert(names, child.Name)
        end
    end
    table.sort(names, function(a, b)
        if a == "None" then
            return true
        elseif b == "None" then
            return false
        else
            return a < b
        end
    end)
    return names
end

local function getInventory()
    return dataControllerModule.fetch("Inventory")
end

local function getToolFromLink(link : string) : ()
    
    if character:FindFirstChildOfClass("Tool") then
        if character:FindFirstChildOfClass("Tool"):FindFirstChild("link") then
            if character:FindFirstChildOfClass("Tool").link.Value == link  then
                return character:FindFirstChildOfClass("Tool")
            end
        end
    end

    for _,item in pairs(player.Backpack:GetChildren()) do
        if item:FindFirstChild("link") then
            if item.link.Value == link then
                return item
            end
        end
    end

    return nil
end

local function getItemFromDifference(old: table, new: table) : (Tool, table)
    for key, newItem in pairs(new) do
        local oldItem = old[key]
        if not oldItem then
            return getToolFromLink(key), newItem
        elseif oldItem.sub and oldItem.sub.Stack and newItem.sub and newItem.sub.Stack then
            if oldItem.sub.Stack ~= newItem.sub.Stack then
                return getToolFromLink(key), newItem
            end
        end
    end
end

local function appraiseItem(item : Tool) : (Tool,boolean,boolean,string)
    local before = getInventory()
    if not item then
        notify(true,"Item Not Found in appraiseItem function", "equip an item")
        return
    end
    if item.Parent ~= character then
        equipTool(item)
    end

    dialogRF:InvokeServer(15,1)
    dialogRF:InvokeServer(6,1)
    task.wait(0.2)
    local after = getInventory()
    local newItemTool, newItemTable = getItemFromDifference(before,after)
    if not newItemTable then
        return nil,false,false,""
    end
    local shiny = newItemTable.sub.Shiny or false
    local sparkling = newItemTable.sub.Sparkling or false
    local mutation = newItemTable.sub.Mutation or ""
    return newItemTool, shiny, sparkling, mutation
end

local function getEnchant(rod : Tool)
    local enchant = rodStats:FindFirstChild(rod.Name).Value
    if enchant then
        return string.lower(enchant)
    else
        notify(true,"Enchant Not Found in getEnchant function")
        return nil
    end
end

local function enchantRod(relic : Tool) : string
    if not relic then
        notify(true,"Relic Not Found in enchantRod function", "equip a relic")
        return
    end
    if relic.Parent ~= character then
        notify(true,"item not equipped","equipping item")
        equipTool(relic)
    end
    HRP.Position = Vector3.new(1310.54651, -799.469604, -82.7303467)
    task.wait(0.1)
    repeat 
        task.wait()
    until interactables:FindFirstChild("Enchant Altar")
    local altar = interactables:FindFirstChild("Enchant Altar")
    if altar:FindFirstChild("PromptTemplate") then
        task.wait(1)
        fireproximityprompt(altar:FindFirstChild("PromptTemplate"))
        repeat task.wait() until player.PlayerGui:FindFirstChild("over")
        repeat task.wait() until player.PlayerGui.over:FindFirstChild("prompt")
        repeat task.wait() until player.PlayerGui.over.prompt:FindFirstChild("confirm")
        firesignal(player.PlayerGui.over.prompt.confirm.MouseButton1Click)
    else
        notify(true,"Couldnt find altar proximityprompt", "i probably need to add a longer wait")
    end
    repeat 
        task.wait(0.1)
    until altar:FindFirstChild("PromptTemplate").Enabled
    return getEnchant(getRod())
end

local function getBoat()
    return humanoid.SeatPart and humanoid.SeatPart.Parent or nil
end

local function setModelTransperancy(model : Model,flag : boolean, ignore : table) : table
    local set = {}
    if flag then
        for _,v in pairs(model:GetDescendants()) do
            if v:IsA("BasePart") then
                if v.Transparency ~= 1 then
                        v.Transparency = 1
                else
                    table.insert(set,v)
                end
            end
        end
    else
        for _,v in pairs(model:GetDescendants()) do
            if v:IsA("BasePart") then
                if not table.find(ignore,v) then
                    v.Transparency = 0
                end
            end
        end
    end
    return set
end

local function getPrettyMutation(shiny : boolean, sparkling : boolean, mutation : string) : string
    local result = ""

    if shiny then
        result = result .. "Shiny"
    end

    if sparkling then
        result = result .. "Sparkling"
    end

    result = result .. mutation

    return string.lower(result)
end

local function shallowEqual(t1, t2)
	if t1 == t2 then return true end
	if type(t1) ~= "table" or type(t2) ~= "table" then return false end

	for k, v in pairs(t1) do
		if t2[k] ~= v then
			return false
		end
	end
	for k in pairs(t2) do
		if t1[k] == nil then
			return false
		end
	end
	return true
end

-- auto farm tab

local fluentAutoFarmToggle = Tabs.autoFarmTab:AddToggle("AutoFarmToggle",{Title = "Auto Farm Toggle", Default = false})

fluentAutoFarmToggle:OnChanged(function()

    autoFarmToggle = options.AutoFarmToggle.Value

    if options.AutoFarmToggle.Value then
        castRod(getRod())
    end

end)

local fluentAutoShakeToggle = Tabs.autoFarmTab:AddToggle("AutoShakeToggle",{Title = "Auto Shake Toggle", Default = true})

fluentAutoShakeToggle:OnChanged(function()

    autoShakeToggle = options.AutoShakeToggle.Value

end)

local fluentAutoReelToggle = Tabs.autoFarmTab:AddToggle("AutoReelToggle",{Title = "Auto Reel Toggle",Default = true})

fluentAutoReelToggle:OnChanged(function()

    autoReelToggle = options.AutoReelToggle.Value

end)

-- upgrade tab

Tabs.upgradeTab:AddButton({
    Title = "Button",
    Description = "Appraise Current Held Item",
    Callback = function()
        local item = character:FindFirstChildOfClass("Tool")
        notify(false, "Appraising Item", "Name: ".. (item and item.Name or ""))
            local _,shiny,sparkling,mutation = appraiseItem(item)
            local prettyMutation = getPrettyMutation(shiny,sparkling,mutation)
            notify(false,"Item Appraised","Got: ".. prettyMutation == "" and "Nothing" or prettyMutation)
    end,
})

Tabs.upgradeTab:AddInput("wantedAppraiseInput",{
        Title = "Enter Wanted Appraisal Mutations Here",
        Default = "",
        Placeholder = "Example: \"Shiny Sparkling \" ",
        Numeric = false,
        Finished = false,
        Callback = function(Text)
            wantedAppraise = string.lower(Text):gsub(" ","")
        end,
})

-- variable to store old inventory
Tabs.upgradeTab:AddButton({
    Title = "Button",
    Description = "Appraise Until Wanted Appraise",
    Callback = function()
        local item = character:FindFirstChildOfClass("Tool")
        if not item then
            notify(true,"Item not found","Make Sure To Equip An Item")
            return
        end
        local count = 0
        repeat
            task.wait()
            local result,shiny,sparkling,mutation = appraiseItem(item)
            item = result
            local prettyMutation = getPrettyMutation(shiny,sparkling,mutation)
            notify(false,"Item Appraised, Run Count: "..count,"Got: ".. (prettyMutation == "" and "Nothing" or prettyMutation))
            count += 1
            task.wait(0.75)
            item = result
        until string.find(prettyMutation,wantedAppraise)
    end,
})

Tabs.upgradeTab:AddButton({
    Title = "Button",
    Description = "Enchant Rod ( Hold Relic )",
    Callback = function()
        local relic = character:FindFirstChildOfClass("Tool")
        if relic and string.find(relic.Name,"Relic") then
            local enchantName = enchantRod(relic)
            notify(false,"Enchanted Rod Finished", "Enchant Name: "..enchantName)
        else
            notify(true,"Please Hold A Relic In Your Hand", "Current Item Held: ".. (relic and relic.Name or "Not Found"))
        end
    end,
})

Tabs.upgradeTab:AddInput("wantedEnchantInput",{
        Title = "Enter Wanted Enchant Name Here",
        Default = "",
        Placeholder = "Enchant Name Here",
        Numeric = false,
        Finished = false,
        Callback = function(Text)
            wantedEnchant = string.lower(Text)
        end,
})

Tabs.upgradeTab:AddButton({
    Title = "Button",
    Description = "Enchant Until You Get Wanted Enchant",
    Callback = function()
        local relic = character:FindFirstChildOfClass("Tool")
        if relic and string.find(relic.Name,"Relic") then
            repeat
                local enchantName = enchantRod(relic)
                notify(false,"Enchanted Rod","Got Enchant: " .. enchantName)
                task.wait(1)
            until string.find(wantedEnchant,enchantName) or not relic.Parent
        else
            notify(true,"Please Hold A Relic In Your Hand", "Current Item Held: ".. (relic and relic.Name or "Not Found"))
        end
    end,
})

-- local player tab

local FluentTpToSpot

local TpToSpotInput = Tabs.lpTab:AddInput(
    "TpToSpotSearch",
    {
        Title = "Search Spots",
        Default = "",
        Placeholder = "Enter Search Here",
        Numeric = false,
        Finished = false,
        Callback = function(Text)
            local matching = {"None"}
            for _,v in pairs(getSpawnNames(spawnsDir)) do
                if v~= "None" then
                    if string.find(string.lower(v), string.lower(Text), 1, true) then
                        table.insert(matching, v)
                    end
                end
            end

            if Text == "" then 
                if shallowEqual(FluentTpToSpot.Values, matching) then
                    return
                end
            end

            if FluentTpToSpot then
                FluentTpToSpot:SetValues(matching)
                FluentTpToSpot:SetValue("None")
            end
        end,
    }
)


FluentTpToSpot = Tabs.lpTab:AddDropdown("TpToSpotDropdown", {
    Title = "TP To Spot",
    Values = getSpawnNames(spawnsDir),
    Multi = false,
    Default = 1,
})

FluentTpToSpot:OnChanged(function(Value)
    if Value == "None" then return end
    local folder = spawnsDir:FindFirstChild(Value)
    if folder then
        HRP.Position = folder:FindFirstChild("spawn").Position + Vector3.new(0,5,0)
        FluentTpToSpot:SetValue("None")
        if options.TpToSpotSearch.Value ~= "" then
            TpToSpotInput:SetValue("")
        end
    else
        notify(true,"Couldnt Find Map Folder","Couldnt Find Folder For: ".. Value)
    end
end)

Tabs.lpTab:AddButton({
    Title = "Button",
    Description = "Save Position",
    Callback = function()
        savedPosition = HRP.Position
        notify(false,"Position Saved", "X: "..HRP.Position.X .. "Y: ".. HRP.Position.Y .. "Z: ".. HRP.Position.Z)
    end,
})

Tabs.lpTab:AddButton({
    Title = "Button",
    Description = "TP To Saved Position",
    Callback = function()
        if savedPosition then
            HRP.Position = savedPosition
        else
            notify(true,"Please Set A Saved Position", "No Saved Position Found", 10)
        end
    end,
})

Tabs.lpTab:AddButton({
    Title = "Button",
    Description = "Fly GUI",
    Callback = function()
        local main = Instance.new("ScreenGui")
        local Frame = Instance.new("Frame")
        local up = Instance.new("TextButton")
        local down = Instance.new("TextButton")
        local onof = Instance.new("TextButton")
        local TextLabel = Instance.new("TextLabel")
        local plus = Instance.new("TextButton")
        local speed = Instance.new("TextLabel")
        local mine = Instance.new("TextButton")
        local closebutton = Instance.new("TextButton")
        local mini = Instance.new("TextButton")
        local mini2 = Instance.new("TextButton") 

        main.Name = "main"
        main.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        main.ResetOnSpawn = false 

        Frame.Parent = main
        Frame.BackgroundColor3 = Color3.fromRGB(163, 255, 137)
        Frame.BorderColor3 = Color3.fromRGB(103, 221, 213)
        Frame.Position = UDim2.new(0.100320168, 0, 0.379746825, 0)
        Frame.Size = UDim2.new(0, 190, 0, 57) 

        up.Name = "up"
        up.Parent = Frame
        up.BackgroundColor3 = Color3.fromRGB(79, 255, 152)
        up.Size = UDim2.new(0, 44, 0, 28)
        up.Font = Enum.Font.SourceSans
        up.Text = "UP"
        up.TextColor3 = Color3.fromRGB(0, 0, 0)
        up.TextSize = 14.000 

        down.Name = "down"
        down.Parent = Frame
        down.BackgroundColor3 = Color3.fromRGB(215, 255, 121)
        down.Position = UDim2.new(0, 0, 0.491228074, 0)
        down.Size = UDim2.new(0, 44, 0, 28)
        down.Font = Enum.Font.SourceSans
        down.Text = "DOWN"
        down.TextColor3 = Color3.fromRGB(0, 0, 0)
        down.TextSize = 14.000 

        onof.Name = "onof"
        onof.Parent = Frame
        onof.BackgroundColor3 = Color3.fromRGB(255, 249, 74)
        onof.Position = UDim2.new(0.702823281, 0, 0.491228074, 0)
        onof.Size = UDim2.new(0, 56, 0, 28)
        onof.Font = Enum.Font.SourceSans
        onof.Text = "fly"
        onof.TextColor3 = Color3.fromRGB(0, 0, 0)
        onof.TextSize = 14.000 

        TextLabel.Parent = Frame
        TextLabel.BackgroundColor3 = Color3.fromRGB(242, 60, 255)
        TextLabel.Position = UDim2.new(0.469327301, 0, 0, 0)
        TextLabel.Size = UDim2.new(0, 100, 0, 28)
        TextLabel.Font = Enum.Font.SourceSans
        TextLabel.Text = "Fly GUI V3"
        TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextScaled = true
        TextLabel.TextSize = 14.000
        TextLabel.TextWrapped = true 

        plus.Name = "plus"
        plus.Parent = Frame
        plus.BackgroundColor3 = Color3.fromRGB(133, 145, 255)
        plus.Position = UDim2.new(0.231578946, 0, 0, 0)
        plus.Size = UDim2.new(0, 45, 0, 28)
        plus.Font = Enum.Font.SourceSans
        plus.Text = "+"
        plus.TextColor3 = Color3.fromRGB(0, 0, 0)
        plus.TextScaled = true
        plus.TextSize = 14.000
        plus.TextWrapped = true 

        speed.Name = "speed"
        speed.Parent = Frame
        speed.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
        speed.Position = UDim2.new(0.468421042, 0, 0.491228074, 0)
        speed.Size = UDim2.new(0, 44, 0, 28)
        speed.Font = Enum.Font.SourceSans
        speed.Text = "1"
        speed.TextColor3 = Color3.fromRGB(0, 0, 0)
        speed.TextScaled = true
        speed.TextSize = 14.000
        speed.TextWrapped = true 

        mine.Name = "mine"
        mine.Parent = Frame
        mine.BackgroundColor3 = Color3.fromRGB(123, 255, 247)
        mine.Position = UDim2.new(0.231578946, 0, 0.491228074, 0)
        mine.Size = UDim2.new(0, 45, 0, 29)
        mine.Font = Enum.Font.SourceSans
        mine.Text = "-"
        mine.TextColor3 = Color3.fromRGB(0, 0, 0)
        mine.TextScaled = true
        mine.TextSize = 14.000
        mine.TextWrapped = true 

        closebutton.Name = "Close"
        closebutton.Parent = main.Frame
        closebutton.BackgroundColor3 = Color3.fromRGB(225, 25, 0)
        closebutton.Font = "SourceSans"
        closebutton.Size = UDim2.new(0, 45, 0, 28)
        closebutton.Text = "X"
        closebutton.TextSize = 30
        closebutton.Position = UDim2.new(0, 0, -1, 27) 

        mini.Name = "minimize"
        mini.Parent = main.Frame
        mini.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
        mini.Font = "SourceSans"
        mini.Size = UDim2.new(0, 45, 0, 28)
        mini.Text = "-"
        mini.TextSize = 40
        mini.Position = UDim2.new(0, 44, -1, 27) 

        mini2.Name = "minimize2"
        mini2.Parent = main.Frame
        mini2.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
        mini2.Font = "SourceSans"
        mini2.Size = UDim2.new(0, 45, 0, 28)
        mini2.Text = "+"
        mini2.TextSize = 40
        mini2.Position = UDim2.new(0, 44, -1, 57)
        mini2.Visible = false 

        speeds = 1 

        local speaker = game:GetService("Players").LocalPlayer 

        local chr = game.Players.LocalPlayer.Character
        local hum = chr and chr:FindFirstChildWhichIsA("Humanoid") 

        nowe = false 

        game:GetService("StarterGui"):SetCore("SendNotification", { 
        Title = "Fly GUI V3";
        Text = "By me_ozone and Quandale The Dinglish XII#3550";
        Icon = "rbxthumb://type=Asset&id=5107182114&w=150&h=150"})
        Duration = 5; 
        
        Frame.Active = true -- main = gui
        Frame.Draggable = true 
        local flickcon = nil
        local lastChange = 0
        onof.MouseButton1Down:connect(function() 
        
        if nowe == true then
        nowe = false 
        
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,true)
        speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        if flickcon then flickcon:Disconnect() end
        else 
        nowe = true
        
        
        
        for i = 1, speeds do
        spawn(function() 
        
        local hb = game:GetService("RunService").Heartbeat
        
        
        tpwalking = true
        local chr = game.Players.LocalPlayer.Character
        local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
        while tpwalking and hb:Wait() and chr and hum and hum.Parent do
        if hum.MoveDirection.Magnitude > 0 then
        chr:TranslateBy(hum.MoveDirection)
        end
        end 

        end)
        end
        game.Players.LocalPlayer.Character.Animate.Disabled = true
        local Char = game.Players.LocalPlayer.Character
        local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController") 

        for i,v in next, Hum:GetPlayingAnimationTracks() do
        v:AdjustSpeed(0)
        end
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
        speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
        flickcon = game:GetService("RunService").Heartbeat:Connect(function(dt)
            if tick() - lastChange > 0.5 then
                speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
                task.wait()
                speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
                lastChange = tick()
            end
        end)
        end




        if game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R6 then
        
        
        
        local plr = game.Players.LocalPlayer
        local torso = plr.Character.Torso
        local flying = true
        local deb = true
        local ctrl = {f = 0, b = 0, l = 0, r = 0}
        local lastctrl = {f = 0, b = 0, l = 0, r = 0}
        local maxspeed = 50
        local speed = 0
        
        
        local bg = Instance.new("BodyGyro", torso)
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = torso.CFrame
        local bv = Instance.new("BodyVelocity", torso)
        bv.velocity = Vector3.new(0,0.1,0)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        if nowe == true then
        plr.Character.Humanoid.PlatformStand = true
        end
        while nowe == true or game:GetService("Players").LocalPlayer.Character.Humanoid.Health == 0 do
        game:GetService("RunService").RenderStepped:Wait() 
        
        if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
        speed = speed+.5+(speed/maxspeed)
        if speed > maxspeed then
        speed = maxspeed
        end
        elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
        speed = speed-1
        if speed < 0 then
        speed = 0
        end
        end
        if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
        bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
        lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
        elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
        bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
        else
        bv.velocity = Vector3.new(0,0,0)
        end
        --game.Players.LocalPlayer.Character.Animate.Disabled = true
        bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
        end
        ctrl = {f = 0, b = 0, l = 0, r = 0}
        lastctrl = {f = 0, b = 0, l = 0, r = 0}
        speed = 0
        bg:Destroy()
        bv:Destroy()
        plr.Character.Humanoid.PlatformStand = false
        game.Players.LocalPlayer.Character.Animate.Disabled = false
        tpwalking = false




        else
        local plr = game.Players.LocalPlayer
        local UpperTorso = plr.Character.UpperTorso
        local flying = true
        local deb = true
        local ctrl = {f = 0, b = 0, l = 0, r = 0}
        local lastctrl = {f = 0, b = 0, l = 0, r = 0}
        local maxspeed = 50
        local speed = 0
        
        
        local bg = Instance.new("BodyGyro", UpperTorso)
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = UpperTorso.CFrame
        local bv = Instance.new("BodyVelocity", UpperTorso)
        bv.velocity = Vector3.new(0,0.1,0)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        if nowe == true then
        plr.Character.Humanoid.PlatformStand = true
        end
        while nowe == true or game:GetService("Players").LocalPlayer.Character.Humanoid.Health == 0 do
        wait() 
        
        if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
        speed = speed+.5+(speed/maxspeed)
        if speed > maxspeed then
        speed = maxspeed
        end
        elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
        speed = speed-1
        if speed < 0 then
        speed = 0
        end
        end
        if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
        bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
        lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
        elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
        bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
        else
        bv.velocity = Vector3.new(0,0,0)
        end 

        bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
        end
        ctrl = {f = 0, b = 0, l = 0, r = 0}
        lastctrl = {f = 0, b = 0, l = 0, r = 0}
        speed = 0
        bg:Destroy()
        bv:Destroy()
        plr.Character.Humanoid.PlatformStand = false
        game.Players.LocalPlayer.Character.Animate.Disabled = false
        tpwalking = false



        end





        end) 

        local tis 

        up.MouseButton1Down:connect(function()
        tis = up.MouseEnter:connect(function()
        while tis do
        wait()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,1,0)
        end
        end)
        end) 

        up.MouseLeave:connect(function()
        if tis then
        tis:Disconnect()
        tis = nil
        end
        end) 

        local dis 

        down.MouseButton1Down:connect(function()
        dis = down.MouseEnter:connect(function()
        while dis do
        wait()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,-1,0)
        end
        end)
        end) 

        down.MouseLeave:connect(function()
        if dis then
        dis:Disconnect()
        dis = nil
        end
        end)


        game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(char)
        wait(0.7)
        game.Players.LocalPlayer.Character.Humanoid.PlatformStand = false
        game.Players.LocalPlayer.Character.Animate.Disabled = false 
        
        end)


        plus.MouseButton1Down:connect(function()
        speeds = speeds + 1
        speed.Text = speeds
        if nowe == true then
        
        
        tpwalking = false
        for i = 1, speeds do
        spawn(function() 
        
        local hb = game:GetService("RunService").Heartbeat
        
        
        tpwalking = true
        local chr = game.Players.LocalPlayer.Character
        local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
        while tpwalking and hb:Wait() and chr and hum and hum.Parent do
        if hum.MoveDirection.Magnitude > 0 then
        chr:TranslateBy(hum.MoveDirection)
        end
        end 

        end)
        end
        end
        end)
        mine.MouseButton1Down:connect(function()
        if speeds == 1 then
        speed.Text = 'cannot be less than 1'
        wait(1)
        speed.Text = speeds
        else
        speeds = speeds - 1
        speed.Text = speeds
        if nowe == true then
        tpwalking = false
        for i = 1, speeds do
        spawn(function() 
        
        local hb = game:GetService("RunService").Heartbeat
        
        
        tpwalking = true
        local chr = game.Players.LocalPlayer.Character
        local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
        while tpwalking and hb:Wait() and chr and hum and hum.Parent do
        if hum.MoveDirection.Magnitude > 0 then
        chr:TranslateBy(hum.MoveDirection)
        end
        end 

        end)
        end
        end
        end
        end) 

        closebutton.MouseButton1Click:Connect(function()
        main:Destroy()
        if flickcon then flickcon:Disconnect() end
        end) 

        mini.MouseButton1Click:Connect(function()
        up.Visible = false
        down.Visible = false
        onof.Visible = false
        plus.Visible = false
        speed.Visible = false
        mine.Visible = false
        mini.Visible = false
        mini2.Visible = true
        main.Frame.BackgroundTransparency = 1
        closebutton.Position = UDim2.new(0, 0, -1, 57)
        end) 

        mini2.MouseButton1Click:Connect(function()
        up.Visible = true
        down.Visible = true
        onof.Visible = true
        plus.Visible = true
        speed.Visible = true
        mine.Visible = true
        mini.Visible = true
        mini2.Visible = false
        main.Frame.BackgroundTransparency = 0 
        closebutton.Position = UDim2.new(0, 0, -1, 27)
        end)
    end,
})

-- boat tab
Tabs.boatTab:AddParagraph({
    Title = "Boat TP Usage",
    Content = "Enter Wanted Position And Click The Teleport Button."
})

local TPpos = Vector3.new(0,0,0)

local xInput = Tabs.boatTab:AddInput(
    "BoatTPX",
    {
    Title = "X: ",
    Default = "0",
    Placeholder = "GPS X Coordinates Here",
    Numeric = true,
    Finished = false,
    Callback = function(Text)
        TPpos = Vector3.new(tonumber(Text),TPpos.Y,TPpos.Z)
    end,
})

local yInput = Tabs.boatTab:AddInput(
    "BoatTPY",
{
    Title = "Y: ",
    Default = "0",
    Placeholder = "GPS Y Coordinates Here",
    Numeric = true,
    Finished = false,
    Callback = function(Text)
        TPpos = Vector3.new(TPpos.X,tonumber(Text),TPpos.Z)
    end,
})

local zInput = Tabs.boatTab:AddInput(
    "BoatTPZ",
{
    Title = "Z: ",
    Default = "0",
    Placeholder = "GPS Z Coordinates Here",
    Numeric = true,
    Finished = false,
    Callback = function(Text)
        TPpos = Vector3.new(TPpos.X,TPpos.Y,tonumber(Text))
    end,
})

Tabs.boatTab:AddButton({
    Title = "Button",
    Description = "TP To Wanted Position (Small Boat Reccomended)",
    Callback = function()
        local Boat = getBoat()
        if Boat then
            Boat:PivotTo(CFrame.new(TPpos + Vector3.new(0,5,0)))
        else
            notify(true,"Boat Not Found","Please Sit In A Boat")
        end
    end,
})

Tabs.boatTab:AddButton({
    Title = "Button",
    Description = "TP To Saved Position (From Local Player Tab)",
    Callback = function()
        local Boat = getBoat()
        if Boat then
            Boat:PivotTo(CFrame.new(savedPosition + Vector3.new(0,5,0)))
        else
            notify(true,"Boat Not Found","Please Sit In A Boat")
        end
    end,
})

Tabs.boatTab:AddButton({
    Title = "Button",
    Description = "Reset Values",
    Callback = function()
        xInput:SetValue("0")
        yInput:SetValue("0")
        zInput:SetValue("0")
    end,
})

Tabs.boatTab:AddParagraph({
    Title = "Boat Fly Usage",
    Content = "Sit In A Boat, Toggle, Adjust Speed, And Enjoy"
})

local flying = false
local speed = 50
local w = false
local a = false
local s = false
local d = false
local con = nil
local transperancyAffected = {}
local heartbeatCount = 0

uis.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		w = true
	end
	if input.KeyCode == Enum.KeyCode.A then
		a = true
	end
	if input.KeyCode == Enum.KeyCode.S then
		s = true
	end
	if input.KeyCode == Enum.KeyCode.D then
		d = true
	end
end)

uis.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		w = false
	end
	if input.KeyCode == Enum.KeyCode.A then
		a = false
	end
	if input.KeyCode == Enum.KeyCode.S then
		s = false
	end
	if input.KeyCode == Enum.KeyCode.D then
		d = false
	end
end)

local fluentBoatFlyToggle = Tabs.boatTab:AddToggle("BoatFlyToggle",{Title = "Boat Fly(Keyboard Only)", Default = false})

fluentBoatFlyToggle:OnChanged(function()
    local boat = getBoat()
	if boat then
        if options.BoatFlyToggle and options.BoatFlyToggle.Value then
            transperancyAffected = setModelTransperancy(boat,true, {})
        else
            setModelTransperancy(boat,false, transperancyAffected)
            if con then
                con:Disconnect()
            end
        end
    else
        notify(true,"Boat Not Found","Please Sit In A Boat And Try Again")
        if options.BoatFlyToggle.Value then
            options.BoatFlyToggle:SetValue(false)
        end
        return
    end
	flying = options.BoatFlyToggle and options.BoatFlyToggle.Value

    con = rs.Heartbeat:Connect(function(dt)
    	if flying then
    		local boat = getBoat()
    		if boat then
    			local cframeForLookVector = CFrame.new(workspace.CurrentCamera.CFrame.Position,HRP.Position)
                boat.Base.Motor.Velocity = Vector3.zero
    			if w then
    				boat:PivotTo(boat:GetPivot() + ((cframeForLookVector.LookVector*speed) * dt))
    			end
    			if a then
    				boat:PivotTo(boat:GetPivot() - ((cframeForLookVector.RightVector*speed) * dt))
    			end
    			if s then
    				boat:PivotTo(boat:GetPivot() - ((cframeForLookVector.LookVector*speed) * dt))
    			end
    			if d then
    				boat:PivotTo(boat:GetPivot() + ((cframeForLookVector.RightVector*speed) * dt))
    			end
    		end
    	end
    end)
end)

Tabs.boatTab:AddSlider("BoatFlySpeedSlider", {
    Title = "Slider",
    Description = "Adjust Boat Fly Speed",
    Default = 50,
    Min = 1,
    Max = 1000,
    Rounding = 10,
    Callback = function(Value)
        speed = Value
    end
})

-- options tab

Tabs.optionsTab:AddToggle("InfoNotifyToggle",{Title = "Show Informative Notifications",Default = true})

-- auto shake
player:WaitForChild("PlayerGui").childAdded:Connect(function(child)
    if autoShakeToggle then
        if child.Name == "shakeui" then
            local con1
            local con2
            con1 = child.AncestryChanged:Connect(function(child,parent)
                if not parent then
                    notify(false, "Finished Shaking")
                    con2:Disconnect()
                    con1:Disconnect()
                end
            end)

            con2 = child:WaitForChild("safezone").ChildAdded:Connect(function(child)
                if child.Name == "button" then
                    shake(child)
                end         
            end)
        end
    end
end)
-- auto reel
player:WaitForChild("PlayerGui").childAdded:Connect(function(child)
    if autoReelToggle then
        if child.Name == "reel" then
            finishCast(getRod(), autoFarmToggle , child:WaitForChild("bar"):WaitForChild("playerbar") , child:WaitForChild("bar"):WaitForChild("fish"))
        end
    end
end)

while task.wait(300) do
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Tilde, false, nil)
    task.wait(0.1)
    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Tilde, false, nil)
end
