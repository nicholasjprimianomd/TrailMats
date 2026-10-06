local _, T = ...
local gold="|cffffd27f"
local muted="|cffb6c2cc"
local function button(parent,text,width,click)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,24);b:SetText(text);b:SetScript("OnClick",click)
    return b
end
local function label(parent,font,width)
    local f=parent:CreateFontString(nil,"OVERLAY",font)
    f:SetWidth(width);f:SetJustifyH("LEFT");f:SetJustifyV("TOP");return f
end
function T.ScrollBy(amount)
    local f=T.window
    local limit=math.max(0,(f.content:GetHeight() or 0)-(f.scroll:GetHeight() or 0))
    f.scroll:SetVerticalScroll(math.max(0,math.min(limit,(f.scroll:GetVerticalScroll() or 0)+amount)))
end
function T.CreateWindow()
    if T.window then return end
    local f=CreateFrame("Frame","TrailMatsWindow",UIParent,"BackdropTemplate")
    T.window=f;f:SetSize(480,510)
    f:SetPoint("CENTER",UIParent,"CENTER",T.saved.x or 300,T.saved.y or 0)
    f:SetClampedToScreen(true);f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing();local x,y=self:GetCenter();local px,py=UIParent:GetCenter()
        T.saved.x=x-px;T.saved.y=y-py
    end)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(0.035,0.055,0.065,0.98);f:SetBackdropBorderColor(0.35,0.47,0.46,1)
    f.title=label(f,"GameFontNormalLarge",350);f.title:SetPoint("TOPLEFT",16,-14);f.title:SetText("TrailMats")
    f.close=button(f,"Close",55,function() T.saved.hidden=true;f:Hide() end);f.close:SetPoint("TOPRIGHT",-12,-10)
    f.zone=label(f,"GameFontHighlight",444);f.zone:SetPoint("TOPLEFT",16,-40)
    f.destination=button(f,"Next zone",444,function() T.ChangeDestination() end);f.destination:SetPoint("TOPLEFT",16,-62)
    f.tabs={}
    for _,id in ipairs(T.tabOrder) do
        local prof=id
        f.tabs[id]=button(f,T.professions[id].name,id==165 and 140 or 100,function() T.SelectProfession(prof);T.window.scroll:SetVerticalScroll(0) end)
    end
    f.scroll=CreateFrame("ScrollFrame",nil,f);f.scroll:SetPoint("TOPLEFT",16,-159);f.scroll:SetPoint("BOTTOMRIGHT",-16,73)
    f.scroll:EnableMouseWheel(true);f.scroll:SetScript("OnMouseWheel",function(_,delta) T.ScrollBy(-delta*60) end)
    f.content=CreateFrame("Frame",nil,f.scroll);f.content:SetSize(444,1);f.scroll:SetScrollChild(f.content)
    f.rows={}
    f.help=button(f,"Help",50,function() T.Command("help") end);f.help:SetPoint("BOTTOMLEFT",14,37)
    f.refresh=button(f,"Refresh",70,function() T.Command("refresh") end);f.refresh:SetPoint("LEFT",f.help,"RIGHT",5,0)
    f.batch=button(f,"Batch: 3",78,function() T.CycleBatch() end);f.batch:SetPoint("LEFT",f.refresh,"RIGHT",5,0)
    f.up=button(f,"Scroll up",90,function() T.ScrollBy(-160) end);f.up:SetPoint("LEFT",f.batch,"RIGHT",5,0)
    f.down=button(f,"Scroll down",97,function() T.ScrollBy(160) end);f.down:SetPoint("LEFT",f.up,"RIGHT",5,0)
    f.footer=label(f,"GameFontDisableSmall",444);f.footer:SetPoint("BOTTOMLEFT",16,10)
    f.footer:SetText("Optional suggestions. Skill-ups and drops vary. Bags only.")
    if T.saved.hidden then f:Hide() end
end
function T.MaterialSource(m)
    if m.vendor then return "Basic vendor supply" end
    if m.missing==0 then return "Already in your bags" end
    local water=T.water[T.area] and T.water[T.area][m.item]
    if water then return "Fish in "..water.." (reference)" end
    local list=T.GetSources(m.item).areas[T.area]
    if list and list[1] then return list[1].name.." (source reference)" end
    return "No local source recorded"
end
function T.Render()
    if not T.window or not T.plan then return end
    local f=T.window;local selected=T.SelectedProfession()
    f.zone:SetText("While questing in "..T.zoneName)
    local assumed=T.plan.assumed and T.plan.destination~=0 and " (assumed)" or ""
    f.destination:SetText("Next zone: "..T.destinationNames[T.plan.destination]..assumed.." - change")
    f.batch:SetText("Batch: "..(T.saved.batch or 3))
    local x,y=0,97
    for _,id in ipairs(T.tabOrder) do
        local b=f.tabs[id]
        if T.skills[id] then
            local width=id==165 and 140 or 100
            if x+width>444 then x=0;y=y+29 end
            b:ClearAllPoints();b:SetPoint("TOPLEFT",16+x,-y)
            b:SetText((id==selected and gold or "")..T.professions[id].name..(id==selected and "|r" or ""));b:Show();x=x+width+6
        else b:Hide() end
    end
    for _,r in ipairs(f.rows) do r:Hide();if r.action then r.action:Hide() end end
    local index,height=0,0
    local function row(text,detail,actionText,click)
        index=index+1;local r=f.rows[index]
        if not r then
            r=CreateFrame("Frame",nil,f.content);r:SetWidth(444);r:EnableMouse(true)
            r.label=label(r,"GameFontHighlight",442);r.label:SetPoint("TOPLEFT");f.rows[index]=r
        end
        r:ClearAllPoints();r:SetPoint("TOPLEFT",0,-height);r.label:SetText(text)
        local h=math.max(18,r.label:GetStringHeight() or 18)+12
        if click then
            if not r.action then r.action=button(r,actionText,140,nil) end
            r.action:SetText(actionText);r.action:ClearAllPoints();r.action:SetPoint("TOPLEFT",0,-h)
            r.action:SetScript("OnClick",click);r.action:Show();h=h+30
        end
        r:SetScript("OnEnter",function(self)
            if detail then GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:AddLine(detail,0.85,0.9,0.9,true);GameTooltip:Show() end
        end)
        r:SetScript("OnLeave",function() GameTooltip:Hide() end)
        r:SetHeight(h);r:Show();height=height+h
    end
    local d=selected and T.plan.professions[selected]
    if not d then row("Learn a profession, then press Refresh.")
    else
        local skill=T.skills[selected]
        row(gold..T.professions[selected].name.."|r  Skill "..skill.rank.." / "..skill.cap)
        local colour=d.state=="ready" and "|cff88d99d" or gold
        row("Before leaving: "..colour..d.status.."|r",d.goal.."\n"..d.reason.."\n"..d.action.."\n"..d.evidence,"Departure details",function()
            T.saved.departureDetails=not T.saved.departureDetails;T.Render()
        end)
        if T.saved.departureDetails then row(d.goal.."\n"..d.reason.."\n"..muted..d.action.."\n"..d.evidence.."|r") end
        local op=T.plan.opportunities[selected]
        if T.professions[selected].craft then
            row(gold.."AN EASY OPTION HERE|r")
            if op then
                local click=#T.plan.alternatives[selected]>1 and function() T.CycleRecipe(selected) end or nil
                row("Try "..op.batch.." crafts of "..gold..op.name.."|r\n"..muted..op.why.."|r",
                    "This is an optional small batch, not a required shopping list or a promise of one skill point per craft.","Another recipe",click)
                for _,m in ipairs(op.materials) do
                    row(T.ItemName(m.item).."\n".."In bags: "..m.have.."   For this batch: "..m.need.."   Collect: "..m.missing.."\n"..muted..T.MaterialSource(m).."|r",
                        m.perCraft.." per craft of "..op.name..". "..T.SourceText(m.item,3).." No fixed kill count is known.")
                end
                local suggestions=T.CurrentMerchantSuggestions()
                if #suggestions>0 then
                    row(gold.."AT THIS VENDOR|r")
                    for _,v in ipairs(suggestions) do row(T.MerchantText(v),"Actual price and stock at this merchant. No purchase is made automatically.") end
                end
            elseif skill.rank>=skill.cap then row("Train the next rank to keep gaining skill. No extra materials suggested while capped.")
            else row("Open "..T.professions[selected].name.." to read recipes at your current skill.\nIf no option appears, there is no usable recipe with recorded local ingredients or enough in your bags.") end
        elseif selected==393 then
            row(gold.."WHILE YOU QUEST|r\nSkin eligible beasts you already defeat. Keep useful leather; no kill quota.","Check the corpse's Skinning requirement. Classic references do not establish Forever skin loot.")
        elseif selected==356 then
            row(gold.."WHILE YOU QUEST|r\n"..((T.zones[T.area] and T.zones[T.area].water) or "No water reference for this zone yet.").."\nKeep fish for recipes you know; no catch quota.")
        end
    end
    f.content:SetHeight(math.max(1,height));T.ScrollBy(0)
end
function T.AddNPCTooltip(tooltip,unit)
    if not T.plan or not T.saved.tooltips then return end
    local npc=T.NPCFromGUID(T.Safe(UnitGUID,unit or "mouseover"));local id=T.SelectedProfession()
    local key=tostring(npc)..":"..tostring(id)
    if not npc or tooltip.trailMatsNPC==key then return end
    tooltip.trailMatsNPC=key;local added=false
    if id==393 then
        local source=T.GetSources(2318).npcs[npc]
        if source then
            tooltip:AddLine("TrailMats / Skinning: check this beast for useful leather.",1,0.82,0.5,true)
            tooltip:AddLine(source.evidence..". The corpse's actual Skinning requirement takes priority.",0.7,0.7,0.7,true)
            added=true
        end
    end
    for _,m in ipairs(T.CurrentMaterials()) do
        local source=T.GetSources(m.item).npcs[npc]
        if m.missing>0 and source then
            tooltip:AddLine("TrailMats: collect "..m.missing.." "..T.ItemName(m.item).." for "..T.CurrentOpportunity().name,1,0.82,0.5,true)
            tooltip:AddLine(source.evidence..". Kills vary; no reliable kill estimate.",0.7,0.7,0.7,true);added=true
        end
    end
    if added then tooltip:Show() end
end
function T.AddItemTooltip(tooltip)
    if not T.plan or not T.saved.tooltips then return end
    local _,link=tooltip:GetItem();local item=link and tonumber(link:match("item:(%d+)"));local id=T.SelectedProfession()
    local key=tostring(item)..":"..tostring(id)
    if not item or tooltip.trailMatsItem==key then return end
    for _,m in ipairs(T.CurrentMaterials()) do
        if m.item==item then
            tooltip.trailMatsItem=key
            tooltip:AddLine("TrailMats: collect "..m.missing.." more for "..T.CurrentOpportunity().batch.." crafts of "..T.CurrentOpportunity().name,1,0.82,0.5,true)
            for _,v in ipairs(T.CurrentMerchantSuggestions()) do if v.item==item then tooltip:AddLine(T.MerchantText(v),0.8,0.9,0.8,true) end end
            tooltip:Show();return
        end
    end
end
function T.InstallTooltips()
    if not GameTooltip then return end
    GameTooltip:HookScript("OnTooltipCleared",function(t) t.trailMatsNPC=nil;t.trailMatsItem=nil end)
    local unitHook=pcall(GameTooltip.HookScript,GameTooltip,"OnTooltipSetUnit",function(t) local _,unit=t:GetUnit();T.AddNPCTooltip(t,unit) end)
    local itemHook=pcall(GameTooltip.HookScript,GameTooltip,"OnTooltipSetItem",T.AddItemTooltip)
    if TooltipDataProcessor and Enum and Enum.TooltipDataType then
        if not unitHook and Enum.TooltipDataType.Unit then TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,function(t) if t==GameTooltip then local _,unit=t:GetUnit();T.AddNPCTooltip(t,unit) end end) end
        if not itemHook and Enum.TooltipDataType.Item then TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item,function(t) if t==GameTooltip then T.AddItemTooltip(t) end end) end
    end
end
