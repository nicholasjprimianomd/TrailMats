-- Profession registry, detection and the Enchanting craft-window scan, without the UI mock.
local root=arg[1] or "."
local T={saved={recipes={},scanned={},selected={},observed={},levelingPrices={}},skills={}}
T.Refresh=function() end
UnitFactionGroup=function() return "Alliance" end
for _,name in ipairs({"Data","Ranges","Future","LevelingData","LevelingTrades","Leveling","Automatic","Client","Actions"}) do
    assert(loadfile(root.."/TrailMats/"..name..".lua"))("TrailMats",T)
end
local checks=0
local function check(ok,label) assert(ok,label);checks=checks+1 end
local function professions(list) -- slot -> {skillLine,rank,cap}; nil slots mimic an empty primary
    GetProfessions=function() local r={};for i=1,6 do r[i]=list[i] and i or nil end;return unpack(r,1,6) end
    GetProfessionInfo=function(i) local p=list[i];if not p then return end;return T.professions[p[1]].name,nil,p[2],p[3],nil,nil,p[1] end
end

-- All twelve Forever professions are known by skill line id.
for _,id in ipairs({171,164,333,202,197,165,185,129,393,182,186,356}) do check(T.professions[id],"profession "..id.." registered") end
check(#T.order==12 and #T.tabOrder==12,"order lists cover every profession")
for id,info in pairs(T.professions) do check((info.craft or info.gather) and not (info.craft and info.gather),"profession "..id.." is crafting or gathering") end
professions({{171,20,75},{182,15,75},nil,{356,1,75},{185,5,75},{129,1,75}})
T.ReadSkills()
check(T.skills[171] and T.skills[182] and T.skills[356] and T.skills[185] and T.skills[129] and not T.skills[165],"detects alchemy, herbalism and the secondaries")
check(T.skills[171].name=="Alchemy" and T.skills[182].rank==15,"names and ranks come from the client")
check(T.FutureProfession(182)==171 and T.FutureProfession(186)==164 and T.FutureProfession(393)==165 and T.FutureProfession(356)==185 and T.FutureProfession(171)==171,"gathering professions follow their crafting partner")
-- Plans: gathering professions have no route; a crafting profession without reviewed data says so instead of pretending.
local herb=T.BuildLeveling(182);check(herb.gathering and not herb.noRoute,"herbalism is a gathering plan")
local alch=T.BuildLeveling(171);check((alch.noRoute==true)==(T.levelingEdges[171]==nil) and not alch.gathering,"crafting profession without data is flagged noRoute")
check(T.NextAction(182).text=="Gather herbs for Alchemy","gathering next step names its partner")
professions({{186,10,75}});T.ReadSkills();check(T.NextAction(186).text=="Level Mining","gathering without its partner just levels")

-- Enchanting uses the Craft window: a header, an enchant and a crafted rod.
professions({{333,10,75},{393,1,75}});T.ReadSkills()
GetTradeSkillLine=function() return "UNKNOWN",0,0 end;GetNumTradeSkills=function() return 0 end;GetTradeSkillInfo=function() end
local crafts={{"Apprentice","header"},
    {"Enchant Bracer - Minor Deflect","optimal",{[10938]=1},"|Henchant:7428|h[Enchant Bracer - Minor Deflect]|h"},
    {"Runed Copper Rod","medium",{[6217]=1,[247786]=1},"|Hitem:6218|h[Runed Copper Rod]|h"}}
GetNumCrafts=function() return #crafts end
GetCraftDisplaySkillLine=function() return "Enchanting",10,75 end
GetCraftInfo=function(i) local c=crafts[i];return c[1],nil,c[2],1,true end
GetCraftItemLink=function(i) return crafts[i][4] end
local function reagents(i)
    local list={};for item,qty in pairs(crafts[i][3] or {}) do list[#list+1]={item,qty} end
    table.sort(list,function(a,b) return a[1]<b[1] end);return list
end
GetCraftNumReagents=function(i) return #reagents(i) end
GetCraftReagentInfo=function(i,j) local r=reagents(i)[j];return "Reagent",nil,r[2],0 end
GetCraftReagentItemLink=function(i,j) return "|Hitem:"..reagents(i)[j][1].."|h[Reagent]|h" end
T.ScanRecipes()
check(T.lastScanned==333 and T.saved.scanned[333],"craft window scan identifies Enchanting")
local ench=T.saved.recipes[7428]
check(ench and ench.profession==333 and ench.mats[10938]==1 and ench.difficulty=="optimal" and ench.rank==10 and not ench.outputItem,"enchant stored by enchant id without an output item")
local rod=T.saved.recipes["live:333:Runed Copper Rod"]
check(rod and rod.outputItem==6218 and rod.outputCount==1 and rod.mats[6217]==1 and rod.mats[247786]==1,"crafted rod keeps its output item")
check(T.saved.recipes["live:333:Apprentice"]==nil,"headers are skipped")
GetNumCrafts=function() return 0 end;T.saved.scanned={};T.lastScanned=nil;T.ScanRecipes()
check(not T.saved.scanned[333] and T.lastScanned==nil,"a closed craft window scans nothing")
print("PASS: "..checks.." profession registry, detection and craft-window checks")
