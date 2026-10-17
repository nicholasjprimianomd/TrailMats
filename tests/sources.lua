local root=arg[1] or "."
local T={saved={observed={}},area=148,zoneName="Darkshore"}
T.Safe=function(fn,...) if type(fn)=="function" then return fn(...) end end
for _,name in ipairs({"Data","Sources","Actions"}) do
    assert(loadfile(root.."/TrailMats/"..name..".lua"))("TrailMats",T)
end
local checks=0
local function check(ok,label) assert(ok,label);checks=checks+1 end
local faction="Alliance"
UnitFactionGroup=function() return faction end
local reads=0
local npcs={
    [1]={name="Alliance Supplies",friendly="A",spawns={[148]={{10,10}}}},
    [2]={name="Horde Supplies",friendly="H",spawns={[148]={{20,20}}}},
    [3]={name="Neutral Supplies",friendly="AH",spawns={[148]={{30,30}}}},
    [4]={name="Elsewhere Supplies",friendly="AH",spawns={[141]={{40,40}}}},
    [5]={name="Unknown allegiance",spawns={[148]={{50,50}}}},
    [6]={name="Low chance creature",spawns={[148]={{60,60}}}},
    [7]={name="Zero chance creature",spawns={[148]={{70,70}}}},
}
T.qdb={Item={vendors=function() return {1,2,3,4,5,1} end},
    Npc={name=function(id) return npcs[id] and npcs[id].name end,
        spawns=function(id) return npcs[id] and npcs[id].spawns end,
        friendlyToFaction=function(id) return npcs[id] and npcs[id].friendly end},
    Support={Get=function(name)
        reads=reads+1;check(name=="QuestieClassicItemDrops","reads installed flavor support module")
        return {wowheadData="return {[2589]={[6]=0.5,[7]=0}}"}
    end}}
check(T.VendorSource(2320)=="Alliance Supplies, Neutral Supplies","local faction-compatible vendors, sorted and deduplicated")
faction="Horde"
check(T.VendorSource(2320)=="Horde Supplies, Neutral Supplies","opposite-faction vendors excluded")
faction=nil
check(T.VendorSource(2320)=="Neutral Supplies","unknown player faction uses only neutral vendors")
T.area=9999
check(not T.VendorSource(2320),"no invented local vendor")
T.area=148
local source=T.ZoneSource(2589)
check(source=="From: Low chance creature","positive database drop chances retained; zero excluded")
T.GetSources(2592);T.DatabaseDrops()
check(reads==1,"large fallback table decoded once")
T.saved.observed[2589]={[7]={area=148}};T.sourceCache={}
check(T.ZoneSource(2589)==source,"saved personal loot cannot override database")
T.dropDB={tableCorrections={[2589]={[3]=20}},tableWowhead={[2589]={[1]=20}}};T.sourceCache={}
check(T.ZoneSource(2589)=="From: Neutral Supplies","Questie corrections take precedence over fallback data")
T.qdb=nil;T.dropDB=nil;T.sourceCache={}
check(not T.ZoneSource(2318),"missing NPC names never become random creature numbers")
check(T.NoLocalSource()=="Source database unavailable","provider unavailable is explicit")
print("PASS: "..checks.." database fallback, vendor, faction and source checks")
