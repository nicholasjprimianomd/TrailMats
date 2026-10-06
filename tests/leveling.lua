-- Focused economic and inventory checks, independent of the UI mock.
local root=arg[1] or "."
local T={saved={recipes={},levelingPrices={}},skills={}}
local bags={}
T.Count=function(id) return bags[id] or 0 end
T.Safe=function(fn,...) if type(fn)=="function" then return fn(...) end end
T.Refresh=function() end
UnitFactionGroup=function() return "Alliance" end
for _,file in ipairs({"Data","Ranges","Future","LevelingData","Leveling"}) do
    assert(loadfile(root.."/TrailMats/"..file..".lua"))("TrailMats",T)
end
local checks=0
local function check(ok,label) assert(ok,label);checks=checks+1 end
local function reset(rank,id,cap)
    bags={};T.saved.recipes={};T.saved.levelingPrices={};T.merchantStock={}
    T.skills={[id or 129]={rank=rank,cap=cap or 300}}
end
local function price(id,value) T.saved.levelingPrices[id]={copper=value} end
local function chosen(id) return T.BuildLeveling(id or 129).chosen end
reset(1)
local p=T.BuildLeveling(129)
check(p.target==75 and p.start==1,"first milestone is 75")
check(not p.allPriced and p.pricedCount==0,"missing prices never become free")
check(p.chosen.steps[1].recipe.key=="linen","reference cloth route wins an unpriced tie")
check(p.chosen.byItem[2589].need==130,"aggregate both linen recipes")
bags[2589]=60
local cloth=T.EvaluateLevelingRoute(129,{{recipe=T.LevelingRecipe(T.levelingRecipes.linen),crafts=50},
    {recipe=T.LevelingRecipe(T.levelingRecipes["heavy-linen"]),crafts=40}})
check(cloth.byItem[2589].missing==70,"shared bag stack subtracted once across both recipes")
price(2589,10);price(2447,1);price(2678,1);price(3371,1)
p=T.BuildLeveling(129)
check(p.chosen.cost==117 and #p.chosen.steps==2,"owned cloth can make a mixed bandage-potion route cheapest")
bags={};p=T.BuildLeveling(129)
check(p.allPriced and p.chosen.steps[1].recipe.key=="minor-potion","cheaper potion route wins after complete prices")
check(p.chosen.cost==243,"potion inputs include herb, spice and vial")
bags[2589]=60;price(2447,100);p=T.BuildLeveling(129)
check(p.chosen.steps[1].recipe.key=="linen" and p.chosen.cost==700,"price change flips route and credits bags")
T.saved.levelingPrices[2447]=nil;p=T.BuildLeveling(129)
check(not p.allPriced and p.pricedCount==1,"unknown competitor prevents a lowest-cost claim")
check(p.chosen.unknown==0,"priced choice retained with explicit incomplete comparison")
reset(74);p=T.BuildLeveling(129)
check(p.target==75 and p.chosen.steps[1].crafts==2,"partial band rounds estimated crafts upward")
reset(75,129,75);p=T.BuildLeveling(129)
check(p.target==150 and p.training,"at cap previews next rank and flags training")
check(p.chosen.byItem[2589].need==24 and p.chosen.byItem[2592].need==150,"75-150 covers linen bridge and both wool recipes")
reset(149);p=T.BuildLeveling(129);check(p.target==150,"one skill short stays at milestone")
reset(150);p=T.BuildLeveling(129);check(p.target==225 and #p.chosen.steps==3,"150-225 is complete")
reset(225);p=T.BuildLeveling(129);check(p.target==300 and p.unsupported and not p.chosen,"unverified 300 cannot masquerade as complete")
reset(300);check(T.BuildLeveling(129).complete,"max skill has no materials to buy")
reset(20,356);check(T.BuildLeveling(356).gathering,"fishing has no invented crafting list")
reset(20,393);check(T.BuildLeveling(393).gathering,"skinning has no invented material quota")

reset(20,165)
local function step(key,count) return {recipe=T.LevelingRecipe(T.levelingRecipes[key]),crafts=count,low=20,high=30} end
local r=T.EvaluateLevelingRoute(165,{step("scraps",3),step("gloves",2)})
check(r.byItem[2934].missing==9,"scrap inputs calculated")
check(r.byItem[2318].need==6 and r.byItem[2318].fromCrafts==6 and r.byItem[2318].missing==0,"earlier leather production covers later recipes")
reset(100,165)
r=T.EvaluateLevelingRoute(165,{step("pants",4)})
check(r.steps[1].extra and r.steps[1].recipe.key=="light-hide" and r.steps[1].crafts==2,"starting mid-route inserts intermediate preparation")
check(r.byItem[783].missing==2 and r.byItem[4289].missing==2,"cured hide ingredients included")
check(r.byItem[4231].fromCrafts==4 and r.byItem[4231].missing==0,"intermediate not also charged as a purchase")
bags[4231]=3;r=T.EvaluateLevelingRoute(165,{step("pants",4)})
check(r.byItem[4231].fromBags==3 and r.byItem[783].missing==1,"existing cured hides reduce prep crafts")
T.saved.recipes[3816]={profession=165,name="Cured Light Hide",learned=true,rank=100,difficulty="trivial",mats={[783]=1,[4289]=2},outputItem=4231,outputCount=1}
r=T.EvaluateLevelingRoute(165,{step("pants",4)})
check(r.byItem[4289].missing==2,"live intermediate input quantities override reference")
check(r.steps[1].recipe.output[2]==1,"live output yield overrides reference")
reset(55,165)
T.saved.recipes[3756]={profession=165,name="Embossed Leather Gloves",learned=true,rank=55,difficulty="trivial",mats={[2318]=3,[2320]=2}}
check(T.BuildLeveling(165).blocked,"fresh gray recipe rejects incompatible guide route")
T.saved.recipes[3756].difficulty="optimal";T.saved.recipes[3756].mats[2318]=4
check(chosen(165).byItem[2318].need==84,"live skill route ingredient override")

reset(40,129)
T.merchantStock={{item=2678,quantity=5,price=7,available=-1},{item=2678,quantity=10,price=100,available=-1}}
local cost,source=T.LevelingCost(2678,6)
check(cost==14 and source:find("packs"),"merchant cost respects packs and total outlay")
T.merchantStock[1].available=5
check(T.LevelingCost(2678,6)==100,"insufficient offer is not treated as full coverage")
T.merchantStock[2].available=0
check(T.LevelingCost(2678,6)==nil,"insufficient stock leaves cost unknown")
T.merchantStock={{item=2589,quantity=1,price=1,available=-1}}
check(T.LevelingCost(2589,6)==nil,"raw-material prices not inferred from merchant inventory")
check(T.SetLevelingPrice(2678,0) and T.LevelingCost(2678,6)==0,"explicit zero price is supported")
check(not T.SetLevelingPrice(2678,-1) and not T.SetLevelingPrice(2678,"nonsense"),"bad user prices rejected")
check(not T.SetLevelingPrice(2678,math.huge),"infinite price rejected")

reset(20,185);bags[5465]=100
p=T.BuildLeveling(185)
check(p.chosen.steps[1].recipe.key=="spider","held Alliance quest materials considered")
UnitFactionGroup=function() return "Horde" end
p=T.BuildLeveling(185)
for _,candidate in ipairs(p.alternatives) do
    for _,s in ipairs(candidate.steps) do check(s.recipe.key~="spider","faction restriction respected") end
end
reset(40,185);bags[6291]=40
p=T.BuildLeveling(185)
check(p.chosen.steps[1].recipe.key=="smallfish","bag-friendly cooking choice")
check(p.chosen.steps[2].low==50 and p.chosen.steps[2].high==75,"cooking includes next recipe before target")

-- Every supported starting point must yield a contiguous, finite route to its milestone.
for _,id in ipairs({165,185,129}) do
    for rank=1,224 do
        reset(rank,id)
        p=T.BuildLeveling(id)
        check(p.chosen~=nil,"route coverage at "..id..":"..rank)
        local at=rank
        for _,s in ipairs(p.chosen.steps) do
            if not s.extra then check(s.low==at and s.high>at,"contiguous progression");at=s.high end
        end
        check(at==p.target,"route reaches milestone")
        for _,m in ipairs(p.chosen.materials) do
            check(m.need==m.fromBags+m.fromCrafts+m.missing,"conserved material allocation")
        end
    end
end
print("PASS: "..checks.." milestone, costing, intermediate, faction and full-range checks")
