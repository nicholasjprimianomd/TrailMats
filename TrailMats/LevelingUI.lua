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
    row(gold..p.start.." to "..p.target.." (est.)|r",
        "Materials and craft counts are estimates. Stop each recipe at its target skill. Bags and skill changes update the list; skill-ups are not guaranteed.",
        not p.gathering and not p.complete and not p.unsupported and not p.blocked and (page=="recipes" and "Materials" or "Recipes") or nil,
        not p.gathering and not p.complete and not p.unsupported and not p.blocked and function() switch(page=="recipes" and "materials" or "recipes") end or nil)
    if p.complete then row("Skill 300 reached.");return end
    if p.gathering then
        row(id==356 and "Fish while you quest." or "Skin beasts while you quest.")
        local companion=id==356 and 185 or 165
        row("Materials: "..T.professions[companion].name,
            "Gathering needs no crafting shopping list. This zone and Track show materials for your paired crafting profession, if learned.",
            T.skills[companion] and "Open" or nil,T.skills[companion] and function() T.SelectProfession(companion);switch("materials") end or nil)
        if p.training then row("Train the next rank first.") end
        return
    end
    if p.unsupported then row("Routes currently stop at 225.","A complete route to 300 has not been verified for this beta.");return end
    if p.blocked then row("Open your profession, then Refresh.","The guide route conflicts with your latest recipe colors. Use Now for available recipes.");return end
    local c=p.chosen
    if p.training then row(gold.."Train the next rank first.|r","Your trained cap is below this plan's target. Check character level and training requirements.") end
    local cost=c.unknown==0 and ("Est. cost: "..T.Money(c.cost)) or "Cost: add prices"
    local comparison=p.allPriced and "Lowest priced route" or p.pricedCount>0 and "Some routes need prices" or "Uses what you have"
    row(cost.."\n"..muted..comparison.."|r",
        p.pricedCount.." of "..p.candidateCount.." reviewed routes fully priced. Compares additional material spending using bags, your quotes and current vendor packs. Unknown prices are never free.\n"..
        "Only supported recipe combinations are compared. Gathering time, resale value, training, recipe books and the value of owned materials are excluded. Without complete prices, routes favor materials already held. Quotes may need updating.")
    if page=="prices" then
        row(gold.."Prices per item|r","Your quote overrides the open vendor. Blank clears it. Prices do not confirm auction stock; update old quotes when the market changes.")
        for _,item in ipairs(p.priceItems) do
            local itemID=item
            local quote=T.saved.levelingPrices[item]
            local cost,source=T.LevelingCost(item,1)
            local value=quote and (T.Money(quote.copper).." each") or cost and (T.Money(cost).." / vendor pack") or "No price"
            local detail="Enter copper per item. Blank removes your quote."
            if quote and quote.at and date then detail=detail.."\nSaved "..date("%b %d %H:%M",quote.at) end
            if source then detail=detail.."\n"..source end
            row(T.ItemName(item).."\n"..muted..value.."|r",detail,"Edit",function() T.EditLevelingPrice(itemID) end,{item=item})
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
        "Missing amounts subtract bags and outputs from earlier planned crafts. Hover a material for the breakdown. Bank, mail and other characters are excluded.",
        f.showAllMats and "Missing only" or "Show all",function() f.showAllMats=not f.showAllMats;T.Render() end)
    local shown=0
    for _,m in ipairs(c.materials) do
        if m.need>0 and (f.showAllMats or m.missing>0) then
            shown=shown+1
            local source,detail
            if m.supply then source="Vendor supply"
            elseif m.missing==0 then source=m.fromCrafts>0 and "Bags + planned crafts" or "In bags"
            else source,detail=T.ZoneSource(m.item);source=source or "No local source recorded" end
            row(T.ItemName(m.item).."\n"..muted..source.."|r",
                "Total needed: "..m.need.."\nIn bags: "..m.have.." (used: "..m.fromBags..")\nMade along the way: "..m.fromCrafts..
                "\nStill needed: "..m.missing.."\n"..m.priceSource..(m.cost and (": "..T.Money(m.cost)) or "")..(detail and ("\n"..detail) or ""),
                nil,nil,{item=m.item,value=m.missing>0 and ("Need "..m.missing) or "Covered"})
        end
    end
    if shown==0 then row("Materials covered.","Bags and earlier planned crafts cover this route. Check Recipes for the order and any recipes you still need to learn.") end
end

function T.RenderHelp(row)
    row(gold.."Using TrailMats|r",nil,nil,nil,{heading=true})
    row("Now: your next craft and local materials.","Open your profession first. Suggestions need a learned, non-grey recipe scanned at your current skill. Reopen it after gaining skill; clear restrictive recipe filters if needed.")
    row("Keep: what to save from your bags.","The reserve covers one optional batch, not the whole milestone. Uses of the same material are alternatives, not totals. Unlisted items may still be useful.")
    row("Plan: materials to 75, 150 or 225.","Recipes shows the crafting order and how to obtain each recipe. Counts are estimates; stop at each step's skill target. Training and recipe books may cost extra. Routes to 300 are not yet complete.")
    row("Track: a small list while you quest.","Tracks one profession until you untrack it. Drag the tracker to move it. Open returns to Now. It follows your bags and current zone, including while the main window is closed.")
    row("Prices: compare material costs.","Enter copper per item. Your quotes and the open vendor are used to compare supported routes. Missing prices are unknown. No automatic Auction House scan. Bags lower purchases; farming time, resale value and training costs are excluded.")
    row("* Guide source: check in-game.","Sources may use Classic data. Coordinates identify a reference spawn, not your nearest live target. No kill count or guaranteed drop is inferred. Next-zone advice is optional and is not a character-level requirement.")
    row("All counts use bags only.","Bank, mail and other characters are excluded. Fishing and Skinning share material goals with Cooking and Leatherworking when those professions are learned. Nothing is bought or crafted automatically.")
    row("Commands", "/tm: open or close\n/tm now, /tm keep, /tm mats: change view\n/tm track: toggle tracker for selected profession\n/tm refresh: update recipes and sources\n/tm quiet: zone notices\n/tm tips: item and creature tooltips\n/tm auto: reset destination and recipe choices\n/tm status: version and database status")
    row("Version 0.7.0", "WoW Forever. Supported professions: Leatherworking, Cooking, First Aid, Skinning and Fishing. Guide coverage and live recipe availability can differ during the beta.")
end
