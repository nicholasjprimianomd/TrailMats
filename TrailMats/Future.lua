local _, T = ...

T.items[783]="Light Hide";T.items[4289]="Salt";T.items[4232]="Medium Hide"
T.items[6308]="Raw Bristle Whisker Catfish";T.items[5503]="Clam Meat"
T.items[2673]="Coyote Meat";T.items[2677]="Boar Ribs"
T.items[4231]="Cured Light Hide";T.items[2321]="Fine Thread"
T.vendor[4289]=true
T.vendor[2321]=true
T.fish[6308]=true

function T.FutureProfession(id)
    local info=T.professions[id]
    return info and info.pair or id
end

local function better(a,b)
    if a.coverage~=b.coverage then return a.coverage>b.coverage end
    if a.distance~=b.distance then return a.distance<b.distance end
    if a.learned~=b.learned then return a.learned end
    if a.source~=b.source then
        local priority={trainer=1,vendor=2,quest=3}
        local pa=priority[a.source] or (a.source=="Trainer" and 1 or 2)
        local pb=priority[b.source] or (b.source=="Trainer" and 1 or 2)
        if pa~=pb then return pa<pb end
    end
    return a.name<b.name
end

-- Reuse the complete reviewed leveling data. One record per recipe name.
local cachedCatalog
local function catalog()
    if cachedCatalog then return cachedCatalog end
    local list,seen={},{}
    for profession,edges in pairs(T.levelingEdges) do
        for _,e in ipairs(edges) do
            local key=profession..":"..e.recipe.name
            local c=seen[key]
            if not c then
                c={name=e.recipe.name,profession=profession,low=e.low,high=e.high,
                    source=e.recipe.source,mats=e.recipe.mats,faction=e.recipe.faction,key=e.recipe.key}
                seen[key]=c;list[#list+1]=c
            else c.low=math.min(c.low,e.low);c.high=math.max(c.high,e.high) end
        end
    end
    table.sort(list,function(a,b) if a.profession~=b.profession then return a.profession<b.profession end return a.name<b.name end)
    cachedCatalog=list
    return list
end

-- For a material, add successive uses, but never add two alternative recipes
-- for the same skill interval. This is a keep-up-to limit, not a shopping list.
local function reserve(item,uses)
    local points,seen={},{}
    for _,use in ipairs(uses) do
        for _,s in ipairs(use.recipe.segments) do
            for _,n in ipairs({s.low,s.high}) do if not seen[n] then seen[n]=true;points[#points+1]=n end end
        end
    end
    table.sort(points)
    local amounts,stop={},0
    for i=1,#points-1 do
        local lo,hi=points[i],points[i+1]
        local chosen,segment
        for _,use in ipairs(uses) do
            for _,s in ipairs(use.recipe.segments) do
                if s.low<=lo and s.high>=hi and (not chosen or better(use.recipe,chosen.recipe)) then chosen=use;segment=s end
            end
        end
        if chosen then
            amounts[chosen]=(amounts[chosen] or 0)+(hi-lo)*segment.crafts/(segment.high-segment.low)
            stop=math.max(stop,hi)
        end
    end
    local total,parts=0,{}
    for _,use in ipairs(uses) do
        if amounts[use] then
            local count=math.ceil(amounts[use]-0.000001)*use.material.perCraft
            total=total+count;parts[#parts+1]={recipe=use.recipe,amount=count}
        end
    end
    local have=T.Count(item)
    return {item=item,uses=uses,parts=parts,recipe=uses[1].recipe,stop=stop,
        material={item=item,have=have,need=total,missing=math.max(0,total-have)}}
end

function T.BuildFuture()
    local result={byItem={},byProfession={}}
    local byName={}
    for _,r in pairs(T.saved.recipes) do
        if r.learned and r.profession and r.name then byName[r.profession..":"..r.name]=r end
    end
    local faction=T.Safe(UnitFactionGroup,"player")
    local grouped={}
    for _,r in ipairs(catalog()) do
        local skill=T.skills[r.profession]
        local learned=byName[r.profession..":"..r.name]
        local fresh=learned and skill and type(learned.rank)=="number" and learned.rank<=skill.rank
        local stopped=fresh and (learned.difficulty=="trivial" or learned.difficulty=="easy")
        local start=skill and math.max(skill.rank,r.low)
        local target=start and T.AutomaticTarget(r.profession,r.name,start)
        if skill and target and not stopped and (not r.faction or r.faction==faction or learned) then
            local c={id=r.key,name=r.name,profession=r.profession,low=start,high=target.stop,source=r.source,
                learned=not not learned,batch=target.crafts,segments=target.segments,distance=math.max(0,r.low-skill.rank),
                materials={},rawHave=0,rawNeed=0,rawKindsHeld=0,missing={},suppliesMissing={},
                trainRank=skill.cap<target.stop}
            local mats=learned and learned.mats or r.mats
            local valid=type(mats)=="table" and next(mats)~=nil
            if valid then
                for item,qty in pairs(mats) do
                    if type(item)~="number" or type(qty)~="number" or qty<=0 or qty~=qty or qty==math.huge then valid=false;break end
                    local have=T.Count(item);local need=qty*target.crafts;local missing=math.max(0,need-have)
                    local vendor=not not T.levelingSupplies[item]
                    local m={item=item,have=have,need=need,missing=missing,vendor=vendor,perCraft=qty}
                    c.materials[#c.materials+1]=m
                    if not vendor then
                        c.rawHave=c.rawHave+math.min(have,need);c.rawNeed=c.rawNeed+need
                        if have>0 then c.rawKindsHeld=c.rawKindsHeld+1 end
                    end
                    if missing>0 then
                        local list=vendor and c.suppliesMissing or c.missing
                        list[#list+1]={item=item,amount=missing}
                    end
                end
            end
            if valid and c.rawNeed>0 then
                c.coverage=c.rawHave/c.rawNeed
                c.readiness=c.coverage>=1 and "Materials covered" or "Materials still needed"
                c.recipeStatus=c.learned and "Learned (recorded)" or (c.source.."; not recorded as learned")
                grouped[c.profession]=grouped[c.profession] or {}
                for _,m in ipairs(c.materials) do
                    if not m.vendor then
                        local items=grouped[c.profession]
                        items[m.item]=items[m.item] or {}
                        items[m.item][#items[m.item]+1]={recipe=c,material=m}
                    end
                end
            end
        end
    end
    for profession,items in pairs(grouped) do
        local rows={}
        for item,uses in pairs(items) do
            table.sort(uses,function(a,b) return better(a.recipe,b.recipe) end)
            rows[item]=reserve(item,uses)
        end
        -- Preserve inputs for intermediate crafts even after those crafts stop
        -- giving worthwhile skill. Credit their planned production once.
        local expanded={}
        local function expand(item,depth)
            if expanded[item] or depth>4 then return end
            expanded[item]=true
            local use=rows[item];local key=T.levelingConversions[item]
            if not use or not key or T.levelingRecipes[key].profession~=profession then return end
            local r=T.LevelingRecipe(T.levelingRecipes[key])
            local crafts=math.ceil(use.material.missing/r.output[2])
            for input,qty in pairs(r.mats) do
                if not T.levelingSupplies[input] then
                    local existing=rows[input];local represented=0
                    if existing then
                        for _,part in ipairs(existing.parts) do if part.recipe.name==r.name then represented=represented+part.amount end end
                    end
                    if existing and crafts>0 then existing.stop=math.max(existing.stop,use.stop) end
                    local extra=math.max(0,crafts*qty-represented)
                    if extra>0 then
                        local c={name=r.name,profession=profession,low=T.skills[profession].rank,high=use.stop,
                            source=r.source,learned=r.learned,coverage=0,distance=0,trainRank=use.stop>T.skills[profession].cap,
                            recipeStatus=r.learned and "Learned (recorded)" or r.source.."; not recorded as learned",preparation=true}
                        if not existing then
                            local have=T.Count(input)
                            existing={item=input,recipe=c,uses={},parts={},stop=use.stop,material={item=input,have=have,need=0}}
                            rows[input]=existing
                        end
                        existing.parts[#existing.parts+1]={recipe=c,amount=extra}
                        existing.material.need=existing.material.need+extra
                        existing.material.missing=math.max(0,existing.material.need-existing.material.have)
                        existing.stop=math.max(existing.stop,use.stop)
                        expand(input,depth+1)
                    end
                end
            end
        end
        for item in pairs(T.levelingConversions) do expand(item,0) end
        local visible={}
        for item,use in pairs(rows) do
            result.byItem[item]=result.byItem[item] or {}
            result.byItem[item][#result.byItem[item]+1]=use
            if use.material.have>0 then visible[#visible+1]=use end
        end
        table.sort(visible,function(a,b) if a.stop~=b.stop then return a.stop<b.stop end return a.item<b.item end)
        result.byProfession[profession]=visible
    end
    for _,uses in pairs(result.byItem) do table.sort(uses,function(a,b) return a.recipe.profession<b.recipe.profession end) end
    return result
end

function T.FutureText(use)
    local m=use.material
    local text="Keep up to "..m.need.." "..T.ItemName(use.item).."; you have "..m.have..".\n"..
        "Useful through "..T.professions[use.recipe.profession].name.." "..use.stop.." (estimated)."
    for index,part in ipairs(use.parts) do
        if index>2 then text=text.."\nAlso needed by later recipes.";break end
        local c=part.recipe
        text=text.."\nFor "..c.name..(c.preparation and " (prepare ingredients)" or "").."."
        if not c.learned then text=text.." "..c.source.."; check that you know it." end
    end
    if use.stop>T.skills[use.recipe.profession].cap then text=text.."\nSave for later training ranks." end
    return text
end
function T.FutureDetail(use)
    return "Estimated keep limit, not a farming order. Alternative ingredients can cover the same skill points. Plan shows what to collect for the chosen route."
end

function T.AddKeepTooltip(tooltip,item)
    local uses=T.plan and T.plan.future and T.plan.future.byItem[item]
    if not uses or not uses[1] then return false end
    local total=0
    for _,use in ipairs(uses) do total=total+use.material.need end
    tooltip:AddLine("TrailMats: keep up to "..total.."; bags: "..T.Count(item).." (estimated).",1,0.82,0.5,true)
    for _,use in ipairs(uses) do
        local c=use.recipe
        tooltip:AddLine(T.professions[c.profession].name..": "..use.material.need.." for "..c.name..
            (#use.parts>1 and " and later recipes" or "").." (through skill "..use.stop..").",0.8,0.9,0.8,true)
    end
    return true
end
