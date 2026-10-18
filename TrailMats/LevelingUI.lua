local _, T = ...
local gold="|cffffd27f"
local muted="|cffb6c2cc"

function T.EditLevelingPrice(item)
    if not StaticPopupDialogs or not StaticPopup_Show then return end
    local function save(dialog)
        local box=dialog.EditBox or dialog.editBox
        local value=box and box:GetText() or ""
        if value:match("^%s*$") then
            T.saved.levelingPrices[dialog.data]=nil;T.Refresh(false,false);return true
        end
        if T.SetLevelingPrice(dialog.data,value) then return true end
        T.Print("Enter copper per item, or leave blank to clear.")
        return false
    end
    StaticPopupDialogs.TRAILMATS_UNIT_PRICE={
        text="%s\nCopper per item (100 = 1 silver)\nBlank clears. Zero means free.",
        button1="Save",button2="Cancel",hasEditBox=true,editBoxWidth=220,timeout=0,whileDead=true,hideOnEscape=true,
        OnShow=function(dialog)
            local box=dialog.EditBox or dialog.editBox
            local quote=T.saved.levelingPrices[dialog.data]
            box:SetText(quote and tostring(quote.copper) or "");box:SetFocus();box:HighlightText()
        end,
        OnAccept=function(dialog) if not save(dialog) then return true end end,
        EditBoxOnEnterPressed=function(box) local dialog=box:GetParent();if save(dialog) then dialog:Hide() end end,
    }
    StaticPopup_Show("TRAILMATS_UNIT_PRICE",T.ItemName(item),nil,item)
end

function T.RenderLeveling(id,row,page)
    local p=T.plan.leveling[id]
    if not p then row("Open your profession, then Refresh.");return end
    local f=T.window
    local function switch(page) f.planPage=page;T.Render() end
    row(gold..T.professions[id].name..": "..p.start.." to "..p.target.." (est.)|r",
        "Materials and craft counts are estimates. Stop each recipe at its target skill. Bags and skill changes update the list; skill-ups are not guaranteed.",
        not p.gathering and not p.complete and not p.unsupported and not p.blocked and (page=="recipes" and "Materials" or "Recipes") or nil,
        not p.gathering and not p.complete and not p.unsupported and not p.blocked and function() switch(page=="recipes" and "materials" or "recipes") end or nil)
    if p.complete then row("Skill 300 reached.");return end
    if p.noRoute then
        row("No reviewed route for "..T.professions[id].name.." yet.","Next step and Materials still work from your learned recipes and bags. Craft counts need reviewed guide data; see SOURCES.md.")
        return
    end
    if p.gathering then
        local companion=T.FutureProfession(id)
        row(T.professions[id].verb.." while you quest.")
        row("Materials: "..T.professions[companion].name,
            "Gathering needs no crafting shopping list. Next step and the tracker show materials for your paired crafting profession, if learned.",
            T.skills[companion] and "Open" or nil,T.skills[companion] and function() T.SelectProfession(companion);switch("materials") end or nil)
        if p.training then row("Train the next rank first.") end
        return
    end
    if p.unsupported then row("Routes currently stop at 225.","A complete route to 300 has not been verified for this beta.");return end
    if p.blocked then row("Open your profession, then Refresh.","The guide route conflicts with your latest recipe colors. Use Next step for available recipes.");return end
    local c=p.chosen
    if p.training then row(gold.."Train the next rank first.|r","Your trained cap is below this plan's target. Check character level and training requirements.") end
    local cost=c.unknown==0 and ("Est. cost: "..T.Money(c.cost)) or "Cost: add prices"
    local comparison=p.allPriced and "Lowest priced route" or p.pricedCount>0 and "Some routes need prices" or "Uses what you have"
    if page=="prices" then row(cost.."\n"..muted..comparison.."|r",
        p.pricedCount.." of "..p.candidateCount.." reviewed routes fully priced. Compares additional material spending using bags, your quotes and current vendor packs. Unknown prices are never free.\n"..
        "Only supported recipe combinations are compared. Gathering time, resale value, training, recipe books and the value of owned materials are excluded. Without complete prices, routes favor materials already held. Quotes may need updating.") end
    if page=="prices" then
        row(gold.."Prices per item|r","Your quote overrides the open vendor and recorded auction prices. Blank clears it. Prices do not confirm auction stock; update old quotes when the market changes.")
        if T.AuctionSummary and T.AuctionSummary().count==0 then
            row("Scan prices at an auction house to fill these.","Open the auction house and click TrailMats: Scan prices. Browsing the auction house also records prices.")
        end
        for _,item in ipairs(p.priceItems) do
            local itemID=item
            local quote=T.saved.levelingPrices[item]
            local unit,source=T.BuyUnit(item)
            local value=unit and (T.Money(T.DisplayCopper(unit)).." each") or "No price"
            local detail="Enter copper per item. Blank removes your quote."
            if quote and quote.at and date then detail=detail.."\nSaved "..date("%b %d %H:%M",quote.at) end
            detail=detail.."\n"..source..(source=="Open vendor" and "; routes buy whole packs" or "")
            row(T.ItemName(item).."\n"..muted..value.." | "..source.."|r",detail,"Edit",function() T.EditLevelingPrice(itemID) end,{item=item})
        end
        return
    end
    if page=="recipes" then
        row(gold.."Craft in order|r","Check recipe availability first. Open your profession to update learned recipes; a missing record does not prove you lack a recipe.")
        for index,s in ipairs(c.steps) do
            local r=s.recipe;local inputs={}
            for item,qty in pairs(r.mats) do inputs[#inputs+1]=(qty*s.crafts).." "..T.ItemName(item) end
            table.sort(inputs)
            local status=r.learned and "Learned" or "Check recipe"
            local range=s.extra and "Prepare first" or (s.low.."-"..s.high)
            row(index..". "..r.name.."\n"..muted..range.." | "..status.."|r",
                table.concat(inputs,", ").."\n"..r.source.."\n"..
                (r.learned and "Recorded as learned; open your profession to refresh." or "Not recorded as learned. Obtain the recipe if needed.")..
                "\nEstimated crafts. Stop at the target skill. Extra supply crafts receive no assumed skill credit.",nil,nil,{value=s.crafts.." crafts"})
        end
        if #c.keep>0 then
            local lines={}
            for _,m in ipairs(c.keep) do lines[#lines+1]=m.amount.." "..T.ItemName(m.item) end
            row(gold.."Keep leftovers|r\n"..table.concat(lines,", "),"These outputs may help with later recipes. Reference yields apply until scanned in your profession window.")
        end
        return
    end
    row(gold..(f.showAllMats and "All materials" or "Still needed").."|r",
        "Collect the listed materials and buy the vendor supplies. Hover to see which recipe needs each item. Bank, mail and other characters are not counted.",
        f.showAllMats and "Missing only" or "Show all",function() f.showAllMats=not f.showAllMats;T.Render() end)
    local shown=0
    for _,m in ipairs(c.materials) do
        if m.need>0 and (f.showAllMats or m.missing>0) then
            shown=shown+1
            local action,detail,source=T.MaterialAdvice(m,T.professions[id].name.." to skill "..p.target,nil,c.steps)
            row(T.ItemName(m.item).."\n"..muted..source.."|r",detail,
                nil,nil,{item=m.item,value=action,have=m.have,need=m.need,state=T.MaterialState(m)})
        end
    end
    if shown==0 then row("Materials covered.","You have the supplies for this route. Check Recipes for anything you must make first or still need to learn.") end
end

function T.RenderMaterials(selected,row)
    local id=T.FutureProfession(selected)
    local skill=T.skills[id]
    local function heading(text,detail) row(gold..text.."|r",detail,nil,nil,{heading=true}) end
    if not skill then row("Learn "..T.professions[id].name.." to get a material plan.");return end
    local goal=T.FarmGoal(id)
    if not goal then
        if skill.rank>=T.levelingLimit then row("Reviewed material plans stop at skill "..T.levelingLimit..".")
        else row("No reviewed efficient recipe at your current skill.","Open your profession to refresh recipes. The database cannot supply a verified leveling target for this gap.") end
        return
    end
    heading(T.professions[id].name.." to skill "..goal.target.." (est.)",
        "Materials for the next efficient recipe, including ingredients you do not own yet. Counts adjust with your bags and skill.")
    if skill.rank>=skill.cap then row("Train "..T.professions[id].name.." before continuing.") end
    row("Make "..goal.recipe,"Open your profession to check or learn this recipe before crafting.")
    local groups={{key="here",name="Collect in "..T.zoneName},{key="away",name="No source listed in this zone"},
        {key="vendor",name="Buy supplies"},{key="prepare",name="Craft first"},{key="ready",name="In your bags"}}
    local entries,current={},{}
    local missingRaw,localRaw=0,0
    for _,m in ipairs(goal.materials) do
        if m.need>0 then
            current[m.item]=true
            local action,detail,source=T.MaterialAdvice(m,T.professions[id].name.." to skill "..goal.target,goal.recipe,goal.steps)
            local key
            if m.missing==0 then key=(m.fromCrafts or 0)>0 and "prepare" or "ready"
            elseif m.supply or m.vendor then key="vendor"
            else
                missingRaw=missingRaw+1
                if T.ZoneSource(m.item) then key="here";localRaw=localRaw+1 else key="away" end
            end
            entries[#entries+1]={key=key,item=m.item,action=action,detail=detail,source=source,have=m.have,need=m.need,state=T.MaterialState(m)}
        end
    end
    if missingRaw>0 and localRaw==0 then
        row(T.NoLocalSource().." for the missing materials.","No match in the available data does not prove the material cannot drop here.")
    end
    for _,g in ipairs(groups) do
        local shown=false
        for _,e in ipairs(entries) do
            if e.key==g.key then
                if not shown then heading(g.key=="away" and not T.qdb and not T.dropDB and "Source database unavailable" or g.name);shown=true end
                row(T.ItemName(e.item).."\n"..muted..e.source.."|r",e.detail,nil,nil,
                    {item=e.item,value=e.action,have=e.have,need=e.need,state=e.state})
            end
        end
    end
    local shown=false
    for _,use in ipairs(T.plan.future and T.plan.future.byProfession[id] or {}) do
        if not current[use.item] then
            if not shown then heading("Save for later recipes");shown=true end
            local detail=use
            row(T.ItemName(use.item).."\n"..muted..use.recipe.name.."|r",
                function() return T.FutureText(detail).."\n"..T.FutureDetail(detail) end,nil,nil,
                {item=use.item,value="Keep up to "..use.material.need,have=use.material.have,need=use.material.need,state="keep"})
        end
    end
end

function T.RenderHelp(row)
    row(gold.."Using TrailMats|r",nil,nil,nil,{heading=true})
    row("Next step: what to collect, buy and craft.","Open your profession first. The checklist focuses on one recipe at a time. Quantities are automatic. Suggestions need a learned orange/yellow recipe with a reviewed target, scanned at your current skill. Stop at the displayed skill or when it turns green. Reopen it after gaining skill; clear restrictive recipe filters if needed.")
    row("Materials: what to collect here and save for later.","The list includes materials you do not own yet and database sources in your current zone. Keep limits follow each material through its useful leveling ranges, including later recipes and ingredient preparation. Limits shrink as skill rises. Different materials may be alternatives; you do not need to collect every limit. Unlisted items may still be useful.")
    row("Plan: materials to 75, 150 or 225.","Recipes shows the crafting order and how to obtain each recipe. Counts are estimates; stop at each step's skill target. Training and recipe books may cost extra. Routes to 300 are not yet complete.")
    row("Pin: keep a small list on screen.","Pins one profession until you unpin it. Drag the tracker to move it. Open returns to Next step. It follows your bags and current zone, including while the main window is closed.")
    row("Prices: compare material costs.","Each item shows its price source: your quote, the open vendor, or the auction house with the age of that price. Quotes win; vendor supplies use the cheaper of vendor and auction house. Missing prices are unknown, never free. Bags lower purchases; farming time, resale value and training costs are excluded.")
    row("Sell: what crafts and materials are worth.","Craft to sell ranks learned recipes by profit per craft after the auction house cut, using full replacement cost for materials. Your materials values held items at the auction house and at a vendor next to their keep limits. Prices are asking prices, not sales; recipes with missing prices say so. Nothing is posted, bought or marked safe to sell.")
    row("Scan prices at the auction house.","Open the auction house and click TrailMats: Scan prices below the frame; Full scan appears when the client allows one. Prices are also recorded while you browse. They expire after 14 days and are shared by your characters of one faction. Set the auction house cut under Options.")
    row("Sources come from the database.","QuestieDB and profession references supply locations without waiting for personal loot. Some records retain Classic references. No listed source means the data has no match here, not proof of absence.")
    row("All twelve professions, one tab each.","Reviewed plans cover Leatherworking, Cooking, First Aid, Alchemy, Blacksmithing, Enchanting, Engineering and Tailoring to skill 225. Skinning, Herbalism, Mining and Fishing follow their crafting partner's plan (Leatherworking, Alchemy, Blacksmithing, Cooking) and show where to gather at your skill; herb and vein tooltips show the skill they need.")
    row("All counts use bags only.","Bank, mail and other characters are excluded. Gathering tabs share material goals with their crafting partner when it is learned. Nothing is bought or crafted automatically.")
    row("Notices: when to craft, switch and train.","Crafting notices tell you when your bags cover the whole target for the current recipe, and when a skill-up means it is time to switch recipes. Training reminders appear once per login at your trained cap. Turn each off under Options.")
    row("Options: minimap button, notices, scale.","Open with the Options button, /tm options, or the game's AddOns settings. Settings are shared by all your characters. Escape closes this window. Key bindings are under Key Bindings > AddOns.")
    row("Commands", "/tm: open or close\n/tm now, /tm keep, /tm mats, /tm sell: change view\n/tm track: toggle tracker for selected profession\n/tm options: settings\n/tm minimap: show or hide the minimap button\n/tm refresh: update recipes and sources\n/tm quiet: zone notices\n/tm tips: item and creature tooltips\n/tm auto: reset destination and recipe choices\n/tm status: version and database status")
    row("Version "..T.version, "WoW Forever. All twelve professions are detected; routes come from beta-tested guides and stop at 225. Guide coverage and live recipe availability can differ as the game changes.")
end
