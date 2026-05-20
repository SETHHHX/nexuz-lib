-- ============================================================
--  NexusLib v2.0  —  UI Library para Roblox Executors
--  Diseño moderno con gradientes, glassmorphism y animaciones
-- ============================================================

local Nexus = {}
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-- ─── TEMA ───────────────────────────────────────────────────
local T = {
    -- Fondos
    BG          = Color3.fromRGB(10, 11, 15),
    Surface     = Color3.fromRGB(16, 18, 24),
    Card        = Color3.fromRGB(22, 25, 34),
    CardHover   = Color3.fromRGB(28, 32, 44),
    Sidebar     = Color3.fromRGB(14, 16, 22),

    -- Acentos
    Accent      = Color3.fromRGB(108, 92, 231),
    AccentLight = Color3.fromRGB(140, 122, 255),
    AccentDim   = Color3.fromRGB(70, 58, 160),
    Cyan        = Color3.fromRGB(80, 200, 200),
    Pink        = Color3.fromRGB(220, 100, 180),

    -- Bordes
    Border      = Color3.fromRGB(38, 42, 58),
    BorderLight = Color3.fromRGB(55, 60, 82),

    -- Texto
    Text        = Color3.fromRGB(225, 228, 240),
    TextSub     = Color3.fromRGB(140, 148, 170),
    TextDim     = Color3.fromRGB(70, 78, 100),

    -- Estados
    Success     = Color3.fromRGB(72, 199, 142),
    Warning     = Color3.fromRGB(255, 180, 80),
    Danger      = Color3.fromRGB(238, 90, 90),
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(0, 0, 0),
}

-- ─── UTILS ──────────────────────────────────────────────────
local function tw(obj, t, props, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function ni(class, props, parent)
    local o = Instance.new(class)
    for k,v in pairs(props) do o[k]=v end
    if parent then o.Parent = parent end
    return o
end

local function corner(p, r)
    return ni("UICorner",{CornerRadius=UDim.new(0,r or 8)},p)
end

local function stroke(p, col, thick, trans)
    return ni("UIStroke",{
        Color=col or T.Border,
        Thickness=thick or 1,
        Transparency=trans or 0,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    },p)
end

local function pad(p, t,b,l,r)
    return ni("UIPadding",{
        PaddingTop=UDim.new(0,t or 8),
        PaddingBottom=UDim.new(0,b or 8),
        PaddingLeft=UDim.new(0,l or 10),
        PaddingRight=UDim.new(0,r or 10),
    },p)
end

local function list(p, gap, dir)
    return ni("UIListLayout",{
        Padding=UDim.new(0,gap or 6),
        FillDirection=dir or Enum.FillDirection.Vertical,
        SortOrder=Enum.SortOrder.LayoutOrder,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
    },p)
end

local function gradient(p, c0, c1, rot)
    return ni("UIGradient",{
        Color=ColorSequence.new(c0,c1),
        Rotation=rot or 90,
    },p)
end

local function ripple(parent, x, y)
    local rip = ni("Frame",{
        Size=UDim2.new(0,0,0,0),
        Position=UDim2.new(0,x-parent.AbsolutePosition.X,0,y-parent.AbsolutePosition.Y),
        BackgroundColor3=T.White,
        BackgroundTransparency=0.7,
        BorderSizePixel=0,
        ZIndex=parent.ZIndex+5,
    },parent)
    corner(rip,100)
    tw(rip,0.5,{Size=UDim2.new(0,200,0,200),Position=UDim2.new(0,x-parent.AbsolutePosition.X-100,0,y-parent.AbsolutePosition.Y-100),BackgroundTransparency=1})
    game:GetService("Debris"):AddItem(rip,0.6)
end

-- ─── DRAG ───────────────────────────────────────────────────
local function draggable(frame, handle)
    handle = handle or frame
    local drag, inp, st, sp = false,nil,nil,nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; st=i.Position; sp=frame.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then inp=i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i==inp and drag then
            local d=i.Position-st
            tw(frame,0.08,{Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)},Enum.EasingStyle.Linear)
        end
    end)
end

-- ════════════════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════════════════
function Nexus:CreateWindow(cfg)
    cfg = cfg or {}
    local win = { _tabs={}, _activeTab=nil }

    -- ScreenGui
    local gui = ni("ScreenGui",{
        Name="NexusLib",
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn=false,
        IgnoreGuiInset=true,
    })
    pcall(function() gui.Parent=game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent=LocalPlayer:WaitForChild("PlayerGui") end

    -- ── Sombra exterior
    local shadowFrame = ni("Frame",{
        Size=UDim2.new(0,580,0,420),
        Position=UDim2.new(0.5,-290,0.5,-210),
        BackgroundColor3=T.Black,
        BackgroundTransparency=0.3,
        BorderSizePixel=0,
    },gui)
    corner(shadowFrame,18)

    -- ── Main frame
    local main = ni("Frame",{
        Size=UDim2.new(0,560,0,400),
        Position=UDim2.new(0.5,-280,0.5,-200),
        BackgroundColor3=T.BG,
        BorderSizePixel=0,
        ClipsDescendants=true,
    },gui)
    corner(main,14)
    stroke(main,T.BorderLight,1.2)

    -- Entrada animada
    main.Size=UDim2.new(0,0,0,0)
    main.BackgroundTransparency=1
    shadowFrame.BackgroundTransparency=1
    tw(main,0.5,{Size=UDim2.new(0,560,0,400),BackgroundTransparency=0},Enum.EasingStyle.Back)
    tw(shadowFrame,0.5,{BackgroundTransparency=0.55},Enum.EasingStyle.Quart)

    -- ── Topbar
    local topbar = ni("Frame",{
        Size=UDim2.new(1,0,0,58),
        BackgroundColor3=T.Surface,
        BorderSizePixel=0,
    },main)

    -- Gradiente sutil en topbar
    gradient(topbar,
        Color3.fromRGB(20,22,32),
        Color3.fromRGB(14,16,22),
        180)

    -- Línea inferior topbar con gradiente de color
    local topLine = ni("Frame",{
        Size=UDim2.new(1,0,0,2),
        Position=UDim2.new(0,0,1,-2),
        BackgroundColor3=T.Accent,
        BorderSizePixel=0,
    },topbar)
    gradient(topLine,T.Accent,T.Cyan,0)

    -- Dot animado
    local dot = ni("Frame",{
        Size=UDim2.new(0,10,0,10),
        Position=UDim2.new(0,16,0.5,-5),
        BackgroundColor3=T.AccentLight,
        BorderSizePixel=0,
    },topbar)
    corner(dot,5)
    -- Glow dot
    local dotGlow = ni("Frame",{
        Size=UDim2.new(0,20,0,20),
        Position=UDim2.new(0,-5,0.5,-10),
        BackgroundColor3=T.Accent,
        BackgroundTransparency=0.5,
        BorderSizePixel=0,
    },topbar)
    corner(dotGlow,10)
    -- Pulsar animación del dot
    spawn(function()
        while gui.Parent do
            tw(dotGlow,0.8,{BackgroundTransparency=0.8,Size=UDim2.new(0,26,0,26),Position=UDim2.new(0,-8,0.5,-13)})
            task.wait(0.9)
            tw(dotGlow,0.8,{BackgroundTransparency=0.5,Size=UDim2.new(0,20,0,20),Position=UDim2.new(0,-5,0.5,-10)})
            task.wait(0.9)
        end
    end)

    -- Título
    ni("TextLabel",{
        Size=UDim2.new(0,220,0,28),
        Position=UDim2.new(0,36,0,8),
        BackgroundTransparency=1,
        Text=cfg.Title or "NexusLib",
        TextColor3=T.Text,
        Font=Enum.Font.GothamBold,
        TextSize=16,
        TextXAlignment=Enum.TextXAlignment.Left,
    },topbar)

    -- Subtítulo con gradiente (usando TextLabel normal)
    ni("TextLabel",{
        Size=UDim2.new(0,220,0,16),
        Position=UDim2.new(0,36,0,32),
        BackgroundTransparency=1,
        Text=cfg.Subtitle or "v2.0",
        TextColor3=T.TextSub,
        Font=Enum.Font.Gotham,
        TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left,
    },topbar)

    -- Botones topbar
    local function makeTopBtn(xOff, col, icon)
        local btn = ni("TextButton",{
            Size=UDim2.new(0,26,0,26),
            Position=UDim2.new(1,xOff,0.5,-13),
            BackgroundColor3=col,
            Text=icon,
            TextColor3=T.White,
            Font=Enum.Font.GothamBold,
            TextSize=12,
            BorderSizePixel=0,
            AutoButtonColor=false,
        },topbar)
        corner(btn,6)
        btn.MouseEnter:Connect(function()
            tw(btn,0.15,{BackgroundTransparency=0.2})
        end)
        btn.MouseLeave:Connect(function()
            tw(btn,0.15,{BackgroundTransparency=0})
        end)
        return btn
    end

    local closeBtn = makeTopBtn(-38, T.Danger, "✕")
    local minBtn   = makeTopBtn(-72, Color3.fromRGB(255,170,50), "─")

    closeBtn.MouseButton1Click:Connect(function()
        tw(main,0.3,{Size=UDim2.new(0,560,0,0),BackgroundTransparency=1})
        tw(shadowFrame,0.3,{BackgroundTransparency=1})
        task.delay(0.35,function() gui:Destroy() end)
    end)

    local minimized=false
    minBtn.MouseButton1Click:Connect(function()
        minimized=not minimized
        tw(main,0.35,{Size=minimized and UDim2.new(0,560,0,58) or UDim2.new(0,560,0,400)},Enum.EasingStyle.Back)
    end)

    draggable(main, topbar)

    -- ── Sidebar
    local sidebar = ni("Frame",{
        Size=UDim2.new(0,140,1,-58),
        Position=UDim2.new(0,0,0,58),
        BackgroundColor3=T.Sidebar,
        BorderSizePixel=0,
    },main)
    gradient(sidebar,Color3.fromRGB(14,16,22),Color3.fromRGB(12,13,18),180)

    -- Línea divisoria sidebar
    local divLine = ni("Frame",{
        Size=UDim2.new(0,1,1,0),
        Position=UDim2.new(1,-1,0,0),
        BackgroundColor3=T.Border,
        BorderSizePixel=0,
    },sidebar)

    -- Gradiente en línea divisoria
    local divGrad = ni("UIGradient",{
        Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,T.Accent),
            ColorSequenceKeypoint.new(0.5,T.BorderLight),
            ColorSequenceKeypoint.new(1,T.Border),
        },
        Rotation=90,
    },divLine)

    list(sidebar, 3, Enum.FillDirection.Vertical)
    pad(sidebar, 10, 10, 8, 8)

    -- Branding pequeño abajo del sidebar
    ni("TextLabel",{
        Size=UDim2.new(1,-10,0,20),
        Position=UDim2.new(0,5,1,-28),
        BackgroundTransparency=1,
        Text="NexusLib v2.0",
        TextColor3=T.TextDim,
        Font=Enum.Font.Gotham,
        TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=2,
    },sidebar)

    -- ── Content
    local content = ni("ScrollingFrame",{
        Size=UDim2.new(1,-141,1,-58),
        Position=UDim2.new(0,141,0,58),
        BackgroundColor3=T.BG,
        BorderSizePixel=0,
        ScrollBarThickness=0,
        ScrollingEnabled=false,
        ClipsDescendants=false,
    },main)

    -- ════ TAB ════
    function win:CreateTab(tabCfg)
        tabCfg = tabCfg or {}
        local tab = { _sections={}, Name=tabCfg.Name or "Tab", Icon=tabCfg.Icon or "◈" }

        -- Botón sidebar
        local tabBtn = ni("TextButton",{
            Size=UDim2.new(1,0,0,36),
            BackgroundColor3=Color3.fromRGB(0,0,0),
            BackgroundTransparency=1,
            Text="",
            BorderSizePixel=0,
            AutoButtonColor=false,
        },sidebar)
        corner(tabBtn,8)

        -- Indicador activo (barra izquierda)
        local activeIndicator = ni("Frame",{
            Size=UDim2.new(0,3,0,20),
            Position=UDim2.new(0,0,0.5,-10),
            BackgroundColor3=T.Accent,
            BorderSizePixel=0,
            BackgroundTransparency=1,
        },tabBtn)
        corner(activeIndicator,2)

        -- Fondo activo
        local activeBg = ni("Frame",{
            Size=UDim2.new(1,0,1,0),
            BackgroundColor3=T.Card,
            BorderSizePixel=0,
            BackgroundTransparency=1,
        },tabBtn)
        corner(activeBg,8)

        -- Icono
        local tabIco = ni("TextLabel",{
            Size=UDim2.new(0,24,1,0),
            Position=UDim2.new(0,14,0,0),
            BackgroundTransparency=1,
            Text=tab.Icon,
            TextColor3=T.TextDim,
            Font=Enum.Font.Gotham,
            TextSize=15,
        },tabBtn)

        -- Nombre
        local tabLbl = ni("TextLabel",{
            Size=UDim2.new(1,-42,1,0),
            Position=UDim2.new(0,38,0,0),
            BackgroundTransparency=1,
            Text=tab.Name,
            TextColor3=T.TextSub,
            Font=Enum.Font.Gotham,
            TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
        },tabBtn)

        -- Página de contenido
        local page = ni("ScrollingFrame",{
            Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1,
            BorderSizePixel=0,
            ScrollBarThickness=3,
            ScrollBarImageColor3=T.Accent,
            CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            Visible=false,
        },content)
        list(page, 10)
        pad(page, 12, 12, 12, 12)

        tab._page=page; tab._btn=tabBtn

        local function activate()
            if win._activeTab and win._activeTab~=tab then
                local o=win._activeTab
                o._page.Visible=false
                tw(o._btn:FindFirstChild("Frame"),0.2,{BackgroundTransparency=1})
                tw(o._btn:FindFirstChildOfClass("Frame"),0.2,{BackgroundTransparency=1})
            end
            win._activeTab=tab
            page.Visible=true
            tw(activeBg,0.25,{BackgroundTransparency=0.4})
            tw(activeIndicator,0.25,{BackgroundTransparency=0})
            tw(tabIco,0.2,{TextColor3=T.AccentLight})
            tw(tabLbl,0.2,{TextColor3=T.Text,Font=Enum.Font.GothamBold})
        end

        tabBtn.MouseButton1Click:Connect(function()
            activate()
            ripple(tabBtn, UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        end)
        tabBtn.MouseEnter:Connect(function()
            if win._activeTab~=tab then
                tw(activeBg,0.15,{BackgroundTransparency=0.7})
                tw(tabIco,0.15,{TextColor3=T.TextSub})
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if win._activeTab~=tab then
                tw(activeBg,0.15,{BackgroundTransparency=1})
                tw(tabIco,0.15,{TextColor3=T.TextDim})
            end
        end)

        if #win._tabs==0 then activate() end
        table.insert(win._tabs, tab)

        -- ════ SECTION ════
        function tab:CreateSection(sCfg)
            sCfg = sCfg or {}
            local sec = {}

            local sFrame = ni("Frame",{
                Size=UDim2.new(1,-4,0,0),
                BackgroundColor3=T.Card,
                BorderSizePixel=0,
                AutomaticSize=Enum.AutomaticSize.Y,
            },page)
            corner(sFrame,10)
            stroke(sFrame,T.Border,1)

            -- Gradiente sutil en card
            gradient(sFrame,Color3.fromRGB(24,27,38),Color3.fromRGB(20,23,32),180)

            pad(sFrame,12,12,14,14)
            local sLayout = list(sFrame,10)
            local order = 0

            local function nxt() order=order+1; return order end

            -- Header de sección
            if sCfg.Name then
                local hdr = ni("Frame",{
                    Size=UDim2.new(1,0,0,28),
                    BackgroundTransparency=1,
                    LayoutOrder=0,
                },sFrame)

                -- Pill de color
                local pill = ni("Frame",{
                    Size=UDim2.new(0,4,0,16),
                    Position=UDim2.new(0,0,0.5,-8),
                    BackgroundColor3=T.Accent,
                    BorderSizePixel=0,
                },hdr)
                corner(pill,2)

                ni("TextLabel",{
                    Size=UDim2.new(1,-12,1,0),
                    Position=UDim2.new(0,12,0,0),
                    BackgroundTransparency=1,
                    Text=sCfg.Name:upper(),
                    TextColor3=T.TextSub,
                    Font=Enum.Font.GothamBold,
                    TextSize=10,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    LetterSpacing=2,
                },hdr)

                -- Línea decorativa
                local hline = ni("Frame",{
                    Size=UDim2.new(1,0,0,1),
                    BackgroundColor3=T.Border,
                    BorderSizePixel=0,
                    LayoutOrder=1,
                },sFrame)
                gradient(hline,T.Accent,Color3.fromRGB(20,23,32),0)
            end

            -- ── TOGGLE ──
            function sec:AddToggle(c)
                c=c or {}
                local state=c.Default or false
                local cb=c.Callback or function()end

                local row=ni("Frame",{
                    Size=UDim2.new(1,0,0,c.Description and 50 or 38),
                    BackgroundTransparency=1,
                    LayoutOrder=nxt(),
                },sFrame)

                -- Hover bg
                local rowBg=ni("Frame",{
                    Size=UDim2.new(1,8,1,4),
                    Position=UDim2.new(0,-4,0,-2),
                    BackgroundColor3=T.CardHover,
                    BackgroundTransparency=1,
                    BorderSizePixel=0,
                },row)
                corner(rowBg,8)

                ni("TextLabel",{
                    Size=UDim2.new(1,-58,0,20),
                    Position=UDim2.new(0,0,0,c.Description and 6 or 9),
                    BackgroundTransparency=1,
                    Text=c.Name or "Toggle",
                    TextColor3=T.Text,
                    Font=Enum.Font.GothamMedium,
                    TextSize=13,
                    TextXAlignment=Enum.TextXAlignment.Left,
                },row)

                if c.Description then
                    ni("TextLabel",{
                        Size=UDim2.new(1,-58,0,14),
                        Position=UDim2.new(0,0,0,26),
                        BackgroundTransparency=1,
                        Text=c.Description,
                        TextColor3=T.TextDim,
                        Font=Enum.Font.Gotham,
                        TextSize=11,
                        TextXAlignment=Enum.TextXAlignment.Left,
                    },row)
                end

                -- Track
                local track=ni("Frame",{
                    Size=UDim2.new(0,46,0,26),
                    Position=UDim2.new(1,-46,0.5,-13),
                    BackgroundColor3=state and T.Accent or T.Surface,
                    BorderSizePixel=0,
                },row)
                corner(track,13)
                stroke(track,state and T.AccentLight or T.Border,1)

                -- Gradiente del track (cuando ON)
                local trackGrad=ni("UIGradient",{
                    Color=ColorSequence.new(T.Accent,T.Cyan),
                    Rotation=0,
                    Enabled=state,
                },track)

                -- Thumb
                local thumb=ni("Frame",{
                    Size=UDim2.new(0,20,0,20),
                    Position=state and UDim2.new(0,23,0.5,-10) or UDim2.new(0,3,0.5,-10),
                    BackgroundColor3=T.White,
                    BorderSizePixel=0,
                },track)
                corner(thumb,10)

                -- Sombra del thumb
                ni("UIStroke",{
                    Color=T.Accent,
                    Thickness=2,
                    Transparency=state and 0.4 or 1,
                    ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
                },thumb)

                local tog={Value=state}

                local function setT(v, skip)
                    tog.Value=v
                    trackGrad.Enabled=v
                    tw(track,0.28,{BackgroundColor3=v and T.Accent or T.Surface})
                    tw(thumb,0.3,{Position=v and UDim2.new(0,23,0.5,-10) or UDim2.new(0,3,0.5,-10)},Enum.EasingStyle.Back)
                    if not skip then pcall(cb,v) end
                end

                local btn=ni("TextButton",{
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1,
                    Text="",
                    ZIndex=row.ZIndex+1,
                },row)

                btn.MouseButton1Click:Connect(function() setT(not tog.Value) end)
                btn.MouseEnter:Connect(function() tw(rowBg,0.15,{BackgroundTransparency=0.6}) end)
                btn.MouseLeave:Connect(function() tw(rowBg,0.15,{BackgroundTransparency=1}) end)

                function tog:Set(v,s) setT(v,s) end
                return tog
            end

            -- ── BUTTON ──
            function sec:AddButton(c)
                c=c or {}
                local cb=c.Callback or function()end

                local wrap=ni("Frame",{
                    Size=UDim2.new(1,0,0,36),
                    BackgroundTransparency=1,
                    LayoutOrder=nxt(),
                },sFrame)

                local btn=ni("TextButton",{
                    Size=UDim2.new(1,0,1,0),
                    BackgroundColor3=T.Accent,
                    Text="",
                    BorderSizePixel=0,
                    AutoButtonColor=false,
                },wrap)
                corner(btn,8)
                gradient(btn,T.Accent,T.AccentDim,135)

                stroke(btn,T.AccentLight,1,0.5)

                ni("TextLabel",{
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1,
                    Text=c.Name or "Botón",
                    TextColor3=T.White,
                    Font=Enum.Font.GothamBold,
                    TextSize=13,
                },btn)

                btn.MouseButton1Click:Connect(function(x,y)
                    ripple(btn,x,y)
                    tw(btn,0.07,{Size=UDim2.new(0.98,0,0.9,0),Position=UDim2.new(0.01,0,0.05,0)})
                    task.delay(0.07,function()
                        tw(btn,0.25,{Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,0,0,0)},Enum.EasingStyle.Back)
                    end)
                    pcall(cb)
                end)
                btn.MouseEnter:Connect(function()
                    tw(btn,0.2,{BackgroundColor3=T.AccentLight})
                end)
                btn.MouseLeave:Connect(function()
                    tw(btn,0.2,{BackgroundColor3=T.Accent})
                end)

                local b={}
                function b:SetText(t) btn.Text=t end
                return b
            end

            -- ── SLIDER ──
            function sec:AddSlider(c)
                c=c or {}
                local min=c.Min or 0; local max=c.Max or 100
                local def=math.clamp(c.Default or min,min,max)
                local cb=c.Callback or function()end
                local suffix=c.Suffix or ""

                local wrap=ni("Frame",{
                    Size=UDim2.new(1,0,0,56),
                    BackgroundTransparency=1,
                    LayoutOrder=nxt(),
                },sFrame)

                ni("TextLabel",{
                    Size=UDim2.new(0.6,0,0,20),
                    BackgroundTransparency=1,
                    Text=c.Name or "Slider",
                    TextColor3=T.Text,
                    Font=Enum.Font.GothamMedium,
                    TextSize=13,
                    TextXAlignment=Enum.TextXAlignment.Left,
                },wrap)

                local valLbl=ni("TextLabel",{
                    Size=UDim2.new(0.4,0,0,20),
                    Position=UDim2.new(0.6,0,0,0),
                    BackgroundTransparency=1,
                    Text=tostring(def)..suffix,
                    TextColor3=T.AccentLight,
                    Font=Enum.Font.GothamBold,
                    TextSize=13,
                    TextXAlignment=Enum.TextXAlignment.Right,
                },wrap)

                -- Track bg
                local track=ni("Frame",{
                    Size=UDim2.new(1,0,0,8),
                    Position=UDim2.new(0,0,0,32),
                    BackgroundColor3=T.Surface,
                    BorderSizePixel=0,
                },wrap)
                corner(track,4)
                stroke(track,T.Border,1)

                local pct=(def-min)/(max-min)

                -- Fill con gradiente
                local fill=ni("Frame",{
                    Size=UDim2.new(pct,0,1,0),
                    BackgroundColor3=T.Accent,
                    BorderSizePixel=0,
                },track)
                corner(fill,4)
                gradient(fill,T.Accent,T.Cyan,0)

                -- Thumb
                local thumb=ni("Frame",{
                    Size=UDim2.new(0,18,0,18),
                    Position=UDim2.new(pct,-9,0.5,-9),
                    BackgroundColor3=T.White,
                    BorderSizePixel=0,
                    ZIndex=fill.ZIndex+1,
                },track)
                corner(thumb,9)
                stroke(thumb,T.Accent,2,0.3)

                local sld={Value=def}
                local dragging=false

                local function upd(ix)
                    local rel=math.clamp((ix-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                    local val=math.floor(min+rel*(max-min)+0.5)
                    sld.Value=val
                    valLbl.Text=tostring(val)..suffix
                    tw(fill,0.06,{Size=UDim2.new(rel,0,1,0)},Enum.EasingStyle.Linear)
                    tw(thumb,0.06,{Position=UDim2.new(rel,-9,0.5,-9)},Enum.EasingStyle.Linear)
                    pcall(cb,val)
                end

                local hit=ni("TextButton",{
                    Size=UDim2.new(1,0,0,34),
                    Position=UDim2.new(0,0,0.5,-17),
                    BackgroundTransparency=1,
                    Text="",
                    ZIndex=thumb.ZIndex+1,
                },track)

                hit.MouseButton1Down:Connect(function(x) dragging=true; upd(x) end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
                end)

                function sld:Set(v)
                    local r=math.clamp((v-min)/(max-min),0,1)
                    sld.Value=math.clamp(v,min,max)
                    valLbl.Text=tostring(sld.Value)..suffix
                    tw(fill,0.15,{Size=UDim2.new(r,0,1,0)})
                    tw(thumb,0.15,{Position=UDim2.new(r,-9,0.5,-9)})
                end

                return sld
            end

            -- ── DROPDOWN ──
            function sec:AddDropdown(c)
                c=c or {}
                local opts=c.Options or {}
                local cb=c.Callback or function()end
                local sel=c.Default or opts[1] or "—"

                local wrap=ni("Frame",{
                    Size=UDim2.new(1,0,0,38),
                    BackgroundTransparency=1,
                    LayoutOrder=nxt(),
                    ClipsDescendants=false,
                },sFrame)

                ni("TextLabel",{
                    Size=UDim2.new(0.42,0,1,0),
                    BackgroundTransparency=1,
                    Text=c.Name or "Dropdown",
                    TextColor3=T.Text,
                    Font=Enum.Font.GothamMedium,
                    TextSize=13,
                    TextXAlignment=Enum.TextXAlignment.Left,
                },wrap)

                local ddBtn=ni("TextButton",{
                    Size=UDim2.new(0.55,0,0,30),
                    Position=UDim2.new(0.45,0,0.5,-15),
                    BackgroundColor3=T.Surface,
                    Text="",
                    BorderSizePixel=0,
                    AutoButtonColor=false,
                },wrap)
                corner(ddBtn,7)
                stroke(ddBtn,T.Border,1)

                local selLbl=ni("TextLabel",{
                    Size=UDim2.new(1,-28,1,0),
                    Position=UDim2.new(0,10,0,0),
                    BackgroundTransparency=1,
                    Text=sel,
                    TextColor3=T.Text,
                    Font=Enum.Font.Gotham,
                    TextSize=12,
                    TextXAlignment=Enum.TextXAlignment.Left,
                },ddBtn)

                local arrow=ni("TextLabel",{
                    Size=UDim2.new(0,18,1,0),
                    Position=UDim2.new(1,-22,0,0),
                    BackgroundTransparency=1,
                    Text="▾",
                    TextColor3=T.TextSub,
                    Font=Enum.Font.GothamBold,
                    TextSize=14,
                },ddBtn)

                -- Menu
                local menu=ni("Frame",{
                    Size=UDim2.new(0.55,0,0,0),
                    Position=UDim2.new(0.45,0,1,6),
                    BackgroundColor3=T.Surface,
                    BorderSizePixel=0,
                    ZIndex=20,
                    ClipsDescendants=true,
                    Visible=false,
                },wrap)
                corner(menu,8)
                stroke(menu,T.BorderLight,1)
                list(menu,2)
                pad(menu,4,4,4,4)

                local th=#opts*30+8
                local isOpen=false
                local dd={Value=sel}

                for _,opt in ipairs(opts) do
                    local item=ni("TextButton",{
                        Size=UDim2.new(1,0,0,28),
                        BackgroundColor3=T.Surface,
                        Text=opt,
                        TextColor3=T.Text,
                        Font=Enum.Font.Gotham,
                        TextSize=12,
                        BorderSizePixel=0,
                        AutoButtonColor=false,
                        ZIndex=21,
                    },menu)
                    corner(item,6)

                    item.MouseEnter:Connect(function()
                        tw(item,0.12,{BackgroundColor3=T.Card})
                        tw(item,0.12,{TextColor3=T.AccentLight})
                    end)
                    item.MouseLeave:Connect(function()
                        tw(item,0.12,{BackgroundColor3=T.Surface})
                        tw(item,0.12,{TextColor3=T.Text})
                    end)
                    item.MouseButton1Click:Connect(function()
                        dd.Value=opt; selLbl.Text=opt
                        isOpen=false; menu.Visible=false
                        tw(menu,0.2,{Size=UDim2.new(0.55,0,0,0)})
                        tw(arrow,0.2,{Rotation=0})
                        pcall(cb,opt)
                    end)
                end

                ddBtn.MouseButton1Click:Connect(function()
                    isOpen=not isOpen
                    menu.Visible=true
                    tw(menu,0.28,{Size=isOpen and UDim2.new(0.55,0,0,th) or UDim2.new(0.55,0,0,0)},Enum.EasingStyle.Back)
                    tw(arrow,0.2,{Rotation=isOpen and 180 or 0})
                    if not isOpen then task.delay(0.3,function() menu.Visible=false end) end
                end)

                function dd:Set(v) dd.Value=v; selLbl.Text=v end
                return dd
            end

            -- ── INPUT ──
            function sec:AddInput(c)
                c=c or {}
                local cb=c.Callback or function()end

                local wrap=ni("Frame",{
                    Size=UDim2.new(1,0,0,38),
                    BackgroundTransparency=1,
                    LayoutOrder=nxt(),
                },sFrame)

                ni("TextLabel",{
                    Size=UDim2.new(0.38,0,1,0),
                    BackgroundTransparency=1,
                    Text=c.Name or "Input",
                    TextColor3=T.Text,
                    Font=Enum.Font.GothamMedium,
                    TextSize=13,
                    TextXAlignment=Enum.TextXAlignment.Left,
                },wrap)

                local box=ni("TextBox",{
                    Size=UDim2.new(0.59,0,0,30),
                    Position=UDim2.new(0.41,0,0.5,-15),
                    BackgroundColor3=T.Surface,
                    PlaceholderText=c.Placeholder or "Escribir...",
                    PlaceholderColor3=T.TextDim,
                    Text=c.Default or "",
                    TextColor3=T.Text,
                    Font=Enum.Font.Gotham,
                    TextSize=12,
                    BorderSizePixel=0,
                    ClearTextOnFocus=false,
                },wrap)
                corner(box,7)
                pad(box,0,0,10,10)
                local st=stroke(box,T.Border,1)

                box.Focused:Connect(function()
                    tw(st,0.2,{Color=T.Accent,Transparency=0})
                    tw(box,0.2,{BackgroundColor3=T.Card})
                end)
                box.FocusLost:Connect(function(e)
                    tw(st,0.2,{Color=T.Border})
                    tw(box,0.2,{BackgroundColor3=T.Surface})
                    if e then pcall(cb,box.Text) end
                end)

                local inp={Value=box.Text}
                function inp:Set(v) box.Text=v; inp.Value=v end
                function inp:Get() return box.Text end
                return inp
            end

            -- ── LABEL ──
            function sec:AddLabel(c)
                c=c or {}
                local lbl=ni("TextLabel",{
                    Size=UDim2.new(1,0,0,c.Size and c.Size+4 or 20),
                    BackgroundTransparency=1,
                    Text=c.Text or "",
                    TextColor3=c.Color or T.TextSub,
                    Font=c.Bold and Enum.Font.GothamBold or Enum.Font.Gotham,
                    TextSize=c.Size or 12,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    TextWrapped=true,
                    LayoutOrder=nxt(),
                },sFrame)
                local l={}
                function l:Set(t) lbl.Text=t end
                function l:SetColor(col) lbl.TextColor3=col end
                return l
            end

            -- ── DIVIDER ──
            function sec:AddDivider()
                local div=ni("Frame",{
                    Size=UDim2.new(1,0,0,1),
                    BackgroundColor3=T.Border,
                    BorderSizePixel=0,
                    LayoutOrder=nxt(),
                },sFrame)
                gradient(div,T.Accent,Color3.fromRGB(20,23,32),0)
            end

            table.insert(tab._sections,sec)
            return sec
        end

        return tab
    end

    -- ── NOTIFY
    function win:Notify(cfg)
        cfg=cfg or {}
        local nf=ni("Frame",{
            Size=UDim2.new(0,260,0,70),
            Position=UDim2.new(1,280,1,-82),
            BackgroundColor3=T.Card,
            BorderSizePixel=0,
            ZIndex=100,
        },gui)
        corner(nf,11)
        stroke(nf,T.Accent,1,0.3)
        gradient(nf,Color3.fromRGB(26,28,40),Color3.fromRGB(20,22,32),135)

        -- Barra izquierda de color
        local bar=ni("Frame",{
            Size=UDim2.new(0,3,0.65,0),
            Position=UDim2.new(0,10,0.175,0),
            BackgroundColor3=cfg.Color or T.Accent,
            BorderSizePixel=0,
            ZIndex=101,
        },nf)
        corner(bar,2)

        ni("TextLabel",{
            Size=UDim2.new(1,-28,0,24),
            Position=UDim2.new(0,22,0,10),
            BackgroundTransparency=1,
            Text=cfg.Title or "Notificación",
            TextColor3=T.Text,
            Font=Enum.Font.GothamBold,
            TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=101,
        },nf)

        ni("TextLabel",{
            Size=UDim2.new(1,-28,0,20),
            Position=UDim2.new(0,22,0,34),
            BackgroundTransparency=1,
            Text=cfg.Content or "",
            TextColor3=T.TextSub,
            Font=Enum.Font.Gotham,
            TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=101,
        },nf)

        tw(nf,0.45,{Position=UDim2.new(1,-272,1,-82)},Enum.EasingStyle.Back)
        task.delay(cfg.Duration or 3,function()
            tw(nf,0.3,{Position=UDim2.new(1,280,1,-82),BackgroundTransparency=0.5})
            task.delay(0.35,function() nf:Destroy() end)
        end)
    end

    function win:Destroy() gui:Destroy() end
    return win
end

return Nexus
