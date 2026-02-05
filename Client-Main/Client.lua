local Games = loadstring(game:HttpGet("https://raw.githubusercontent.com/Skibidi50-lol/BloomWare-Client/refs/heads/main/Client-Main/Games/List.lua"))()

local URL = Games[game.GameId]

if URL then
  loadstring(game:HttpGet(URL))()
end
