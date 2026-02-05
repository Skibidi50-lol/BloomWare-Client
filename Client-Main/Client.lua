local success, Games = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/Skibidi50-lol/BloomWare-Client/main/Client-Main/Games/List.lua",
        true
    ))()
end)

if not success or type(Games) ~= "table" then
    warn("Failed to load game list or it's not a table")
    return
end

local URL = Games[game.PlaceId]



if URL and URL ~= "" then
    loadstring(game:HttpGet(URL, true))()
else
    warn("No script found for PlaceId " .. game.GameId)
end
