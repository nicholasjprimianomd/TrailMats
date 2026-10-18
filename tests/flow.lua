local root=arg[1] or "."
local T={saved={recipes={},levelingPrices={},scanned={}},skills={},area=148,zoneName="Darkshore"}
local bags={}
T.Count=function(item) return bags[item] or 0 end
T.Safe=function(fn,...) if type(fn)=="function" then return fn(...) end end
UnitFactionGroup=function() return "Alliance" end
for _,name in ipairs({"Data","Ranges","Future","LevelingData","LevelingTrades","Leveling","Automatic","Actions"}) do
    assert(loadfile(root.."/TrailMats/"..name..".lua"))("TrailMats",T)
end
T.ItemName=function(item) return T.items[item] or tostring(item) end
local sources={areas={[148]={{name="Foreststrider Fledgling",evidence="Observed on this character",position={45,27}}}}}
T.GetSources=function() return sources end
T.VendorSource=function() return nil end
local checks=0
local function check(ok,label) assert(ok,label);checks=checks+1 end
local function clean(text)
    for _,phrase in ipairs({"Total needed", "used:", "Made along", "Price needed", "Near ", "45, 27"}) do
        check(not text:find(phrase,1,true),"no internal accounting or raw coordinates: "..phrase)
    end
end

local m={item=6889,have=0,need=15,missing=15}
local action,text,source=T.MaterialAdvice(m,"Cooking to skill 50","Herb Baked Egg")
check(action=="Collect 15 more","screenshot becomes a single collect instruction")
check(text:find("You have 0",1,true) and text:find("Herb Baked Egg",1,true),"ownership and purpose explicit")
check(text:find("Database sources",1,true) and source=="From: Foreststrider Fledgling","database source stated in plain language")
clean(text)
m.have=6;m.missing=9
action,text=T.MaterialAdvice(m,"Cooking to skill 50","Herb Baked Egg")
check(action=="Collect 9 more" and text:find("You have 6",1,true),"new loot reduces remaining count")
m.have=20;m.missing=0
action,text=T.MaterialAdvice(m,"Cooking to skill 50","Herb Baked Egg")
check(action=="Ready" and not text:find("Foreststrider",1,true),"covered stack does not keep asking player to farm")
clean(text)
m={item=2678,have=2,need=15,missing=13,supply=true}
action,text,source=T.MaterialAdvice(m,"Cooking to skill 50","Herb Baked Egg")
check(action=="Buy 13 more" and source=="Vendor location not listed here","vendor supplies never presented as farm loot")
clean(text)
m={item=4231,have=0,need=24,missing=0,fromCrafts=24}
local steps={{recipe=T.levelingRecipes["light-hide"]},{recipe=T.levelingRecipes.pants}}
action,text=T.MaterialAdvice(m,"Leatherworking to skill 115",nil,steps)
check(action=="Craft first","planned production is not already ready")
check(text:find("Make Cured Light Hide first",1,true) and text:find("Light Leather Pants",1,true),"intermediate explains action and purpose")
clean(text)
sources.areas[148][1].evidence="Classic drop reference"
local name,detail=T.ZoneSource(6889)
check(name=="From: Foreststrider Fledgling" and detail:find("Database sources",1,true),"source independent of personal observation")
clean(detail)
sources={areas={}}
action,text,source=T.MaterialAdvice({item=6889,have=0,missing=15},"Cooking to skill 50","Herb Baked Egg")
check(source=="Source database unavailable","missing database never invents directions")
T.qdb={}
action,text,source=T.MaterialAdvice({item=6889,have=0,missing=15},"Cooking to skill 50","Herb Baked Egg")
check(source=="No listed source in Darkshore","connected database distinguishes absent records from unavailable provider")

-- With no live recipe, farm only the next step, not the whole milestone.
local function plan(rank,id)
    T.saved.recipes={};bags={};T.skills={[id]={rank=rank,cap=300}}
    T.plan={opportunities={},leveling={[id]=T.BuildLeveling(id)}}
end
plan(20,129)
local goal=T.FarmGoal(129)
check(goal.target==40 and goal.recipe=="Linen Bandage","unscanned First Aid previews only the next recipe")
check(goal.materials[1].need==26,"next-step cloth excludes later heavy bandages")
check(T.FarmGoal(129)==goal,"goal calculation cached for this refresh")
plan(100,165)
goal=T.FarmGoal(165)
check(goal.recipe=="Light Leather Pants" and goal.target==115,"main recipe remains the stated goal")
local hide,prepared
for _,r in ipairs(goal.materials) do
    if r.item==783 then hide=r end
    if r.item==4231 then prepared=r end
end
check(hide and hide.missing==12,"raw intermediate inputs included in next farming step")
check(prepared and T.MaterialAdvice(prepared)=="Craft first","intermediate remains a preparation action")
check(T.FarmGoal(393)==goal,"Skinning follows same Leatherworking goal")
local live={name="Light Leather Pants",stop=115,materials={{item=2318,have=10,need=20,missing=10}}}
T.plan.opportunities[165]=live
check(T.FarmGoal(165).materials==live.materials,"fresh learned recommendation takes priority over cached forecast")
plan(225,129)
check(not T.FarmGoal(129),"unsupported tiers do not create farming orders")
print("PASS: "..checks.." farming flow, tooltip and preparation checks")
