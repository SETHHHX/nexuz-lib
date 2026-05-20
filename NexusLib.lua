-- ============================================================
--  NexusLib v1.0  —  UI Library para Roblox Executors
--  Estilo: ventana flotante con tabs, secciones y componentes
--  Uso: local Nexus = loadstring(readfile("NexusLib.lua"))()
-- ============================================================

local Nexus = {}
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local Players         = game:GetService("Players")
local LocalPlayer     = Players.LocalPlayer

-- ─── TEMA ───────────────────────────────────────────────────
local Theme = {
    Background   = Color3.fromRGB(13, 14, 18),
    Surface      = Color3.fromRGB(20, 22, 30),
    Card         = Color3.fromRGB(26, 29, 38),
    Border       = Color3.fromRGB(42, 45, 56),
    Accent       = Color3.fromRGB(124, 106, 247),
    AccentDark   = Color3.fromRGB(80, 65, 180),
    AccentGlow   = Color3.fromRGB(100, 85, 220),
    Text         = Color3.fromRGB(232, 234, 240),
    TextMuted    = Color3.fromRGB(107, 114, 128),
    TextDim      = Color3.fromRGB(60, 65, 80),
    Success      = Color3.fromRGB(78, 205, 196),
    Warning      = Color3.fromRGB(247, 167, 108),
    Danger       = Color3.fromRGB(240, 108, 108),
    White        = Color3.fromRGB(255, 255, 255),
    TabActive    = Color3.fromRGB(124, 106, 247),
    TabInactive  = Color3.fromRGB(26, 29, 38),
}

-- ─── UTILIDADES ─────────────────────────────────────────────
local function tween(obj, info, props)
    TweenService:Create(obj, info, props):Play()
end

local function makeTI(t, style, dir)
    return TweenInfo.new(t, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
end

local function newInstance(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

local function addCorner(parent, radius)
    return newInstance("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function addStroke(parent, color, thickness)
    return newInstance("UIStroke", {
        Color     = color or Theme.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function addPadding(parent, top, bottom, left, right)
    return newInstance("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft   = UDim.new(0, left   or 10),
        PaddingRight  = UDim.new(0, right  or 10),
    }, parent)
end

local function addListLayout(parent, padding, dir)
    return newInstance("UIListLayout", {
        Padding         = UDim.new(0, padding or 6),
        FillDirection   = dir or Enum.FillDirection.Vertical,
        SortOrder       = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, parent)
end

-- ─── DRAG ───────────────────────────────────────────────────
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            tween(frame, makeTI(0.1, Enum.EasingStyle.Linear), { Position = newPos })
        end
    end)
end

-- ════════════════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════════════════
function Nexus:CreateWindow(config)
    config = config or {}

    local win = {
        _tabs     = {},
        _activeTab = nil,
        Title     = config.Title    or "NexusLib",
        Subtitle  = config.Subtitle or "v1.0",
    }

    -- ── ScreenGui
    local screenGui = newInstance("ScreenGui", {
        Name            = "NexusLib_" .. tostring(math.random(1000,9999)),
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn    = false,
    })

    -- Intentar usar CoreGui (executors), fallback a PlayerGui
    pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)
    if not screenGui.Parent then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- ── Main Frame
    local mainFrame = newInstance("Frame", {
        Name            = "MainFrame",
        Size            = UDim2.new(0, 540, 0, 380),
        Position        = UDim2.new(0.5, -270, 0.5, -190),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, screenGui)
    addCorner(mainFrame, 12)
    addStroke(mainFrame, Theme.Border, 1)

    -- Sombra exterior (frame más grande detrás)
    local shadow = newInstance("Frame", {
        Name            = "Shadow",
        Size            = UDim2.new(1, 20, 1, 20),
        Position        = UDim2.new(0, -10, 0, -10),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ZIndex          = mainFrame.ZIndex - 1,
    }, mainFrame)
    addCorner(shadow, 16)

    -- Entrada animada
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    tween(mainFrame, makeTI(0.4, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 540, 0, 380),
        BackgroundTransparency = 0,
    })

    -- ── Topbar
    local topbar = newInstance("Frame", {
        Name            = "Topbar",
        Size            = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
    }, mainFrame)
    addCorner(topbar, 12)
    -- Cubrir esquinas inferiores del topbar
    newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
    }, topbar)

    -- Acento de línea en topbar
    newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, topbar)

    -- Dot decorativo
    local dot = newInstance("Frame", {
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 14, 0.5, -4),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, topbar)
    addCorner(dot, 4)

    -- Título
    newInstance("TextLabel", {
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        BackgroundTransparency = 1,
        Text = win.Title,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, topbar)

    -- Subtítulo
    newInstance("TextLabel", {
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 30, 0, 18),
        BackgroundTransparency = 1,
        Text = win.Subtitle,
        TextColor3 = Theme.TextMuted,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, topbar)

    -- Botón cerrar
    local closeBtn = newInstance("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -38, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(240, 108, 108),
        Text = "✕",
        TextColor3 = Theme.White,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        BorderSizePixel = 0,
    }, topbar)
    addCorner(closeBtn, 6)

    closeBtn.MouseButton1Click:Connect(function()
        tween(mainFrame, makeTI(0.3, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
        })
        task.delay(0.35, function() screenGui:Destroy() end)
    end)

    -- Minimizar
    local minBtn = newInstance("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -72, 0.5, -14),
        BackgroundColor3 = Theme.Warning,
        Text = "─",
        TextColor3 = Theme.White,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        BorderSizePixel = 0,
    }, topbar)
    addCorner(minBtn, 6)

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        tween(mainFrame, makeTI(0.3, Enum.EasingStyle.Quart), {
            Size = minimized
                and UDim2.new(0, 540, 0, 52)
                or  UDim2.new(0, 540, 0, 380),
        })
    end)

    makeDraggable(mainFrame, topbar)

    -- ── Tab bar
    local tabBar = newInstance("Frame", {
        Name = "TabBar",
        Size = UDim2.new(0, 130, 1, -52),
        Position = UDim2.new(0, 0, 0, 52),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
    }, mainFrame)

    addListLayout(tabBar, 4, Enum.FillDirection.Vertical)
    addPadding(tabBar, 10, 10, 8, 8)

    -- Separador vertical
    newInstance("Frame", {
        Size = UDim2.new(0, 1, 1, -52),
        Position = UDim2.new(0, 130, 0, 52),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
    }, mainFrame)

    -- ── Content area
    local contentArea = newInstance("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -131, 1, -52),
        Position = UDim2.new(0, 131, 0, 52),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, mainFrame)

    -- ════ TAB API ════
    function win:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tab = {
            _sections = {},
            Name      = tabConfig.Name or "Tab",
            Icon      = tabConfig.Icon or "☰",
        }

        -- Botón en sidebar
        local tabBtn = newInstance("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Theme.TabInactive,
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
        }, tabBar)
        addCorner(tabBtn, 7)

        local tabIcon = newInstance("TextLabel", {
            Size = UDim2.new(0, 22, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = tab.Icon,
            TextColor3 = Theme.TextMuted,
            Font = Enum.Font.Gotham,
            TextSize = 14,
        }, tabBtn)

        local tabLabel = newInstance("TextLabel", {
            Size = UDim2.new(1, -36, 1, 0),
            Position = UDim2.new(0, 34, 0, 0),
            BackgroundTransparency = 1,
            Text = tab.Name,
            TextColor3 = Theme.TextMuted,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, tabBtn)

        -- Indicador activo
        local activeBar = newInstance("Frame", {
            Size = UDim2.new(0, 3, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
        }, tabBtn)
        addCorner(activeBar, 2)

        -- Scroll frame para contenido del tab
        local tabPage = newInstance("ScrollingFrame", {
            Name = "Page_" .. tab.Name,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, contentArea)
        addListLayout(tabPage, 8)
        addPadding(tabPage, 10, 10, 10, 10)

        tab._page    = tabPage
        tab._btn     = tabBtn
        tab._bar     = activeBar
        tab._label   = tabLabel
        tab._icon    = tabIcon

        local function activate()
            -- Desactivar tab anterior
            if win._activeTab and win._activeTab ~= tab then
                local old = win._activeTab
                old._page.Visible = false
                tween(old._btn, makeTI(0.2), { BackgroundColor3 = Theme.TabInactive })
                tween(old._label, makeTI(0.2), { TextColor3 = Theme.TextMuted })
                tween(old._icon,  makeTI(0.2), { TextColor3 = Theme.TextMuted })
                tween(old._bar, makeTI(0.2), { BackgroundTransparency = 1 })
            end
            win._activeTab = tab
            tabPage.Visible = true
            tween(tabBtn, makeTI(0.25), { BackgroundColor3 = Theme.Card })
            tween(tabLabel, makeTI(0.2), { TextColor3 = Theme.Text })
            tween(tabIcon,  makeTI(0.2), { TextColor3 = Theme.Accent })
            tween(activeBar, makeTI(0.2), { BackgroundTransparency = 0 })
        end

        tabBtn.MouseButton1Click:Connect(activate)

        -- Hover
        tabBtn.MouseEnter:Connect(function()
            if win._activeTab ~= tab then
                tween(tabBtn, makeTI(0.15), { BackgroundColor3 = Color3.fromRGB(30, 33, 45) })
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if win._activeTab ~= tab then
                tween(tabBtn, makeTI(0.15), { BackgroundColor3 = Theme.TabInactive })
            end
        end)

        -- Activar si es el primero
        if #win._tabs == 0 then
            activate()
        end
        table.insert(win._tabs, tab)

        -- ════ SECTION API ════
        function tab:CreateSection(sectionConfig)
            sectionConfig = sectionConfig or {}
            local section = { _items = {} }

            local sectionFrame = newInstance("Frame", {
                Size = UDim2.new(1, -4, 0, 0),
                BackgroundColor3 = Theme.Card,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
            }, tabPage)
            addCorner(sectionFrame, 9)
            addStroke(sectionFrame, Theme.Border, 1)
            addPadding(sectionFrame, 10, 10, 12, 12)

            local sectionLayout = addListLayout(sectionFrame, 8)

            -- Título de sección
            if sectionConfig.Name then
                local sectionTitle = newInstance("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = sectionConfig.Name:upper(),
                    TextColor3 = Theme.TextMuted,
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = 0,
                }, sectionFrame)

                -- Línea bajo el título
                newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                    LayoutOrder = 1,
                }, sectionFrame)
            end

            section._frame = sectionFrame
            section._order = 10

            local function nextOrder()
                section._order = section._order + 1
                return section._order
            end

            -- ════════════════════════════
            --  TOGGLE
            -- ════════════════════════════
            function section:AddToggle(cfg)
                cfg = cfg or {}
                local state   = cfg.Default or false
                local callback = cfg.Callback or function() end

                local row = newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                }, sectionFrame)

                newInstance("TextLabel", {
                    Size = UDim2.new(1, -60, 1, 0),
                    BackgroundTransparency = 1,
                    Text = cfg.Name or "Toggle",
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, row)

                if cfg.Description then
                    row.Size = UDim2.new(1, 0, 0, 48)
                    newInstance("TextLabel", {
                        Size = UDim2.new(1, -60, 0, 14),
                        Position = UDim2.new(0, 0, 0, 20),
                        BackgroundTransparency = 1,
                        Text = cfg.Description,
                        TextColor3 = Theme.TextMuted,
                        Font = Enum.Font.Gotham,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, row)
                end

                -- Track del toggle
                local track = newInstance("Frame", {
                    Size = UDim2.new(0, 44, 0, 24),
                    Position = UDim2.new(1, -44, 0.5, -12),
                    BackgroundColor3 = state and Theme.Accent or Theme.Border,
                    BorderSizePixel = 0,
                }, row)
                addCorner(track, 12)

                -- Thumb
                local thumb = newInstance("Frame", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = state
                        and UDim2.new(0, 23, 0.5, -9)
                        or  UDim2.new(0, 3,  0.5, -9),
                    BackgroundColor3 = Theme.White,
                    BorderSizePixel = 0,
                }, track)
                addCorner(thumb, 9)

                -- Glow del thumb
                local thumbGlow = newInstance("Frame", {
                    Size = UDim2.new(1, 8, 1, 8),
                    Position = UDim2.new(0, -4, 0, -4),
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 0.7,
                    BorderSizePixel = 0,
                    ZIndex = thumb.ZIndex - 1,
                    Visible = state,
                }, thumb)
                addCorner(thumbGlow, 13)

                local toggle = { Value = state }

                local function setToggle(newState, skipCallback)
                    toggle.Value = newState
                    tween(track, makeTI(0.25, Enum.EasingStyle.Quart), {
                        BackgroundColor3 = newState and Theme.Accent or Theme.Border,
                    })
                    tween(thumb, makeTI(0.3, Enum.EasingStyle.Back), {
                        Position = newState
                            and UDim2.new(0, 23, 0.5, -9)
                            or  UDim2.new(0, 3,  0.5, -9),
                    })
                    thumbGlow.Visible = newState
                    if not skipCallback then
                        pcall(callback, newState)
                    end
                end

                -- Clickable area
                local btn = newInstance("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                }, row)

                btn.MouseButton1Click:Connect(function()
                    setToggle(not toggle.Value)
                end)

                -- Hover glow en row
                btn.MouseEnter:Connect(function()
                    tween(row, makeTI(0.15), { BackgroundColor3 = Color3.fromRGB(30,33,45) })
                    row.BackgroundTransparency = 0.5
                end)
                btn.MouseLeave:Connect(function()
                    row.BackgroundTransparency = 1
                end)

                function toggle:Set(v, skip)
                    setToggle(v, skip)
                end

                return toggle
            end

            -- ════════════════════════════
            --  BUTTON
            -- ════════════════════════════
            function section:AddButton(cfg)
                cfg = cfg or {}
                local callback = cfg.Callback or function() end

                local btn = newInstance("TextButton", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Theme.Accent,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    LayoutOrder = nextOrder(),
                }, sectionFrame)
                addCorner(btn, 7)

                newInstance("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = cfg.Name or "Button",
                    TextColor3 = Theme.White,
                    Font = Enum.Font.GothamBold,
                    TextSize = 13,
                }, btn)

                btn.MouseButton1Click:Connect(function()
                    tween(btn, makeTI(0.08, Enum.EasingStyle.Linear), { Size = UDim2.new(1, -6, 0, 30) })
                    task.delay(0.08, function()
                        tween(btn, makeTI(0.2, Enum.EasingStyle.Back), { Size = UDim2.new(1, 0, 0, 34) })
                    end)
                    pcall(callback)
                end)

                btn.MouseEnter:Connect(function()
                    tween(btn, makeTI(0.2), { BackgroundColor3 = Theme.AccentGlow })
                end)
                btn.MouseLeave:Connect(function()
                    tween(btn, makeTI(0.2), { BackgroundColor3 = Theme.Accent })
                end)

                local button = {}
                function button:SetText(t) end
                return button
            end

            -- ════════════════════════════
            --  SLIDER
            -- ════════════════════════════
            function section:AddSlider(cfg)
                cfg = cfg or {}
                local min      = cfg.Min      or 0
                local max      = cfg.Max      or 100
                local default  = cfg.Default  or min
                local callback = cfg.Callback or function() end
                local suffix   = cfg.Suffix   or ""

                local current = math.clamp(default, min, max)

                local wrap = newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 54),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                }, sectionFrame)

                local topRow = newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                }, wrap)

                newInstance("TextLabel", {
                    Size = UDim2.new(0.7, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = cfg.Name or "Slider",
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, topRow)

                local valLabel = newInstance("TextLabel", {
                    Size = UDim2.new(0.3, 0, 1, 0),
                    Position = UDim2.new(0.7, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(current) .. suffix,
                    TextColor3 = Theme.Accent,
                    Font = Enum.Font.GothamBold,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right,
                }, topRow)

                -- Track
                local track = newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 30),
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                }, wrap)
                addCorner(track, 3)

                -- Fill
                local pct = (current - min) / (max - min)
                local fill = newInstance("Frame", {
                    Size = UDim2.new(pct, 0, 1, 0),
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                }, track)
                addCorner(fill, 3)

                -- Thumb
                local thumb = newInstance("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(pct, -8, 0.5, -8),
                    BackgroundColor3 = Theme.White,
                    BorderSizePixel = 0,
                    ZIndex = fill.ZIndex + 1,
                }, track)
                addCorner(thumb, 8)

                -- Hitbox invisible sobre el track
                local hitbox = newInstance("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    Position = UDim2.new(0, 0, 0.5, -15),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = thumb.ZIndex + 1,
                }, track)

                local slider = { Value = current }
                local dragging = false

                local function updateSlider(inputX)
                    local rel   = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    local val   = math.floor(min + rel * (max - min) + 0.5)
                    slider.Value = val
                    valLabel.Text = tostring(val) .. suffix
                    tween(fill,  makeTI(0.05, Enum.EasingStyle.Linear), { Size = UDim2.new(rel, 0, 1, 0) })
                    tween(thumb, makeTI(0.05, Enum.EasingStyle.Linear), { Position = UDim2.new(rel, -8, 0.5, -8) })
                    pcall(callback, val)
                end

                hitbox.MouseButton1Down:Connect(function(x) dragging = true; updateSlider(x) end)
                hitbox.MouseButton1Up:Connect(function() dragging = false end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(input.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                function slider:Set(v)
                    local rel = math.clamp((v - min) / (max - min), 0, 1)
                    slider.Value = math.clamp(v, min, max)
                    valLabel.Text = tostring(slider.Value) .. suffix
                    tween(fill, makeTI(0.15), { Size = UDim2.new(rel, 0, 1, 0) })
                    tween(thumb, makeTI(0.15), { Position = UDim2.new(rel, -8, 0.5, -8) })
                end

                return slider
            end

            -- ════════════════════════════
            --  DROPDOWN
            -- ════════════════════════════
            function section:AddDropdown(cfg)
                cfg = cfg or {}
                local options  = cfg.Options  or {}
                local callback = cfg.Callback or function() end
                local selected = cfg.Default  or options[1] or "Seleccionar"

                local wrap = newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                    ClipsDescendants = false,
                }, sectionFrame)

                newInstance("TextLabel", {
                    Size = UDim2.new(0.45, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = cfg.Name or "Dropdown",
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, wrap)

                local ddBtn = newInstance("TextButton", {
                    Size = UDim2.new(0.52, 0, 0, 28),
                    Position = UDim2.new(0.48, 0, 0.5, -14),
                    BackgroundColor3 = Theme.Surface,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                }, wrap)
                addCorner(ddBtn, 6)
                addStroke(ddBtn, Theme.Border, 1)

                local selLabel = newInstance("TextLabel", {
                    Size = UDim2.new(1, -30, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = selected,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, ddBtn)

                newInstance("TextLabel", {
                    Size = UDim2.new(0, 20, 1, 0),
                    Position = UDim2.new(1, -24, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "▾",
                    TextColor3 = Theme.TextMuted,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                }, ddBtn)

                -- Menu flotante
                local menu = newInstance("Frame", {
                    Size = UDim2.new(0.52, 0, 0, 0),
                    Position = UDim2.new(0.48, 0, 1, 4),
                    BackgroundColor3 = Theme.Surface,
                    BorderSizePixel = 0,
                    ZIndex = 10,
                    ClipsDescendants = true,
                    Visible = false,
                }, wrap)
                addCorner(menu, 7)
                addStroke(menu, Theme.Border, 1)
                addListLayout(menu, 2)
                addPadding(menu, 4, 4, 4, 4)

                local targetH = #options * 30 + 8
                local isOpen  = false
                local dropdown = { Value = selected }

                for _, opt in ipairs(options) do
                    local item = newInstance("TextButton", {
                        Size = UDim2.new(1, 0, 0, 26),
                        BackgroundColor3 = Theme.Surface,
                        Text = opt,
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Gotham,
                        TextSize = 12,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        ZIndex = 11,
                    }, menu)
                    addCorner(item, 5)

                    item.MouseEnter:Connect(function()
                        tween(item, makeTI(0.15), { BackgroundColor3 = Theme.Card })
                    end)
                    item.MouseLeave:Connect(function()
                        tween(item, makeTI(0.15), { BackgroundColor3 = Theme.Surface })
                    end)

                    item.MouseButton1Click:Connect(function()
                        dropdown.Value = opt
                        selLabel.Text  = opt
                        isOpen = false
                        menu.Visible = false
                        tween(menu, makeTI(0.2, Enum.EasingStyle.Quart), { Size = UDim2.new(0.52, 0, 0, 0) })
                        pcall(callback, opt)
                    end)
                end

                ddBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    menu.Visible = true
                    tween(menu, makeTI(0.25, Enum.EasingStyle.Back), {
                        Size = isOpen
                            and UDim2.new(0.52, 0, 0, targetH)
                            or  UDim2.new(0.52, 0, 0, 0),
                    })
                    if not isOpen then
                        task.delay(0.25, function() menu.Visible = false end)
                    end
                end)

                function dropdown:Set(v)
                    dropdown.Value = v
                    selLabel.Text  = v
                end

                return dropdown
            end

            -- ════════════════════════════
            --  INPUT (TextBox)
            -- ════════════════════════════
            function section:AddInput(cfg)
                cfg = cfg or {}
                local callback = cfg.Callback or function() end

                local wrap = newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                }, sectionFrame)

                newInstance("TextLabel", {
                    Size = UDim2.new(0.4, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = cfg.Name or "Input",
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, wrap)

                local box = newInstance("TextBox", {
                    Size = UDim2.new(0.57, 0, 0, 28),
                    Position = UDim2.new(0.43, 0, 0.5, -14),
                    BackgroundColor3 = Theme.Surface,
                    PlaceholderText = cfg.Placeholder or "Escribir...",
                    PlaceholderColor3 = Theme.TextMuted,
                    Text = cfg.Default or "",
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    BorderSizePixel = 0,
                    ClearTextOnFocus = false,
                }, wrap)
                addCorner(box, 6)
                addPadding(box, 0, 0, 8, 8)

                local stroke = addStroke(box, Theme.Border, 1)

                box.Focused:Connect(function()
                    tween(stroke, makeTI(0.2), { Color = Theme.Accent })
                end)
                box.FocusLost:Connect(function(entered)
                    tween(stroke, makeTI(0.2), { Color = Theme.Border })
                    if entered then pcall(callback, box.Text) end
                end)

                local input = { Value = box.Text }

                function input:Set(v)
                    box.Text    = v
                    input.Value = v
                end

                function input:Get()
                    return box.Text
                end

                return input
            end

            -- ════════════════════════════
            --  LABEL
            -- ════════════════════════════
            function section:AddLabel(cfg)
                cfg = cfg or {}
                local lbl = newInstance("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = cfg.Text or "",
                    TextColor3 = cfg.Color or Theme.TextMuted,
                    Font = Enum.Font.Gotham,
                    TextSize = cfg.Size or 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = nextOrder(),
                }, sectionFrame)

                local label = {}
                function label:Set(t) lbl.Text = t end
                return label
            end

            -- ════════════════════════════
            --  DIVIDER
            -- ════════════════════════════
            function section:AddDivider()
                newInstance("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                    LayoutOrder = nextOrder(),
                }, sectionFrame)
            end

            table.insert(tab._sections, section)
            return section
        end

        return tab
    end

    -- Notificación
    function win:Notify(cfg)
        cfg = cfg or {}
        local notif = newInstance("Frame", {
            Size = UDim2.new(0, 240, 0, 60),
            Position = UDim2.new(1, 260, 1, -70),
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
        }, screenGui)
        addCorner(notif, 10)
        addStroke(notif, Theme.Accent, 1)

        newInstance("Frame", {
            Size = UDim2.new(0, 3, 0.7, 0),
            Position = UDim2.new(0, 8, 0.15, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
        }, notif)

        newInstance("TextLabel", {
            Size = UDim2.new(1, -24, 0, 22),
            Position = UDim2.new(0, 20, 0, 8),
            BackgroundTransparency = 1,
            Text = cfg.Title or "Notificación",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, notif)

        newInstance("TextLabel", {
            Size = UDim2.new(1, -24, 0, 18),
            Position = UDim2.new(0, 20, 0, 30),
            BackgroundTransparency = 1,
            Text = cfg.Content or "",
            TextColor3 = Theme.TextMuted,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, notif)

        tween(notif, makeTI(0.4, Enum.EasingStyle.Back), {
            Position = UDim2.new(1, -256, 1, -70),
        })
        task.delay(cfg.Duration or 3, function()
            tween(notif, makeTI(0.3), { Position = UDim2.new(1, 260, 1, -70) })
            task.delay(0.35, function() notif:Destroy() end)
        end)
    end

    function win:Destroy()
        screenGui:Destroy()
    end

    return win
end

return Nexus
