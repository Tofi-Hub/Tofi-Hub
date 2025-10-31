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
 -- rayfield
 local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
 local Window = Rayfield:CreateWindow({
   Name = "Brace hub",
   Icon = 0,
   LoadingTitle = "Rayfield Interface Suite",
   LoadingSubtitle = "by Sirius",
   Theme = "Default",
   ToggleUIKeybind = "G",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = false,
      FolderName = "BraceConfigs",
      FileName = "config"
   },
})

local testTab = Window:CreateTab("main tab")
local vechileFolder = workspace.CurrentVehicles
local trackpartsFolder = workspace.TrackParts
local autoFarmToggle = false

local function getPlayerVechile()
   local playerName = player.Name
   for _,car in pairs(vechileFolder:GetChildren()) do
      if car.Name == playerName then
         return car
      end
   end
end

local function Teleport(tp) 
    local vechile = getPlayerVechile()
    if vechile then
       vechile:PivotTo(tp)
    else
       print("Attempted to move vechile when it didnt exist yet")
    end
end

local function isRoundStarted()
    local car = getPlayerVechile()
    if not car then return false end
    if not car.PrimaryPart then return false end
    if car.PrimaryPart.Anchored then return false end
    return true
end

local function getStageByNumber(number : number)
    print("Entered getStageByNumber with number: "..number)
    local result = {}
    for _,stage in pairs(trackpartsFolder:GetChildren()) do
        print("Comparing: "..stage.Name.." With: "..number..".")
        if stage.Name == tostring(number) then
            print("Found Stage")
            table.insert(result,stage)
        end
    end
    return result
end

local function getCheckpoints()
    local checkpoints = {}
    for i,stage in pairs(trackpartsFolder:GetChildren()) do
        for _,stagey in pairs(getStageByNumber(i)) do
            if stagey:FindFirstChild("Trigger") then
                table.insert(checkpoints, stagey.Trigger)
            end
        end
    end
    return checkpoints
end

testTab:CreateButton({
   Name = "TP END",
   Callback = function()
    Teleport(workspace.TrackParts.End.Finish.CFrame)
   end,
})

testTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    flag = "autoFarm",
    Callback = function(Value)
        print("set autofarm to: "..tostring(Value))
        autoFarmToggle = Value
    end,
})

task.spawn(function()
    while true do
        if autoFarmToggle then
            task.wait()
            local started = isRoundStarted()
            if started then
                local checkpoints = getCheckpoints()
                for _,v in pairs(checkpoints) do
                    Teleport(v.CFrame)
                    task.wait(1.5)
                end
                Teleport(workspace.TrackParts.End.Finish.CFrame)
            else
                print("Round Not Started")
            end
        else
            task.wait(1)
        end
    end
end)

-- anti afk

task.spawn(function()
    while task.wait(100) do
        vim:SendKeyEvent(true, Enum.KeyCode.Tilde, false, nil)
        task.wait(0.1)
        vim:SendKeyEvent(false, Enum.KeyCode.Tilde, false, nil)
    end
end)


