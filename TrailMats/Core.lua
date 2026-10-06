local addon,T=...
_G.TrailMats=T
local frame=CreateFrame("Frame")
T.eventFrame=frame
local pending,scanPending,announcePending=false,false,false
local lastArea

function T.Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd27fTrailMats:|r "..message) end
end

function T.Refresh(scan,announce)
    if not T.saved then return end
    T.ReadSkills();T.ReadZone()
    if scan then T.ScanRecipes() end
    T.ReadMerchant()
    T.plan=T.BuildPlan()
    T.Render();T.MarkMerchant()
    local key=T.area~=0 and T.area or T.zoneName
    if announce and key~=lastArea then
        lastArea=key
        if T.saved.announce then
            T.Print(T.zoneName..": /tm shows each profession's departure advice. Next zone: "..T.destinationNames[T.plan.destination]..".")
        end
    end
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
    if command=="refresh" then T.ConnectDatabase();T.Refresh(true,false)
    elseif command=="quiet" then T.saved.announce=not T.saved.announce;T.Print("Zone notices "..(T.saved.announce and "on." or "off."))
    elseif command=="tips" then T.saved.tooltips=not T.saved.tooltips;T.Print("Tooltips "..(T.saved.tooltips and "on." or "off."))
    elseif command=="auto" then T.saved.destinations={};T.saved.selected={};T.Refresh(false,false);T.Print("Default destinations restored.")
    elseif command=="status" then
        T.Print("v0.3.0 | "..T.zoneName.." | QuestieDB "..(T.qdb and "connected" or "unavailable").." | departure advice")
        for _,id in ipairs(T.order) do local s=T.skills[id];if s then T.Print(T.professions[id].name.." "..s.rank.."/"..s.cap..(T.saved.scanned[id] and " (recipes read)" or "")) end end
    elseif command=="help" then
        T.Print("/tm opens TrailMats. Choose a profession tab. Open that profession once to find learned recipes that still give skill.")
        T.Print("Check the Next zone button; click it to change the destination. Assumed routes are labeled.")
        T.Print("Easy opportunities are optional batches of 1, 3 or 5 crafts. Hover sources for evidence. Vendor hints show actual stock and price; buy or craft yourself only if you want to.")
        T.Print("Reference means not verified on this Forever character; Not assessed means no reviewed rule. /tm quiet toggles zone notices; /tm tips toggles tooltips.")
    else
        T.saved.hidden=T.window:IsShown()
        T.window:SetShown(not T.saved.hidden)
    end
end

frame:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" then
        if name~=addon then return end
        _G.TrailMatsDB=type(_G.TrailMatsDB)=="table" and _G.TrailMatsDB or {}
        T.saved=_G.TrailMatsDB
        for _,key in ipairs({"recipes","selected","observed","scanned","destinations"}) do
            if type(T.saved[key])~="table" then T.saved[key]={} end
        end
        if T.saved.announce==nil then T.saved.announce=true end
        if T.saved.tooltips==nil then T.saved.tooltips=true end
        if T.saved.batch~=1 and T.saved.batch~=3 and T.saved.batch~=5 then T.saved.batch=3 end
        T.ConnectDatabase();T.ReadSkills();T.ReadZone();T.CreateWindow();T.InstallTooltips();T.InstallMerchantHook()
        _G.SLASH_TRAILMATS1="/tm";_G.SLASH_TRAILMATS2="/trailmats"
        SlashCmdList.TRAILMATS=T.Command
    elseif event=="PLAYER_LOGIN" then
        C_Timer.After(2,function() T.ConnectDatabase();T.Refresh(true,true) end)
    elseif event=="MERCHANT_SHOW" then
        T.merchantOpen=true;T.InstallMerchantHook();T.Queue(false,false)
    elseif event=="MERCHANT_CLOSED" then
        T.merchantOpen=false;T.merchantStock={};T.MarkMerchant();T.Queue(false,false)
    elseif event=="LOOT_READY" or event=="LOOT_OPENED" then
        if T.saved then T.ObserveLoot();T.Queue(false,false) end
    else
        local scan=event=="TRADE_SKILL_SHOW" or event=="TRADE_SKILL_UPDATE" or event=="NEW_RECIPE_LEARNED"
        local zone=event=="ZONE_CHANGED_NEW_AREA" or event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED"
        T.Queue(scan,zone)
    end
end)
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED",
    "SKILL_LINES_CHANGED","BAG_UPDATE_DELAYED","TRADE_SKILL_SHOW","TRADE_SKILL_UPDATE","NEW_RECIPE_LEARNED","LOOT_READY","LOOT_OPENED","MERCHANT_SHOW","MERCHANT_UPDATE","MERCHANT_CLOSED"}) do
    pcall(frame.RegisterEvent,frame,event)
end
