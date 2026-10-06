local _, T = ...

-- Keep action text short. Evidence stays attached to the row's tooltip.
function T.ZoneSource(item,area)
    area=area or T.area
    local water=T.water[area] and T.water[area][item]
    if water then return "Fish: "..water.." *","Guide location; catches have not been confirmed on this character." end
    local list=T.GetSources(item).areas[area]
    if not list or not list[1] then return nil end
    local source=list[1]
    for _,s in ipairs(list) do if s.evidence=="Observed on this character" then source=s;break end end
    local confirmed=source.evidence=="Observed on this character"
    local detail=source.name.."\n"..source.evidence
    local pos=source.position
    if type(pos)=="table" and type(pos[1])=="number" and type(pos[2])=="number" then
        detail=detail..string.format("\nNear %.0f, %.0f",pos[1],pos[2])
    end
    return source.name..(confirmed and "" or " *"),detail
end

function T.ZoneNeeds(id)
    local result={here={},vendor={},elsewhere={}}
    local p=T.plan and T.plan.leveling and T.plan.leveling[id]
    local materials=p and p.chosen and p.chosen.materials or {}
    -- Gathering tabs follow the corresponding crafting profession, when owned.
    if id==393 or id==356 then
        id=id==393 and 165 or 185
        p=T.plan and T.plan.leveling and T.plan.leveling[id]
        materials=p and p.chosen and p.chosen.materials or {}
    end
    result.profession=id;result.target=p and p.target
    for _,m in ipairs(materials) do
        if m.missing>0 then
            local location,detail
            if not m.supply then location,detail=T.ZoneSource(m.item) end
            local entry={item=m.item,missing=m.missing,have=m.have,need=m.need,source=location,detail=detail}
            local list=m.supply and result.vendor or location and result.here or result.elsewhere
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
        local ready=op.batch
        local rawMissing=0
        for _,m in ipairs(op.materials) do
            ready=math.min(ready,math.floor(m.have/m.perCraft))
            if m.have<m.perCraft then
                if not m.vendor then rawMissing=rawMissing+1 end
            end
        end
        if ready>0 then
            return {text="Craft "..ready.." x "..op.name,detail="You have the materials for "..ready.." of the selected "..op.batch.." crafts. Craft in your profession window."}
        end
        return {text=rawMissing>0 and "Gather for "..op.name or "Get supplies for "..op.name,
            detail="Selected batch: "..op.batch.." crafts. Open the profession after gaining skill to refresh recipe colors."}
    end
    if T.professions[id].craft then
        if not T.saved.scanned[id] then return {text="Open "..T.professions[id].name,detail="Open your crafting window once so TrailMats can read your learned recipes."} end
        local fresh=false
        for _,r in pairs(T.saved.recipes) do if r.profession==id and r.learned and r.rank==s.rank then fresh=true end end
        if not fresh then return {text="Open "..T.professions[id].name.." to refresh",detail="Your skill changed since the last recipe scan."} end
        local needs=T.ZoneNeeds(id)
        if needs.here[1] then return {text="Gather "..T.ItemName(needs.here[1].item),detail="For the plan to skill "..needs.target..". This is a guide-based material target; check recipe availability in Plan."} end
        return {text="Check your next recipe",detail="No learned, non-grey recipe is ready with bag materials or recorded sources in this zone. See Plan for upcoming recipes."}
    end
    return {text=id==356 and "Fish while you quest" or "Skin beasts while you quest",
        detail=id==356 and "Keep fish for Cooking. Catch counts vary." or "Check the corpse's Skinning requirement. Keep leather for Leatherworking."}
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
    local top=32+math.max(18,f.action:GetStringHeight() or 18)+6
    for index,line in ipairs(f.lines) do
        local m=needs.here[index]
        line:ClearAllPoints();line:SetPoint("TOPLEFT",10,-top)
        line:SetText(m and (m.missing.." "..T.ItemName(m.item)) or "")
        if m then top=top+math.max(18,line:GetStringHeight() or 18) end
    end
    f.zone:SetText(T.zoneName..(#needs.here>0 and " (est.)" or "")..(#needs.here>3 and (" +"..(#needs.here-3)) or ""))
    f.detail=action.detail or ""
    if #needs.here>0 then
        f.detail=f.detail.."\nGather for "..T.professions[needs.profession].name.." "..needs.target.." (estimated):"
        for _,m in ipairs(needs.here) do f.detail=f.detail.."\n"..m.missing.." "..T.ItemName(m.item)..": "..m.source end
    end
    f.detail=f.detail.."\n* Guide source; not confirmed here. Click Open for details."
    f:SetHeight(top+math.max(26,f.zone:GetStringHeight()+14));f:Show()
end
