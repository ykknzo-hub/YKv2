--[[
    Roblox Nametag System - GitHub Edition
    Load via: loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/RobloxNametag.lua"))()
    
    This script fetches nametag data from GitHub and displays them above player heads
    with smooth bobbing animation, gradient support, white borders, and rounded corners.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- ===== CONFIGURATION =====
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/ykknzo-hub/YKv2/refs/heads/main/nametags.json"
local NAMETAG_HEIGHT = 4
local BOB_SPEED = 2
local BOB_AMOUNT = 0.3
local BORDER_SIZE = 1
local CORNER_RADIUS = 4
local NAMETAG_WIDTH = 4.5
local NAMETAG_HEIGHT_SIZE = 1.2
local CACHE_REFRESH_INTERVAL = 30
-- ==========================

local nametagCache = {}
local lastCacheTime = 0

local function hexToColor3(hex)
    if not hex or hex == "" then
        return Color3.fromRGB(88, 101, 242)
    end
    
    hex = hex:gsub("#", "")
    if #hex ~= 6 then
        return Color3.fromRGB(88, 101, 242)
    end
    
    local success, result = pcall(function()
        return Color3.fromRGB(
            tonumber("0x" .. hex:sub(1, 2)),
            tonumber("0x" .. hex:sub(3, 4)),
            tonumber("0x" .. hex:sub(5, 6))
        )
    end)
    
    return success and result or Color3.fromRGB(88, 101, 242)
end

local function fetchFromGitHub()
    local success, result = pcall(function()
        local response = HttpService:GetAsync(GITHUB_RAW_URL)
        return HttpService:JSONDecode(response)
    end)
    
    if success then
        return result
    else
        warn("⚠️ Failed to fetch nametags from GitHub")
        return nametagCache
    end
end

local function getPlayerTagData(playerName)
    for tagName, tagData in pairs(nametagCache) do
        if tagData.users then
            for _, user in ipairs(tagData.users) do
                if user == playerName then
                    return {
                        tag = tagName,
                        gradient = tagData.gradient,
                        color = tagData.color
                    }
                end
            end
        end
    end
    return nil
end

local function createNametag(character, playerName, tagData)
    if not character:FindFirstChild("Head") then return end
    
    local oldTag = character:FindFirstChild("NametagHolder")
    if oldTag then oldTag:Destroy() end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "NametagHolder"
    billboardGui.Size = UDim2.new(NAMETAG_WIDTH, 0, NAMETAG_HEIGHT_SIZE, 0)
    billboardGui.MaxDistance = 100
    billboardGui.Parent = character.Head
    
    -- White border background
    local borderFrame = Instance.new("Frame")
    borderFrame.Name = "Border"
    borderFrame.Size = UDim2.new(1, 0, 1, 0)
    borderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    borderFrame.BorderSizePixel = 0
    borderFrame.ZIndex = 0
    borderFrame.Parent = billboardGui
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    borderCorner.Parent = borderFrame
    
    -- Main content frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "NametagFrame"
    mainFrame.Size = UDim2.new(1, -BORDER_SIZE * 2, 1, -BORDER_SIZE * 2)
    mainFrame.Position = UDim2.new(0, BORDER_SIZE, 0, BORDER_SIZE)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 1
    mainFrame.Parent = billboardGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    corner.Parent = mainFrame
    
    -- Gradient or solid color
    if tagData and tagData.gradient then
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, hexToColor3(tagData.gradient.color1)),
            ColorSequenceKeypoint.new(1, hexToColor3(tagData.gradient.color2))
        })
        gradient.Rotation = 45
        gradient.Parent = mainFrame
    else
        mainFrame.BackgroundColor3 = hexToColor3(tagData and tagData.color or "#5865F2")
    end
    
    -- Text container for multi-line layout with padding
    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.Size = UDim2.new(1, -4, 1, -2)
    textContainer.Position = UDim2.new(0, 2, 0, 1)
    textContainer.BackgroundTransparency = 1
    textContainer.BorderSizePixel = 0
    textContainer.ZIndex = 2
    textContainer.Parent = mainFrame
    
    -- Top line - Tag name
    local topLabel = Instance.new("TextLabel")
    topLabel.Name = "TagName"
    topLabel.Size = UDim2.new(1, 0, 0.5, 0)
    topLabel.Position = UDim2.new(0, 0, 0, 0)
    topLabel.BackgroundTransparency = 1
    topLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    topLabel.TextScaled = true
    topLabel.Font = Enum.Font.GothamBold
    topLabel.TextSize = 14
    topLabel.ZIndex = 2
    topLabel.Parent = textContainer
    topLabel.Text = tagData and tagData.tag or "TAG"
    
    -- Bottom line - Username with @
    local bottomLabel = Instance.new("TextLabel")
    bottomLabel.Name = "Username"
    bottomLabel.Size = UDim2.new(1, 0, 0.5, 0)
    bottomLabel.Position = UDim2.new(0, 0, 0.5, 0)
    bottomLabel.BackgroundTransparency = 1
    bottomLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    bottomLabel.TextScaled = true
    bottomLabel.Font = Enum.Font.Gotham
    bottomLabel.TextSize = 12
    bottomLabel.ZIndex = 2
    bottomLabel.Parent = textContainer
    bottomLabel.Text = "@" .. playerName
    
    billboardGui:SetAttribute("bobTime", 0)
    return billboardGui
end

local function updateAnimation(billboardGui, deltaTime)
    if not billboardGui or not billboardGui.Parent then return end
    
    local bobTime = billboardGui:GetAttribute("bobTime") or 0
    bobTime = bobTime + deltaTime
    billboardGui:SetAttribute("bobTime", bobTime)
    
    local bobOffset = math.sin(bobTime * BOB_SPEED * math.pi * 2) * BOB_AMOUNT
    
    local head = billboardGui.Parent
    if head and head.Parent then
        billboardGui.StudsOffset = Vector3.new(0, NAMETAG_HEIGHT + bobOffset, 0)
    end
end

local function onPlayerAdded(player)
    local function onCharacterAdded(character)
        wait(0.5)
        
        if tick() - lastCacheTime >= CACHE_REFRESH_INTERVAL then
            nametagCache = fetchFromGitHub()
            lastCacheTime = tick()
        end
        
        local tagData = getPlayerTagData(player.Name)
        createNametag(character, player.Name, tagData)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

RunService.RenderStepped:Connect(function(deltaTime)
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local billboardGui = head:FindFirstChild("NametagHolder")
                if billboardGui then
                    updateAnimation(billboardGui, deltaTime)
                end
            end
        end
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if tick() - lastCacheTime >= CACHE_REFRESH_INTERVAL then
        nametagCache = fetchFromGitHub()
        lastCacheTime = tick()
    end
end)

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

nametagCache = fetchFromGitHub()
lastCacheTime = tick()
