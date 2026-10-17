-- Automatic goals and keep limits, including shared and intermediate materials.
local root=arg[1] or "."
local T={saved={recipes={},levelingPrices={},batch=5},skills={}}
local bags={}
T.Count=function(item) return bags[item] or 0 end
T.Safe=function(fn,...) if type(fn)=="function" then return fn(...) end end
T.ItemName=function(item) return T.items[item] or tostring(item) end
UnitFactionGroup=function() return "Alliance" end
for _,name in ipairs({"Data","Ranges","Future","LevelingData","Leveling","Automatic"}) do
    assert(loadfile(root.."/TrailMats/"..name..".lua"))("TrailMats",T)
end
local checks=0
local function check(ok,label) assert(ok,label);checks=checks+1 end
local function reset(id,rank,cap)
    T.skills={[id]={rank=rank,cap=cap or 300}}
    T.saved.recipes={};bags={}
end
local function use(item)
    local uses=T.BuildFuture().byItem[item]
    return uses and uses[1]
end
local function need(item) local u=use(item);return u and u.material.need end

local a=T.AutomaticTarget(165,"Light Armor Kit",20,75)
check(a.crafts==12 and a.stop==30,"kit aims for reviewed switch, not fixed batch")
a=T.AutomaticTarget(165,"Light Armor Kit",29,75)
check(a.crafts==2 and a.stop==30,"round remaining estimated crafts upward")
check(not T.AutomaticTarget(165,"Light Armor Kit",30,75),"stop at switch even if still orange")
a=T.AutomaticTarget(165,"Light Armor Kit",20,25)
check(a.crafts==6 and a.stop==25,"trained cap limits current crafts")
check(not T.AutomaticTarget(165,"Unreviewed recipe",20,75),"unknown range has no invented target")
a=T.AutomaticTarget(185,"Bristle Whisker Catfish",125,225)
check(a.crafts==30 and a.stop==150,"one recipe joins contiguous guide intervals")

reset(185,20,75)
check(need(6291)==34,"smallfish reserve reaches 50, not three crafts")
check(need(6308)==55 and use(6308).stop==150,"unlearned later fish gets full useful reserve")
T.skills[185].rank=49;check(need(6291)==2,"reserve shrinks with skill")
T.skills[185].rank=50;check(not need(6291),"obsolete fish leaves guidance")
T.skills[185].rank=20
T.saved.recipes[1]={name="Brilliant Smallfish",profession=185,rank=20,learned=true,difficulty="easy",mats={[6291]=1}}
check(not need(6291),"live green overrides guide efficiency")
T.skills[185].rank=21;check(not need(6291),"older green record cannot revive as skill rises")
T.skills[185].rank=20;T.saved.recipes[1].difficulty="medium";T.saved.recipes[1].mats[6291]=2
check(need(6291)==68,"live ingredient counts override references")
T.saved.recipes[1].mats[6291]=0/0;check(not need(6291),"invalid recipe quantity cannot poison reserve")
T.saved.recipes={};UnitFactionGroup=function() return "Horde" end
check(not need(5465),"unlearned faction recipe excluded")
UnitFactionGroup=function() return "Alliance" end

reset(129,20,75);bags[2589]=10
local u=use(2589)
check(u.material.need==130 and u.material.missing==120 and u.stop==80,"successive linen uses added, bags subtracted once")
T.skills[129].rank=40;check(need(2589)==104,"finished linen recipe no longer reserved")
T.skills[129].rank=80;check(not need(2589),"linen stops after last supported use")
check(need(2592)==150,"both wool recipes included")
T.skills[129].rank=150;check(not need(2592),"wool stops at 150")

reset(165,1)
check(need(783)==27,"curing output covers later pants without duplicate raw hides")
T.skills[165].rank=55;check(need(783)==12,"keep raw hides for future intermediate after curing skill band")
bags[4231]=24;check(not need(783),"owned cured hides eliminate extra preparation reserve")
bags={};T.skills[165].rank=100
T.saved.recipes[1]={name="Cured Light Hide",profession=165,rank=100,learned=true,difficulty="trivial",mats={[783]=1,[4289]=1},outputItem=4231,outputCount=1}
check(need(783)==24,"gray intermediate allowed for ingredients, live yield respected")
check(T.FutureText(use(783)):find("prepare ingredients",1,true),"intermediate purpose explained")
T.skills[165].rank=115;T.saved.recipes={}
check(need(2318)==30,"later belt inputs survive direct leather cutoff")
bags[4246]=10;check(not need(2318),"owned intermediate belts avoid reserving duplicate leather")

-- Overlapping alternatives for the same input must not double its reserve.
reset(165,140)
local medium=need(2319)
check(medium==280,"overlapping Hillman bands counted once")

-- Every supported rank yields finite, integer totals and consistent explanations.
for _,id in ipairs({165,185,129}) do
    for rank=1,225 do
        reset(id,rank,75)
        local f=T.BuildFuture()
        for item,uses in pairs(f.byItem) do
            for _,r in ipairs(uses) do
                local m=r.material
                check(m.need>0 and m.need==math.floor(m.need) and m.need<10000,"bounded integer reserve")
                check(r.stop>rank and r.stop<=225,"only remaining reviewed uses")
                local total=0;for _,part in ipairs(r.parts) do total=total+part.amount end
                check(total==m.need and m.missing==m.need,"reserve explanation conserves quantities")
            end
        end
        if rank==225 then check(next(f.byItem)==nil,"unsupported later tiers not guessed") end
    end
end
print("PASS: "..checks.." automatic target, efficiency, reserve and intermediate checks")
