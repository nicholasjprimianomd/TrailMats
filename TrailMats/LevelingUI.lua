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
        T.Print("Enter a non-negative copper price per item, or leave blank to clear.")
        return false
    end
    StaticPopupDialogs.TRAILMATS_UNIT_PRICE={
        text="Unit price for %s\nCopper per ONE item (100 copper = 1 silver).\nBlank clears the quote. Zero means you explicitly value it at zero.",
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

function T.RenderLeveling(id,row,prices)
    local p=T.plan.leveling[id]
    if not p then row("Read your professions, then press Refresh.");return end
    row(gold.."NEXT MILESTONE: "..p.start.." to "..p.target.."|r\n"..T.professions[id].name)
    if p.complete then row("You have reached skill 300.");return end
    if p.gathering then
        row("This profession gains skill by gathering, so there is no crafting-material shopping list.")
        row(id==356 and "Fish while leveling Cooking. The Cooking tab lists the fish needed for its next milestone." or
            "Skin eligible beasts while leveling Leatherworking. The Leatherworking tab lists its next milestone materials.")
        if p.training then row("Train the next profession rank before gaining more skill.") end
        return
    end
    if p.unsupported then
        row("A complete route to 300 is not verified for this beta. Reviewed milestone lists currently end at 225. No partial list is presented as complete.")
        return
    end
    if p.blocked then
        row("The reviewed route conflicts with your current recipe colors. Open your profession and Refresh; use Overview for live alternatives.")
        return
    end
    local c=p.chosen
    if p.training then row(gold.."TRAINING REQUIRED|r\nYour trained cap is below this target. Unlock the next rank before following this plan.") end
    local title=p.allPriced and "Lowest estimated material cost among reviewed routes" or
        p.pricedCount>0 and "Lowest fully priced route; other routes need prices" or "Bag-friendly reference route; prices incomplete"
    row(gold..title.."|r\n"..p.candidateCount.." researched route(s); "..p.pricedCount.." fully priced. "..
        (c.unknown==0 and ("Missing materials: "..T.Money(c.cost)..".") or "Total purchase cost unknown. Click Prices to compare."),
        "Compares full recipe bands using your prices and open-vendor packs. Owned bags reduce purchases. Does not optimize every possible recipe or mixture. Gathering time, resale value, recipe books and training fees are excluded.")
    row(muted.."Craft counts and materials are estimates, not a guarantee. Stop each step at its target skill; the list refreshes as bags and skill change.\nUnlearned recipes must be obtained first. Budget separately for training and recipe books.|r")
    if prices then
        row(gold.."PRICES FOR ALL REVIEWED ALTERNATIVES|r\nEnter current per-item prices to compare material spending. Quotes are saved per character; update them when the market changes.")
        for _,item in ipairs(p.priceItems) do
            local itemID=item
            local quote=T.saved.levelingPrices[item]
            local cost,source=T.LevelingCost(item,1)
            local text=T.ItemName(item).."\n"..(quote and ("Your quote: "..T.Money(quote.copper).." each") or
                cost and (source..": "..T.Money(cost).." for the smallest pack") or "No price recorded")
            if quote and quote.at and date then text=text.."; saved "..date("%b %d %H:%M",quote.at) end
            row(text,"Blank removes your quote. Your unit quote takes precedence over the current vendor. Quotes do not confirm stock or available auction quantity.","Set unit price",function() T.EditLevelingPrice(itemID) end)
        end
        return
    end
    row(gold.."ALL MATERIALS FOR THIS ROUTE|r\nNeed is total recipe use. Made is supplied by earlier crafts. Missing accounts for both Made and the bags used by this route.")
    for _,m in ipairs(c.materials) do
        if m.need>0 then
            row(gold..T.ItemName(m.item).."|r"..(m.supply and "  (vendor supply)" or "")..
                "\nNeed "..m.need.."   /   Have "..m.have.."   /   Made "..m.fromCrafts..
                "\n"..(m.missing==0 and "Covered by bags / planned crafts" or "Missing "..m.missing)..
                (m.missing>0 and m.cost and ("   |   "..T.Money(m.cost)) or ""),
                "Bags allocated once: "..m.fromBags..". "..m.priceSource..". Bank, mail and other characters are excluded.")
        end
    end
    row(gold.."CRAFT IN THIS ORDER|r")
    for index,s in ipairs(c.steps) do
        local r=s.recipe;local inputs={}
        for item,qty in pairs(r.mats) do inputs[#inputs+1]=(qty*s.crafts).." "..T.ItemName(item) end
        table.sort(inputs)
        row(index..". "..r.name.."\n"..s.crafts.." craft(s)"..(s.extra and " to supply a later recipe" or ("; skill "..s.low.." to "..s.high))..
            "\n"..table.concat(inputs,", ").."\n"..(r.learned and "Learned (recorded)" or (r.source.."; not recorded as learned")),
            "Uses recorded live ingredient quantities when available. Forecast counts are scaled from reviewed guide estimates. Extra supply crafts receive no assumed skill credit. Open the profession to refresh your recipe record.")
    end
    if #c.keep>0 then
        local lines={}
        for _,m in ipairs(c.keep) do lines[#lines+1]=m.amount.." "..T.ItemName(m.item) end
        row(gold.."KEEP THE LEFTOVERS|r\n"..table.concat(lines,", ").." may help with later recipes. Output yields are reference values until scanned in your crafting window.")
    end
    row(muted.."References checked Oct 6, 2026: WoW-Professions Forever guides and Wowhead Forever spell records. Beta recipes can change.|r")
end
