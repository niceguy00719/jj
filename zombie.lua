--[[
    Coreix Hub • Zombie Edition (zombie.lua)
    - Powered by WindUI
    - Native WindUI minimize support for PC & Mobile
    - Minimizes via [-] topbar button or [RightShift] / [Keybind]
    - When minimized, WindUI's native OpenButton appears
    - Features: Session stats, Head Hitbox Expander & Visualizer, Player Mods (Infinite Jump, Instant Use Proximity Prompts), Infinite Yield Anti-AFK, Fullbright/Map visibility, Server tools
]]

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))
local Lighting = cloneref(game:GetService("Lighting"))
local Workspace = cloneref(game:GetService("Workspace"))
local ProximityPromptService = cloneref(game:GetService("ProximityPromptService"))

local LocalPlayer = Players.LocalPlayer

-- Clean up any previous custom logo if it existed
pcall(function()
    local CoreGui = cloneref(game:GetService("CoreGui"))
    for _, child in ipairs(CoreGui:GetChildren()) do
        if child.Name:match("^WindUI_FloatingLogo_") then
            child:Destroy()
        end
    end
end)

-- Detect Place / Game Name
local gameTitle = "Zombie Survival"
pcall(function()
    local productInfo = MarketplaceService:GetProductInfo(game.PlaceId)
    if productInfo and productInfo.Name then
        gameTitle = productInfo.Name
    end
end)

-- ========================================================
-- 1. Load WindUI Library
-- ========================================================
local WindUI
do
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()
    end)
    if success and result then
        WindUI = result
    else
        WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end
end

-- ========================================================
-- 2. Create WindUI Window with Native OpenButton & Topbar
-- ========================================================
local Window = WindUI:CreateWindow({
    Title = "Coreix Hub • Zombie",
    Author = "by Footagesus • WindUI",
    Folder = "CoreixHub_Zombie",
    Icon = "solar:danger-triangle-bold",
    NewElements = true,
    HideSearchBar = false,
    ToggleKey = Enum.KeyCode.RightShift,

    -- Native WindUI OpenButton configuration
    OpenButton = {
        Title = "Open Coreix Zombie Hub",
        Icon = "solar:danger-triangle-bold",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.9,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("#FF4B4B")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("#7775F2")),
        }),
    },

    Topbar = {
        Height = 44,
        ButtonsType = "Default",
    },
})

-- ========================================================
-- 3. PC Fix for WindUI Native OpenButton
-- ========================================================
pcall(function()
    Window.IsPC = false
end)

Window:OnClose(function()
    task.spawn(function()
        task.wait(0.42)
        if Window.Closed and Window.OpenButtonMain and Window.IsOpenButtonEnabled ~= false then
            pcall(function()
                Window.OpenButtonMain:Visible(true)
            end)
        end
    end)
end)

Window:OnOpen(function()
    pcall(function()
        if Window.OpenButtonMain then
            Window.OpenButtonMain:Visible(false)
        end
    end)
end)

-- Dedicated Hotkey fallback for PC (RightShift toggle)
local currentToggleKey = Enum.KeyCode.RightShift
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == currentToggleKey then
        pcall(function()
            Window:Toggle()
        end)
    end
end)

-- Topbar Tags
Window:Tag({
    Title = "Zombie Edition",
    Icon = "solar:skull-bold",
    Color = Color3.fromHex("#221b1b"),
    Border = true,
})

Window:Tag({
    Title = gameTitle,
    Icon = "solar:gamepad-minimalistic-bold",
    Color = Color3.fromHex("#FF4B4B"),
    Border = false,
})

-- ========================================================
-- 4. Sections & Tabs (Clean UI Layout)
-- ========================================================
local MainSection = Window:Section({
    Title = "Main Navigation",
    Opened = true,
})

local Tabs = {
    Info = MainSection:Tab({
        Title = "Info",
        Icon = "solar:info-circle-bold",
    }),
    Main = MainSection:Tab({
        Title = "Main",
        Icon = "solar:target-bold",
    }),
    ESP = MainSection:Tab({
        Title = "ESP",
        Icon = "solar:eye-bold",
    }),
    Player = MainSection:Tab({
        Title = "Player",
        Icon = "solar:user-bold",
    }),
    Misc = MainSection:Tab({
        Title = "Miscellaneous",
        Icon = "solar:widget-2-bold",
    }),
    Settings = Window:Section({ Title = "System", Opened = true }):Tab({
        Title = "Settings",
        Icon = "solar:settings-minimalistic-bold",
    }),
}

-- --------------------------------------------------------
-- Tab: Info (Session & Player Stats)
-- --------------------------------------------------------
local InfoSection = Tabs.Info:Section({ Title = "Session Overview", Opened = true })

local fpsParagraph = InfoSection:Paragraph({
    Title = "Performance",
    Desc = "FPS: Calculating... | Ping: Calculating...",
    Image = "solar:speedometer-bold",
    ImageSize = 20,
})

-- Live FPS & Ping tracker
task.spawn(function()
    local frameCount = 0
    local lastTime = tick()
    local currentFps = 60

    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 1 then
            currentFps = frameCount
            frameCount = 0
            lastTime = now

            local ping = 0
            pcall(function()
                local statsService = cloneref(game:GetService("Stats"))
                local network = statsService:FindFirstChild("Network")
                if network and network:FindFirstChild("ServerStatsItem") then
                    ping = math.floor(network.ServerStatsItem["Data Ping"]:GetValue())
                end
            end)

            pcall(function()
                fpsParagraph:SetDesc(string.format("FPS: %d  •  Ping: %d ms  •  Players: %d", currentFps, ping, #Players:GetPlayers()))
            end)
        end
    end)
end)

-- Server Time Tracker (Time spent in server)
local sessionJoinTick = tick()
local serverTimeParagraph = InfoSection:Paragraph({
    Title = "Time in Server",
    Desc = "Calculating stay time...",
    Image = "solar:clock-circle-bold",
    ImageSize = 20,
})

task.spawn(function()
    while true do
        local elapsed = math.floor(tick() - sessionJoinTick)
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = elapsed % 60

        local formattedTime
        if hours > 0 then
            formattedTime = string.format("%dh %dm %ds  (%02d:%02d:%02d)", hours, minutes, seconds, hours, minutes, seconds)
        elseif minutes > 0 then
            formattedTime = string.format("%dm %ds  (%02d:%02d)", minutes, seconds, minutes, seconds)
        else
            formattedTime = string.format("%ds  (00:%02d)", seconds, seconds)
        end

        pcall(function()
            serverTimeParagraph:SetDesc(formattedTime)
        end)
        task.wait(1)
    end
end)

InfoSection:Paragraph({
    Title = "Player Information",
    Desc = string.format("User: %s (@%s)\nUserId: %d", LocalPlayer.DisplayName, LocalPlayer.Name, LocalPlayer.UserId),
    Image = "solar:user-bold",
    ImageSize = 20,
})

pcall(function()
    if InfoSection.Open then
        InfoSection:Open()
    end
end)

-- --------------------------------------------------------
-- Tab: Main (Head Hitbox Expander & Hitbox Size)
-- --------------------------------------------------------
local MainTabSection = Tabs.Main:Section({ Title = "Hitbox Expander & Visualizer", Opened = true })

local hitboxStatsParagraph = MainTabSection:Paragraph({
    Title = "Hitbox Status",
    Desc = "Head Hitbox Expander: Disabled  •  Size: 10 studs",
    Image = "solar:box-minimalistic-bold",
    ImageSize = 20,
})

local isHitboxExpanderActive = false
local currentHitboxSize = 10
local originalHeadAttributes = {}

-- Utility to identify if an instance belongs to an actual player
local function isPlayerCharacter(charModel)
    if not charModel or not charModel:IsA("Model") then
        return true
    end
    if charModel == LocalPlayer.Character then
        return true
    end
    -- Check if username exists directly in Players service (e.g. workspace.Characters.Sweet_snow54)
    if Players:FindFirstChild(charModel.Name) then
        return true
    end
    -- Check via Player reference
    if Players:GetPlayerFromCharacter(charModel) then
        return true
    end
    -- Check against all player usernames and display names
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == charModel or player.Name == charModel.Name or player.DisplayName == charModel.Name then
            return true
        end
    end
    return false
end

-- Get non-player entity models from workspace.Characters
local function getNonPlayerCharacters()
    local entityList = {}
    local charactersContainer = Workspace:FindFirstChild("Characters")
    if charactersContainer then
        for _, child in ipairs(charactersContainer:GetChildren()) do
            if child:IsA("Model") and not isPlayerCharacter(child) then
                table.insert(entityList, child)
            end
        end
    else
        -- Fallback: check workspace directly if Characters folder does not exist
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Model") and child:FindFirstChild("Head") and child:FindFirstChildOfClass("Humanoid") and not isPlayerCharacter(child) then
                table.insert(entityList, child)
            end
        end
    end
    return entityList
end
-- Turn off / disable hitbox expander for a single entity (restores head to normal & removes visualizer/fake head)
local function disableHitboxForEntity(entity)
    if not entity then return end
    pcall(function()
        local fakeHead = entity:FindFirstChild("FakeVisualHead")
        if fakeHead then
            fakeHead:Destroy()
        end

        local head = entity:FindFirstChild("Head")
        if head then
            local edgeBox = head:FindFirstChild("HitboxEdgeVisualizer")
            if edgeBox then
                edgeBox:Destroy()
            end
            local oldBox = head:FindFirstChild("HitboxVisualizer")
            if oldBox then
                oldBox:Destroy()
            end

            local original = originalHeadAttributes[head]
            if original then
                head.Size = original.Size
                head.Transparency = original.Transparency
                head.CanCollide = original.CanCollide
                head.Massless = original.Massless
                if original.Decals then
                    for decal, trans in pairs(original.Decals) do
                        if decal and decal.Parent == head then
                            decal.Transparency = trans
                        end
                    end
                end
                originalHeadAttributes[head] = nil
            end
        end
    end)
end

-- Apply functional hitbox expansion with edge-only wireframe visualizer (no big visible head)
local function applyHeadHitbox(charModel)
    if not isHitboxExpanderActive then return end
    if isPlayerCharacter(charModel) then return end

    local humanoid = charModel:FindFirstChildOfClass("Humanoid") or charModel:FindFirstChild("Humanoid")

    -- If entity has NO Humanoid inside, or its health is <= 0: turn off hitbox extender for them (never delete/destroy the model)
    if not humanoid or humanoid.Health <= 0 then
        disableHitboxForEntity(charModel)
        return
    end

    local head = charModel:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return end

    -- Hook health and status listeners so if health reaches 0 or humanoid is removed, turn off extender for this entity
    if humanoid and not charModel:FindFirstChild("CoreixDeathCleanup") then
        local marker = Instance.new("BoolValue")
        marker.Name = "CoreixDeathCleanup"
        marker.Parent = charModel

        local function checkHealthAndStatus()
            if not humanoid or humanoid.Health <= 0 then
                disableHitboxForEntity(charModel)
            end
        end

        humanoid:GetPropertyChangedSignal("Health"):Connect(checkHealthAndStatus)
        humanoid.Died:Connect(checkHealthAndStatus)
        humanoid.AncestryChanged:Connect(function(_, parent)
            if not parent then
                disableHitboxForEntity(charModel)
            end
        end)
        charModel.ChildRemoved:Connect(function(child)
            if child == humanoid then
                disableHitboxForEntity(charModel)
            end
        end)
    end

    -- Cache original head properties before modifying
    if not originalHeadAttributes[head] then
        local decalMap = {}
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("Decal") then
                decalMap[child] = child.Transparency
            end
        end

        originalHeadAttributes[head] = {
            Size = head.Size,
            Transparency = head.Transparency,
            CanCollide = head.CanCollide,
            Massless = head.Massless,
            Decals = decalMap,
        }
    end

    local original = originalHeadAttributes[head]
    local targetSize = Vector3.new(currentHitboxSize, currentHitboxSize, currentHitboxSize)

    pcall(function()
        -- 1. Create client-side visual dummy head at normal original size
        -- This ensures the zombie's head visually looks normal and NOT big
        local fakeHead = charModel:FindFirstChild("FakeVisualHead")
        if not fakeHead then
            fakeHead = Instance.new("Part")
            fakeHead.Name = "FakeVisualHead"
            fakeHead.Size = original.Size
            fakeHead.CFrame = head.CFrame
            fakeHead.Color = head.Color
            fakeHead.Material = head.Material
            fakeHead.Transparency = original.Transparency
            fakeHead.CanCollide = false
            fakeHead.CanQuery = false -- Weapons ignore this dummy and hit the expanded physical head
            fakeHead.CanTouch = false
            fakeHead.Massless = true

            local mesh = head:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                local cloneMesh = mesh:Clone()
                cloneMesh.Parent = fakeHead
            end

            for _, child in ipairs(head:GetChildren()) do
                if child:IsA("Decal") then
                    local cloneDecal = child:Clone()
                    cloneDecal.Transparency = original.Decals[child] or 0
                    cloneDecal.Parent = fakeHead
                end
            end

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = fakeHead
            weld.Part1 = head
            weld.Parent = fakeHead

            fakeHead.Parent = charModel
        end

        -- 2. Expand the actual physical Head for weapon hit registration & make it invisible
        if head.Size ~= targetSize then
            head.Size = targetSize
        end
        head.Transparency = 1 -- Hide the expanded physical part completely
        head.CanCollide = false -- Keep collision off so NPCs move smoothly
        head.CanQuery = true -- Allow weapon raycasts and bullet detection to register hits
        head.CanTouch = true
        head.Massless = true

        -- Hide original decals on the enlarged head so they don't stretch
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("Decal") then
                child.Transparency = 1
            end
        end

        -- Clean up any legacy solid BoxHandleAdornment
        local oldBox = head:FindFirstChild("HitboxVisualizer")
        if oldBox then
            oldBox:Destroy()
        end

        -- 3. Edge-only wireframe visualizer: SelectionBox with SurfaceTransparency = 1
        -- This draws ONLY the 12 bounding box edges (wireframe outline) and NO cube faces
        local edgeBox = head:FindFirstChild("HitboxEdgeVisualizer")
        if not edgeBox or not edgeBox:IsA("SelectionBox") then
            if edgeBox then edgeBox:Destroy() end
            edgeBox = Instance.new("SelectionBox")
            edgeBox.Name = "HitboxEdgeVisualizer"
            edgeBox.Parent = head
        end
        edgeBox.Adornee = head
        edgeBox.Color3 = Color3.fromRGB(255, 30, 30)
        edgeBox.LineThickness = 0.1 -- Made edge bit thick for clearer visibility
        edgeBox.SurfaceTransparency = 1 -- Critical: 100% transparent faces, ONLY edges are shown!
        edgeBox.AlwaysOnTop = true
    end)
end

-- Restore all modified heads to original dimensions, restore visuals, and remove edge boxes
local function restoreAllHitboxes()
    for head, original in pairs(originalHeadAttributes) do
        pcall(function()
            if head and head.Parent then
                head.Size = original.Size
                head.Transparency = original.Transparency
                head.CanCollide = original.CanCollide
                head.Massless = original.Massless

                if original.Decals then
                    for decal, trans in pairs(original.Decals) do
                        if decal and decal.Parent == head then
                            decal.Transparency = trans
                        end
                    end
                end

                local edgeBox = head:FindFirstChild("HitboxEdgeVisualizer")
                if edgeBox then
                    edgeBox:Destroy()
                end

                local oldBox = head:FindFirstChild("HitboxVisualizer")
                if oldBox then
                    oldBox:Destroy()
                end

                local charModel = head.Parent
                if charModel then
                    local fakeHead = charModel:FindFirstChild("FakeVisualHead")
                    if fakeHead then
                        fakeHead:Destroy()
                    end
                end
            end
        end)
    end
    table.clear(originalHeadAttributes)

    -- Sweep all non-player characters to remove visualizers and fake heads
    pcall(function()
        local entities = getNonPlayerCharacters()
        for _, entity in ipairs(entities) do
            disableHitboxForEntity(entity)
        end
    end)
end

-- If any children in workspace.Characters do NOT have a Humanoid (or health <= 0), turn off extender for them
local function syncHitboxEligibility()
    local charactersContainer = Workspace:FindFirstChild("Characters")
    if charactersContainer then
        for _, child in ipairs(charactersContainer:GetChildren()) do
            if child:IsA("Model") and not isPlayerCharacter(child) then
                local hum = child:FindFirstChildOfClass("Humanoid") or child:FindFirstChild("Humanoid")
                if not hum or hum.Health <= 0 then
                    disableHitboxForEntity(child)
                end
            end
        end
    end
end

-- Update all non-player characters in workspace.Characters
local function updateAllHitboxes()
    syncHitboxEligibility()
    if not isHitboxExpanderActive then return end
    local entities = getNonPlayerCharacters()
    for _, entity in ipairs(entities) do
        local hum = entity:FindFirstChildOfClass("Humanoid") or entity:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            disableHitboxForEntity(entity)
        else
            applyHeadHitbox(entity)
        end
    end
    -- Clean up dead entities from attribute cache
    for head in pairs(originalHeadAttributes) do
        if not head or not head.Parent then
            originalHeadAttributes[head] = nil
        end
    end
end

-- Continuous background sync loop for newly spawned mobs/zombies
task.spawn(function()
    while true do
        pcall(function()
            syncHitboxEligibility()
            if isHitboxExpanderActive then
                updateAllHitboxes()
            end
        end)
        task.wait(0.5)
    end
end)

-- Workspace listener for instant detection when new entities spawn
pcall(function()
    local charFolder = Workspace:FindFirstChild("Characters")
    if charFolder then
        charFolder.ChildAdded:Connect(function(child)
            if isHitboxExpanderActive then
                task.wait(0.1)
                applyHeadHitbox(child)
            end
        end)
    end
    Workspace.ChildAdded:Connect(function(child)
        if child.Name == "Characters" then
            child.ChildAdded:Connect(function(entity)
                if isHitboxExpanderActive then
                    task.wait(0.1)
                    applyHeadHitbox(entity)
                end
            end)
        end
    end)
end)

-- Slider: Hitbox size (3 to 20) placed ABOVE the toggle
MainTabSection:Slider({
    Title = "Hitbox Size",
    Desc = "Adjust the size of the wireframe edge box around the head (3 to 20 studs)",
    Step = 1,
    Value = {
        Min = 3,
        Max = 20,
        Default = 10,
    },
    Callback = function(value)
        currentHitboxSize = value
        pcall(function()
            hitboxStatsParagraph:SetDesc(string.format("Head Hitbox Expander: %s  •  Size: %d studs", isHitboxExpanderActive and "Enabled" or "Disabled", currentHitboxSize))
        end)
        if isHitboxExpanderActive then
            updateAllHitboxes()
        end
    end,
})

-- Feature Toggle: Head Hitbox Expander
MainTabSection:Toggle({
    Title = "Head Hitbox Expander",
    Desc = "Expands head hit detection with a wireframe edge box without enlarging the visible head",
    Value = false,
    Callback = function(state)
        isHitboxExpanderActive = state
        pcall(function()
            hitboxStatsParagraph:SetDesc(string.format("Head Hitbox Expander: %s  •  Size: %d studs", isHitboxExpanderActive and "Enabled" or "Disabled", currentHitboxSize))
        end)
        if state then
            updateAllHitboxes()
            WindUI:Notify({
                Title = "Hitbox Expander Enabled",
                Content = string.format("Hitbox expanded to %d studs with wireframe edges.", currentHitboxSize),
                Icon = "solar:box-minimalistic-bold",
                Duration = 2.5,
            })
        else
            restoreAllHitboxes()
            WindUI:Notify({
                Title = "Hitbox Expander Disabled",
                Content = "Restored head hitboxes and removed wireframe edges.",
                Icon = "solar:shield-cross-bold",
                Duration = 2.5,
            })
        end
    end,
})

-- Force Refresh Button
MainTabSection:Button({
    Title = "Refresh Hitboxes Now",
    Desc = "Forces an immediate update across all workspace.Characters entities",
    Icon = "solar:refresh-bold",
    Callback = function()
        if isHitboxExpanderActive then
            updateAllHitboxes()
            WindUI:Notify({
                Title = "Hitboxes Refreshed",
                Content = "Updated wireframe edge boxes for all detected NPC characters.",
                Duration = 2,
            })
        else
            WindUI:Notify({
                Title = "Expander Not Active",
                Content = "Turn on Head Hitbox Expander toggle first.",
                Duration = 2,
            })
        end
    end,
})

pcall(function()
    if MainTabSection.Open then
        MainTabSection:Open()
    end
end)

-- --------------------------------------------------------
-- Tab: ESP (Fuel ESP Section)
-- --------------------------------------------------------
local FuelESPSection = Tabs.ESP:Section({ Title = "Fuel ESP", Opened = true })

local isFuelEspActive = false
local selectedFuels = {
    ["Fuel"] = true,
    ["Refined Fuel"] = true,
    ["Nuclear Fuel"] = true,
}

local function updateSelectedFuels(options)
    if type(options) == "table" then
        selectedFuels["Fuel"] = false
        selectedFuels["Refined Fuel"] = false
        selectedFuels["Nuclear Fuel"] = false

        for key, val in pairs(options) do
            local itemStr = ""
            if type(val) == "string" then
                itemStr = val
            elseif type(val) == "table" and (val.Title or val.Name) then
                itemStr = val.Title or val.Name
            elseif type(val) == "boolean" and val == true then
                itemStr = tostring(key)
            else
                itemStr = tostring(val)
            end

            if string.find(itemStr, "Nuclear") then
                selectedFuels["Nuclear Fuel"] = true
            elseif string.find(itemStr, "Refined") then
                selectedFuels["Refined Fuel"] = true
            elseif string.find(itemStr, "Fuel") then
                selectedFuels["Fuel"] = true
            end
        end
    elseif type(options) == "string" then
        selectedFuels["Fuel"] = (string.find(options, "Fuel") ~= nil and string.find(options, "Refined") == nil and string.find(options, "Nuclear") == nil)
        selectedFuels["Refined Fuel"] = string.find(options, "Refined") ~= nil
        selectedFuels["Nuclear Fuel"] = string.find(options, "Nuclear") ~= nil
    end

    -- Safety check: ensure at least one fuel remains active
    if not selectedFuels["Fuel"] and not selectedFuels["Refined Fuel"] and not selectedFuels["Nuclear Fuel"] then
        selectedFuels["Fuel"] = true
        selectedFuels["Refined Fuel"] = true
        selectedFuels["Nuclear Fuel"] = true
    end
end

-- Identify dropped fuel types in workspace.DroppedItems
local function getFuelType(item)
    if not item then return nil end
    local name = string.lower(item.Name or "")

    -- Direct name check
    if string.find(name, "nuclear") then
        return "Nuclear Fuel"
    elseif string.find(name, "refined") then
        return "Refined Fuel"
    elseif string.find(name, "fuel") or string.find(name, "gas") or string.find(name, "canister") then
        return "Fuel"
    end

    -- Check attributes if set by game
    local attr = item:GetAttribute("ItemName") or item:GetAttribute("Type") or item:GetAttribute("Name")
    if attr then
        local attrLower = string.lower(tostring(attr))
        if string.find(attrLower, "nuclear") then
            return "Nuclear Fuel"
        elseif string.find(attrLower, "refined") then
            return "Refined Fuel"
        elseif string.find(attrLower, "fuel") or string.find(attrLower, "gas") then
            return "Fuel"
        end
    end

    -- Check child value objects
    local valObj = item:FindFirstChild("ItemName") or item:FindFirstChild("Type")
    if valObj and valObj:IsA("ValueBase") then
        local valLower = string.lower(tostring(valObj.Value))
        if string.find(valLower, "nuclear") then
            return "Nuclear Fuel"
        elseif string.find(valLower, "refined") then
            return "Refined Fuel"
        elseif string.find(valLower, "fuel") then
            return "Fuel"
        end
    end

    return nil
end

local function isCurrentFuelSelected(fuelType)
    return selectedFuels[fuelType] == true
end

-- Apply high-visibility Chams highlight & Billboard tag with distinct colors
local function applyFuelHighlight(item, fuelType)
    local fuelColor = (fuelType == "Nuclear Fuel" and Color3.fromRGB(50, 255, 75))
        or (fuelType == "Refined Fuel" and Color3.fromRGB(45, 140, 255))
        or Color3.fromRGB(255, 45, 45)

    -- Highlight (through walls)
    local hl = item:FindFirstChild("CoreixFuelHighlight")
    if not hl or not hl:IsA("Highlight") then
        if hl then hl:Destroy() end
        hl = Instance.new("Highlight")
        hl.Name = "CoreixFuelHighlight"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0
        hl.Adornee = item
        hl.Parent = item
    end
    hl.FillColor = fuelColor

    -- Billboard text label with fuel name
    local adorneePart = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
    if adorneePart then
        local tag = item:FindFirstChild("CoreixFuelTag")
        if not tag or not tag:IsA("BillboardGui") then
            if tag then tag:Destroy() end
            tag = Instance.new("BillboardGui")
            tag.Name = "CoreixFuelTag"
            tag.Adornee = adorneePart
            tag.Size = UDim2.new(0, 130, 0, 30)
            tag.StudsOffset = Vector3.new(0, 1.8, 0)
            tag.AlwaysOnTop = true
            tag.MaxDistance = 1500

            local lbl = Instance.new("TextLabel")
            lbl.Name = "FuelLabel"
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextStrokeTransparency = 0.2
            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 12
            lbl.Parent = tag

            tag.Parent = item
        end

        local lbl = tag:FindFirstChild("FuelLabel")
        if lbl then
            lbl.TextColor3 = fuelColor
            lbl.Text = "[" .. fuelType .. "]"
        end
    end
end

-- Remove highlight and tag from an item
local function removeFuelHighlight(item)
    local hl = item:FindFirstChild("CoreixFuelHighlight")
    if hl then hl:Destroy() end
    local tag = item:FindFirstChild("CoreixFuelTag")
    if tag then tag:Destroy() end
end

-- Cleanup all highlights from dropped items
local function cleanupAllFuelEsp()
    local dropped = Workspace:FindFirstChild("DroppedItems")
    if dropped then
        for _, item in ipairs(dropped:GetChildren()) do
            removeFuelHighlight(item)
        end
    end
end

-- Update all items currently inside workspace.DroppedItems
local function updateAllFuelEsp()
    local dropped = Workspace:FindFirstChild("DroppedItems")
    if not dropped then return end

    if not isFuelEspActive then
        cleanupAllFuelEsp()
        return
    end

    for _, item in ipairs(dropped:GetChildren()) do
        local fuelType = getFuelType(item)
        if fuelType then
            if isCurrentFuelSelected(fuelType) then
                applyFuelHighlight(item, fuelType)
            else
                removeFuelHighlight(item)
            end
        end
    end
end

-- Listener for newly dropped fuel items in workspace.DroppedItems
pcall(function()
    local dropped = Workspace:FindFirstChild("DroppedItems")
    if dropped then
        dropped.ChildAdded:Connect(function(child)
            if isFuelEspActive then
                task.wait(0.1)
                local fuelType = getFuelType(child)
                if fuelType and isCurrentFuelSelected(fuelType) then
                    applyFuelHighlight(child, fuelType)
                end
            end
        end)
    end
    Workspace.ChildAdded:Connect(function(child)
        if child.Name == "DroppedItems" then
            child.ChildAdded:Connect(function(item)
                if isFuelEspActive then
                    task.wait(0.1)
                    local fuelType = getFuelType(item)
                    if fuelType and isCurrentFuelSelected(fuelType) then
                        applyFuelHighlight(item, fuelType)
                    end
                end
            end)
        end
    end)
end)

-- Background periodic refresh for dropped fuel items
task.spawn(function()
    while true do
        if isFuelEspActive then
            pcall(function()
                updateAllFuelEsp()
            end)
        end
        task.wait(1.5)
    end
end)

-- Switch / Toggle: FUEL ESP (Like Head Hitbox Expander switch)
FuelESPSection:Toggle({
    Title = "FUEL ESP",
    Desc = "Highlights dropped fuel items across workspace.DroppedItems",
    Value = false,
    Callback = function(state)
        isFuelEspActive = state
        if state then
            updateAllFuelEsp()
            local activeNames = {}
            if selectedFuels["Fuel"] then table.insert(activeNames, "Fuel") end
            if selectedFuels["Refined Fuel"] then table.insert(activeNames, "Refined") end
            if selectedFuels["Nuclear Fuel"] then table.insert(activeNames, "Nuclear") end

            WindUI:Notify({
                Title = "FUEL ESP Enabled",
                Content = "Tracking: " .. table.concat(activeNames, ", "),
                Icon = "solar:eye-bold",
                Duration = 2.5,
            })
        else
            cleanupAllFuelEsp()
            WindUI:Notify({
                Title = "FUEL ESP Disabled",
                Content = "All fuel highlights turned off.",
                Icon = "solar:eye-closed-bold",
                Duration = 2.5,
            })
        end
    end,
})

-- Extender Dropdown: Select Fuel (Select all of them or at least one)
FuelESPSection:Dropdown({
    Title = "Select Fuel",
    Desc = "Extender menu: select all fuels or pick specific types",
    Values = {
        "Fuel [Red]",
        "Refined Fuel [Blue]",
        "Nuclear Fuel [Green]",
    },
    Value = {
        "Fuel [Red]",
        "Refined Fuel [Blue]",
        "Nuclear Fuel [Green]",
    },
    AllowNone = false,
    Multi = true,
    Callback = function(selectedOptions)
        updateSelectedFuels(selectedOptions)
        if isFuelEspActive then
            updateAllFuelEsp()
        end
        local activeNames = {}
        if selectedFuels["Fuel"] then table.insert(activeNames, "Fuel") end
        if selectedFuels["Refined Fuel"] then table.insert(activeNames, "Refined") end
        if selectedFuels["Nuclear Fuel"] then table.insert(activeNames, "Nuclear") end

        WindUI:Notify({
            Title = "Fuel Selection Updated",
            Content = "Active: " .. table.concat(activeNames, ", "),
            Icon = "solar:check-circle-bold",
            Duration = 2,
        })
    end,
})

pcall(function()
    if FuelESPSection.Open then
        FuelESPSection:Open()
    end
end)

-- --------------------------------------------------------
-- Tab: Player (Movement & Interaction Mods)
-- --------------------------------------------------------
local PlayerTabSection = Tabs.Player:Section({ Title = "Movement & Interaction", Opened = true })

local playerStatusParagraph = PlayerTabSection:Paragraph({
    Title = "Player Status",
    Desc = "Infinite Jump: Disabled  •  Instant Use: Disabled",
    Image = "solar:user-bold",
    ImageSize = 20,
})

local isInfJumpActive = false
local isInstantUseActive = false

local function updatePlayerStatus()
    pcall(function()
        playerStatusParagraph:SetDesc(string.format(
            "Infinite Jump: %s  •  Instant Use: %s",
            isInfJumpActive and "Enabled" or "Disabled",
            isInstantUseActive and "Enabled" or "Disabled"
        ))
    end)
end

-- --------------------------------------------------------
-- Infinite Jump (infjump / uninfjump from inf.lua)
-- --------------------------------------------------------
local infJumpConn = nil
local infJumpDebounce = false

local function enableInfJump()
    if infJumpConn then
        infJumpConn:Disconnect()
        infJumpConn = nil
    end
    infJumpDebounce = false
    infJumpConn = UserInputService.JumpRequest:Connect(function()
        if not infJumpDebounce then
            infJumpDebounce = true
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
            task.wait()
            infJumpDebounce = false
        end
    end)
end

local function disableInfJump()
    if infJumpConn then
        infJumpConn:Disconnect()
        infJumpConn = nil
    end
    infJumpDebounce = false
end

-- --------------------------------------------------------
-- Instant Use (instantpp / uninstantpp from inf.lua)
-- --------------------------------------------------------
local PromptButtonHoldBegan = nil
local promptHoldCache = {}
local promptAddedConn = nil

local function enableInstantUse()
    -- Disconnect previous if any (uninstantpp)
    if PromptButtonHoldBegan ~= nil then
        PromptButtonHoldBegan:Disconnect()
        PromptButtonHoldBegan = nil
    end
    if promptAddedConn ~= nil then
        promptAddedConn:Disconnect()
        promptAddedConn = nil
    end

    if fireproximityprompt then
        task.wait(0.1)
        PromptButtonHoldBegan = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
            pcall(function()
                fireproximityprompt(prompt)
            end)
        end)
    else
        -- Fallback HoldDuration bypass if fireproximityprompt is missing
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                if promptHoldCache[prompt] == nil then
                    promptHoldCache[prompt] = prompt.HoldDuration
                end
                prompt.HoldDuration = 0
            end
        end
        promptAddedConn = Workspace.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("ProximityPrompt") then
                if promptHoldCache[descendant] == nil then
                    promptHoldCache[descendant] = descendant.HoldDuration
                end
                descendant.HoldDuration = 0
            end
        end)
    end
end

local function disableInstantUse()
    -- Exactly uninstantpp from inf.lua
    if PromptButtonHoldBegan ~= nil then
        PromptButtonHoldBegan:Disconnect()
        PromptButtonHoldBegan = nil
    end
    if promptAddedConn ~= nil then
        promptAddedConn:Disconnect()
        promptAddedConn = nil
    end
    for prompt, originalDuration in pairs(promptHoldCache) do
        pcall(function()
            if prompt and prompt.Parent then
                prompt.HoldDuration = originalDuration
            end
        end)
    end
    table.clear(promptHoldCache)
end

-- Toggle: Infinite Jump
PlayerTabSection:Toggle({
    Title = "Infinite Jump",
    Desc = "Allows you to jump continuously mid-air before hitting the ground (inf jump)",
    Value = false,
    Callback = function(state)
        isInfJumpActive = state
        updatePlayerStatus()
        if state then
            enableInfJump()
            WindUI:Notify({
                Title = "Infinite Jump Enabled",
                Content = "You can now jump continuously in mid-air.",
                Icon = "solar:running-round-bold",
                Duration = 2.5,
            })
        else
            disableInfJump()
            WindUI:Notify({
                Title = "Infinite Jump Disabled",
                Content = "Restored normal jumping behavior.",
                Icon = "solar:shield-cross-bold",
                Duration = 2,
            })
        end
    end,
})

-- Toggle: Instant Use (instantpp / uninstantpp)
PlayerTabSection:Toggle({
    Title = "Instant Use",
    Desc = "Instantly trigger Proximity Prompts with 0 hold time (instantpp / uninstantpp)",
    Value = false,
    Callback = function(state)
        isInstantUseActive = state
        updatePlayerStatus()
        if state then
            enableInstantUse()
            WindUI:Notify({
                Title = "Instant Use Enabled",
                Content = fireproximityprompt and "Instant Proximity Prompts active via fireproximityprompt (inf.lua instantpp)." or "Instant Proximity Prompts active via HoldDuration bypass.",
                Icon = "solar:bolt-bold",
                Duration = 2.5,
            })
        else
            disableInstantUse()
            WindUI:Notify({
                Title = "Instant Use Disabled",
                Content = "Proximity Prompts restored to normal hold times (inf.lua uninstantpp).",
                Icon = "solar:shield-cross-bold",
                Duration = 2,
            })
        end
    end,
})

pcall(function()
    if PlayerTabSection.Open then
        PlayerTabSection:Open()
    end
end)

-- --------------------------------------------------------
-- Tab: Miscellaneous (Anti-AFK & Server Utilities)
-- --------------------------------------------------------
local MiscSection = Tabs.Misc:Section({ Title = "Utilities", Opened = true })

-- Anti-AFK (Infinite Yield Method)
local antiAfkConn = nil
local isAntiAfkActive = false

local function enableAntiAfk(notifyUser)
    if isAntiAfkActive and antiAfkConn then
        if notifyUser then
            WindUI:Notify({
                Title = "Anti-AFK",
                Content = "Infinite Yield Anti-AFK is already active!",
                Icon = "solar:shield-check-bold",
                Duration = 2.5,
            })
        end
        return
    end

    isAntiAfkActive = true

    -- Infinite Yield Method: Disconnect/Disable existing Idled connections
    local GC = getconnections or get_signal_cons
    if GC then
        pcall(function()
            for _, conn in pairs(GC(LocalPlayer.Idled)) do
                if conn["Disable"] then
                    conn["Disable"](conn)
                elseif conn["Disconnect"] then
                    conn["Disconnect"](conn)
                end
            end
        end)
    end

    -- Hook Idled event with VirtualUser simulation
    local VirtualUser = cloneref(game:GetService("VirtualUser"))
    antiAfkConn = LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)

    if notifyUser then
        WindUI:Notify({
            Title = "Anti-AFK Enabled",
            Content = "Infinite Yield Anti-AFK activated! Prevents 20-min idle disconnect.",
            Icon = "solar:shield-check-bold",
            Duration = 3,
        })
    end
end

local function disableAntiAfk(notifyUser)
    if antiAfkConn then
        pcall(function() antiAfkConn:Disconnect() end)
        antiAfkConn = nil
    end
    isAntiAfkActive = false

    if notifyUser then
        WindUI:Notify({
            Title = "Anti-AFK Disabled",
            Content = "Anti-AFK has been turned off.",
            Icon = "solar:shield-cross-bold",
            Duration = 2.5,
        })
    end
end

local antiAfkToggleRef = nil

antiAfkToggleRef = MiscSection:Toggle({
    Title = "Anti-AFK",
    Desc = "Prevents 20-minute idle kick (Infinite Yield method)",
    Value = false,
    Callback = function(state)
        if state then
            enableAntiAfk(true)
        else
            disableAntiAfk(true)
        end
    end,
})

MiscSection:Button({
    Title = "Activate Anti-AFK",
    Desc = "One-click activation for Infinite Yield anti-idle bypass",
    Icon = "solar:shield-check-bold",
    Callback = function()
        enableAntiAfk(true)
        pcall(function()
            if antiAfkToggleRef and antiAfkToggleRef.Set then
                antiAfkToggleRef:Set(true)
            end
        end)
    end,
})

-- Fullbright / Night Visibility for dark zombie maps
local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalFogEnd = Lighting.FogEnd
local originalGlobalShadows = Lighting.GlobalShadows
local isFullbrightActive = false

MiscSection:Toggle({
    Title = "Fullbright / Clear Night Vision",
    Desc = "Increases map brightness and removes thick fog in dark zombie survival maps",
    Value = false,
    Callback = function(state)
        isFullbrightActive = state
        pcall(function()
            if state then
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
            else
                Lighting.Brightness = originalBrightness
                Lighting.ClockTime = originalClockTime
                Lighting.FogEnd = originalFogEnd
                Lighting.GlobalShadows = originalGlobalShadows
            end
        end)
    end,
})

MiscSection:Button({
    Title = "Rejoin Current Server",
    Desc = "Teleports you back into this server",
    Icon = "solar:refresh-bold",
    Callback = function()
        local TeleportService = cloneref(game:GetService("TeleportService"))
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("\nRejoining...")
            task.wait()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end,
})

MiscSection:Button({
    Title = "Server Hop",
    Desc = "Find and join a different server instance",
    Icon = "solar:transfer-horizontal-bold",
    Callback = function()
        WindUI:Notify({
            Title = "Server Hop",
            Content = "Searching for an available server...",
            Duration = 3,
        })
        task.spawn(function()
            local HttpService = cloneref(game:GetService("HttpService"))
            local TeleportService = cloneref(game:GetService("TeleportService"))
            local requestFunc = request or http_request or (syn and syn.request) or (http and http.request)
            if not requestFunc then return end

            local success, res = pcall(function()
                return requestFunc({
                    Url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100", tostring(game.PlaceId)),
                    Method = "GET"
                })
            end)
            if success and res and res.Body then
                local data = HttpService:JSONDecode(res.Body)
                if data and data.data then
                    for _, srv in ipairs(data.data) do
                        if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                            break
                        end
                    end
                end
            end
        end)
    end,
})

pcall(function()
    if MiscSection.Open then
        MiscSection:Open()
    end
end)

-- --------------------------------------------------------
-- Tab: Settings
-- --------------------------------------------------------
local KeybindSection = Tabs.Settings:Section({ Title = "UI Keybinds & Window Controls", Opened = true })

KeybindSection:Keybind({
    Title = "Toggle UI Keybind",
    Desc = "Key to minimize / restore the window",
    Value = Enum.KeyCode.RightShift,
    Callback = function(key)
        currentToggleKey = key
        pcall(function()
            Window:SetToggleKey(key)
        end)
        WindUI:Notify({
            Title = "Keybind Changed",
            Content = "Toggle key set to: " .. tostring(key.Name),
            Duration = 2,
        })
    end,
})

KeybindSection:Button({
    Title = "Minimize Window",
    Desc = "Minimizes the window into WindUI's OpenButton",
    Icon = "solar:minimize-square-bold",
    Callback = function()
        Window:Close()
    end,
})

KeybindSection:Button({
    Title = "Unload / Destroy UI",
    Desc = "Completely remove the interface and OpenButton",
    Color = Color3.fromHex("#EF4F1D"),
    Icon = "solar:trash-bin-trash-bold",
    Callback = function()
        pcall(function() cleanupAllFuelEsp() end)
        pcall(function() restoreAllHitboxes() end)
        pcall(function() Window:Destroy() end)
    end,
})

pcall(function()
    if KeybindSection.Open then
        KeybindSection:Open()
    end
end)

pcall(function()
    Tabs.Main:Select()
end)

-- Welcome Notification
WindUI:Notify({
    Title = "Coreix Zombie Hub Loaded!",
    Content = "Click [-] to minimize to the native WindUI button, or press [RightShift].",
    Icon = "solar:check-circle-bold",
    Duration = 3.5,
})
