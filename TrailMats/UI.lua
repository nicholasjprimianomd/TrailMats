local _, T = ...
local gold="|cffffd27f"
local muted="|cffb6c2cc"
local green="|cff88d99d"
local width=456
local tabWidths={[165]=128,[393]=82,[356]=76,[185]=80,[129]=86}
local function tabWidth(id) return tabWidths[id] or math.max(60,16+8*#T.professions[id].name) end
-- Row colours by what the player must do: the accent strip, the action line and the bar share one.
local states={collect={0.36,0.72,0.59},buy={1,0.82,0.5},prepare={0.95,0.62,0.35},ready={0.53,0.85,0.62},keep={0.56,0.65,0.73}}
local function tint(c) return string.format("|cff%02x%02x%02x",math.floor(c[1]*255+0.5),math.floor(c[2]*255+0.5),math.floor(c[3]*255+0.5)) end
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
-- Offsets from the screen centre in the frame's own scale, so SetPoint restores them at any scale.
function T.Offsets(f)
    local x,y=f:GetCenter();local px,py=UIParent:GetCenter();local s=f:GetScale() or 1
    return x-px/s,y-py/s
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
    f.drag:SetScript("OnDragStop",function() f:StopMovingOrSizing();T.saved.x,T.saved.y=T.Offsets(f) end)
    f.title=label(f.drag,"GameFontNormalLarge",350);f.title:SetPoint("TOPLEFT",18,-14);f.title:SetText("TrailMats "..muted..T.version.."|r")
    f.close=button(f,"Close",55,function() T.saved.hidden=true;f:Hide() end);f.close:SetPoint("TOPRIGHT",-14,-10)
    f.zone=label(f,"GameFontHighlight",484);f.zone:SetPoint("TOPLEFT",18,-43)
    f.tabs={}
    for _,id in ipairs(T.tabOrder) do
        local prof=id
        f.tabs[id]=button(f,T.professions[id].name,tabWidth(id),function() T.SelectProfession(prof) end)
    end
    f.overview=button(f,"Next step",94,function() T.saved.view="overview";T.Render() end)
    f.keep=button(f,"Materials",94,function() T.saved.view="keep";T.Render() end)
    f.leveling=button(f,"Plan",74,function() T.saved.view="leveling";T.Render() end)
    f.sell=button(f,"Sell",60,function() T.saved.view="sell";T.Render() end)
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
    f.prices=button(f,"Prices",84,function() f.planPage=f.planPage=="prices" and "materials" or "prices";T.Render() end);f.prices:SetPoint("LEFT",f.refresh,"RIGHT",6,0)
    f.track=button(f,"Track",74,function() T.ToggleTracker() end);f.track:SetPoint("LEFT",f.refresh,"RIGHT",6,0)
    f.options=button(f,"Options",74,function() T.OpenOptions() end);f.options:SetPoint("BOTTOMRIGHT",-14,35)
    f.scrollHint=label(f,"GameFontDisableSmall",200);f.scrollHint:SetPoint("RIGHT",f.options,"LEFT",-8,0);f.scrollHint:SetJustifyH("RIGHT")
    f.footer=label(f,"GameFontDisableSmall",484);f.footer:SetPoint("BOTTOMLEFT",18,12)
    f.footer:SetText("Hover for the recipe and source  |  Counts are estimates")
    f:SetScript("OnShow",function() T.Render() end)
    -- Escape hides the frame itself; a hidden parent (cinematics) must not count as closing it.
    f:SetScript("OnHide",function(self) if not self:IsShown() then T.saved.hidden=true end end)
    if UISpecialFrames then table.insert(UISpecialFrames,"TrailMatsWindow") end
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
    f:SetScript("OnDragStart",function() if not T.settings.lockTracker then f:StartMoving() end end)
    f:SetScript("OnDragStop",function() f:StopMovingOrSizing();T.saved.trackX,T.saved.trackY=T.Offsets(f) end)
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
    local keep=view=="keep";local leveling=view=="leveling";local sell=view=="sell";local help=view=="help"
    f.activeKey=tostring(selected)..":"..view..(leveling and (":"..(f.planPage or "materials")) or "")
    local scroll=f.positions[f.activeKey] or 0
    f.activeProfession=selected
    f.zone:SetText(T.zoneName)
    f.track:ClearAllPoints();f.track:SetPoint("LEFT",leveling and selected and T.professions[selected].craft and f.prices or f.refresh,"RIGHT",6,0)
    f.prices:SetShown(leveling and selected and T.professions[selected].craft or false)
    f.prices:SetText(f.planPage=="prices" and "Materials" or "Prices")
    f.track:SetShown(not help and selected~=nil)
    f.track:SetText(T.saved.trackProfession==selected and "Unpin" or "Pin")
    local x,y=0,72
    for _,id in ipairs(T.tabOrder) do
        local b=f.tabs[id]
        if T.skills[id] then
            local w=tabWidth(id)
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
    f.sell:ClearAllPoints();f.sell:SetPoint("LEFT",f.leveling,"RIGHT",6,0)
    f.help:ClearAllPoints();f.help:SetPoint("LEFT",f.sell,"RIGHT",6,0)
    for name,b in pairs({overview=f.overview,keep=f.keep,leveling=f.leveling,sell=f.sell,help=f.help}) do
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
        if r.value then r.value:Hide();r.note:Hide();r.bar:Hide() end;if r.icon then r.icon:Hide() end
    end
    local index,height=0,0
    local function row(text,detail,actionText,click,options)
        options=options or {};index=index+1;local r=f.rows[index]
        if not r then
            r=CreateFrame("Frame",nil,f.content);r:SetWidth(width);r:EnableMouse(true);r:EnableMouseWheel(true)
            r:SetScript("OnMouseWheel",function(_,delta) T.ScrollBy(-delta*48) end)
            r.label=label(r,"GameFontHighlight",width-16)
            r.background=r:CreateTexture(nil,"BACKGROUND");r.background:SetAllPoints()
            r.accent=r:CreateTexture(nil,"BORDER");r.accent:SetPoint("TOPLEFT");r.accent:SetPoint("BOTTOMLEFT");r.accent:SetWidth(3)
            r:SetScript("OnEnter",function(self)
                if not self.heading then self.background:SetColorTexture(0.18,0.26,0.28,0.7) end
                local detail=type(self.detail)=="function" and self.detail() or self.detail
                if detail then GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:AddLine(detail,0.85,0.9,0.9,true);GameTooltip:Show() end
            end)
            r:SetScript("OnLeave",function(self)
                if not self.heading then self.background:SetColorTexture(0.12,0.18,0.19,0.35) end
                GameTooltip:Hide()
            end)
            f.rows[index]=r
        end
        local left=options.item and 40 or 8
        local right=(options.value or click) and 114 or 8
        r.detail=detail;r.heading=options.heading;r:ClearAllPoints();r:SetPoint("TOPLEFT",0,-height)
        r.label:ClearAllPoints();r.label:SetPoint("TOPLEFT",left,-6);r.label:SetWidth(width-left-right);r.label:SetText(text)
        r.background:SetColorTexture(0.12,0.18,0.19,options.heading and 0 or 0.35)
        local color=states[options.state]
        if color then r.accent:SetColorTexture(color[1],color[2],color[3],0.9);r.accent:Show() else r.accent:Hide() end
        local h=math.max(18,r.label:GetStringHeight() or 18)+12
        if options.item then
            if not r.icon then r.icon=r:CreateTexture(nil,"ARTWORK");r.icon:SetPoint("TOPLEFT",8,-6);r.icon:SetSize(24,24) end
            r.icon:SetTexture(T.Safe(C_Item and C_Item.GetItemIconByID,options.item) or T.Safe(GetItemIcon,options.item) or "Interface\\Icons\\INV_Misc_QuestionMark")
            r.icon:Show();h=math.max(h,36)
        end
        if options.value then
            if not r.value then
                r.value=label(r,"GameFontHighlight",104);r.value:SetPoint("TOPRIGHT",-8,-6);r.value:SetJustifyH("RIGHT")
                r.note=label(r,"GameFontHighlightSmall",104);r.note:SetPoint("TOPRIGHT",r.value,"BOTTOMRIGHT",0,-1);r.note:SetJustifyH("RIGHT")
                r.bar=CreateFrame("StatusBar",nil,r);r.bar:SetSize(104,11);r.bar:SetPoint("TOPRIGHT",r.value,"BOTTOMRIGHT",0,-3)
                r.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
                local track=r.bar:CreateTexture(nil,"BACKGROUND");track:SetAllPoints();track:SetColorTexture(0.13,0.19,0.21,1)
                r.bar.text=r.bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");r.bar.text:SetPoint("CENTER")
            end
            -- The first line is the action in the row's colour; a have/need bar or a quiet note sits under it.
            local action,note=tostring(options.value):match("^([^\n]*)\n?(.*)$")
            r.value:SetText(color and (tint(color)..action.."|r") or action);r.value:Show()
            local top=(r.value:GetStringHeight() or 14)+6
            h=math.max(h,top+6)
            if options.need then
                local c=color or states.keep
                r.bar:SetMinMaxValues(0,math.max(1,options.need));r.bar:SetValue(math.min(options.have or 0,options.need))
                r.bar:SetStatusBarColor(c[1],c[2],c[3],1);r.bar.text:SetText((options.have or 0).." / "..options.need);r.bar:Show()
                h=math.max(h,top+3+11+6)
            elseif note~="" then
                r.note:SetText(muted..note.."|r");r.note:Show()
                h=math.max(h,top+1+(r.note:GetStringHeight() or 12)+6)
            end
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
    elseif keep then T.RenderMaterials(selected,row)
    elseif sell then T.RenderSell(selected,row)
    else
        local action=T.NextAction(selected)
        local op=T.plan.opportunities[selected]
        row(gold..action.text.."|r",(action.detail or "")..(op and ("\n"..op.why) or ""),nil,nil,{heading=true})
        local goal=T.FarmGoal(selected)
        if goal then
            heading("For "..goal.recipe.." - skill "..goal.target,
                "Estimated ingredients for the next step. Open your profession to check the recipe. Plan shows the full route.")
            if op then row("Stop at skill "..op.stop.." or when the recipe turns green.",T.TargetText(op)) end
            local groups={{name="Collect next",state="collect"},{name="Buy supplies",state="buy"},{name="Craft these first",state="prepare"},{name="In your bags",state="ready"}}
            for _,group in ipairs(groups) do
                local shown=false
                for _,m in ipairs(goal.materials) do
                    local state=T.MaterialState(m)
                    if state==group.state and (m.need or 0)>0 then
                        if not shown then heading(group.name);shown=true end
                        local action,detail,source=T.MaterialAdvice(m,T.professions[goal.profession].name.." to skill "..goal.target,goal.recipe,goal.steps)
                        row(T.ItemName(m.item).."\n"..muted..source.."|r",detail,nil,nil,
                            {item=m.item,value=action,have=m.have,need=m.need,state=state})
                    end
                end
            end
            local offers=T.CurrentMerchantSuggestions()
            if #offers>0 then heading("Available at this vendor") end
            for _,v in ipairs(offers) do
                row(T.ItemName(v.item),T.MerchantText(v),nil,nil,{item=v.item,value="Buy "..v.amount.."\n"..T.Money(v.cost),state="buy"})
            end
        elseif not T.professions[selected].craft then
            row(selected==356 and "Learn Cooking to use your catch." or "Learn Leatherworking to use your leather.",
                "A paired crafting profession gives this tab an ingredient target.")
        end
        if selected==356 and T.fishingEfficiency[T.area] then
            local advice=T.RangeAdvice(356,T.area)
            row("Fishing target here: "..T.fishingEfficiency[T.area].target.." including bonuses",
                advice.text.."\n"..(advice.note or "").."\n"..(advice.detail or ""))
        end
    end
    f.content:SetHeight(math.max(1,height));T.SyncScroll(scroll)
end
function T.AddNPCTooltip(tooltip,unit)
    if not T.plan or not T.settings.tooltips then return end
    local npc=T.NPCFromGUID(T.Safe(UnitGUID,unit or "mouseover"));local id=T.SelectedProfession()
    local key=tostring(npc)..":"..tostring(id)
    if not npc or tooltip.trailMatsNPC==key then return end
    tooltip.trailMatsNPC=key;local added=false
    if id==393 then
        local source=T.GetSources(2318).npcs[npc]
        if source then
            tooltip:AddLine("TrailMats / Skinning: check this beast for useful leather.",1,0.82,0.5,true)
            tooltip:AddLine("Database source. The corpse's actual Skinning requirement takes priority.",0.7,0.7,0.7,true)
            added=true
        end
    end
    for _,m in ipairs(T.CurrentMaterials()) do
        local source=T.GetSources(m.item).npcs[npc]
        if m.missing>0 and source then
            tooltip:AddLine("TrailMats: collect "..m.missing.." "..T.ItemName(m.item).." for "..T.CurrentOpportunity().name,1,0.82,0.5,true)
            tooltip:AddLine("Database source. Kills vary; no reliable kill estimate.",0.7,0.7,0.7,true);added=true
        end
    end
    if added then tooltip:Show() end
end
function T.AddItemTooltip(tooltip)
    if not T.plan or not T.settings.tooltips then return end
    local _,link=tooltip:GetItem();local item=link and tonumber(link:match("item:(%d+)"));local id=T.SelectedProfession()
    local key=tostring(item)..":"..tostring(id)
    if not item or tooltip.trailMatsItem==key then return end
    tooltip.trailMatsItem=key
    local added=T.AddKeepTooltip(tooltip,item)
    for _,m in ipairs(T.CurrentMaterials()) do
        if m.item==item then
            tooltip:AddLine("TrailMats next recipe: "..m.missing.." more for "..T.CurrentOpportunity().batch.." crafts of "..T.CurrentOpportunity().name,1,0.82,0.5,true)
            for _,v in ipairs(T.CurrentMerchantSuggestions()) do if v.item==item then tooltip:AddLine(T.MerchantText(v),0.8,0.9,0.8,true) end end
            added=true;break
        end
    end
    local ah=T.AuctionPrice and T.AuctionPrice(item)
    if ah then
        tooltip:AddLine("TrailMats AH: "..T.Money(math.ceil(ah.copper)).." each ("..(ah.source=="TSM" and "TSM" or (T.AgeText(ah.at)..(ah.source~="AH" and (", "..ah.source) or "")))..")",0.8,0.9,0.8,true)
        local have=T.Count(item)
        if have>1 then tooltip:AddLine("x"..have..": "..T.Money(T.FloorCopper(have*math.max(0,ah.copper-1)*(1-T.AuctionCut()))).." after cut",0.8,0.9,0.8,true) end
        added=true
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
