local _, T = ...
local function copy(t) local r={};for k,v in pairs(t or {}) do r[k]=v end;return r end
local function validMats(mats)
    if type(mats)~="table" or not next(mats) then return false end
    for item,qty in pairs(mats) do
        if type(item)~="number" or type(qty)~="number" or qty<=0 or qty~=qty or qty==math.huge then return false end
    end
    return true
end

function T.NextMilestone(rank)
    for _,goal in ipairs({75,150,225,300}) do if rank<goal then return goal end end
    return 300
end

function T.LevelingRecipe(reference)
    local live
    for _,r in pairs(T.saved.recipes or {}) do
        if r.profession==reference.profession and r.name==reference.name and r.learned and validMats(r.mats) then live=r;break end
    end
    local r=copy(reference)
    r.mats=copy(live and live.mats or reference.mats)
    r.learned=live~=nil
    r.gray=live and live.rank==T.skills[r.profession].rank and live.difficulty=="trivial"
    if r.output and live and live.outputItem==r.output[1] and type(live.outputCount)=="number" and live.outputCount>0 then
        r.output={live.outputItem,live.outputCount}
    end
    return r
end

-- Prices are explicit copper-per-item quotes, never vendor sell values or inferred AH prices.
function T.SetLevelingPrice(item,value)
    local amount=tonumber(value)
    if not item or not amount or amount<0 or amount~=amount or amount==math.huge or amount>1000000000 then return false end
    T.saved.levelingPrices=T.saved.levelingPrices or {}
    T.saved.levelingPrices[item]={copper=amount,at=T.Safe(time)}
    T.Refresh(false,false)
    return true
end

function T.LevelingCost(item,amount)
    if amount<=0 then return 0,"Already covered" end
    local quote=T.saved.levelingPrices and T.saved.levelingPrices[item]
    if type(quote)=="table" and type(quote.copper)=="number" and quote.copper>=0 and quote.copper<math.huge then
        return math.ceil(quote.copper*amount),"Your unit price"
    end
    local best
    if T.levelingSupplies[item] then
        for _,v in ipairs(T.merchantStock or {}) do
            if v.item==item then
                local packs=math.ceil(amount/v.quantity)
                if v.available==-1 or v.available>=packs*v.quantity then
                    local price=packs*v.price
                    if not best or price<best then best=price end
                end
            end
        end
    end
    if best then return best,"Open vendor; whole packs" end
    return nil,"Price needed"
end

-- Simulate a whole route in order. Bags and intermediate outputs are consumed once.
-- Extra intermediate crafts do not receive speculative skill credit.
function T.EvaluateLevelingRoute(profession,route)
    local result={steps={},materials={},byItem={},cost=0,unknown=0,missingRaw=0,rawNeed=0,unlearned=0,keep={}}
    local bags,made={},{}
    local function row(item)
        if not result.byItem[item] then
            local have=T.Count(item);bags[item]=have;made[item]=made[item] or 0
            local m={item=item,have=have,need=0,missing=0,fromBags=0,fromCrafts=0,supply=not not T.levelingSupplies[item]}
            result.byItem[item]=m;result.materials[#result.materials+1]=m
        end
        return result.byItem[item]
    end
    local craft,consume
    consume=function(item,amount,depth)
        local m=row(item);m.need=m.need+amount
        local generated=math.min(amount,made[item]);made[item]=made[item]-generated
        m.fromCrafts=m.fromCrafts+generated;amount=amount-generated
        local owned=math.min(amount,bags[item]);bags[item]=bags[item]-owned
        m.fromBags=m.fromBags+owned;amount=amount-owned
        local key=T.levelingConversions[item]
        if amount>0 and key and profession==165 and depth<4 then
            local r=T.LevelingRecipe(T.levelingRecipes[key])
            local count=math.ceil(amount/r.output[2])
            craft(r,count,nil,nil,true,depth+1)
            generated=math.min(amount,made[item]);made[item]=made[item]-generated
            m.fromCrafts=m.fromCrafts+generated;amount=amount-generated
        end
        if amount>0 then m.missing=m.missing+amount end
    end
    craft=function(r,count,lo,hi,extra,depth)
        local inputs={}
        for item in pairs(r.mats) do inputs[#inputs+1]=item end
        table.sort(inputs)
        for _,item in ipairs(inputs) do consume(item,r.mats[item]*count,depth or 0) end
        result.steps[#result.steps+1]={recipe=r,crafts=count,low=lo,high=hi,extra=extra}
        if not r.learned then result.unlearned=result.unlearned+1 end
        if r.output then
            row(r.output[1]);made[r.output[1]]=made[r.output[1]]+count*r.output[2]
        end
    end
    for _,s in ipairs(route) do craft(s.recipe,s.crafts,s.low,s.high,false,0) end
    for _,m in ipairs(result.materials) do
        m.cost,m.priceSource=T.LevelingCost(m.item,m.missing)
        if m.cost then result.cost=result.cost+m.cost else result.unknown=result.unknown+1 end
        if not m.supply then result.missingRaw=result.missingRaw+m.missing;result.rawNeed=result.rawNeed+m.need end
        if made[m.item]>0 then result.keep[#result.keep+1]={item=m.item,amount=made[m.item]} end
    end
    table.sort(result.materials,function(a,b)
        if a.supply~=b.supply then return not a.supply end
        return a.item<b.item
    end)
    return result
end

function T.BuildLeveling(profession)
    local skill=T.skills[profession]
    if not skill then return nil end
    local target=T.NextMilestone(skill.rank)
    local plan={profession=profession,start=skill.rank,target=target,training=skill.cap<target,alternatives={},priceItems={}}
    if not T.levelingEdges[profession] then plan.gathering=true;return plan end
    if skill.rank>=300 then plan.complete=true;return plan end
    if target>T.levelingLimit then plan.unsupported=true;return plan end
    local candidates,items={},{}
    local faction=T.Safe(UnitFactionGroup,"player")
    local function walk(at,route)
        if at>=target then candidates[#candidates+1]=T.EvaluateLevelingRoute(profession,route);return end
        for _,e in ipairs(T.levelingEdges[profession]) do
            if e.low<=at and at<e.high then
                local r=T.LevelingRecipe(e.recipe)
                if not r.gray and (not r.faction or r.faction==faction or r.learned) then
                    local stop=math.min(target,e.high)
                    -- Scale the source's estimated whole-band count; never promise exact skill-ups.
                    local count=math.ceil((stop-at)*e.crafts/(e.high-e.low))
                    route[#route+1]={recipe=r,low=at,high=stop,crafts=count}
                    walk(stop,route);route[#route]=nil
                end
            end
        end
    end
    walk(skill.rank,{})
    plan.candidateCount=#candidates
    if #candidates==0 then plan.blocked=true;return plan end
    local priced=0
    for index,r in ipairs(candidates) do
        r.order=index
        if r.unknown==0 then priced=priced+1 end
        for _,m in ipairs(r.materials) do items[m.item]=true end
    end
    table.sort(candidates,function(a,b)
        if (a.unknown==0)~=(b.unknown==0) then return a.unknown==0 end
        if a.unknown==0 and a.cost~=b.cost then return a.cost<b.cost end
        local ca=a.rawNeed>0 and a.missingRaw/a.rawNeed or 0
        local cb=b.rawNeed>0 and b.missingRaw/b.rawNeed or 0
        if ca~=cb then return ca<cb end
        -- Stable researched ordering resolves ties without treating unknown costs as zero.
        return a.order<b.order
    end)
    plan.pricedCount=priced;plan.allPriced=priced==#candidates
    plan.chosen=candidates[1]
    plan.alternatives=candidates
    for item in pairs(items) do plan.priceItems[#plan.priceItems+1]=item end
    table.sort(plan.priceItems)
    return plan
end
