local _, T = ...
local muted="|cffb6c2cc"

-- Bindings.xml refers to these names in the game's Key Bindings list.
_G.BINDING_HEADER_TRAILMATS="TrailMats"
_G.BINDING_NAME_TRAILMATS_TOGGLE="Open or close TrailMats"
_G.BINDING_NAME_TRAILMATS_TRACK="Pin or unpin the tracker"
_G.BINDING_NAME_TRAILMATS_OPTIONS="Open TrailMats settings"

-- Shared by every character. Recipes, prices, positions and the selected tab stay per character.
T.defaults={announce=true,tooltips=true,craftNotices=true,trainReminder=true,sound=false,follow=true,
    lockTracker=false,scale=1,trackerScale=1,minimap={hide=false,angle=220},
    auctionCut=0.05,neutralAuctionHouse=false,recordPrices=true}

local function fill(target,source)
    for key,value in pairs(source) do
        if type(value)=="table" then
            if type(target[key])~="table" then target[key]={} end
            fill(target[key],value)
        elseif target[key]==nil then target[key]=value end
    end
end

local function clamp(value,low,high,default)
    value=tonumber(value) or default
    return math.max(low,math.min(high,value))
end

function T.LoadSettings()
    _G.TrailMatsSettings=type(_G.TrailMatsSettings)=="table" and _G.TrailMatsSettings or {}
    T.settings=_G.TrailMatsSettings
    -- Before 0.11.0 these two were saved per character; the first character to log in brings them along.
    if T.settings.announce==nil and T.saved.announce~=nil then T.settings.announce=T.saved.announce end
    if T.settings.tooltips==nil and T.saved.tooltips~=nil then T.settings.tooltips=T.saved.tooltips end
    T.saved.announce=nil;T.saved.tooltips=nil
    fill(T.settings,T.defaults)
    T.settings.scale=clamp(T.settings.scale,0.5,2,1)
    T.settings.trackerScale=clamp(T.settings.trackerScale,0.5,2,1)
    T.settings.minimap.angle=clamp(T.settings.minimap.angle,-360,360,T.defaults.minimap.angle)
end

function T.ApplySettings()
    local s=T.settings
    if T.window then T.window:SetScale(s.scale) end
    if T.tracker then T.tracker:SetScale(s.trackerScale) end
    if T.minimapButton then T.minimapButton:SetShown(not s.minimap.hide);T.UpdateMinimapButton() end
    if T.options and T.options:IsShown() then T.options.refresh() end
end

function T.ResetSettings()
    for key in pairs(T.settings) do T.settings[key]=nil end
    fill(T.settings,T.defaults);T.ApplySettings()
end

function T.ResetPositions()
    T.saved.x,T.saved.y,T.saved.trackX,T.saved.trackY=nil,nil,nil,nil
    T.settings.minimap.angle=T.defaults.minimap.angle
    if T.window then T.window:ClearAllPoints();T.window:SetPoint("CENTER",UIParent,"CENTER",300,0) end
    if T.tracker then T.tracker:ClearAllPoints();T.tracker:SetPoint("CENTER",UIParent,"CENTER",-300,100) end
    T.ApplySettings()
end

local function tooltip(frame,detail)
    frame:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:AddLine(detail,0.85,0.9,0.9,true);GameTooltip:Show() end)
    frame:SetScript("OnLeave",function() GameTooltip:Hide() end)
end

local function checkbox(panel,x,y,text,detail,get,set)
    local b=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate")
    b:SetSize(26,26);b:SetPoint("TOPLEFT",x,y)
    b.label=panel:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    b.label:SetPoint("LEFT",b,"RIGHT",4,0);b.label:SetText(text)
    b.get=get
    b:SetScript("OnClick",function(self) set(self:GetChecked() and true or false);T.ApplySettings() end)
    tooltip(b,detail)
    return b
end

local function slider(panel,y,text,detail,low,high,step,get,set)
    local s=CreateFrame("Slider",nil,panel,"BackdropTemplate")
    s.slider=true;s:SetOrientation("HORIZONTAL");s:SetSize(220,12);s:SetPoint("TOPLEFT",20,y-22)
    s:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});s:SetBackdropColor(0.12,0.18,0.20,1)
    s:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb=s:GetThumbTexture();thumb:SetSize(10,18);thumb:SetVertexColor(0.56,0.73,0.69,1)
    s:SetMinMaxValues(low,high);s:SetValueStep(step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s.label=panel:CreateFontString(nil,"OVERLAY","GameFontHighlight");s.label:SetPoint("TOPLEFT",20,y-2);s.label:SetText(text)
    s.readout=panel:CreateFontString(nil,"OVERLAY","GameFontHighlight");s.readout:SetPoint("LEFT",s,"RIGHT",10,0)
    s.get=get
    s:SetScript("OnValueChanged",function(self,value)
        value=math.floor(value/step+0.5)*step
        self.readout:SetText(math.floor(value*100+0.5).."%")
        if self.syncing then return end
        set(value);T.ApplySettings()
    end)
    tooltip(s,detail)
    return s
end

function T.CreateOptions()
    if T.options then return end
    local panel=CreateFrame("Frame","TrailMatsOptions",UIParent)
    panel.name="TrailMats";panel:Hide();T.options=panel
    local title=panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",16,-16);title:SetText("TrailMats "..muted..T.version.."|r")
    local intro=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT",16,-40);intro:SetWidth(560);intro:SetJustifyH("LEFT")
    intro:SetText("These settings apply to all your characters. Recipes, prices, the selected tab and window positions stay per character.")
    panel.controls={}
    local y=-68
    local function add(c) panel.controls[#panel.controls+1]=c;return c end
    -- Checkboxes fill two columns so the page fits the game's settings canvas.
    local column=0
    local function slot() local x,row=column==0 and 14 or 296,y;column=1-column;if column==0 then y=y-28 end;return x,row end
    local function flag(text,detail,key)
        local x,row=slot()
        add(checkbox(panel,x,row,text,detail,function() return T.settings[key] end,function(v) T.settings[key]=v end))
    end
    local x,row=slot()
    add(checkbox(panel,x,row,"Show the minimap button","Left-click opens TrailMats. Right-click pins the tracker. Shift-click opens these settings. Drag it around the minimap.",
        function() return not T.settings.minimap.hide end,function(v) T.settings.minimap.hide=not v end))
    flag("Zone notices in chat","One line when you enter a new zone, with the /tm reminder.","announce")
    flag("Item and creature hints in tooltips","Shows how many more of an item the current recipe needs, and which creatures have a database source.","tooltips")
    flag("Crafting notices","Says when your bags cover the whole target for the current recipe, and when a skill-up means it is time to switch recipes.","craftNotices")
    flag("Training reminders","Once per login when a profession reaches its trained skill cap.","trainReminder")
    flag("Play a sound with crafting notices","Uses the ready-check sound.","sound")
    flag("Switch tabs to the profession you open","Opening a crafting window selects that profession's tab in TrailMats.","follow")
    flag("Lock the tracker position","Stops the pinned tracker from being dragged by accident.","lockTracker")
    flag("Record prices while browsing","Keeps the lowest unit buyout of every auction house page you view. The Scan prices button works either way.","recordPrices")
    flag("Neutral auction house (15% cut)","Use the neutral auction house cut for profit and value figures. Opening the auction house in Tanaris, Stranglethorn Vale or Winterspring sets this for the session on its own.","neutralAuctionHouse")
    if column==1 then y=y-28 end
    y=y-6
    add(slider(panel,y,"Window scale","Size of the main window.",0.7,1.3,0.05,function() return T.settings.scale end,function(v) T.settings.scale=v end));y=y-56
    add(slider(panel,y,"Tracker scale","Size of the pinned tracker.",0.7,1.5,0.05,function() return T.settings.trackerScale end,function(v) T.settings.trackerScale=v end));y=y-56
    add(slider(panel,y,"Auction house cut","Share of each sale kept by the auction house in profit and value figures. Faction houses take 5%; the neutral option above overrides this with 15%.",0,0.2,0.01,function() return T.settings.auctionCut end,function(v) T.settings.auctionCut=v end));y=y-56
    local function action(text,x,click)
        local b=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
        b:SetSize(130,24);b:SetText(text);b:SetPoint("TOPLEFT",x,y);b:SetScript("OnClick",click);return b
    end
    panel.open=action("Open TrailMats",16,function() T.Command("") end)
    panel.positions=action("Reset positions",152,function() T.ResetPositions() end)
    panel.defaults=action("Default settings",288,function() T.ResetSettings() end)
    y=y-34
    local commands=panel:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    commands:SetPoint("TOPLEFT",16,y);commands:SetWidth(560);commands:SetJustifyH("LEFT")
    commands:SetText("/tm opens or closes the window. /tm options opens this page. /tm track pins the tracker. /tm minimap shows or hides the button. /tm help lists everything. Key bindings are under Key Bindings > AddOns.")
    function panel.refresh()
        for _,c in ipairs(panel.controls) do
            if c.slider then c.syncing=true;c:SetValue(c.get());c.syncing=false
            else c:SetChecked(c.get() and true or false) end
        end
    end
    panel:SetScript("OnShow",panel.refresh)
    panel.OnRefresh=panel.refresh;panel.OnDefault=T.ResetSettings
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok,category=pcall(Settings.RegisterCanvasLayoutCategory,panel,"TrailMats")
        if ok and category then
            if category.ID==nil then category.ID="TrailMats" end
            pcall(Settings.RegisterAddOnCategory,category);T.optionsCategory=category
        end
    elseif InterfaceOptions_AddCategory then pcall(InterfaceOptions_AddCategory,panel) end
end

function T.OpenOptions()
    T.CreateOptions()
    if T.optionsCategory and Settings and Settings.OpenToCategory then
        local id=T.optionsCategory.GetID and T.optionsCategory:GetID() or T.optionsCategory.ID
        if pcall(Settings.OpenToCategory,id) then return end
    end
    if InterfaceOptionsFrame_OpenToCategory then
        -- Older option frames land on the wrong page the first time; the second call corrects it.
        pcall(InterfaceOptionsFrame_OpenToCategory,T.options);pcall(InterfaceOptionsFrame_OpenToCategory,T.options);return
    end
    T.Print("Open the game menu, then Options > AddOns > TrailMats.")
end
