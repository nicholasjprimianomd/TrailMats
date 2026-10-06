local _, T = ...
local gold="|cffffd27f"
local muted="|cffb6c2cc"
local green="|cff88d99d"
local width=456
local function button(parent,text,w,click)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(w,24);b:SetText(text);b:SetScript("OnClick",click)
    return b
end
local function label(parent,font,w)
    local f=parent:CreateFontString(nil,"OVERLAY",font)
    f:SetWidth(w);f:SetJustifyH("LEFT");f:SetJustifyV("TOP");return f
end
function T.ScrollBy(amount)
    local f=T.window
    local limit=math.max(0,f.content:GetHeight()-f.scroll:GetHeight())
    f.scrollbar:SetValue(math.max(0,math.min(limit,f.scroll:GetVerticalScroll()+amount)))
end
function T.SyncScroll(value)
    local f=T.window
    local limit=math.max(0,f.content:GetHeight()-f.scroll:GetHeight())
    f.syncing=true
    f.scrollbar:SetMinMaxValues(0,limit)
    value=math.max(0,math.min(limit,value or f.scroll:GetVerticalScroll()))
    f.scrollbar:SetValue(value);f.scroll:SetVerticalScroll(value)
    local viewport=math.max(1,f.scroll:GetHeight())
    f.scrollbar:GetThumbTexture():SetHeight(math.max(24,math.min(viewport,viewport*viewport/math.max(viewport,f.content:GetHeight()))))
    f.scrollbar:SetShown(limit>0)
    f.scrollHint:SetText(limit>0 and "Mouse wheel or drag the scrollbar" or "All details visible")
    if f.activeKey then f.positions[f.activeKey]=value end
    f.syncing=false
end
function T.CreateWindow()
    if T.window then return end
    local f=CreateFrame("Frame","TrailMatsWindow",UIParent,"BackdropTemplate")
    T.window=f;f:SetSize(520,600);f.positions={}
    f:SetPoint("CENTER",UIParent,"CENTER",T.saved.x or 300,T.saved.y or 0)
    f:SetClampedToScreen(true);f:SetMovable(true);f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(0.035,0.055,0.065,0.98);f:SetBackdropBorderColor(0.35,0.47,0.46,1)
    f.drag=CreateFrame("Frame",nil,f);f.drag:SetPoint("TOPLEFT");f.drag:SetPoint("TOPRIGHT",-78,0);f.drag:SetHeight(38)
    f.drag:EnableMouse(true);f.drag:RegisterForDrag("LeftButton")
    f.drag:SetScript("OnDragStart",function() f:StartMoving() end)
    f.drag:SetScript("OnDragStop",function()
        f:StopMovingOrSizing();local x,y=f:GetCenter();local px,py=UIParent:GetCenter()
        T.saved.x=x-px;T.saved.y=y-py
    end)
    f.title=label(f.drag,"GameFontNormalLarge",350);f.title:SetPoint("TOPLEFT",18,-14);f.title:SetText("TrailMats  |cffb6c2cc0.6.0|r")
    f.close=button(f,"Close",55,function() T.saved.hidden=true;f:Hide() end);f.close:SetPoint("TOPRIGHT",-14,-10)
    f.zone=label(f,"GameFontHighlight",484);f.zone:SetPoint("TOPLEFT",18,-42)
    f.destination=button(f,"Next zone",484,function() T.ChangeDestination() end);f.destination:SetPoint("TOPLEFT",18,-65)
    f.tabs={}
    for _,id in ipairs(T.tabOrder) do
        local prof=id
        f.tabs[id]=button(f,T.professions[id].name,id==165 and 140 or 100,function() T.SelectProfession(prof) end)
    end
    f.overview=button(f,"Overview",110,function() T.saved.view="overview";T.Render() end)
    f.keep=button(f,"Keep for later",140,function() T.saved.view="keep";T.Render() end)
    f.leveling=button(f,"Leveling mats",146,function() T.saved.view="leveling";T.Render() end)
    f.skill=label(f,"GameFontHighlight",484)
    f.progress=CreateFrame("StatusBar",nil,f);f.progress:SetSize(484,6)
    f.progress:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");f.progress:SetStatusBarColor(0.36,0.72,0.59)
    local bg=f.progress:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(0.13,0.19,0.21,1)
    f.scroll=CreateFrame("ScrollFrame",nil,f);f.scroll:SetPoint("BOTTOMRIGHT",-46,72)
    f.scroll:EnableMouseWheel(true);f.scroll:SetScript("OnMouseWheel",function(_,delta) T.ScrollBy(-delta*48) end)
    f.content=CreateFrame("Frame",nil,f.scroll);f.content:SetSize(width,1);f.scroll:SetScrollChild(f.content)
    f.scrollbar=CreateFrame("Slider",nil,f,"BackdropTemplate")
    f.scrollbar:SetOrientation("VERTICAL");f.scrollbar:SetWidth(14)
    f.scrollbar:SetPoint("TOPLEFT",f.scroll,"TOPRIGHT",12,0);f.scrollbar:SetPoint("BOTTOMLEFT",f.scroll,"BOTTOMRIGHT",12,0)
    f.scrollbar:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});f.scrollbar:SetBackdropColor(0.12,0.18,0.20,1)
    f.scrollbar:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb=f.scrollbar:GetThumbTexture();thumb:SetSize(12,36);thumb:SetVertexColor(0.56,0.73,0.69,1)
    f.scrollbar:SetMinMaxValues(0,0);f.scrollbar:SetValueStep(1);f.scrollbar:EnableMouseWheel(true)
    f.scrollbar:SetScript("OnMouseWheel",function(_,delta) T.ScrollBy(-delta*48) end)
    f.scrollbar:SetScript("OnValueChanged",function(_,value)
        if f.syncing then return end
        f.scroll:SetVerticalScroll(value)
        if f.activeKey then f.positions[f.activeKey]=value end
    end)
    f.rows={}
    f.help=button(f,"Help",52,function() T.Command("help") end);f.help:SetPoint("BOTTOMLEFT",18,35)
    f.refresh=button(f,"Refresh",74,function() T.Command("refresh") end);f.refresh:SetPoint("LEFT",f.help,"RIGHT",6,0)
    f.batch=button(f,"Batch: 3",84,function() T.CycleBatch() end);f.batch:SetPoint("LEFT",f.refresh,"RIGHT",6,0)
    f.prices=button(f,"Prices",84,function() f.showPrices=not f.showPrices;T.Render() end);f.prices:SetPoint("LEFT",f.refresh,"RIGHT",6,0)
    f.scrollHint=label(f,"GameFontDisableSmall",240);f.scrollHint:SetPoint("BOTTOMRIGHT",-18,40);f.scrollHint:SetJustifyH("RIGHT")
    f.footer=label(f,"GameFontDisableSmall",484);f.footer:SetPoint("BOTTOMLEFT",18,12)
    f.footer:SetText("Optional goals  |  Bag inventory  |  Hover for sources")
    f:SetScript("OnShow",function() T.Render() end)
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
    if not T.window or not T.plan or not T.window:IsShown() then return end
    local f=T.window;local selected=T.SelectedProfession()
    local keep=T.saved.view=="keep"
    local leveling=T.saved.view=="leveling"
    f.activeKey=tostring(selected)..":"..T.saved.view..(leveling and f.showPrices and ":prices" or "")
    local scroll=f.positions[f.activeKey] or 0
    f.activeProfession=selected
    f.zone:SetText(T.zoneName.."  |  Profession companion")
    local assumed=T.plan.assumed and T.plan.destination~=0 and " (assumed)" or ""
    f.destination:SetText("Next: "..T.destinationNames[T.plan.destination]..assumed.."  - click to change")
    f.batch:SetText("Batch: "..(T.saved.batch or 3))
    f.batch:SetShown(not leveling and (keep or (selected and T.professions[selected].craft) or false))
    f.prices:SetShown(leveling and selected and T.professions[selected].craft or false)
    f.prices:SetText(f.showPrices and "Materials" or "Prices")
    local x,y=0,101
    for _,id in ipairs(T.tabOrder) do
        local b=f.tabs[id]
        if T.skills[id] then
            local w=id==165 and 140 or 100
            if x+w>484 then x=0;y=y+29 end
            b:ClearAllPoints();b:SetPoint("TOPLEFT",18+x,-y)
            b:SetText((id==selected and gold or "")..T.professions[id].name..(id==selected and "|r" or ""))
            if id==selected then b:LockHighlight() else b:UnlockHighlight() end
            b:Show();x=x+w+6
        else b:Hide() end
    end
    f.overview:ClearAllPoints();f.overview:SetPoint("TOPLEFT",18,-y-32)
    f.keep:ClearAllPoints();f.keep:SetPoint("LEFT",f.overview,"RIGHT",8,0)
    f.leveling:ClearAllPoints();f.leveling:SetPoint("LEFT",f.keep,"RIGHT",8,0)
    for view,b in pairs({overview=f.overview,keep=f.keep,leveling=f.leveling}) do
        if T.saved.view==view then b:LockHighlight() else b:UnlockHighlight() end
    end
    y=y+32
    local skill=selected and T.skills[selected]
    f.skill:ClearAllPoints();f.skill:SetPoint("TOPLEFT",18,-y-34)
    f.skill:SetText(skill and (T.professions[selected].name.."   "..skill.rank.." / "..skill.cap..(skill.rank>=skill.cap and "   |cffffd27fTraining needed|r" or "")) or "No professions learned")
    f.progress:ClearAllPoints();f.progress:SetPoint("TOPLEFT",18,-y-56)
    f.progress:SetMinMaxValues(0,skill and math.max(1,skill.cap) or 1);f.progress:SetValue(skill and skill.rank or 0)
    f.scroll:ClearAllPoints();f.scroll:SetPoint("TOPLEFT",18,-y-76);f.scroll:SetPoint("BOTTOMRIGHT",-46,72)
    for _,r in ipairs(f.rows) do r:Hide();if r.action then r.action:Hide() end end
    local index,height=0,0
    local function row(text,detail,actionText,click)
        index=index+1;local r=f.rows[index]
        if not r then
            r=CreateFrame("Frame",nil,f.content);r:SetWidth(width);r:EnableMouse(true);r:EnableMouseWheel(true)
            r:SetScript("OnMouseWheel",function(_,delta) T.ScrollBy(-delta*48) end)
            r.label=label(r,"GameFontHighlight",width-16);r.label:SetPoint("TOPLEFT",8,-6)
            r.background=r:CreateTexture(nil,"BACKGROUND");r.background:SetAllPoints()
            r:SetScript("OnEnter",function(self)
                local detail=type(self.detail)=="function" and self.detail() or self.detail
                if detail then GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:AddLine(detail,0.85,0.9,0.9,true);GameTooltip:Show() end
            end)
            r:SetScript("OnLeave",function() GameTooltip:Hide() end)
            f.rows[index]=r
        end
        r.detail=detail;r:ClearAllPoints();r:SetPoint("TOPLEFT",0,-height);r.label:SetText(text)
        r.background:SetColorTexture(0.12,0.18,0.19,index%2==1 and 0.65 or 0.3)
        local h=math.max(18,r.label:GetStringHeight() or 18)+14
        if click then
            if not r.action then r.action=button(r,actionText,144,nil) end
            r.action:SetText(actionText);r.action:ClearAllPoints();r.action:SetPoint("TOPLEFT",8,-h)
            r.action:SetScript("OnClick",click);r.action:Show();h=h+30
        end
        r:SetHeight(h);r:Show();height=height+h+5
    end
    local d=selected and T.plan.professions[selected]
    if not d then row("Learn a profession, then press Refresh.")
    elseif leveling then T.RenderLeveling(selected,row,f.showPrices)
    elseif keep then
        local profession=T.FutureProfession(selected)
        local future=T.plan.future and T.plan.future.byProfession[profession] or {}
        row(gold.."KEEP FOR LATER |r"..T.professions[profession].name..
            "\nRecipes you can learn later. Best matches to your bags come first.\n"..muted..
            "Targets cover one optional batch. Shared recipe options are not added together.|r")
        if not T.skills[profession] then
            row("Learn "..T.professions[profession].name.." to plan uses for these gathered materials.")
        elseif #future==0 then
            row("No held materials match the reviewed basic recipes at your skill. Hover new fish or loot for keep advice.\n"..
                muted.."Coverage is limited to early foods, leather recipes and bandages. An unlisted item may still be useful.|r")
        else
            for _,use in ipairs(future) do
                local detail=use
                row(gold..T.ItemName(use.item).."|r\n"..T.FutureText(use)..
                    (#use.uses>1 and ("\n"..muted..(#use.uses-1).." other reviewed use(s); hover for alternatives.|r") or ""),
                    function()
                        local text=T.FutureDetail(detail)
                        for i=2,math.min(#detail.uses,4) do
                            local c=detail.uses[i].recipe
                            text=text.."\nAlso: "..c.name.." ("..c.low.."-"..c.high.."). "..c.recipeStatus.."."
                        end
                        return text
                    end)
            end
        end
        row(muted.."Bag inventory only. Keep targets are a starting reserve, not a limit or a sell recommendation.\nOpen your profession to update which recipes are learned.|r")
    else
        local advice=T.RangeAdvice(selected,T.plan.destination)
        if advice then
            row(gold..advice.title.."|r\n"..advice.text..(advice.note and ("\n"..muted..advice.note.."|r") or ""),advice.detail)
        end
        if skill.rank>=skill.cap then row(gold.."Train the next profession rank|r\nYou are at your trained cap. Train before crafting for more skill.") end
        local colour=d.state=="ready" and green or gold
        row("Before leaving: "..colour..d.status.."|r\n"..muted..d.goal.."|r",d.reason.."\n"..d.action.."\n"..d.evidence,
            T.saved.departureDetails and "Hide departure details" or "Departure details",function()
                T.saved.departureDetails=not T.saved.departureDetails;T.Render()
            end)
        if T.saved.departureDetails then row(d.reason.."\n"..d.action.."\n"..muted..d.evidence.."|r") end
        local op=T.plan.opportunities[selected]
        if T.professions[selected].craft then
            row(gold.."CRAFTING OPPORTUNITY|r")
            if op then
                local click=#T.plan.alternatives[selected]>1 and function() T.CycleRecipe(selected) end or nil
                local band=T.recipeBands[op.id]
                local range=band and ("\nReviewed recipe range: "..band[1].."-"..band[2]..(skill.rank>=band[2] and " (past recommended range)" or skill.rank<band[1] and " (below recommended range)" or "")) or "\nNumeric recipe range not reviewed."
                row("Try "..op.batch.." crafts of "..gold..op.name.."|r\n"..muted..op.why..range.."|r",
                    "Ranges are recommendations. The live recipe color determines current skill-up viability. A batch counts crafts, not guaranteed skill points.","Another recipe",click)
                for _,m in ipairs(op.materials) do
                    local status=m.missing==0 and (green.."Ready in bags|r") or (gold.."Collect "..m.missing.."|r")
                    row(T.ItemName(m.item).."   "..status.."\n".."Have "..m.have.." / Need "..m.need.."   |   "..muted..T.MaterialSource(m).."|r",
                        function() return m.perCraft.." per craft of "..op.name..". "..T.SourceText(m.item,3).." No fixed kill count is known." end)
                end
                local suggestions=T.CurrentMerchantSuggestions()
                if #suggestions>0 then
                    row(gold.."AT THIS VENDOR|r")
                    for _,v in ipairs(suggestions) do row(T.MerchantText(v),"Actual price and stock at this merchant.") end
                end
            elseif skill.rank>=skill.cap then row("No crafting batch while skill is capped.")
            else row("Open "..T.professions[selected].name.." to refresh learned recipes.\nNo usable recipe with enough bag materials or recorded local sources is currently available.") end
        elseif selected==393 then
            row(gold.."WHILE YOU QUEST|r\nSkin eligible beasts you already defeat. Keep useful leather; no kill quota.","Check the corpse's Skinning requirement. Classic references do not establish Forever skin loot.")
        elseif selected==356 then
            row(gold.."WHILE YOU QUEST|r\n"..((T.zones[T.area] and T.zones[T.area].water) or "No water reference for this zone yet.").."\nKeep fish for recipes you know; no catch quota.")
        end
    end
    f.content:SetHeight(math.max(1,height));T.SyncScroll(scroll)
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
    tooltip.trailMatsItem=key
    local added=T.AddKeepTooltip(tooltip,item)
    for _,m in ipairs(T.CurrentMaterials()) do
        if m.item==item then
            tooltip:AddLine("TrailMats current batch: "..m.missing.." more for "..T.CurrentOpportunity().batch.." crafts of "..T.CurrentOpportunity().name,1,0.82,0.5,true)
            for _,v in ipairs(T.CurrentMerchantSuggestions()) do if v.item==item then tooltip:AddLine(T.MerchantText(v),0.8,0.9,0.8,true) end end
            added=true;break
        end
    end
    if added then tooltip:Show() end
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
