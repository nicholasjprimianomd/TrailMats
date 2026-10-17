from pathlib import Path
import sys,re,base64
import cbor2
from lupa.lua51 import LuaRuntime
addons=Path(sys.argv[1]);repo=Path(__file__).resolve().parents[1]
meta={}
for line in (addons/'QuestieDB/QuestieDB_Camelot.toc').read_text(encoding='utf-8-sig').splitlines():
    m=re.match(r'## X-(Item|Npc|Object)-(\d+)-(\d+|S): (.*)',line)
    if m: meta[(m[1],int(m[2]),m[3])]=m[4]
lua=LuaRuntime(unpack_returned_tuples=True)
def convert(v):
    if isinstance(v,bytes): return v.decode()
    if isinstance(v,(dict,list)): return lua.table_from({k:convert(x) for k,x in (v.items() if isinstance(v,dict) else enumerate(v,1))})
    return v
def read(kind,ident,field):
    value=meta.get((kind,int(ident),str(int(field))))
    if value and not value.startswith('~'): return convert(cbor2.loads(base64.b64decode(value)))
    value=meta.get((kind,int(ident),'S'))
    if value and not value.startswith('~'):
        row=cbor2.loads(base64.b64decode(value));return convert(row.get(int(field)) if isinstance(row,dict) else None)
lua.globals().dbread=read
lua.globals().repo=repo.as_posix();lua.globals().addons=addons.as_posix()
lua.execute('''
local support={}
QuestieLoader={CreateModule=function() return support end}
dofile(addons.."/QuestieDB/support/Forever/DropTables/classicItemDrops.lua")
T={saved={recipes={},observed={},levelingPrices={}},skills={[129]={rank=72,cap=150}},area=148,zoneName="Darkshore"}
T.Safe=function(fn,...) if type(fn)=="function" then return fn(...) end end
T.Count=function() return 0 end
UnitFactionGroup=function() return "Alliance" end
for _,name in ipairs({"Data","Ranges","Future","LevelingData","Leveling","Automatic","Sources","Actions","LevelingUI"}) do
    assert(loadfile(repo.."/TrailMats/"..name..".lua"))("TrailMats",T)
end
T.ItemName=function(item) return T.items[item] or tostring(item) end
local reads=0
T.qdb={Item={npcDrops=function(id) return dbread("Item",id,2) end,objectDrops=function(id) return dbread("Item",id,3) end,vendors=function(id) return dbread("Item",id,14) end},
    Npc={name=function(id) return dbread("Npc",id,1) end,spawns=function(id) return dbread("Npc",id,7) end,friendlyToFaction=function(id) return dbread("Npc",id,13) end},
    Object={name=function(id) return dbread("Object",id,1) end,spawns=function(id) return dbread("Object",id,4) end},
    Support={Get=function(name) reads=reads+1;if name=="QuestieClassicItemDrops" then return support end end}}
assert(T.HasLocalSource(2589),"real Darkshore linen sources without Questie consumer or personal observations")
assert(T.HasLocalSource(6889),"real Darkshore egg sources")
assert(T.HasLocalSource(2318),"Darkshore skinning reference")
assert(T.HasLocalSource(6291),"Darkshore fishing reference")
T.DatabaseDrops();assert(reads==1,"fallback decoded once")
assert(T.VendorSource(2320),"real Darkshore coarse thread vendor")
print("Coarse Thread vendor: "..T.VendorSource(2320))
T.plan={opportunities={},leveling={[129]=T.BuildLeveling(129)},future=T.BuildFuture()}
local goal=T.FarmGoal(129)
assert(goal.recipe=="Heavy Linen Bandage" and goal.target==80,"rank 72 aims at last reviewed heavy linen interval")
assert(goal.materials[1].missing==32,"remaining reviewed count includes the short bridge")
local lines={}
T.RenderMaterials(129,function(text,detail,action,click,options)
    lines[#lines+1]=text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    if options and options.value then lines[#lines+1]=options.value end
end)
print(table.concat(lines,"\\n"))
T.saved.observed[2589]={[999999]={area=148}};T.sourceCache={}
assert(not T.GetSources(2589).npcs[999999],"observations cannot replace database sources")
T.area=99999;T.zoneName="Unknown zone"
assert(not T.ZoneSource(2589),"no invented local source")
print("PASS: installed QuestieDB sources, fallback caching, screenshot state and no-observation integration")
''')

