local _, T = ...

-- Small reviewed catalog for basic crafting. Bands are planning guidance, not
-- exact learning requirements. Future advice never grants a learned recipe.
local sources={
    trainer="Trainer recipe",
    vendor="Buy the recipe from a Cooking recipe vendor",
    quest="Optional quest recipe: Recipe of the Kaldorei (Alliance)",
}
T.futureCatalog={}
local function add(id,profession,name,low,high,source,mats)
    T.futureCatalog[#T.futureCatalog+1]={id=id,profession=profession,name=name,low=low,high=high,source=source,mats=mats}
end
for _,r in ipairs(T.recipes) do
    local band=T.recipeBands[r.id] or {r.start,r.stop}
    local source=T.fish[next(r.mats)] and "vendor" or "trainer"
    if r.id==6412 then source="quest" end
    add(r.id,r.profession,r.name,band[1],band[2],source,r.mats)
end
-- Factual ingredient tuples from the reviewed Forever profession guides.
add("light-leather",165,"Light Leather",1,30,"trainer",{[2934]=3})
add("cured-light-hide",165,"Cured Light Hide",30,55,"trainer",{[783]=1,[4289]=1})
add("medium-leather",165,"Medium Leather",75,80,"trainer",{[2318]=4})
add("cured-medium-hide",165,"Cured Medium Hide",80,90,"trainer",{[4232]=1,[4289]=1})
add("fine-leather-belt",165,"Fine Leather Belt",90,100,"trainer",{[2318]=6,[2320]=2})
add("light-leather-pants",165,"Light Leather Pants",100,115,"trainer",{[2318]=10,[4231]=1,[2321]=1})
add("catfish",185,"Bristle Whisker Catfish",100,150,"vendor",{[6308]=1})
add("boiled-clams",185,"Boiled Clams",50,100,"trainer",{[5503]=1,[159]=1})
add("coyote-steak",185,"Coyote Steak",50,100,"trainer",{[2673]=1})
add("crab-cake",185,"Crab Cake",100,130,"trainer",{[2674]=1,[2678]=1})
add("dry-pork-ribs",185,"Dry Pork Ribs",100,130,"trainer",{[2677]=1,[2678]=1})
add("heavy-wool",129,"Heavy Wool Bandage",115,150,"trainer",{[2592]=2})
T.items[783]="Light Hide";T.items[4289]="Salt";T.items[4232]="Medium Hide"
T.items[6308]="Raw Bristle Whisker Catfish";T.items[5503]="Clam Meat"
T.items[2673]="Coyote Meat";T.items[2677]="Boar Ribs"
T.items[4231]="Cured Light Hide";T.items[2321]="Fine Thread"
T.vendor[4289]=true
T.vendor[2321]=true
T.fish[6308]=true

function T.FutureProfession(id)
    if id==356 then return 185 end
    if id==393 then return 165 end
    return id
end

local function learnedRecipe(r,byName)
    local recorded=T.saved.recipes[r.id]
    if recorded and recorded.profession==r.profession and recorded.learned then return recorded end
    return byName[r.profession..":"..r.name]
end

local function better(a,b)
    if a.coverage~=b.coverage then return a.coverage>b.coverage end
    if a.distance~=b.distance then return a.distance<b.distance end
    if a.learned~=b.learned then return a.learned end
    if a.source~=b.source then
        local priority={trainer=1,vendor=2,quest=3}
        return priority[a.source]<priority[b.source]
    end
    return a.name<b.name
end

function T.BuildFuture()
    local result={byItem={},byProfession={}}
    local batch=T.saved.batch or 3
    local byName={}
    for _,r in pairs(T.saved.recipes) do
        if r.learned and r.profession and r.name then byName[r.profession..":"..r.name]=r end
    end
    local faction=T.Safe(UnitFactionGroup,"player")
    for _,r in ipairs(T.futureCatalog) do
        local skill=T.skills[r.profession]
        local learned=learnedRecipe(r,byName)
        local accessible=r.source~="quest" or learned or faction=="Alliance"
        local fresh=learned and learned.rank== (skill and skill.rank)
        local viable=fresh and (learned.difficulty=="optimal" or learned.difficulty=="medium" or learned.difficulty=="easy")
        if skill and accessible and (skill.rank<r.high or viable) and not (fresh and learned.difficulty=="trivial") then
            local c={id=r.id,name=r.name,profession=r.profession,low=r.low,high=r.high,source=r.source,
                learned=not not learned,batch=batch,distance=math.max(0,r.low-skill.rank),
                materials={},rawHave=0,rawNeed=0,rawKindsHeld=0,missing={},suppliesMissing={},
                trainRank=skill.rank>=skill.cap or r.low>skill.cap}
            local mats=learned and learned.mats or r.mats
            local valid=type(mats)=="table" and next(mats)~=nil
            if valid then
                for item,qty in pairs(mats) do
                    if type(item)~="number" or type(qty)~="number" or qty<=0 then valid=false;break end
                    local have=T.Count(item);local need=qty*batch;local missing=math.max(0,need-have)
                    local vendor=not not T.vendor[item]
                    local m={item=item,have=have,need=need,missing=missing,vendor=vendor}
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
                c.readiness=c.coverage>=1 and "Raw materials ready" or c.coverage>=0.5 and "Most raw materials held" or "Some materials still needed"
                c.recipeStatus=c.learned and "Learned (recorded)" or (sources[c.source].."; not recorded as learned")
                table.sort(c.materials,function(a,b) return a.item<b.item end)
                local function order(a,b) return a.item<b.item end
                table.sort(c.missing,order);table.sort(c.suppliesMissing,order)
                -- Inventory view shows held materials at any supported future band.
                -- Tooltip index includes unheld items too, so new loot can be assessed.
                for _,m in ipairs(c.materials) do
                    if not m.vendor then
                        result.byItem[m.item]=result.byItem[m.item] or {}
                        result.byItem[m.item][#result.byItem[m.item]+1]={recipe=c,material=m}
                        if m.have>0 then
                            result.byProfession[c.profession]=result.byProfession[c.profession] or {}
                            local list=result.byProfession[c.profession]
                            list[m.item]=list[m.item] or {}
                            list[m.item][#list[m.item]+1]={recipe=c,material=m}
                        end
                    end
                end
            end
        end
    end
    for _,uses in pairs(result.byItem) do table.sort(uses,function(a,b) return better(a.recipe,b.recipe) end) end
    for profession,items in pairs(result.byProfession) do
        local rows={}
        for item,uses in pairs(items) do
            table.sort(uses,function(a,b) return better(a.recipe,b.recipe) end)
            rows[#rows+1]={item=item,uses=uses,recipe=uses[1].recipe,material=uses[1].material}
        end
        table.sort(rows,function(a,b)
            if a.recipe==b.recipe then return a.item<b.item end
            return better(a.recipe,b.recipe)
        end)
        result.byProfession[profession]=rows
    end
    return result
end

local function amounts(list)
    local text={}
    for _,m in ipairs(list) do text[#text+1]=m.amount.." "..T.ItemName(m.item) end
    return table.concat(text,", ")
end
function T.FutureText(use)
    local c,m=use.recipe,use.material
    local text="Set aside "..math.min(m.have,m.need).." of "..m.have.." held (batch needs "..m.need..").\n"..
        c.batch.." crafts of "..c.name.." | "..T.professions[c.profession].name.." "..c.low.."-"..c.high.." recommended.\n"..
        c.readiness..". "..c.recipeStatus.."."
    if c.distance>0 then text=text.."\n"..c.distance.." skill to the suggested band." end
    if c.trainRank then text=text.." Train the next profession rank when eligible." end
    if #c.missing>0 then text=text.."\nOther/remaining raw materials: "..amounts(c.missing).."." end
    if #c.suppliesMissing>0 then text=text.."\nBasic vendor supplies: "..amounts(c.suppliesMissing).."." end
    return text
end
function T.FutureDetail(use)
    local c=use.recipe
    return "One optional batch, not a leveling stockpile. Do not add overlapping recipe options together. Extra materials may have other uses. "..
        (c.learned and "Quantities use your recorded learned recipe." or "Quantities use reviewed Forever reference data; check the recipe before crafting.")..
        " Open the profession to update learned status. Bands are planning ranges, not exact learning requirements."
end

function T.AddKeepTooltip(tooltip,item)
    local uses=T.plan and T.plan.future and T.plan.future.byItem[item]
    if not uses or not uses[1] then return false end
    -- Global across owned professions, independent of the selected tab or view.
    local seen,count={},0
    for _,use in ipairs(uses) do
        local c,m=use.recipe,use.material
        if not seen[c.profession] then
            seen[c.profession]=true;count=count+1
            tooltip:AddLine("TrailMats: keep for "..c.name.." ("..T.professions[c.profession].name.." "..c.low.."-"..c.high..").",1,0.82,0.5,true)
            tooltip:AddLine("One "..c.batch.."-craft batch uses "..m.need.."; bags: "..T.Count(item)..". "..c.recipeStatus..".",0.8,0.9,0.8,true)
            if count>=3 then break end
        end
    end
    return count>0
end
