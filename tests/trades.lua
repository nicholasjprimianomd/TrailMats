-- Every reviewed route must carry a character from any starting skill to its milestone, for both factions.
local root=arg[1] or "."
local T={saved={recipes={},levelingPrices={},scanned={}},skills={}}
local bags={}
T.Count=function(id) return bags[id] or 0 end
T.Safe=function(fn,...) if type(fn)=="function" then return fn(...) end end
T.Refresh=function() end
for _,file in ipairs({"Data","Ranges","Future","LevelingData","LevelingTrades","Leveling","Automatic"}) do
    assert(loadfile(root.."/TrailMats/"..file..".lua"))("TrailMats",T)
end
local checks=0
local function check(ok,label) assert(ok,label);checks=checks+1 end
local professions={}
for pid in pairs(T.levelingEdges) do professions[#professions+1]=pid end
table.sort(professions)
check(#professions>=7,"routes exist for the original three and the four trade professions")
for _,pid in ipairs(professions) do
    local name=T.professions[pid].name
    local keys,high={},0
    for _,e in ipairs(T.levelingEdges[pid]) do
        check(e.recipe and e.recipe.profession==pid,name..": edge recipe belongs to the profession")
        check(e.low<e.high and e.crafts>0,name..": edge "..e.low.."-"..e.high.." has a positive band and count")
        high=math.max(high,e.high)
    end
    for key,r in pairs(T.levelingRecipes) do
        if r.profession==pid then
            check(not keys[r.name] or keys[r.name]==key,name..": one key per recipe name ("..r.name..")");keys[r.name]=key
            for item,qty in pairs(r.mats) do check(type(item)=="number" and item>0 and type(qty)=="number" and qty>0,name..": "..key.." has numeric reagents") end
            if r.output then check(type(r.output[1])=="number" and type(r.output[2])=="number" and r.output[2]>0,name..": "..key.." output is item and count") end
            for item in pairs(r.mats) do check(T.items[item]~=nil,name..": reagent "..item.." of "..key.." has a name") end
        end
    end
    local limit=math.min(high,T.levelingLimit)
    for _,faction in ipairs({"Alliance","Horde"}) do
        UnitFactionGroup=function() return faction end
        for rank=1,limit-1 do
            T.skills={[pid]={rank=rank,cap=300}}
            local plan=T.BuildLeveling(pid)
            check(plan.chosen and not plan.blocked,name..": a route exists from skill "..rank.." for "..faction)
            local reach,target=0,math.min(plan.target,limit)
            for _,s in ipairs(plan.chosen.steps) do if not s.extra then reach=math.max(reach,s.high) end end
            check(reach>=target,name..": route from "..rank.." reaches "..target.." (got "..reach..")")
        end
    end
    T.skills={[pid]={rank=1,cap=300}}
    check(T.BuildFuture()~=nil,name..": keep limits build without error")
end
print("PASS: "..checks.." route checks across "..#professions.." professions")
