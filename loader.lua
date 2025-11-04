local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

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

if associated then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Tofi-Hub/Tofi-Hub/refs/heads/main/"..associated))()
        Fluent:Notify(
        {
        Title = "Loading Script",
        Content = "Loading Script For " .. gameName,
        Duration = 10
        })
else


    Fluent:Notify(
        {
        Title = "GAME NOT SUPPORTED",
        Content = gameName .. " Is Not Supported By Tofi Hub",
        Duration = 15
        })
end
