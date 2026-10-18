local addon,T=...
_G.TrailMats=T
T.version="0.11.0"
local frame=CreateFrame("Frame")
T.eventFrame=frame
local pending,scanPending,announcePending=false,false,false
local lastZone

function T.Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd27fTrailMats:|r "..message) end
end

function T.Refresh(scan,announce)
    if not T.saved then return end
    T.ReadSkills();T.ReadZone()
    if scan then T.ScanRecipes() end
    if T.followPending then
        T.followPending=nil
        if T.settings.follow and T.skills[T.lastScanned] then T.saved.profession=T.lastScanned end
    end
    T.ReadMerchant()
    T.plan=T.BuildPlan()
    T.Render();T.RenderTracker();T.MarkMerchant()
    -- Loading screens have no zone yet, and an area ID can arrive after its name; neither is a new zone.
    if announce and T.zoneKnown and T.zoneName~=lastZone then
        lastZone=T.zoneName
        if T.settings.announce then
            T.Print(T.zoneName.." | /tm")
        end
    end
    T.CheckNotices()
end

function T.Queue(scan,announce)
    scanPending=scanPending or scan
    announcePending=announcePending or announce
    if pending then return end
    pending=true
    C_Timer.After(0.25,function()
        pending=false
        local s,a=scanPending,announcePending
        scanPending=false;announcePending=false
        T.Refresh(s,a)
    end)
end

function T.Command(command)
    command=(command or ""):lower():match("^%s*(.-)%s*$")
    if command=="" then
        T.saved.hidden=T.window:IsShown()
        T.window:SetShown(not T.saved.hidden)
    elseif command=="refresh" then T.ConnectDatabase();T.Refresh(true,false)
    elseif command=="keep" or command=="mats" or command=="now" or command=="help" or command=="sell" then
        T.saved.view=command=="mats" and "leveling" or command=="now" and "overview" or command
        T.saved.hidden=false;T.window:Show();T.Render()
    elseif command=="track" then T.ToggleTracker()
    elseif command=="options" or command=="settings" or command=="config" then T.OpenOptions()
    elseif command=="minimap" then
        T.settings.minimap.hide=not T.settings.minimap.hide;T.ApplySettings()
        T.Print("Minimap button "..(T.settings.minimap.hide and "hidden." or "shown."))
    elseif command=="quiet" then T.settings.announce=not T.settings.announce;T.ApplySettings();T.Print("Zone notices "..(T.settings.announce and "on." or "off."))
    elseif command=="tips" then T.settings.tooltips=not T.settings.tooltips;T.ApplySettings();T.Print("Tooltips "..(T.settings.tooltips and "on." or "off."))
    elseif command=="auto" then T.saved.destinations={};T.saved.selected={};T.Refresh(false,false);T.Print("Default destinations restored.")
    elseif command=="status" then
        T.Print("v"..T.version.." | "..T.zoneName.." | QuestieDB "..(T.qdb and "connected" or "unavailable"))
        for _,id in ipairs(T.order) do local s=T.skills[id];if s then T.Print(T.professions[id].name.." "..s.rank.."/"..s.cap..(T.saved.scanned[id] and " (recipes read)" or "")) end end
    else T.Print("Unknown command \""..command.."\". /tm help lists the commands.") end
end

frame:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" then
        if name~=addon then return end
        _G.TrailMatsDB=type(_G.TrailMatsDB)=="table" and _G.TrailMatsDB or {}
        T.saved=_G.TrailMatsDB
        for _,key in ipairs({"recipes","selected","observed","scanned","destinations"}) do
            if type(T.saved[key])~="table" then T.saved[key]={} end
        end
        if type(T.saved.levelingPrices)~="table" then T.saved.levelingPrices={} end
        if T.saved.view~="overview" and T.saved.view~="keep" and T.saved.view~="leveling" and T.saved.view~="sell" and T.saved.view~="help" then T.saved.view="overview" end
        T.LoadSettings()
        T.ConnectDatabase();T.ReadSkills();T.ReadZone();T.CreateWindow();T.CreateTracker();T.InstallTooltips();T.InstallMerchantHook()
        T.CreateMinimapButton();T.CreateOptions();T.ApplySettings()
        _G.SLASH_TRAILMATS1="/tm";_G.SLASH_TRAILMATS2="/trailmats"
        SlashCmdList.TRAILMATS=T.Command
    elseif event=="PLAYER_LOGIN" then
        C_Timer.After(2,function() T.ConnectDatabase();T.Refresh(true,true);T.Welcome() end)
    elseif event=="MERCHANT_SHOW" then
        T.merchantOpen=true;T.InstallMerchantHook();T.Queue(false,false)
    elseif event=="MERCHANT_CLOSED" then
        T.merchantOpen=false;T.merchantStock={};T.MarkMerchant();T.Queue(false,false)
    elseif event=="LOOT_READY" or event=="LOOT_OPENED" then
        if T.saved then T.Queue(false,false) end
    else
        local scan=event=="TRADE_SKILL_SHOW" or event=="TRADE_SKILL_UPDATE" or event=="CRAFT_SHOW" or event=="CRAFT_UPDATE" or event=="NEW_RECIPE_LEARNED" or event=="SKILL_LINES_CHANGED"
        local zone=event=="ZONE_CHANGED_NEW_AREA" or event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED"
        if event=="TRADE_SKILL_SHOW" or event=="CRAFT_SHOW" then T.followPending=true end
        T.Queue(scan,zone)
    end
end)
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED",
    "SKILL_LINES_CHANGED","BAG_UPDATE_DELAYED","TRADE_SKILL_SHOW","TRADE_SKILL_UPDATE","CRAFT_SHOW","CRAFT_UPDATE","NEW_RECIPE_LEARNED","LOOT_READY","LOOT_OPENED","MERCHANT_SHOW","MERCHANT_UPDATE","MERCHANT_CLOSED"}) do
    pcall(frame.RegisterEvent,frame,event)
end
