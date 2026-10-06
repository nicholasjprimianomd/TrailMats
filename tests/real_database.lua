local fixture=dofile(arg[1])
local addons=arg[2]
local module={}
QuestieLoader={CreateModule=function() return module end}
dofile(addons.."/QuestieDB/support/Forever/DropTables/classicItemDrops.lua")
local drops=assert(loadstring(module.wowheadData))()
local T={saved={observed={}}}
assert(loadfile("TrailMats/Data.lua"))("TrailMats",T)
assert(loadfile("TrailMats/Sources.lua"))("TrailMats",T)
T.qdb={Item={npcDrops=function(id) return fixture.items[id] end},
    Npc={name=function(id) return fixture.npcs[id] and fixture.npcs[id].name end,
        spawns=function(id) return fixture.npcs[id] and fixture.npcs[id].spawns end}}
T.dropDB={tableWowhead=drops}
T.area=141
assert(T.HasLocalSource(6889),"Teldrassil eggs")
assert(T.HasLocalSource(5465),"Teldrassil spider legs")
assert(T.GetSources(6889).npcs[1995].name=="Strigid Owl")
print("Teldrassil eggs: "..T.SourceText(6889,2))
T.area=148
assert(T.HasLocalSource(2589),"Darkshore linen from actual Questie drop data")
assert(T.HasLocalSource(6889),"Darkshore moonkin eggs")
assert(T.HasLocalSource(2318),"Darkshore skinning candidates")
assert(T.HasLocalSource(6291),"Darkshore inland fishing reference")
print("Darkshore linen: "..T.SourceText(2589,3))
print("Darkshore eggs: "..T.SourceText(6889,2))
print("PASS: installed QuestieDB 1.0.4 source integration (no copied database in addon)")

assert(fixture.npcs[2163].minLevel==11 and fixture.npcs[2163].maxLevel==12,"Thistle Bear Classic level reference")
assert(fixture.npcs[3823].minLevel==19 and fixture.npcs[3823].maxLevel==20,"Ghostpaw Runner Classic level reference")
print("PASS: departure skinning reference levels match installed database; Forever skill rule still unverified")
