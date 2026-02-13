local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Lib/main/source.lua"))()
local window = library:Window("Items Giver")

window:Button("Developer Gun", function()
    local args = {
        [1] = "guns",
        [2] = "Developer"
    }

    game:GetService("ReplicatedStorage").common.packages.Knit.Services.InventoryService.RF.EquipItem:InvokeServer(unpack(args))
end)

window:Button("Tubes", function()
    local args = {
        [1] = "tubes",
        [2] = "Sea Mine"
    }

    game:GetService("ReplicatedStorage").common.packages.Knit.Services.InventoryService.RF.EquipItem:InvokeServer(unpack(args))
end)

window:Label("Credit : Skibidi50-lol", Color3.fromRGB(127, 143, 166))
