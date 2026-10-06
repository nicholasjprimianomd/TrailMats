local _, T = ...
T.tabOrder={165,393,356,185,129}
T.destinations={148,331,406,17,40,38,0}
T.destinationNames={[148]="Darkshore",[331]="Ashenvale",[406]="Stonetalon Mountains",[17]="The Barrens",[40]="Westfall",[38]="Loch Modan",[0]="Other / not set"}
T.defaultDestinations={[141]=148,[148]=331}
-- Only fishing has a published zone entry requirement. These are minimums,
-- not the much higher skill for avoiding escapes. Base skill is used below;
-- gear/lure bonuses can satisfy the effective requirement but are not counted.
T.fishingMinimum={[148]=1,[331]=55,[406]=55,[17]=1,[40]=1,[38]=1}

function T.Destination()
    local key=T.area~=0 and T.area or T.zoneName
    local selected=T.saved.destinations[key]
    if selected~=nil and T.destinationNames[selected] then return selected,false end
    return T.defaultDestinations[T.area] or 0,true
end

function T.ChangeDestination()
    local current=T.Destination()
    local index=0
    for i,id in ipairs(T.destinations) do if id==current then index=i end end
    local key=T.area~=0 and T.area or T.zoneName
    T.saved.destinations[key]=T.destinations[index % #T.destinations+1]
    T.Refresh(false,false)
end

function T.SelectProfession(id)
    if not T.skills[id] then return end
    T.saved.profession=id
    T.Render();T.MarkMerchant()
end

function T.SelectedProfession()
    if T.skills[T.saved.profession] then return T.saved.profession end
    for _,id in ipairs(T.tabOrder) do if T.skills[id] then T.saved.profession=id;return id end end
end

function T.Departure(id,destination)
    local s=T.skills[id]
    local d={state="unknown",status="Not assessed",goal="No verified departure minimum",reason="This destination is not covered for this profession yet.",action="Keep useful materials. Do not grind to an invented number.",evidence="No reviewed route data.",items={}}
    if not s then return d end
    if destination==0 then
        d.reason="Choose your next zone to assess this profession."
        d.action="Click the Next zone button to change the destination."
        return d
    end
    if destination==T.area then
        d.reason="Your destination is the zone you are already in."
        d.action="Choose the zone you plan to visit next."
        return d
    end
    if id==356 and T.fishingMinimum[destination] then
        local required=T.fishingMinimum[destination]
        d.minimum=required
        d.goal="Minimum to start fishing there: "..required.." effective skill"
        d.evidence="Forever fishing guide reference; beta rules can change."
        d.reason=destination==148 and "You can start in Darkshore at Fishing 1. Skill 75 is for avoiding escapes, not for leaving Teldrassil." or "This is the published minimum to cast in the next zone, not a no-escape target."
        if s.rank>=required then
            d.state="ready";d.status="Ready to continue"
            d.action="Take your fishing pole. Keep leveling Fishing in the next zone."
        else
            d.state="not_yet";d.status="Not yet at the unboosted fishing minimum"
            d.action="Reach Fishing "..required.." here, or use enough pole/lure bonus to reach it. Bonuses are not counted by this check."
        end
        return d
    end
    if destination==148 then
        if id==165 and s.rank<75 then
            d.state="ready";d.status="Ready to continue"
            d.goal="No extra Leatherworking skill needed before leaving"
            d.reason="Starter leather is still available in Darkshore; early Leatherworking does not require finishing in Teldrassil."
            d.action="Keep Light Leather and scraps. Continue your learned leather recipes in Darkshore; check the Skinning tab for gathering."
            d.evidence="Forever recipe facts + Classic skinning-source references; not a guarantee for every beast."
            d.items={2318,2934}
            if not T.skills[393] then
                d.state="unknown";d.status="Self-farming needs Skinning"
                d.action="Learn Skinning if you want to gather your own leather. This is not a Leatherworking skill gate."
            end
        elseif id==129 and s.rank<80 then
            d.state="ready";d.status="Ready to continue"
            d.goal="No extra First Aid skill needed before leaving"
            d.reason="Darkshore humanoids have Linen Cloth sources, so early bandage training can continue there."
            d.action="Keep your Linen Cloth and use your learned bandage recipe. No stockpile is required by this check."
            d.evidence="Forever bandage facts + Questie Classic drop references; Forever drops unverified."
            d.items={2589}
        elseif id==185 and s.rank<50 then
            d.state="ready";d.status="Ready to continue"
            d.goal="No extra Cooking skill needed before leaving"
            d.reason="Darkshore has starter ingredients, including Small Eggs and low-level fish. Cooking 50 is not a departure requirement."
            d.action="Keep ingredients for recipes you know. You do not need a quota of boar meat; fish recipes must be learned separately."
            d.evidence="Forever recipe facts + Classic/Questie ingredient references; availability unverified in Forever."
            d.items={6889}
            if T.skills[356] then d.items={6889,6291,6303} end
        elseif id==185 and s.rank<100 and T.skills[356] then
            d.state="ready";d.status="Ready for a fish-based route"
            d.goal="No extra Cooking skill needed before leaving"
            d.reason="Darkshore water has references for Longjaw Mud Snapper and Rainbow Fin Albacore."
            d.action="Check that you know a matching fish recipe before relying on this route. No fish quota is imposed."
            d.evidence="Forever recipe facts + legacy water references; not a guarantee of catches or learned recipes."
            d.items={6289,6361}
        end
    end
    if id==393 and (destination==148 or destination==331) then
        -- This is a target-specific Classic rule, NEVER a required zone minimum.
        -- Deliberately avoid Moonstalker Runt: public references disagree on level.
        local required=destination==148 and 20 or 100
        local creature=destination==148 and "Thistle Bears (levels 11-12)" or "Ghostpaw Runners (levels 19-20)"
        d.goal="No single zone-wide Skinning minimum"
        d.reason="For "..creature..", the Classic skill reference is "..required..". Lower-level creatures may need less."
        d.evidence="Classic skinning formula + Questie creature levels; confirm the corpse's actual Forever requirement."
        d.referenceGoal=required
        if s.rank>=required then
            d.state="ready";d.status="Ready for the listed starter beasts (reference)"
            d.action="Skin eligible beasts as you quest. You do not need to cover every beast in the next zone before leaving."
        else
            d.state="unknown";d.status="Below the listed beast requirement (reference)"
            d.action="Skin lower-level beasts until "..required.." if following this route. This is not a mandatory departure level."
        end
    end
    if s.rank>=s.cap then d.action=d.action.." Your trained skill is capped; train the next rank to keep gaining skill." end
    return d
end

function T.BuildPlan()
    local destination,assumed=T.Destination()
    T.countCache={} -- One bag query per item for this build only.
    local plan={destination=destination,assumed=assumed,professions={},opportunities={},alternatives={}}
    for _,id in ipairs(T.tabOrder) do
        if T.skills[id] then
            plan.professions[id]=T.Departure(id,destination)
            plan.opportunities[id],plan.alternatives[id]=T.ChooseOpportunity(id)
        end
    end
    plan.future=T.BuildFuture()
    plan.leveling={}
    for _,id in ipairs(T.tabOrder) do
        if T.skills[id] then plan.leveling[id]=T.BuildLeveling(id) end
    end
    T.countCache=nil
    return plan
end

local difficultyScore={optimal=40,medium=30,easy=5}
local difficultyText={optimal="Orange recipe",medium="Yellow recipe",easy="Green recipe"}

function T.Opportunities(profession)
    local s=T.skills[profession]
    local candidates={}
    if not s or not T.professions[profession].craft or s.rank>=s.cap then return candidates end
    for id,r in pairs(T.saved.recipes) do
        -- A fresh scan at the current skill is required. Never infer learned
        -- recipes or current skill-up viability from old colours or seed data.
        if r.profession==profession and r.learned and r.rank==s.rank and difficultyScore[r.difficulty] and type(r.mats)=="table" then
            local score,valid,raw= difficultyScore[r.difficulty],true,0
            local availability=0
            local batch=math.min(T.saved.batch or 3,math.max(1,s.cap-s.rank))
            local materials={}
            for item,qty in pairs(r.mats) do
                if type(item)~="number" or type(qty)~="number" or qty<=0 then valid=false;break end
                local have=T.Count(item);local need=qty*batch;local missing=math.max(0,need-have)
                local vendor=not not T.vendor[item]
                local localHere=not vendor and T.HasLocalSource(item) or false
                if not vendor then
                    raw=raw+1
                    if T.leather[item] and not T.skills[393] and missing>0 then valid=false end
                    if T.fish[item] and not T.skills[356] and missing>0 then valid=false end
                    if missing>0 and not localHere then valid=false end
                    availability=availability+(missing==0 and 50 or 20)
                end
                materials[#materials+1]={item=item,have=have,need=need,missing=missing,vendor=vendor,localHere=localHere,perCraft=qty}
            end
            if valid and raw>0 then
                table.sort(materials,function(a,b) if a.vendor~=b.vendor then return not a.vendor end return a.item<b.item end)
                candidates[#candidates+1]={id=id,name=r.name or tostring(id),materials=materials,batch=batch,score=score+availability/raw-#materials*5,
                    why=difficultyText[r.difficulty].."; ingredients are in your bags or have a source in this zone."}
            end
        end
    end
    table.sort(candidates,function(a,b) if a.score==b.score then return tostring(a.id)<tostring(b.id) end return a.score>b.score end)
    return candidates
end
function T.ChooseOpportunity(profession)
    local candidates=T.Opportunities(profession)
    local chosen=candidates[1]
    for _,r in ipairs(candidates) do if r.id==T.saved.selected[profession] then chosen=r end end
    return chosen,candidates
end
function T.CycleRecipe(profession)
    local chosen,candidates=T.ChooseOpportunity(profession)
    if #candidates<2 then return end
    local index=1
    for i,r in ipairs(candidates) do if chosen and chosen.id==r.id then index=i end end
    T.saved.selected[profession]=candidates[index % #candidates+1].id
    T.Refresh(false,false)
end
function T.CycleBatch()
    local nextBatch={[1]=3,[3]=5,[5]=1}
    T.saved.batch=nextBatch[T.saved.batch] or 3;T.Refresh(false,false)
end
function T.ReadMerchant()
    T.merchantStock={}
    if not T.merchantOpen or not GetMerchantNumItems then return end
    for i=1,(T.Safe(GetMerchantNumItems) or 0) do
        local name,_,price,quantity,available,purchasable,_,extended,currency=T.Safe(GetMerchantItemInfo,i)
        local link=T.Safe(GetMerchantItemLink,i)
        local item=T.Safe(GetMerchantItemID,i) or (link and tonumber(link:match("item:(%d+)")))
        if item and name and type(price)=="number" and price>=0 and type(quantity)=="number" and quantity>0 and available and available~=0 and purchasable~=false and not extended and (not currency or currency==0) then
            T.merchantStock[#T.merchantStock+1]={index=i,item=item,name=name,price=price,quantity=quantity,available=available}
        end
    end
end
function T.Money(copper)
    local gold=math.floor(copper/10000);local silver=math.floor(copper/100)%100;local c=copper%100
    if gold>0 then return gold.."g "..silver.."s "..c.."c" end
    if silver>0 then return silver.."s "..c.."c" end
    return c.."c"
end
function T.MerchantSuggestions(opportunity)
    local suggestions={}
    if not opportunity then return suggestions end
    for _,m in ipairs(opportunity.materials) do
        -- Recommend only basic vendor supplies, never buying farmed raw materials.
        if m.vendor and m.missing>0 then
            local best
            for _,stock in ipairs(T.merchantStock or {}) do
                if stock.item==m.item then
                    local packs=math.ceil(m.missing/stock.quantity)
                    if stock.available>=0 then packs=math.min(packs,math.floor(stock.available/stock.quantity)) end
                    if packs>0 then
                        local amount=packs*stock.quantity;local cost=packs*stock.price
                        local row={index=stock.index,item=m.item,amount=amount,cost=cost,missing=m.missing,packs=packs,
                            remaining=math.max(0,m.missing-amount),recipe=opportunity.name,batch=opportunity.batch}
                        if not best or row.remaining<best.remaining or (row.remaining==best.remaining and row.cost<best.cost) then best=row end
                    end
                end
            end
            if best then suggestions[#suggestions+1]=best end
        end
    end
    table.sort(suggestions,function(a,b) return a.cost<b.cost end)
    return suggestions
end
function T.CurrentOpportunity()
    local id=T.SelectedProfession()
    return id and T.plan and T.plan.opportunities[id]
end
function T.CurrentMaterials()
    local op=T.CurrentOpportunity()
    return op and op.materials or {}
end
function T.CurrentMerchantSuggestions()
    return T.MerchantSuggestions(T.CurrentOpportunity())
end
function T.MerchantText(row)
    local text="Consider "..row.amount.." "..T.ItemName(row.item).." for "..T.Money(row.cost).." total."
    return text.." Need "..row.missing.." more for "..row.batch.." crafts of "..row.recipe.."."..
        (row.amount>row.missing and " Extra units come from the vendor's pack size." or "")..
        (row.remaining>0 and " Limited stock; still need "..row.remaining.." after that." or "")
end
function T.MarkMerchant()
    for _,f in pairs(T.merchantMarks or {}) do f:Hide() end
    if not T.merchantOpen or not MerchantFrame or MerchantFrame.selectedTab~=1 then return end
    T.merchantMarks=T.merchantMarks or {}
    local perPage=MERCHANT_ITEMS_PER_PAGE or 10
    local page=MerchantFrame.page or 1
    for _,r in ipairs(T.CurrentMerchantSuggestions()) do
        local slot=r.index-(page-1)*perPage
        local anchor=_G["MerchantItem"..slot.."ItemButton"]
        if slot>=1 and slot<=perPage and anchor then
            local mark=T.merchantMarks[slot]
            if not mark then
                mark=anchor:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
                mark:SetPoint("BOTTOMLEFT",anchor,"TOPLEFT",0,2);T.merchantMarks[slot]=mark
            end
            mark:SetText("TrailMats: "..r.amount);mark:Show()
        end
    end
end
function T.InstallMerchantHook()
    if T.merchantHook or not hooksecurefunc or not MerchantFrame_UpdateMerchantInfo then return end
    hooksecurefunc("MerchantFrame_UpdateMerchantInfo",function() T.MarkMerchant() end)
    T.merchantHook=true
end
