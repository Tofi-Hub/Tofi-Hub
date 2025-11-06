-- THIS SCRIPT WAS NOT MEANT TO BE SECURE OR ANYTHING, I JUST WANT MORE PEOPLE IN MY DISCORD SERVER, THE KEY WILL NEVER CHANGE , PLEASE JUST JOIN MY DISCORD...

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Tofi Hub Loader",
    SubTitle = "by @dandush on discord",
    TabWidth = 160,
    Size = UDim2.fromOffset(650, 500),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.K
})

local discordLink = "https://discord.gg/xBnz3uPXPm"

local loaderTab = Window:AddTab({Title = "Loader Tab", Icon = "file-terminal"})

Window:SelectTab(loaderTab)

local Games = 
{
    [537413528] = "BABFT.lua",
    [7655745946] = "DunkSimulator.lua",
    [17738127017] = "Brace.lua",
    [1828509885] = "EFS.lua",
    [16732694052] = "Fisch.lua",
    [10925589760] = "MergeSimulator.lua",
    [1537690962] = "BSS.lua",
}

local placeID = game.PlaceId

local associated = Games[placeID]

local MarketplaceService = game:GetService("MarketplaceService")
local gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

if not associated then
    Fluent:Notify(
    {
        Title = "GAME NOT SUPPORTED",
        Content = gameName .. " Is Not Supported By Tofi Hub",
        Duration = 15
    })

    Window:Destroy()
end

local input = loaderTab:AddInput("KeyInput" ,{
    Title = "Enter Key Here",
    Default = "",
    Placeholder = "KEY",
    Numeric = false,
    Finished = false,
})

local function loadScript() : ()

    if associated then

        loadstring(game:HttpGet("https://raw.githubusercontent.com/Tofi-Hub/Tofi-Hub/refs/heads/main/"..associated))()
        Fluent:Notify(
        {
        Title = "Loading Script",
        Content = "Loading Script For " .. gameName,
        Duration = 10
        })

        Fluent:Destroy()
    else


        Fluent:Notify(
        {
        Title = "GAME NOT SUPPORTED",
        Content = gameName .. " Is Not Supported By Tofi Hub",
        Duration = 15
        })

        Fluent:Destroy()
    end
end


loaderTab:AddButton({
    Title = "Load",
    Description = "Loads The Script For Current Game",
    Callback = function()

        if Fluent.Options.KeyInput.Value == "\116\79\102\105\71\111\65\116" then
            loadScript()
        else
            Fluent:Notify(
            {
            Title = "KEY IS NOT CORRECT",
            Content = "Find The Key In The \"Tofi Hub Key\" Channel In Discord Or Wait 5 Minutes",
            Duration = 15
            })
        end

    end,
})

local start = tick()

loaderTab:AddSection("Info")

local par = loaderTab:AddParagraph({
    Title = "Instructions To Load Tofi Hub:",
    Description = "Either Join The Discord And Get The PERMENANT Key From The \"Tofi Hub Key\" Channel Or Wait " ..  300 - math.floor(tick() - start) .." Seconds"
})

loaderTab:AddButton({
    Title = "Discord",
    Description = "Copy Discord Invite Link To Clipboard",
    Callback = function()
        setclipboard(discordLink)
        Fluent:Notify(
            {
            Title = "Clipboard",
            Content = "Set Clipboard To Discord Link",
            Duration = 5
            })
    end,
})



while tick() - start < 300 do
    task.wait()
    par:SetDesc("Either Join The Discord And Get The PERMENANT Key From The \"Tofi Hub Key\" Channel Or Wait " ..  300 - math.floor(tick() - start) .." Seconds")
end

if not Fluent.Unloaded then

    loadScript()

end
