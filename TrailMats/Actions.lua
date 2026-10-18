local _, T = ...

-- Keep action text short. Evidence stays attached to the row's tooltip.
-- Uses the same source strength as the map pin (Sources.lua tiers): a zone whose only sources are
-- fallbacks (chests, rare or unlikely drops) defers to a better source elsewhere, and a world drop
-- has no local target. The third return says whether a click can pin it.
function T.ZoneSource(item,area)
    area=area or T.area
    local water=T.water[area] and T.water[area][item]
    if water then return "Fish: "..water,"Fishing location from the profession reference.",false end
    local sources=T.GetSources(item)
    local list=sources.areas[area]
    if not list or not list[1] or sources.worldDrop then return nil end
    local best=4
    for _,source in ipairs(list) do if source.kind~="node" then best=math.min(best,source.tier or 2) end end
    if best==4 or best==3 and (sources.bestTier or 3)<3 then return nil end
    local names,seen={},{}
    for _,source in ipairs(list) do
        if source.kind~="node" and (source.tier or 2)==best and not seen[source.name] then names[#names+1]=source.name;seen[source.name]=true end
        if #names==3 then break end
    end
    local namesText=table.concat(names,", ")
    return (T.leather[item] and "Skin: " or "From: ")..namesText,
        "Database sources in this zone: "..namesText..".",true
end

function T.NoLocalSource()
    if not T.qdb and not T.dropDB then return "Source database unavailable" end
    return "No listed source in "..T.zoneName
end

-- One word for a material row's colour and grouping: what the player must do about it.
function T.MaterialState(m)
    if m.missing>0 then return (m.supply or m.vendor) and "buy" or "collect" end
    return (m.fromCrafts or 0)>0 and "prepare" or "ready"
end

-- Both the immediate checklist and full plan use the same plain-language advice.
function T.MaterialAdvice(m,goal,recipe,steps)
    local supply=m.supply or m.vendor
    local action=m.missing>0 and ((supply and "Buy " or "Collect ")..m.missing.." more") or
        ((m.fromCrafts or 0)>0 and "Craft first" or "Ready")
    local purposes,seen={},{}
    for _,step in ipairs(steps or {}) do
        local r=step.recipe
        if r.mats[m.item] and not seen[r.name] then
            seen[r.name]=true;purposes[#purposes+1]=r.name
        end
    end
    local purpose=recipe or purposes[1]
    if not recipe and #purposes>1 then purpose=purpose.." and later recipes" end
    local text=action..". You have "..m.have.."."
    if purpose then text=text.."\nFor "..purpose.."." end
    if goal then text=text.."\n"..goal.." (estimated)." end
    if (m.fromCrafts or 0)>0 then
        local producer
        for _,step in ipairs(steps or {}) do
            if step.recipe.output and step.recipe.output[1]==m.item then producer=step.recipe.name;break end
        end
        text=text.."\n"..(producer and ("Make "..producer.." first; its ingredients are included in the list.") or
            "An earlier recipe makes this ingredient. Follow the recipe order.")
    end
    local source
    if m.missing>0 then
        local detail
        -- Herbs, ore, stone, gems and bars: the nearest node you can gather, or the skill it needs.
        local gather=not supply and T.GatherSource and T.GatherSource(m.item)
        if gather then source,detail=gather.label,gather.detail
        elseif supply then
            local here=T.VendorSource and T.VendorSource(m.item)
            if here then source="Buy from: "..here;detail="Vendor in "..T.zoneName..": "..here.."." end
        else source,detail=T.ZoneSource(m.item) end
        if not source then
            -- Nothing in this zone: name the nearest database source elsewhere instead of "none here".
            local found=T.FindSource and T.FindSource(m.item) or {label=T.NoLocalSource(),detail=T.NoLocalSource().."."}
            source,detail=found.label,found.detail
        end
        text=text.."\n"..detail
    else source=(m.fromCrafts or 0)>0 and "Make with earlier recipe" or "Already in your bags" end
    return action,text,source
end

function T.FarmGoal(id)
    id=T.FutureProfession(id)
    if not T.plan then return nil end
    local op=T.plan.opportunities[id]
    if op then return {materials=op.materials,target=op.stop,recipe=op.name,profession=id} end
    T.plan.farmGoals=T.plan.farmGoals or {}
    if T.plan.farmGoals[id] then return T.plan.farmGoals[id] end
    local p=T.plan.leveling and T.plan.leveling[id]
    if not p or not p.chosen then return nil end
    for _,step in ipairs(p.chosen.steps) do
        if not step.extra then
            local target=T.AutomaticTarget(id,step.recipe.name,step.low,T.skills[id].cap)
            local first={recipe=step.recipe,crafts=target and target.crafts or step.crafts,low=step.low,high=target and target.stop or step.high}
            local route=T.EvaluateLevelingRoute(id,{first})
            local goal={materials=route.materials,steps=route.steps,target=first.high,recipe=step.recipe.name,profession=id}
            T.plan.farmGoals[id]=goal
            return goal
        end
    end
end

function T.ZoneNeeds(id)
    local result={here={},vendor={},elsewhere={}}
    id=T.FutureProfession(id)
    local goal=T.FarmGoal(id)
    local materials=goal and goal.materials or {}
    result.profession=id;result.target=goal and goal.target;result.recipe=goal and goal.recipe
    for _,m in ipairs(materials) do
        if m.missing>0 then
            local location,detail
            local supply=m.supply or m.vendor
            -- Herbs, ore, stone and bars come from nodes or smelting: local when a node you can gather is here.
            local gather=not supply and T.GatherSource and T.GatherSource(m.item)
            if gather then
                if gather.spot and gather.spot.area==T.area then location,detail=gather.label,gather.detail end
            elseif not supply then location,detail=T.ZoneSource(m.item) end
            local entry={item=m.item,missing=m.missing,have=m.have,need=m.need,source=location,detail=detail}
            local list=supply and result.vendor or location and result.here or result.elsewhere
            list[#list+1]=entry
        end
    end
    return result
end

function T.NextAction(id)
    local s=T.skills[id]
    if not s then return {text="Learn a profession"} end
    if s.rank>=s.cap then
        return {text=s.rank>=300 and "Skill 300 reached" or "Train "..T.professions[id].name,
            detail="Your current skill cap is "..s.cap..". Training and level requirements still apply."}
    end
    local op=T.plan and T.plan.opportunities[id]
    if op then
        local ready=T.ReadyCrafts(op)
        local rawMissing=0
        for _,m in ipairs(op.materials) do
            if m.have<m.perCraft and not m.vendor then rawMissing=rawMissing+1 end
        end
        if ready>0 then
            return {text="Craft "..ready.." x "..op.name,detail="You can make "..ready.." now. "..T.TargetText(op).." Craft in your profession window."}
        end
        return {text=rawMissing>0 and "Gather for "..op.name or "Get supplies for "..op.name,
            detail=T.TargetText(op).." Open your profession to refresh recipe colors."}
    end
    if T.professions[id].craft then
        if not T.saved.scanned[id] then return {text="Open "..T.professions[id].name,detail="Open your crafting window once so TrailMats can read your learned recipes."} end
        local fresh=false
        for _,r in pairs(T.saved.recipes) do if r.profession==id and r.learned and r.rank==s.rank then fresh=true end end
        if not fresh then return {text="Open "..T.professions[id].name.." to refresh",detail="Your skill changed since the last recipe scan."} end
        local needs=T.ZoneNeeds(id)
        if needs.here[1] then return {text="Gather "..T.ItemName(needs.here[1].item),detail="For "..needs.recipe.." to skill "..needs.target.." (estimated). Check the recipe in your profession window before crafting."} end
        return {text="Check your next recipe",detail="No learned orange/yellow recipe has a reviewed target and available materials here. See Plan for the next recipe."}
    end
    local info=T.professions[id];local companion=T.FutureProfession(id)
    local details={[356]="Collect fish for the recipe below. Catch counts vary.",[393]="Collect leather for the recipe below. Check the corpse's Skinning requirement."}
    return {text=companion~=id and T.skills[companion] and (info.verb.." for "..T.professions[companion].name) or ("Level "..info.name),
        detail=details[id] or ("Collect "..info.collect.." for the recipe below. Nodes need the skill shown in their tooltip.")}
end

function T.ToggleTracker()
    local id=T.SelectedProfession()
    if not id then return end
    if T.saved.trackProfession==id then T.saved.trackProfession=nil else T.saved.trackProfession=id end
    T.RenderTracker();T.Render()
end

function T.RenderTracker()
    local f=T.tracker
    if not f then return end
    local id=T.saved.trackProfession
    local s=id and T.skills[id]
    if not s or not T.plan then f:Hide();return end
    f.title:SetText("TrailMats  |  "..s.name.." "..s.rank.."/"..s.cap)
    local action=T.NextAction(id)
    f.action:SetText(action.text)
    local needs=T.ZoneNeeds(id)
    -- Local materials first, then the rest with their zone (or no zone for gather and fishing hints).
    local lines={}
    for _,m in ipairs(needs.here) do lines[#lines+1]={m=m,source=m.source} end
    for _,m in ipairs(needs.elsewhere) do
        local found=T.FindSource and T.FindSource(m.item) or {label=T.NoLocalSource()}
        local away=found.spot and found.spot.area~=T.area
        lines[#lines+1]={m=m,zone=away and T.AreaName(found.spot.area) or nil,source=found.label}
    end
    local top=32+math.max(18,f.action:GetStringHeight() or 18)+6
    for index,line in ipairs(f.lines) do
        local e=lines[index]
        line:ClearAllPoints();line:SetPoint("TOPLEFT",10,-top)
        line:SetText(e and ("Collect "..e.m.missing.." "..T.ItemName(e.m.item)..(e.zone and (" ("..e.zone..")") or "")) or "")
        if e then top=top+math.max(18,line:GetStringHeight() or 18) end
        local b=f.lineButtons and f.lineButtons[index]
        if b then b.item=e and e.m.item or nil;b:SetShown(e~=nil) end
    end
    f.zone:SetText(T.zoneName..(#needs.here>0 and " (est.)" or "")..(#lines>3 and (" +"..(#lines-3)) or ""))
    f.detail=action.detail or ""
    if #lines>0 then
        f.detail=f.detail.."\nFor "..needs.recipe.." to skill "..needs.target.." (estimated):"
        for _,e in ipairs(lines) do f.detail=f.detail.."\n"..e.m.missing.." "..T.ItemName(e.m.item)..": "..e.source end
    end
    f.detail=f.detail.."\nClick a material to mark its nearest source on your map. Open shows the recipe."
    f:SetHeight(top+math.max(26,f.zone:GetStringHeight()+14));f:Show()
end
