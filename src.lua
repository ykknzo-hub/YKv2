local ENDPOINT = "https://api.nullauth.pro/api/v1/loader/get"
local SCRIPT_ID = "1791987174792010685848594346"
local TITLE = "glacier"
local KEY_URL = nil

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local function getHwid()
	local ok, id = pcall(function()
		if gethwid then return gethwid() end
		return game:GetService("RbxAnalyticsService"):GetClientId()
	end)
	return ok and tostring(id) or "unknown"
end

local env = (getgenv and getgenv()) or _G
local httpRequest = request or http_request or (env and (env.request or env.http_request)) or (http and http.request)
assert(type(httpRequest) == "function", "[Null] No HTTP request function available.")

local okHui, hui = pcall(function() return gethui and gethui() end)
local parent = (okHui and hui) or game:GetService("CoreGui")
local gui = Instance.new("ScreenGui")
gui.Name = "Null"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

local function corner(inst, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = inst end

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 220)
frame.Position = UDim2.new(0.5, -160, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
frame.BorderSizePixel = 0
frame.Parent = gui
corner(frame, 14)
local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(40, 40, 46) stroke.Parent = frame

local heading = Instance.new("TextLabel")
heading.Size = UDim2.new(1, -40, 0, 24)
heading.Position = UDim2.fromOffset(20, 20)
heading.BackgroundTransparency = 1
heading.Font = Enum.Font.GothamBold
heading.TextSize = 18
heading.TextXAlignment = Enum.TextXAlignment.Left
heading.TextColor3 = Color3.fromRGB(244, 244, 245)
heading.Text = TITLE
heading.Parent = frame

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, -40, 0, 16)
sub.Position = UDim2.fromOffset(20, 44)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.Gotham
sub.TextSize = 12
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.TextColor3 = Color3.fromRGB(138, 138, 147)
sub.Text = "Enter your key to continue"
sub.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -40, 0, 40)
box.Position = UDim2.fromOffset(20, 78)
box.BackgroundColor3 = Color3.fromRGB(27, 27, 31)
box.BorderSizePixel = 0
box.Font = Enum.Font.Gotham
box.TextSize = 14
box.PlaceholderText = "Key"
box.PlaceholderColor3 = Color3.fromRGB(88, 88, 95)
box.Text = ""
box.ClearTextOnFocus = false
box.TextColor3 = Color3.fromRGB(244, 244, 245)
box.Parent = frame
corner(box, 10)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -40, 0, 16)
status.Position = UDim2.fromOffset(20, 124)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = Color3.fromRGB(138, 138, 147)
status.Text = ""
status.Parent = frame

local load = Instance.new("TextButton")
load.Size = UDim2.new(1, -40, 0, 38)
load.Position = UDim2.fromOffset(20, 150)
load.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
load.BorderSizePixel = 0
load.Font = Enum.Font.GothamBold
load.TextSize = 14
load.TextColor3 = Color3.fromRGB(9, 9, 11)
load.Text = "Load"
load.Parent = frame
corner(load, 10)

if KEY_URL then
	local getKeyBtn = Instance.new("TextButton")
	getKeyBtn.Size = UDim2.new(1, -40, 0, 20)
	getKeyBtn.Position = UDim2.fromOffset(20, 192)
	getKeyBtn.BackgroundTransparency = 1
	getKeyBtn.Font = Enum.Font.Gotham
	getKeyBtn.TextSize = 12
	getKeyBtn.TextColor3 = Color3.fromRGB(138, 138, 147)
	getKeyBtn.Text = "Get a key"
	getKeyBtn.Parent = frame
	getKeyBtn.MouseButton1Click:Connect(function()
		if setclipboard then setclipboard(KEY_URL) end
		status.Text = "Key link copied to clipboard."
	end)
end

local busy = false
load.MouseButton1Click:Connect(function()
	if busy then return end
	local key = box.Text:gsub("%s+", "")
	if key == "" then status.Text = "Enter a key." return end
	busy = true
	load.Text = "Checking..."
	status.Text = ""
	local ok, res = pcall(httpRequest, {
		Url = ENDPOINT,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode({ scriptId = SCRIPT_ID, key = key, hwid = getHwid() }),
	})
	busy = false
	load.Text = "Load"
	if not ok or not res then status.Text = "Request failed." return end
	local code = res.StatusCode or res.status_code or 0
	local body = res.Body or res.body or ""
	if code == 200 or code == 201 then
		local fn = loadstring(body)
		if not fn then status.Text = "Loader error." return end
		if pcall(fn) then gui:Destroy() else status.Text = "Script error." end
	else
		status.Text = tostring(body)
	end
end)
