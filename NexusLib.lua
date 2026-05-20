-- ══════════════════════════════════════════════════════════════
--  NexusLib v3.0  |  UI Library para Roblox Executors
--  Reescrita completa — sin spawn(), sin bugs de tab, sin Z-index
--  roto en dropdowns, sin coordenadas incorrectas en ripple.
-- ══════════════════════════════════════════════════════════════

local Nexus = {}
Nexus.__index = Nexus

-- ─── Servicios ─────────────────────────────────────────────────
local TS   = game:GetService("TweenService")
local UIS  = game:GetService("UserInputService")
local Run  = game:GetService("RunService")
local Deb  = game:GetService("Debris")
local Players = game:GetService("Players")
local LP   = Players.LocalPlayer

-- ─── Tema ──────────────────────────────────────────────────────
local T = {
    BG          = Color3.fromRGB(9,  10, 14),
    Surface     = Color3.fromRGB(15, 17, 23),
    Card        = Color3.fromRGB(21, 24, 33),
    CardHover   = Color3.fromRGB(27, 31, 43),
    Sidebar     = Color3.fromRGB(13, 15, 20),

    Accent      = Color3.fromRGB(99,  84, 216),
    AccentHi    = Color3.fromRGB(130,113, 255),
    AccentLo    = Color3.fromRGB(62,  51, 148),
    Cyan        = Color3.fromRGB(72, 195, 195),
    Pink        = Color3.fromRGB(210, 88, 168),

    Border      = Color3.fromRGB(34, 38, 54),
    BorderHi    = Color3.fromRGB(52, 58, 80),

    Text        = Color3.fromRGB(220, 224, 238),
    TextSub     = Color3.fromRGB(128, 138, 162),
    TextDim     = Color3.fromRGB(62,  70,  94),

    Green       = Color3.fromRGB(60, 190, 130),
    Yellow      = Color3.fromRGB(240, 170, 60),
    Red         = Color3.fromRGB(230, 80,  80),
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(0,   0,   0),
}

-- ─── Utilidades internas ────────────────────────────────────────

-- Tween simplificado
local function tw(obj, dur, props, style, dir)
    if not obj or not obj.Parent then return end
    TS:Create(obj,
        TweenInfo.new(dur, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

-- Crear Instance con propiedades
local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

-- Esquinas redondeadas
local function corner(p, r)
    return mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p)
end

-- Borde UIStroke
local function border(p, col, thick)
    return mk("UIStroke", {
        Color               = col or T.Border,
        Thickness           = thick or 1,
        ApplyStrokeMode     = Enum.ApplyStrokeMode.Border,
        Transparency        = 0,
    }, p)
end

-- Padding
local function pad(p, t, b, l, r)
    return mk("UIPadding", {
        PaddingTop    = UDim.new(0, t or 8),
        PaddingBottom = UDim.new(0, b or 8),
        PaddingLeft   = UDim.new(0, l or 10),
        PaddingRight  = UDim.new(0, r or 10),
    }, p)
end

-- Lista
local function layout(p, gap, dir, halign)
    return mk("UIListLayout", {
        Padding              = UDim.new(0, gap or 6),
        FillDirection        = dir or Enum.FillDirection.Vertical,
        SortOrder            = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment  = halign or Enum.HorizontalAlignment.Left,
    }, p)
end

-- Gradiente de 2 colores
local function grad(p, c0, c1, rot)
    return mk("UIGradient", {
        Color    = ColorSequence.new(c0, c1),
        Rotation = rot or 90,
    }, p)
end

-- Efecto ripple corregido (usa posición relativa real)
local function ripple(parent, inputObj)
    local abs = parent.AbsolutePosition
    local sz  = parent.AbsoluteSize
    local pos = UIS:GetMouseLocation()
    local rx   = math.clamp(pos.X - abs.X, 0, sz.X)
    local ry   = math.clamp(pos.Y - abs.Y, 0, sz.Y)

    local rip = mk("Frame", {
        Size                  = UDim2.new(0, 0, 0, 0),
        Position              = UDim2.new(0, rx, 0, ry),
        AnchorPoint           = Vector2.new(0.5, 0.5),
        BackgroundColor3      = T.White,
        BackgroundTransparency = 0.75,
        BorderSizePixel        = 0,
        ZIndex                 = parent.ZIndex + 10,
    }, parent)
    corner(rip, 100)

    local target = math.max(sz.X, sz.Y) * 2.2
    tw(rip, 0.55, {
        Size                   = UDim2.new(0, target, 0, target),
        Position               = UDim2.new(0, rx, 0, ry),
        BackgroundTransparency = 1,
    })
    Deb:AddItem(rip, 0.6)
end

-- ─── Drag robusto ──────────────────────────────────────────────
local function draggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart, frameStart

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging  = true
        dragStart = inp.Position
        frameStart = frame.Position
    end)

    UIS.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = inp.Position - dragStart
        frame.Position = UDim2.new(
            frameStart.X.Scale, frameStart.X.Offset + delta.X,
            frameStart.Y.Scale, frameStart.Y.Offset + delta.Y
        )
    end)

    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════════════════════════
function Nexus.new(cfg)
    cfg = cfg or {}

    local self = setmetatable({}, Nexus)
    self._tabs      = {}
    self._activeTab = nil

    -- ── ScreenGui
    local gui = mk("ScreenGui", {
        Name            = "NexusLib_v3",
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn    = false,
        IgnoreGuiInset  = true,
    })
    local ok = pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    if not ok or not gui.Parent then
        gui.Parent = LP:WaitForChild("PlayerGui")
    end

    -- ── Sombra
    local shadow = mk("Frame", {
        Size                   = UDim2.new(0, 590, 0, 430),
        Position               = UDim2.new(0.5, -295, 0.5, -215),
        BackgroundColor3       = T.Black,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
    }, gui)
    corner(shadow, 18)

    -- ── Ventana principal
    local main = mk("Frame", {
        Size                   = UDim2.new(0, 0, 0, 0),
        Position               = UDim2.new(0.5, -275, 0.5, -195),
        BackgroundColor3       = T.BG,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
    }, gui)
    corner(main, 14)
    border(main, T.BorderHi, 1)

    -- Animación de entrada
    tw(main, 0.5, {
        Size                   = UDim2.new(0, 550, 0, 390),
        BackgroundTransparency = 0,
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    tw(shadow, 0.5, { BackgroundTransparency = 0.5 }, Enum.EasingStyle.Quart)

    -- ── Topbar
    local topbar = mk("Frame", {
        Size             = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = T.Surface,
        BorderSizePixel  = 0,
    }, main)

    -- Línea degradada inferior del topbar
    local tline = mk("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
    }, topbar)
    grad(tline, T.Accent, T.Cyan, 0)

    -- Dot de estado con pulso (task.spawn en lugar de spawn)
    local dot = mk("Frame", {
        Size             = UDim2.new(0, 8, 0, 8),
        Position         = UDim2.new(0, 16, 0.5, -4),
        BackgroundColor3 = T.AccentHi,
        BorderSizePixel  = 0,
    }, topbar)
    corner(dot, 4)

    local dotRing = mk("Frame", {
        Size                   = UDim2.new(0, 18, 0, 18),
        Position               = UDim2.new(0, 11, 0.5, -9),
        BackgroundColor3       = T.Accent,
        BackgroundTransparency = 0.55,
        BorderSizePixel        = 0,
    }, topbar)
    corner(dotRing, 9)

    -- Pulso del dot usando task.spawn (correcto en executors modernos)
    task.spawn(function()
        while gui and gui.Parent do
            tw(dotRing, 0.85, {
                Size                   = UDim2.new(0, 24, 0, 24),
                Position               = UDim2.new(0, 8, 0.5, -12),
                BackgroundTransparency = 0.82,
            })
            task.wait(0.95)
            tw(dotRing, 0.85, {
                Size                   = UDim2.new(0, 18, 0, 18),
                Position               = UDim2.new(0, 11, 0.5, -9),
                BackgroundTransparency = 0.55,
            })
            task.wait(0.95)
        end
    end)

    -- Título y subtítulo
    mk("TextLabel", {
        Size               = UDim2.new(0, 200, 0, 22),
        Position           = UDim2.new(0, 34, 0, 7),
        BackgroundTransparency = 1,
        Text               = cfg.Title or "NexusLib",
        TextColor3         = T.Text,
        Font               = Enum.Font.GothamBold,
        TextSize           = 15,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }, topbar)

    mk("TextLabel", {
        Size               = UDim2.new(0, 200, 0, 14),
        Position           = UDim2.new(0, 34, 0, 30),
        BackgroundTransparency = 1,
        Text               = cfg.Subtitle or "v3.0",
        TextColor3         = T.TextDim,
        Font               = Enum.Font.Gotham,
        TextSize           = 10,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }, topbar)

    -- Botones de control (cerrar / minimizar)
    local function ctrlBtn(offsetX, col, lbl)
        local b = mk("TextButton", {
            Size             = UDim2.new(0, 24, 0, 24),
            Position         = UDim2.new(1, offsetX, 0.5, -12),
            BackgroundColor3 = col,
            Text             = lbl,
            TextColor3       = T.White,
            Font             = Enum.Font.GothamBold,
            TextSize         = 11,
            BorderSizePixel  = 0,
            AutoButtonColor  = false,
        }, topbar)
        corner(b, 6)
        b.MouseEnter:Connect(function()
            tw(b, 0.12, { BackgroundTransparency = 0.25 })
        end)
        b.MouseLeave:Connect(function()
            tw(b, 0.12, { BackgroundTransparency = 0 })
        end)
        return b
    end

    local btnClose = ctrlBtn(-34, T.Red,    "✕")
    local btnMin   = ctrlBtn(-66, T.Yellow, "—")

    btnClose.MouseButton1Click:Connect(function()
        tw(main,   0.3, { Size = UDim2.new(0, 550, 0, 0), BackgroundTransparency = 1 })
        tw(shadow, 0.3, { BackgroundTransparency = 1 })
        task.delay(0.35, function() gui:Destroy() end)
    end)

    local minimized = false
    btnMin.MouseButton1Click:Connect(function()
        minimized = not minimized
        tw(main, 0.35,
            { Size = minimized and UDim2.new(0, 550, 0, 52) or UDim2.new(0, 550, 0, 390) },
            Enum.EasingStyle.Back
        )
    end)

    draggable(main, topbar)

    -- ── Sidebar
    local sidebar = mk("Frame", {
        Size             = UDim2.new(0, 136, 1, -52),
        Position         = UDim2.new(0, 0, 0, 52),
        BackgroundColor3 = T.Sidebar,
        BorderSizePixel  = 0,
    }, main)

    -- Separador lateral
    mk("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = T.Border,
        BorderSizePixel  = 0,
    }, sidebar)

    local sideList = layout(sidebar, 2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)
    pad(sidebar, 8, 8, 6, 6)

    -- Branding en el sidebar
    mk("TextLabel", {
        Size               = UDim2.new(1, -8, 0, 18),
        Position           = UDim2.new(0, 4, 1, -24),
        BackgroundTransparency = 1,
        Text               = "NexusLib v3.0",
        TextColor3         = T.TextDim,
        Font               = Enum.Font.Gotham,
        TextSize           = 9,
        TextXAlignment     = Enum.TextXAlignment.Center,
        ZIndex             = 3,
    }, sidebar)

    -- ── Área de contenido
    local content = mk("ScrollingFrame", {
        Size                  = UDim2.new(1, -137, 1, -52),
        Position              = UDim2.new(0, 137, 0, 52),
        BackgroundColor3      = T.BG,
        BorderSizePixel       = 0,
        ScrollBarThickness    = 0,
        ScrollingEnabled      = false,
        ClipsDescendants      = false,
    }, main)

    self._gui     = gui
    self._main    = main
    self._shadow  = shadow
    self._sidebar = sidebar
    self._content = content

    return self
end

-- ══════════════════════════════════════════════════════════════
--  TAB
-- ══════════════════════════════════════════════════════════════
function Nexus:CreateTab(cfg)
    cfg = cfg or {}
    local tab = { _sections = {}, Name = cfg.Name or "Tab", Icon = cfg.Icon or "◈" }

    -- Botón en sidebar
    local tabBtn = mk("TextButton", {
        Size                   = UDim2.new(1, 0, 0, 34),
        BackgroundColor3       = T.Card,
        BackgroundTransparency = 1,
        Text                   = "",
        BorderSizePixel        = 0,
        AutoButtonColor        = false,
    }, self._sidebar)
    corner(tabBtn, 8)

    -- Indicador izquierdo
    local indicator = mk("Frame", {
        Size                   = UDim2.new(0, 3, 0, 18),
        Position               = UDim2.new(0, 2, 0.5, -9),
        BackgroundColor3       = T.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
    }, tabBtn)
    corner(indicator, 2)

    -- Fondo del tab activo
    local activeBg = mk("Frame", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundColor3       = T.Card,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = tabBtn.ZIndex - 1,
    }, tabBtn)
    corner(activeBg, 8)

    -- Icono
    local ico = mk("TextLabel", {
        Size               = UDim2.new(0, 22, 1, 0),
        Position           = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text               = tab.Icon,
        TextColor3         = T.TextDim,
        Font               = Enum.Font.Gotham,
        TextSize           = 14,
    }, tabBtn)

    -- Nombre
    local lbl = mk("TextLabel", {
        Size               = UDim2.new(1, -40, 1, 0),
        Position           = UDim2.new(0, 38, 0, 0),
        BackgroundTransparency = 1,
        Text               = tab.Name,
        TextColor3         = T.TextSub,
        Font               = Enum.Font.Gotham,
        TextSize           = 12,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }, tabBtn)

    -- Página
    local page = mk("ScrollingFrame", {
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        ScrollBarThickness    = 3,
        ScrollBarImageColor3  = T.Accent,
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        Visible               = false,
    }, self._content)
    layout(page, 10)
    pad(page, 12, 12, 12, 12)

    tab._page = page
    tab._btn  = tabBtn

    -- Activar tab
    local function activate()
        -- Desactivar anterior
        if self._activeTab and self._activeTab ~= tab then
            local prev = self._activeTab
            prev._page.Visible = false
            tw(prev._activeBg,  0.18, { BackgroundTransparency = 1 })
            tw(prev._indicator, 0.18, { BackgroundTransparency = 1 })
            tw(prev._ico,       0.18, { TextColor3 = T.TextDim })
            tw(prev._lbl,       0.18, { TextColor3 = T.TextSub })
            prev._lbl.Font = Enum.Font.Gotham
        end

        self._activeTab = tab
        page.Visible = true
        tw(activeBg,  0.22, { BackgroundTransparency = 0.45 })
        tw(indicator, 0.22, { BackgroundTransparency = 0 })
        tw(ico,       0.18, { TextColor3 = T.AccentHi })
        tw(lbl,       0.18, { TextColor3 = T.Text })
        lbl.Font = Enum.Font.GothamBold
    end

    -- Guardar referencias para desactivación limpia
    tab._activeBg  = activeBg
    tab._indicator = indicator
    tab._ico       = ico
    tab._lbl       = lbl

    tabBtn.MouseButton1Click:Connect(function()
        activate()
        ripple(tabBtn)
    end)

    tabBtn.MouseEnter:Connect(function()
        if self._activeTab ~= tab then
            tw(activeBg, 0.14, { BackgroundTransparency = 0.78 })
            tw(ico,      0.14, { TextColor3 = T.TextSub })
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if self._activeTab ~= tab then
            tw(activeBg, 0.14, { BackgroundTransparency = 1 })
            tw(ico,      0.14, { TextColor3 = T.TextDim })
        end
    end)

    -- Activar si es el primero
    if #self._tabs == 0 then activate() end
    table.insert(self._tabs, tab)

    -- ── SECTION ────────────────────────────────────────────────
    function tab:CreateSection(sCfg)
        sCfg = sCfg or {}
        local sec   = {}
        local order = 0

        local sFrame = mk("Frame", {
            Size            = UDim2.new(1, -4, 0, 0),
            BackgroundColor3 = T.Card,
            BorderSizePixel = 0,
            AutomaticSize   = Enum.AutomaticSize.Y,
        }, page)
        corner(sFrame, 10)
        border(sFrame, T.Border, 1)
        pad(sFrame, 12, 12, 14, 14)
        layout(sFrame, 8)

        local function nxt()
            order = order + 1
            return order
        end

        -- Encabezado de sección
        if sCfg.Name then
            local hdr = mk("Frame", {
                Size               = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                LayoutOrder        = 0,
            }, sFrame)

            mk("Frame", {
                Size             = UDim2.new(0, 3, 0, 14),
                Position         = UDim2.new(0, 0, 0.5, -7),
                BackgroundColor3 = T.Accent,
                BorderSizePixel  = 0,
            }, hdr):Parent = hdr
            corner(hdr:FindFirstChildOfClass("Frame"), 2)

            mk("TextLabel", {
                Size               = UDim2.new(1, -10, 1, 0),
                Position           = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text               = sCfg.Name:upper(),
                TextColor3         = T.TextSub,
                Font               = Enum.Font.GothamBold,
                TextSize           = 9,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, hdr)

            -- Separador decorativo
            local sep = mk("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = T.Border,
                BorderSizePixel  = 0,
                LayoutOrder      = 1,
            }, sFrame)
            grad(sep, T.Accent, T.Card, 0)
        end

        -- ── TOGGLE ──────────────────────────────────────────
        function sec:AddToggle(c)
            c = c or {}
            local state = c.Default or false
            local cb    = c.Callback or function() end

            local rowH = c.Description and 52 or 38
            local row = mk("Frame", {
                Size               = UDim2.new(1, 0, 0, rowH),
                BackgroundTransparency = 1,
                LayoutOrder        = nxt(),
            }, sFrame)

            local rowBg = mk("Frame", {
                Size                   = UDim2.new(1, 8, 1, 4),
                Position               = UDim2.new(0, -4, 0, -2),
                BackgroundColor3       = T.CardHover,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
            }, row)
            corner(rowBg, 8)

            mk("TextLabel", {
                Size               = UDim2.new(1, -60, 0, 18),
                Position           = UDim2.new(0, 0, 0, c.Description and 5 or 10),
                BackgroundTransparency = 1,
                Text               = c.Name or "Toggle",
                TextColor3         = T.Text,
                Font               = Enum.Font.GothamMedium,
                TextSize           = 13,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, row)

            if c.Description then
                mk("TextLabel", {
                    Size               = UDim2.new(1, -60, 0, 14),
                    Position           = UDim2.new(0, 0, 0, 25),
                    BackgroundTransparency = 1,
                    Text               = c.Description,
                    TextColor3         = T.TextDim,
                    Font               = Enum.Font.Gotham,
                    TextSize           = 11,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                }, row)
            end

            -- Track
            local track = mk("Frame", {
                Size             = UDim2.new(0, 44, 0, 24),
                Position         = UDim2.new(1, -44, 0.5, -12),
                BackgroundColor3 = state and T.Accent or T.Surface,
                BorderSizePixel  = 0,
            }, row)
            corner(track, 12)
            local trackBorder = border(track, state and T.AccentHi or T.Border, 1)

            local trackGrad = mk("UIGradient", {
                Color   = ColorSequence.new(T.Accent, T.Cyan),
                Rotation = 0,
                Enabled  = state,
            }, track)

            -- Thumb
            local thumb = mk("Frame", {
                Size             = UDim2.new(0, 18, 0, 18),
                Position         = state and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
                BackgroundColor3 = T.White,
                BorderSizePixel  = 0,
            }, track)
            corner(thumb, 9)

            local tog = { Value = state }

            local function setToggle(v, silent)
                tog.Value      = v
                trackGrad.Enabled = v
                tw(track, 0.25, { BackgroundColor3 = v and T.Accent or T.Surface })
                tw(thumb, 0.28, {
                    Position = v and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                }, Enum.EasingStyle.Back)
                trackBorder.Color = v and T.AccentHi or T.Border
                if not silent then pcall(cb, v) end
            end

            local clickZone = mk("TextButton", {
                Size               = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text               = "",
                ZIndex             = row.ZIndex + 2,
            }, row)

            clickZone.MouseButton1Click:Connect(function()
                setToggle(not tog.Value)
            end)
            clickZone.MouseEnter:Connect(function()
                tw(rowBg, 0.14, { BackgroundTransparency = 0.62 })
            end)
            clickZone.MouseLeave:Connect(function()
                tw(rowBg, 0.14, { BackgroundTransparency = 1 })
            end)

            function tog:Set(v, silent) setToggle(v, silent) end
            return tog
        end

        -- ── BUTTON ──────────────────────────────────────────
        function sec:AddButton(c)
            c  = c or {}
            local cb = c.Callback or function() end

            local wrap = mk("Frame", {
                Size               = UDim2.new(1, 0, 0, 34),
                BackgroundTransparency = 1,
                LayoutOrder        = nxt(),
            }, sFrame)

            local btn = mk("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = T.Accent,
                Text             = c.Name or "Botón",
                TextColor3       = T.White,
                Font             = Enum.Font.GothamBold,
                TextSize         = 13,
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
            }, wrap)
            corner(btn, 8)
            border(btn, T.AccentHi, 1)
            grad(btn, T.Accent, T.AccentLo, 135)

            btn.MouseButton1Click:Connect(function()
                ripple(btn)
                tw(btn, 0.08, { Size = UDim2.new(0.97, 0, 0.88, 0), Position = UDim2.new(0.015, 0, 0.06, 0) })
                task.delay(0.08, function()
                    tw(btn, 0.22, {
                        Size     = UDim2.new(1, 0, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                    }, Enum.EasingStyle.Back)
                end)
                pcall(cb)
            end)
            btn.MouseEnter:Connect(function()
                tw(btn, 0.16, { BackgroundColor3 = T.AccentHi })
            end)
            btn.MouseLeave:Connect(function()
                tw(btn, 0.16, { BackgroundColor3 = T.Accent })
            end)

            local b = {}
            function b:SetText(t) btn.Text = t end
            function b:SetCallback(fn) cb = fn end
            return b
        end

        -- ── SLIDER ──────────────────────────────────────────
        function sec:AddSlider(c)
            c = c or {}
            local sMin  = c.Min     or 0
            local sMax  = c.Max     or 100
            local def   = math.clamp(c.Default or sMin, sMin, sMax)
            local cb    = c.Callback or function() end
            local suf   = c.Suffix  or ""

            local wrap = mk("Frame", {
                Size               = UDim2.new(1, 0, 0, 54),
                BackgroundTransparency = 1,
                LayoutOrder        = nxt(),
            }, sFrame)

            mk("TextLabel", {
                Size               = UDim2.new(0.6, 0, 0, 18),
                BackgroundTransparency = 1,
                Text               = c.Name or "Slider",
                TextColor3         = T.Text,
                Font               = Enum.Font.GothamMedium,
                TextSize           = 13,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, wrap)

            local valLbl = mk("TextLabel", {
                Size               = UDim2.new(0.4, 0, 0, 18),
                Position           = UDim2.new(0.6, 0, 0, 0),
                BackgroundTransparency = 1,
                Text               = tostring(def) .. suf,
                TextColor3         = T.AccentHi,
                Font               = Enum.Font.GothamBold,
                TextSize           = 13,
                TextXAlignment     = Enum.TextXAlignment.Right,
            }, wrap)

            -- Track
            local track = mk("Frame", {
                Size             = UDim2.new(1, 0, 0, 6),
                Position         = UDim2.new(0, 0, 0, 30),
                BackgroundColor3 = T.Surface,
                BorderSizePixel  = 0,
            }, wrap)
            corner(track, 3)
            border(track, T.Border, 1)

            local pct = (def - sMin) / (sMax - sMin)

            local fill = mk("Frame", {
                Size             = UDim2.new(pct, 0, 1, 0),
                BackgroundColor3 = T.Accent,
                BorderSizePixel  = 0,
            }, track)
            corner(fill, 3)
            grad(fill, T.AccentHi, T.Cyan, 0)

            local thumb = mk("Frame", {
                Size             = UDim2.new(0, 16, 0, 16),
                Position         = UDim2.new(pct, -8, 0.5, -8),
                BackgroundColor3 = T.White,
                BorderSizePixel  = 0,
                ZIndex           = fill.ZIndex + 1,
            }, track)
            corner(thumb, 8)
            border(thumb, T.Accent, 2)

            local sld     = { Value = def }
            local isDragging = false

            local function updateSlider(inputX)
                local rel = math.clamp(
                    (inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X,
                    0, 1
                )
                local val = math.floor(sMin + rel * (sMax - sMin) + 0.5)
                sld.Value    = val
                valLbl.Text  = tostring(val) .. suf
                tw(fill,  0.05, { Size     = UDim2.new(rel, 0, 1, 0) }, Enum.EasingStyle.Linear)
                tw(thumb, 0.05, { Position = UDim2.new(rel, -8, 0.5, -8) }, Enum.EasingStyle.Linear)
                pcall(cb, val)
            end

            -- Zona interactiva más grande que el track
            local hit = mk("TextButton", {
                Size               = UDim2.new(1, 8, 0, 28),
                Position           = UDim2.new(0, -4, 0.5, -14),
                BackgroundTransparency = 1,
                Text               = "",
                ZIndex             = thumb.ZIndex + 1,
            }, track)

            hit.MouseButton1Down:Connect(function(x)
                isDragging = true
                updateSlider(x)
            end)

            UIS.InputChanged:Connect(function(inp)
                if isDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(inp.Position.X)
                end
            end)

            UIS.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = false
                end
            end)

            function sld:Set(v)
                local clamped = math.clamp(v, sMin, sMax)
                local rel     = (clamped - sMin) / (sMax - sMin)
                sld.Value     = clamped
                valLbl.Text   = tostring(clamped) .. suf
                tw(fill,  0.15, { Size     = UDim2.new(rel, 0, 1, 0) })
                tw(thumb, 0.15, { Position = UDim2.new(rel, -8, 0.5, -8) })
            end

            return sld
        end

        -- ── DROPDOWN ────────────────────────────────────────
        --  Corregido: el menú se crea en el gui (no en wrap)
        --  para evitar clipping y Z-index roto.
        function sec:AddDropdown(c)
            c = c or {}
            local opts = c.Options or {}
            local cb   = c.Callback or function() end
            local sel  = c.Default  or opts[1] or "—"

            local wrap = mk("Frame", {
                Size               = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                LayoutOrder        = nxt(),
            }, sFrame)

            mk("TextLabel", {
                Size               = UDim2.new(0.42, 0, 1, 0),
                BackgroundTransparency = 1,
                Text               = c.Name or "Dropdown",
                TextColor3         = T.Text,
                Font               = Enum.Font.GothamMedium,
                TextSize           = 13,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, wrap)

            local ddBtn = mk("TextButton", {
                Size             = UDim2.new(0.56, 0, 0, 28),
                Position         = UDim2.new(0.44, 0, 0.5, -14),
                BackgroundColor3 = T.Surface,
                Text             = "",
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
            }, wrap)
            corner(ddBtn, 7)
            border(ddBtn, T.Border, 1)

            local selLbl = mk("TextLabel", {
                Size               = UDim2.new(1, -26, 1, 0),
                Position           = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text               = sel,
                TextColor3         = T.Text,
                Font               = Enum.Font.Gotham,
                TextSize           = 12,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, ddBtn)

            local arrow = mk("TextLabel", {
                Size               = UDim2.new(0, 16, 1, 0),
                Position           = UDim2.new(1, -20, 0, 0),
                BackgroundTransparency = 1,
                Text               = "▾",
                TextColor3         = T.TextSub,
                Font               = Enum.Font.GothamBold,
                TextSize           = 13,
            }, ddBtn)

            -- Menú flotante en el gui (sin clipping de padres)
            local menuH = math.min(#opts, 6) * 28 + 8
            local menu = mk("Frame", {
                Size             = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = T.Surface,
                BorderSizePixel  = 0,
                ZIndex           = 80,
                ClipsDescendants = true,
                Visible          = false,
            }, self._gui)
            corner(menu, 8)
            border(menu, T.BorderHi, 1)

            -- Si hay más de 6 opciones, scrollable
            local menuScroll = mk("ScrollingFrame", {
                Size                  = UDim2.new(1, -8, 1, -8),
                Position              = UDim2.new(0, 4, 0, 4),
                BackgroundTransparency = 1,
                BorderSizePixel       = 0,
                ScrollBarThickness    = 2,
                ScrollBarImageColor3  = T.Accent,
                CanvasSize            = UDim2.new(0, 0, 0, #opts * 28),
                AutomaticCanvasSize   = Enum.AutomaticSize.None,
                ZIndex                = 81,
            }, menu)
            layout(menuScroll, 2)

            for _, opt in ipairs(opts) do
                local item = mk("TextButton", {
                    Size             = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = T.Surface,
                    Text             = opt,
                    TextColor3       = T.Text,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 12,
                    BorderSizePixel  = 0,
                    AutoButtonColor  = false,
                    ZIndex           = 82,
                }, menuScroll)
                corner(item, 6)

                item.MouseEnter:Connect(function()
                    tw(item, 0.1, { BackgroundColor3 = T.Card, TextColor3 = T.AccentHi })
                end)
                item.MouseLeave:Connect(function()
                    tw(item, 0.1, { BackgroundColor3 = T.Surface, TextColor3 = T.Text })
                end)
                item.MouseButton1Click:Connect(function()
                    dd.Value   = opt
                    selLbl.Text = opt
                    -- cerrar
                    tw(menu, 0.18, { Size = UDim2.new(menu.Size.X.Scale, menu.Size.X.Offset, 0, 0) })
                    task.delay(0.2, function() menu.Visible = false end)
                    tw(arrow, 0.18, { Rotation = 0 })
                    isOpen = false
                    pcall(cb, opt)
                end)
            end

            local dd     = { Value = sel }
            local isOpen = false

            -- Posicionar menú relativo al botón cuando se abre
            local function openMenu()
                local abs = ddBtn.AbsolutePosition
                local sz  = ddBtn.AbsoluteSize
                local w   = sz.X
                menu.Size     = UDim2.new(0, w, 0, 0)
                menu.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
                menu.Visible  = true
                tw(menu, 0.26, { Size = UDim2.new(0, w, 0, menuH) }, Enum.EasingStyle.Back)
            end

            ddBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    openMenu()
                    tw(arrow, 0.18, { Rotation = 180 })
                else
                    tw(menu, 0.18, { Size = UDim2.new(0, menu.AbsoluteSize.X, 0, 0) })
                    task.delay(0.2, function() menu.Visible = false end)
                    tw(arrow, 0.18, { Rotation = 0 })
                end
            end)

            -- Cerrar si se hace click fuera
            UIS.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 and isOpen then
                    local mpos = UIS:GetMouseLocation()
                    local ma   = menu.AbsolutePosition
                    local ms   = menu.AbsoluteSize
                    if not (mpos.X >= ma.X and mpos.X <= ma.X + ms.X and
                            mpos.Y >= ma.Y and mpos.Y <= ma.Y + ms.Y) then
                        isOpen = false
                        tw(menu, 0.18, { Size = UDim2.new(0, ms.X, 0, 0) })
                        task.delay(0.2, function() menu.Visible = false end)
                        tw(arrow, 0.18, { Rotation = 0 })
                    end
                end
            end)

            function dd:Set(v)
                dd.Value    = v
                selLbl.Text = v
            end
            return dd
        end

        -- ── INPUT ────────────────────────────────────────────
        function sec:AddInput(c)
            c = c or {}
            local cb = c.Callback or function() end

            local wrap = mk("Frame", {
                Size               = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                LayoutOrder        = nxt(),
            }, sFrame)

            mk("TextLabel", {
                Size               = UDim2.new(0.38, 0, 1, 0),
                BackgroundTransparency = 1,
                Text               = c.Name or "Input",
                TextColor3         = T.Text,
                Font               = Enum.Font.GothamMedium,
                TextSize           = 13,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, wrap)

            local box = mk("TextBox", {
                Size              = UDim2.new(0.6, 0, 0, 28),
                Position          = UDim2.new(0.4, 0, 0.5, -14),
                BackgroundColor3  = T.Surface,
                PlaceholderText   = c.Placeholder or "Escribir...",
                PlaceholderColor3 = T.TextDim,
                Text              = c.Default or "",
                TextColor3        = T.Text,
                Font              = Enum.Font.Gotham,
                TextSize          = 12,
                BorderSizePixel   = 0,
                ClearTextOnFocus  = false,
            }, wrap)
            corner(box, 7)
            pad(box, 0, 0, 8, 8)

            local brd = border(box, T.Border, 1)

            box.Focused:Connect(function()
                tw(brd,  0.18, { Color = T.Accent })
                tw(box,  0.18, { BackgroundColor3 = T.Card })
            end)
            box.FocusLost:Connect(function(enter)
                tw(brd,  0.18, { Color = T.Border })
                tw(box,  0.18, { BackgroundColor3 = T.Surface })
                if enter then pcall(cb, box.Text) end
            end)

            local inp = { Value = box.Text }
            function inp:Set(v)   box.Text = v; inp.Value = v end
            function inp:Get()    return box.Text end
            return inp
        end

        -- ── LABEL ────────────────────────────────────────────
        function sec:AddLabel(c)
            c = c or {}
            local l = mk("TextLabel", {
                Size               = UDim2.new(1, 0, 0, (c.Size or 12) + 4),
                BackgroundTransparency = 1,
                Text               = c.Text or "",
                TextColor3         = c.Color or T.TextSub,
                Font               = c.Bold and Enum.Font.GothamBold or Enum.Font.Gotham,
                TextSize           = c.Size or 12,
                TextXAlignment     = Enum.TextXAlignment.Left,
                TextWrapped        = true,
                LayoutOrder        = nxt(),
            }, sFrame)
            local lObj = {}
            function lObj:Set(t)      l.Text = t end
            function lObj:SetColor(col) l.TextColor3 = col end
            return lObj
        end

        -- ── DIVIDER ──────────────────────────────────────────
        function sec:AddDivider()
            local div = mk("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = T.Border,
                BorderSizePixel  = 0,
                LayoutOrder      = nxt(),
            }, sFrame)
            grad(div, T.Accent, T.Card, 0)
        end

        -- ── KEYBIND ──────────────────────────────────────────
        function sec:AddKeybind(c)
            c = c or {}
            local cb      = c.Callback or function() end
            local current = c.Default  or Enum.KeyCode.Unknown
            local binding = false

            local row = mk("Frame", {
                Size               = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                LayoutOrder        = nxt(),
            }, sFrame)

            mk("TextLabel", {
                Size               = UDim2.new(0.55, 0, 1, 0),
                BackgroundTransparency = 1,
                Text               = c.Name or "Keybind",
                TextColor3         = T.Text,
                Font               = Enum.Font.GothamMedium,
                TextSize           = 13,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, row)

            local keyBtn = mk("TextButton", {
                Size             = UDim2.new(0.42, 0, 0, 26),
                Position         = UDim2.new(0.58, 0, 0.5, -13),
                BackgroundColor3 = T.Surface,
                Text             = current == Enum.KeyCode.Unknown and "Ninguno" or current.Name,
                TextColor3       = T.AccentHi,
                Font             = Enum.Font.GothamBold,
                TextSize         = 11,
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
            }, row)
            corner(keyBtn, 6)
            border(keyBtn, T.Border, 1)

            keyBtn.MouseButton1Click:Connect(function()
                binding = true
                keyBtn.Text      = "Esperando..."
                keyBtn.TextColor3 = T.Yellow
            end)

            UIS.InputBegan:Connect(function(inp, gp)
                if gp or not binding then return end
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    binding       = false
                    current       = inp.KeyCode
                    keyBtn.Text   = current.Name
                    keyBtn.TextColor3 = T.AccentHi
                    pcall(cb, current)
                end
            end)

            -- Listener global del keybind
            UIS.InputBegan:Connect(function(inp, gp)
                if gp or binding then return end
                if inp.UserInputType == Enum.UserInputType.Keyboard
                   and inp.KeyCode == current
                   and current ~= Enum.KeyCode.Unknown then
                    pcall(cb, current)
                end
            end)

            local kb = { Value = current }
            function kb:Set(k)
                current = k
                keyBtn.Text = k.Name
                kb.Value = k
            end
            return kb
        end

        table.insert(tab._sections, sec)
        return sec
    end

    return tab
end

-- ══════════════════════════════════════════════════════════════
--  NOTIFY  (apilable, hasta 4 simultáneas)
-- ══════════════════════════════════════════════════════════════
local _notifyStack = {}
local NOTIFY_W = 264
local NOTIFY_H = 68
local NOTIFY_GAP = 8
local NOTIFY_X_IN  = -272
local NOTIFY_X_OUT = 280

local function repositionNotify()
    for i, nf in ipairs(_notifyStack) do
        local yOff = -(NOTIFY_H + NOTIFY_GAP) * i
        tw(nf, 0.3, { Position = UDim2.new(1, NOTIFY_X_IN, 1, yOff) })
    end
end

function Nexus:Notify(cfg)
    cfg = cfg or {}

    -- Limitar stack a 4
    if #_notifyStack >= 4 then
        local oldest = table.remove(_notifyStack, 1)
        tw(oldest, 0.2, { Position = UDim2.new(1, NOTIFY_X_OUT, oldest.Position.Y.Scale, oldest.Position.Y.Offset) })
        task.delay(0.25, function() pcall(function() oldest:Destroy() end) end)
    end

    local colMap = {
        success = T.Green,
        warning = T.Yellow,
        error   = T.Red,
        info    = T.Accent,
    }
    local barCol = colMap[cfg.Type] or cfg.Color or T.Accent

    local nf = mk("Frame", {
        Size             = UDim2.new(0, NOTIFY_W, 0, NOTIFY_H),
        Position         = UDim2.new(1, NOTIFY_X_OUT, 1, -NOTIFY_H - NOTIFY_GAP),
        BackgroundColor3 = T.Card,
        BorderSizePixel  = 0,
        ZIndex           = 100,
    }, self._gui)
    corner(nf, 10)
    border(nf, T.BorderHi, 1)

    -- Barra de color izquierda
    local bar = mk("Frame", {
        Size             = UDim2.new(0, 3, 0.6, 0),
        Position         = UDim2.new(0, 10, 0.2, 0),
        BackgroundColor3 = barCol,
        BorderSizePixel  = 0,
        ZIndex           = 101,
    }, nf)
    corner(bar, 2)

    mk("TextLabel", {
        Size               = UDim2.new(1, -28, 0, 22),
        Position           = UDim2.new(0, 22, 0, 10),
        BackgroundTransparency = 1,
        Text               = cfg.Title or "Notificación",
        TextColor3         = T.Text,
        Font               = Enum.Font.GothamBold,
        TextSize           = 13,
        TextXAlignment     = Enum.TextXAlignment.Left,
        ZIndex             = 101,
    }, nf)

    mk("TextLabel", {
        Size               = UDim2.new(1, -28, 0, 18),
        Position           = UDim2.new(0, 22, 0, 34),
        BackgroundTransparency = 1,
        Text               = cfg.Content or "",
        TextColor3         = T.TextSub,
        Font               = Enum.Font.Gotham,
        TextSize           = 11,
        TextXAlignment     = Enum.TextXAlignment.Left,
        TextWrapped        = true,
        ZIndex             = 101,
    }, nf)

    -- Barra de progreso de duración
    local dur = cfg.Duration or 3
    local progBg = mk("Frame", {
        Size             = UDim2.new(1, -20, 0, 2),
        Position         = UDim2.new(0, 10, 1, -8),
        BackgroundColor3 = T.Surface,
        BorderSizePixel  = 0,
        ZIndex           = 102,
    }, nf)
    corner(progBg, 1)

    local prog = mk("Frame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = barCol,
        BorderSizePixel  = 0,
        ZIndex           = 103,
    }, progBg)
    corner(prog, 1)

    table.insert(_notifyStack, nf)
    repositionNotify()

    -- Animar barra de progreso
    tw(prog, dur, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)

    task.delay(dur, function()
        local idx = table.find(_notifyStack, nf)
        if idx then table.remove(_notifyStack, idx) end
        tw(nf, 0.28, { Position = UDim2.new(1, NOTIFY_X_OUT, nf.Position.Y.Scale, nf.Position.Y.Offset) })
        task.delay(0.32, function() pcall(function() nf:Destroy() end) end)
        repositionNotify()
    end)
end

-- ══════════════════════════════════════════════════════════════
--  DESTROY
-- ══════════════════════════════════════════════════════════════
function Nexus:Destroy()
    if self._gui then
        tw(self._main,   0.3, { Size = UDim2.new(0, 550, 0, 0), BackgroundTransparency = 1 })
        tw(self._shadow, 0.3, { BackgroundTransparency = 1 })
        task.delay(0.35, function()
            pcall(function() self._gui:Destroy() end)
        end)
    end
end

return Nexus

-- ══════════════════════════════════════════════════════════════
--  EJEMPLO DE USO
-- ══════════════════════════════════════════════════════════════
--[[
local Nexus = loadstring(game:HttpGet("..."))()

local win = Nexus.new({
    Title    = "Mi Script",
    Subtitle = "by user",
})

local tabMain = win:CreateTab({ Name = "Principal", Icon = "⚙" })
local secMain = tabMain:CreateSection({ Name = "Combate" })

local tgAimbot = secMain:AddToggle({
    Name        = "Aimbot",
    Description = "Apunta automáticamente",
    Default     = false,
    Callback    = function(v) print("Aimbot:", v) end,
})

local sldFOV = secMain:AddSlider({
    Name     = "FOV",
    Min      = 10,
    Max      = 360,
    Default  = 90,
    Suffix   = "°",
    Callback = function(v) print("FOV:", v) end,
})

secMain:AddButton({
    Name     = "Ejecutar",
    Callback = function() win:Notify({ Title = "Listo", Content = "Acción ejecutada.", Type = "success" }) end,
})

local tabOtro = win:CreateTab({ Name = "Visual",    Icon = "◉" })
local tabConf = win:CreateTab({ Name = "Ajustes",   Icon = "≡" })
]]
