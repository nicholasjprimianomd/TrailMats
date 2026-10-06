local _, T = ...
local gold="|cffffd27f"
local muted="|cffb6c2cc"
local green="|cff88d99d"
local width=456
local tabWidths={[165]=128,[393]=82,[356]=76,[185]=80,[129]=86}
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
    f.scrollHint:SetText(limit>0 and "Scroll for more" or "")
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
    f.title=label(f.drag,"GameFontNormalLarge",350);f.title:SetPoint("TOPLEFT",18,-14);f.title:SetText("TrailMats")
    f.close=button(f,"Close",55,function() T.saved.hidden=true;f:Hide() end);f.close:SetPoint("TOPRIGHT",-14,-10)
    f.zone=label(f,"GameFontHighlight",204);f.zone:SetPoint("TOPLEFT",18,-43)
    f.destination=button(f,"Next zone",264,function() T.ChangeDestination() end);f.destination:SetPoint("TOPRIGHT",-18,-36)
    f.tabs={}
    for _,id in ipairs(T.tabOrder) do
        local prof=id
        f.tabs[id]=button(f,T.professions[id].name,tabWidths[id],function() T.SelectProfession(prof) end)
    end
    f.overview=button(f,"Now",74,function() T.saved.view="overview";T.Render() end)
    f.keep=button(f,"Keep",74,function() T.saved.view="keep";T.Render() end)
    f.leveling=button(f,"Plan",74,function() T.saved.view="leveling";T.Render() end)
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
    f.help=button(f,"Help",74,function() T.Command("help") end)
    f.refresh=button(f,"Refresh",74,function() T.Command("refresh") end);f.refresh:SetPoint("BOTTOMLEFT",18,35)
    f.batch=button(f,"Batch: 3",84,function() T.CycleBatch() end);f.batch:SetPoint("LEFT",f.refresh,"RIGHT",6,0)
    f.prices=button(f,"Prices",84,function() f.planPage=f.planPage=="prices" and "materials" or "prices";T.Render() end);f.prices:SetPoint("LEFT",f.refresh,"RIGHT",6,0)
    f.track=button(f,"Track",74,function() T.ToggleTracker() end);f.track:SetPoint("LEFT",f.batch,"RIGHT",6,0)
    f.scrollHint=label(f,"GameFontDisableSmall",200);f.scrollHint:SetPoint("BOTTOMRIGHT",-18,40);f.scrollHint:SetJustifyH("RIGHT")
    f.footer=label(f,"GameFontDisableSmall",484);f.footer:SetPoint("BOTTOMLEFT",18,12)
    f.footer:SetText("Hover for details  |  * Guide source")
    f:SetScript("OnShow",function() T.Render() end)
    if T.saved.hidden then f:Hide() end
end
function T.MaterialSource(m)
    if m.vendor then return "Vendor" end
    if m.missing==0 then return "In bags" end
    return T.ZoneSource(m.item) or "No local source"
end
function T.CreateTracker()
    if T.tracker then return end
    local f=CreateFrame("Frame","TrailMatsTracker",UIParent,"BackdropTemplate")
    T.tracker=f;f:SetSize(340,80)
    f:SetPoint("CENTER",UIParent,"CENTER",T.saved.trackX or -300,T.saved.trackY or 100)
    f:SetClampedToScreen(true);f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(0.035,0.055,0.065,0.92);f:SetBackdropBorderColor(0.35,0.47,0.46,1)
    f:SetScript("OnDragStart",function() f:StartMoving() end)
    f:SetScript("OnDragStop",function()
        f:StopMovingOrSizing();local x,y=f:GetCenter();local px,py=UIParent:GetCenter()
        T.saved.trackX=x-px;T.saved.trackY=y-py
    end)
    f.title=label(f,"GameFontNormalSmall",262);f.title:SetPoint("TOPLEFT",10,-10)
    f.action=label(f,"GameFontHighlight",320);f.action:SetPoint("TOPLEFT",10,-32)
    f.lines={}
    for i=1,3 do
        f.lines[i]=label(f,"GameFontHighlightSmall",320)
    end
    f.zone=label(f,"GameFontDisableSmall",255);f.zone:SetPoint("BOTTOMLEFT",10,10)
    f.close=button(f,"Hide",50,function() T.saved.trackProfession=nil;T.RenderTracker();T.Render() end)
    f.close:SetPoint("TOPRIGHT",-6,-4)
    f.open=button(f,"Open",50,function()
        if T.saved.trackProfession then T.SelectProfession(T.saved.trackProfession) end
        T.saved.view="overview";T.saved.hidden=false;T.window:Show();T.Render()
    end);f.open:SetPoint("BOTTOMRIGHT",-6,4)
    f:SetScript("OnEnter",function()
        GameTooltip:SetOwner(f,"ANCHOR_RIGHT");GameTooltip:AddLine(f.detail or "",0.85,0.9,0.9,true);GameTooltip:Show()
    end)
    f:SetScript("OnLeave",function() GameTooltip:Hide() end)
    f:Hide()
end
function T.Render()
    if not T.window or not T.plan or not T.window:IsShown() then return end
    local f=T.window;local selected=T.SelectedProfession()
    local view=T.saved.view
    local keep=view=="keep";local leveling=view=="leveling";local help=view=="help"
    f.activeKey=tostring(selected)..":"..view..(leveling and (":"..(f.planPage or "materials")) or "")
    local scroll=f.positions[f.activeKey] or 0
    f.activeProfession=selected
    f.zone:SetText(T.zoneName)
    f.destination:SetText("Next: "..T.destinationNames[T.plan.destination]..(T.plan.assumed and " (auto)" or ""))
    f.batch:SetText("Batch: "..(T.saved.batch or 3))
    f.batch:SetShown(not leveling and not help and (keep or (selected and T.professions[selected].craft) or false))
    f.prices:SetShown(leveling and selected and T.professions[selected].craft or false)
    f.prices:SetText(f.planPage=="prices" and "Materials" or "Prices")
    f.track:SetShown(not help and selected~=nil)
    f.track:SetText(T.saved.trackProfession==selected and "Untrack" or "Track")
    local x,y=0,72
    for _,id in ipairs(T.tabOrder) do
        local b=f.tabs[id]
        if T.skills[id] then
            local w=tabWidths[id]
            if x+w>484 then x=0;y=y+29 end
            b:ClearAllPoints();b:SetPoint("TOPLEFT",18+x,-y)
            b:SetText((id==selected and gold or "")..T.professions[id].name..(id==selected and "|r" or ""))
            if id==selected then b:LockHighlight() else b:UnlockHighlight() end
            b:Show();x=x+w+6
        else b:Hide() end
    end
    f.overview:ClearAllPoints();f.overview:SetPoint("TOPLEFT",18,-y-32)
    f.keep:ClearAllPoints();f.keep:SetPoint("LEFT",f.overview,"RIGHT",6,0)
    f.leveling:ClearAllPoints();f.leveling:SetPoint("LEFT",f.keep,"RIGHT",6,0)
    f.help:ClearAllPoints();f.help:SetPoint("LEFT",f.leveling,"RIGHT",6,0)
    for name,b in pairs({overview=f.overview,keep=f.keep,leveling=f.leveling,help=f.help}) do
        if view==name then b:LockHighlight() else b:UnlockHighlight() end
    end
    y=y+32
    local skill=selected and T.skills[selected]
    f.skill:ClearAllPoints();f.skill:SetPoint("TOPLEFT",18,-y-34)
    f.skill:SetText(skill and (T.professions[selected].name.."   "..skill.rank.." / "..skill.cap..
        (skill.rank>=skill.cap and skill.rank<300 and "   |cffffd27fTrain next rank|r" or "")) or "No professions")
    f.progress:ClearAllPoints();f.progress:SetPoint("TOPLEFT",18,-y-56)
    f.progress:SetMinMaxValues(0,skill and math.max(1,skill.cap) or 1);f.progress:SetValue(skill and skill.rank or 0)
    f.scroll:ClearAllPoints();f.scroll:SetPoint("TOPLEFT",18,-y-76);f.scroll:SetPoint("BOTTOMRIGHT",-46,72)
    for _,r in ipairs(f.rows) do
        r:Hide();if r.action then r.action:Hide() end
        if r.value then r.value:Hide() end;if r.icon then r.icon:Hide() end
    end
    local index,height=0,0
    local function row(text,detail,actionText,click,options)
        options=options or {};index=index+1;local r=f.rows[index]
        if not r then
            r=CreateFrame("Frame",nil,f.content);r:SetWidth(width);r:EnableMouse(true);r:EnableMouseWheel(true)
            r:SetScript("OnMouseWheel",function(_,delta) T.ScrollBy(-delta*48) end)
            r.label=label(r,"GameFontHighlight",width-16)
            r.background=r:CreateTexture(nil,"BACKGROUND");r.background:SetAllPoints()
            r:SetScript("OnEnter",function(self)
                local detail=type(self.detail)=="function" and self.detail() or self.detail
                if detail then GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:AddLine(detail,0.85,0.9,0.9,true);GameTooltip:Show() end
            end)
            r:SetScript("OnLeave",function() GameTooltip:Hide() end)
            f.rows[index]=r
        end
        local left=options.item and 40 or 8
        local right=(options.value or click) and 114 or 8
        r.detail=detail;r:ClearAllPoints();r:SetPoint("TOPLEFT",0,-height)
        r.label:ClearAllPoints();r.label:SetPoint("TOPLEFT",left,-6);r.label:SetWidth(width-left-right);r.label:SetText(text)
        r.background:SetColorTexture(0.12,0.18,0.19,options.heading and 0 or index%2==1 and 0.55 or 0.22)
        local h=math.max(18,r.label:GetStringHeight() or 18)+12
        if options.item then
            if not r.icon then r.icon=r:CreateTexture(nil,"ARTWORK");r.icon:SetPoint("TOPLEFT",8,-6);r.icon:SetSize(24,24) end
            r.icon:SetTexture(T.Safe(C_Item and C_Item.GetItemIconByID,options.item) or T.Safe(GetItemIcon,options.item) or "Interface\\Icons\\INV_Misc_QuestionMark")
            r.icon:Show();h=math.max(h,36)
        end
        if options.value then
            if not r.value then r.value=label(r,"GameFontHighlight",104);r.value:SetPoint("TOPRIGHT",-8,-6);r.value:SetJustifyH("RIGHT") end
            r.value:SetText(options.value);r.value:Show();h=math.max(h,(r.value:GetStringHeight() or 18)+12)
        end
        if click then
            if not r.action then r.action=button(r,actionText,100,nil);r.action:SetPoint("TOPRIGHT",-8,-6) end
            r.action:SetText(actionText);r.action:SetScript("OnClick",click);r.action:Show();h=math.max(h,36)
            r.action:SetScript("OnEnter",function() if r.detail then
                local detail=type(r.detail)=="function" and r.detail() or r.detail
                GameTooltip:SetOwner(r.action,"ANCHOR_RIGHT");GameTooltip:AddLine(detail,0.85,0.9,0.9,true);GameTooltip:Show()
            end end)
            r.action:SetScript("OnLeave",function() GameTooltip:Hide() end)
        end
        r:SetHeight(h);r:Show();height=height+h+3
    end
    local function heading(text,detail) row(gold..text.."|r",detail,nil,nil,{heading=true}) end
    local d=selected and T.plan.professions[selected]
    if help then T.RenderHelp(row)
    elseif not d then row("Learn a profession, then Refresh.")
    elseif leveling then T.RenderLeveling(selected,row,f.planPage or "materials")
    elseif keep then
        local profession=T.FutureProfession(selected)
        local future=T.plan.future and T.plan.future.byProfession[profession] or {}
        heading("Keep for "..T.professions[profession].name,"Keep enough for one batch. Other uses may exist; this is not a sell list.")
        if not T.skills[profession] then row("Learn "..T.professions[profession].name.." first.")
        elseif #future==0 then row("Nothing to set aside yet.","No held materials match the supported recipes at your skill. Unlisted items may still be useful.")
        else
            for _,use in ipairs(future) do
                local detail=use;local c,m=use.recipe,use.material
                row(T.ItemName(use.item).."\n"..muted..c.name.."  "..c.low.."-"..c.high.."|r",
                    function()
                        local text=T.FutureText(detail).."\n"..T.FutureDetail(detail)
                        for i=2,math.min(#detail.uses,4) do local r=detail.uses[i].recipe;text=text.."\nAlso: "..r.name.." ("..r.low.."-"..r.high.."). "..r.recipeStatus.."." end
                        return text
                    end,nil,nil,{item=use.item,value="Keep "..math.min(m.have,m.need).."\nof "..m.have})
            end
        end
    else
        local action=T.NextAction(selected)
        local op=T.plan.opportunities[selected]
        local change=op and #T.plan.alternatives[selected]>1 and function() T.CycleRecipe(selected) end or nil
        row(gold..action.text.."|r",(action.detail or "")..(op and ("\nBatch: "..op.batch.." crafts. Skill-ups are not guaranteed.\n"..op.why) or ""),"Change",change,{heading=true})
        if op then
            for _,m in ipairs(op.materials) do
                local mat=m
                row(T.ItemName(m.item).."\n"..muted..T.MaterialSource(m).."|r",
                    function() return mat.perCraft.." per craft. "..T.SourceText(mat.item,3).."\nNeed "..mat.need.."; bags "..mat.have.."; missing "..mat.missing.."." end,
                    nil,nil,{item=m.item,value=m.have.." / "..m.need.."\n"..(m.missing==0 and green.."Ready|r" or "Need "..m.missing)})
            end
            local offers=T.CurrentMerchantSuggestions()
            if #offers>0 then heading("At this vendor") end
            for _,v in ipairs(offers) do
                row(T.ItemName(v.item),T.MerchantText(v),nil,nil,{item=v.item,value=v.amount.." for\n"..T.Money(v.cost)})
            end
        end
        local needs=T.ZoneNeeds(selected)
        if #needs.here>0 then
            heading("This zone (est.)", "Missing materials for "..T.professions[needs.profession].name.." "..needs.target..". Totals are estimates; follow the recipe order in Plan.")
            for i=1,math.min(3,#needs.here) do
                local m=needs.here[i]
                row(T.ItemName(m.item).."\n"..muted..m.source.."|r",m.detail.."\nFor skill "..needs.target.." (estimated).",nil,nil,{item=m.item,value="Need "..m.missing})
            end
            if #needs.here>3 then row((#needs.here-3).." more materials",nil,"Plan",function() T.saved.view="leveling";f.planPage="materials";T.Render() end) end
        elseif not T.professions[selected].craft then
            row(selected==356 and "Keep your catch for Cooking." or "Keep leather for Leatherworking.","No missing materials with a recorded local source for the current plan.")
        end
        local state=d.state=="ready" and "Skill OK *" or d.state=="not_yet" and "Low base skill *" or "Not checked"
        local advice=T.RangeAdvice(selected,T.plan.destination)
        row("Next zone: "..state,d.reason.."\n"..d.action.."\n"..d.evidence..
            (advice and ("\n\n"..advice.title.."\n"..advice.text.."\n"..(advice.note or "").."\n"..(advice.detail or "")) or ""))
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
