-- Nearest database source anywhere and the map pin for it, against a small fake world.
local root=arg[1] or "."
local T={saved={recipes={},levelingPrices={},scanned={}},skills={},settings={openMap=true},area=141,zoneName="Teldrassil"}
T.Safe=function(fn,...) if type(fn)~="function" then return nil end local r={pcall(fn,...)};if not r[1] then return nil end;return unpack(r,2) end
local printed={}
T.Print=function(text) printed[#printed+1]=text end
local faction="Alliance"
UnitFactionGroup=function() return faction end
local clock=1000
GetTime=function() return clock end
for _,name in ipairs({"Data","Ranges","LevelingData","Sources","Locate","Actions"}) do
    assert(loadfile(root.."/TrailMats/"..name..".lua"))("TrailMats",T)
end
local names={[4306]="Silk Cloth",[2320]="Coarse Thread",[2447]="Peacebloom",[2770]="Copper Ore",[2318]="Light Leather",[6291]="Raw Brilliant Smallfish",
    [9999]="Mystery Gizmo",[8888]="Ogre Tooth",[2835]="Rough Stone",[2840]="Copper Bar",[7777]="Odd Trinket",[5555]="Wolf Pelt"}
T.ItemName=function(item) return names[item] or T.items[item] or ("Item #"..item) end
local checks=0
local function check(ok,label) assert(ok,label);checks=checks+1 end

-- World: three Kalimdor zones side by side (1000 yd each); Elwynn and Stormwind on the other continent.
local maps={[1438]={c=1,ox=0,oy=0},[1439]={c=1,ox=1000,oy=0},[1440]={c=1,ox=1000,oy=1000},[1429]={c=0,ox=0,oy=0},[1453]={c=0,ox=5000,oy=0}}
local parents={[1438]=1414,[1439]=1414,[1440]=1414,[1429]=1415,[1453]=1415,[1414]=947,[1415]=947,[230]=1414}
local worldCalls,player=0,{map=1438,x=0.5,y=0.5}
CreateVector2D=function(x,y) return {x=x,y=y} end
Enum={UIMapType={Continent=2,Zone=3}}
local waypoint,supertracked,opened,blocked
C_Map={
    GetBestMapForUnit=function() return player.map end,
    GetPlayerMapPosition=function(map) if player.instance then return nil end return {GetXY=function() return player.x,player.y end} end,
    GetWorldPosFromMapPos=function(map,v)
        worldCalls=worldCalls+1
        local m=maps[map];if not m then return nil end
        return m.c,{x=m.ox+v.x*1000,y=m.oy+v.y*1000}
    end,
    GetMapInfo=function(map) return {mapType=(map==1414 or map==1415) and 2 or 3,parentMapID=parents[map]} end,
    GetAreaInfo=function(area) return ({[331]="Ashenvale",[12]="Elwynn Forest",[1519]="Stormwind City",[719]="Blackfathom Deeps"})[area] end,
    CanSetUserWaypointOnMap=function(map) return map~=blocked end,
    SetUserWaypoint=function(point) waypoint=point end,
    GetMapChildrenInfo=function(continent) if continent==1415 then return {{name="Stormwind City",mapID=1453}} end return {} end,
}
UiMapPoint={CreateFromCoordinates=function(map,x,y) return {uiMapID=map,x=x,y=y} end}
C_SuperTrack={SetSuperTrackedUserWaypoint=function(v) supertracked=v end}
OpenWorldMap=function(map) opened=map end
local combat=false
InCombatLockdown=function() return combat end

-- Database. friendly: "AH" is attackable neutral wildlife in QuestieDB; "A" or "H" alone is friendly to that faction.
local npcs={
    [1]={name="Darkshore Thug",spawns={[148]={{90,10}}},friendly="AH"},
    [2]={name="Ashenvale Bandit",spawns={[331]={{10,10}}},friendly="AH"},
    [3]={name="Lucky Owl",spawns={[141]={{51,51}}},friendly="AH"},
    [4]={name="Horde Supplier",spawns={[141]={{50,50}}},friendly="H"},
    [5]={name="Darkshore Supplier",spawns={[148]={{20,20}}},friendly="A"},
    [6]={name="Elwynn Supplier",spawns={[12]={{50,50}}},friendly="AH"},
    [7]={name="Deep Lurker",spawns={[719]={{-1,-1}}},friendly="AH"},
    [8]={name="Camp Ogre",spawns={},friendly="AH"},
    [9]={name="Sentinel Guard",spawns={[141]={{50,49}}},friendly="A"},
    [10]={name="Rare Silkback",spawns={[141]={{49,50}}},friendly="AH",rank=4},
    [2069]={name="Moonstalker",spawns={[148]={{43,40}}},friendly="AH"},
}
local camp={};for i=1,60 do camp[i]={i,50} end
npcs[8].spawns[148]=camp
local drops={[4306]={[1]=20,[2]=25,[3]=0.5,[9]=40,[10]=60},[9999]={[7]=30},[8888]={[8]=40}}
local vendors={[2320]={4,5,6}}
local npcDrops={}
T.qdb={
    Item={npcDrops=function(id) return npcDrops[id] end,objectDrops=function() return nil end,vendors=function(id) return vendors[id] end},
    Npc={name=function(id) return npcs[id] and npcs[id].name end,spawns=function(id) return npcs[id] and npcs[id].spawns end,
        friendlyToFaction=function(id) return npcs[id] and npcs[id].friendly end,rank=function(id) return npcs[id] and npcs[id].rank end},
}
T.dropDB={tableWowhead=drops}
T.zoneDB={GetUiMapIdByAreaId=function(_,area) return ({[141]=1438,[148]=1439,[331]=1440,[12]=1429})[area] end,
    GetDungeonLocation=function(_,area) if area==719 then return {{331,14.5,14.2}} end end}

-- Ranking: the strongest tier, then the closest. Own-faction creatures and a rare next to the player are out.
local found=T.FindSource(4306)
check(found.spot and found.spot.name=="Ashenvale Bandit" and found.spot.area==331 and found.spot.map==1440,"nearest likely drop across zones")
check(not T.GetSources(4306).npcs[9],"a creature friendly only to the player's faction is never a source")
check(T.GetSources(4306).npcs[10].tier==3 and T.GetSources(4306).npcs[3].tier==3 and T.GetSources(4306).npcs[2].tier==1,"rares and unlikely drops are fallbacks; likely drops are first tier")
check(found.label=="From: Ashenvale Bandit, Ashenvale","label names the source and its zone")
check(math.abs(found.spot.distance-math.sqrt(600^2+600^2))<0.01 and T.DistanceText(found.spot)=="about 850 yd","distance in yards from world positions")
check(found.detail=="Nearest database source: Ashenvale Bandit in Ashenvale, about 850 yd. Classic drop reference.","detail without a duplicate click line")
faction="Horde";T.sourceCache={}
check(T.GetSources(4306).npcs[9]~=nil,"the faction filter follows the player: an Alliance guard is a Horde target")
faction="Alliance";T.sourceCache={}
drops[4306]={[3]=0.5,[10]=60};T.sourceCache={}
check(T.FindSource(4306).spot.name=="Rare Silkback" and T.FindSource(4306).spot.tier==3,"fallbacks are used when nothing better exists, nearest first")
drops[4306]={[1]=20,[2]=25,[3]=0.5,[9]=40,[10]=60};T.sourceCache={}

-- A database drop without a chance is second tier; dozens of them is a world drop with no target.
npcDrops[5555]={2};T.sourceCache={}
check(T.GetSources(5555).npcs[2].tier==2 and T.FindSource(5555).spot.name=="Ashenvale Bandit","a listed drop without a chance still gives a source")
drops[5555]={[2]=1};T.sourceCache={}
check(T.GetSources(5555).npcs[2].chance==1 and T.GetSources(5555).npcs[2].tier==3,"a database drop takes its chance from the drop table")
drops[5555]=nil
local many={};for i=100,170 do npcs[i]={name="Wanderer "..i,spawns={[141]={{i-100,10}}},friendly="AH"};many[#many+1]=i end
npcDrops[8888]=many;T.sourceCache={}
check(T.FindSource(8888).spot.name=="Camp Ogre","a known likely drop beats a world-drop list")
drops[8888]=nil;T.sourceCache={}
found=T.FindSource(8888)
check(not found.spot and found.label=="World drop from many creatures" and found.detail:find("71 creatures",1,true),"world drop: no single target")
check(T.ZoneSource(8888,141)==nil,"the row agrees: a world drop has no local target")
drops[8888]={[8]=40};npcDrops[8888]=nil;T.sourceCache={}

-- Results are cached per zone for 30 seconds; a click, a zone change or time recomputes.
local first=T.FindSource(4306);check(T.FindSource(4306)==first,"repeated lookup reuses the result")
clock=clock+29;check(T.FindSource(4306)==first,"still cached at 29 s")
clock=clock+2;check(T.FindSource(4306)~=first,"recomputed after 30 s")
first=T.FindSource(4306);check(T.FindSource(4306,true)~=first,"a click lookup is always fresh")
T.area=148;check(T.FindSource(4306)~=first,"changing zone recomputes");T.area=141

-- Vendors: friendly only, nearest on this continent first.
found=T.FindSource(2320)
check(found.spot and found.spot.name=="Darkshore Supplier" and found.label=="Buy from: Darkshore Supplier, Darkshore","nearest friendly vendor; the Horde vendor next door is skipped")
check(found.detail:find("^Nearest vendor: Darkshore Supplier in Darkshore"),"vendor detail")
faction="Horde";T.sourceCache={}
check(T.FindSource(2320).spot.name=="Horde Supplier","vendor faction follows the player")
faction="Alliance";player.map=1429;T.area=12;T.sourceCache={}
check(T.FindSource(2320).spot.name=="Elwynn Supplier","this continent's vendor first")
player.map=1438;T.area=141;vendors[2320]={6};T.sourceCache={}
found=T.FindSource(2320)
check(found.spot.name=="Elwynn Supplier" and found.spot.otherContinent and T.DistanceText(found.spot)=="on another continent","a vendor only on another continent is still named")
vendors[2320]={4,5,6};T.sourceCache={}

-- Dungeons: named in the label, a last resort from outside, and first from inside.
found=T.FindSource(9999)
check(found.spot.dungeon==719 and found.spot.area==331 and found.spot.x==14.5,"dungeon spawn placed at its entrance")
check(found.label=="From: Deep Lurker (Blackfathom Deeps), Ashenvale" and found.detail:find("in Blackfathom Deeps, entrance in Ashenvale",1,true),"the dungeon is named")
npcs[11]={name="Shore Crab",spawns={[148]={{95,95}}},friendly="AH"};drops[9999]={[7]=30,[11]=5};T.sourceCache={}
check(T.FindSource(9999).spot.name=="Shore Crab","an open-world source beats a dungeon you are not in")
player.instance=true;player.map=230;T.area=719;T.sourceCache={}
found=T.FindSource(9999)
check(found.spot.name=="Deep Lurker" and found.detail:find("^Nearest database source"),"inside the dungeon its own spawns come first")
drops[9999]={[7]=30};npcs[11]=nil
-- No position inside an instance: the rest prefers this continent, and is worded as a source, not the nearest.
T.area=718;drops[4306]={[2]=25,[6]=80};T.sourceCache={}
found=T.FindSource(4306)
check(found.spot.name=="Ashenvale Bandit" and found.detail:find("^A database source"),"instance: same continent first, not the likeliest drop in the world")
drops[4306]={[1]=20,[2]=25,[3]=0.5,[9]=40,[10]=60}
player.instance=nil;player.map=1438;T.area=141;T.sourceCache={}
local before=worldCalls;T.FindSource(8888,true)
check(worldCalls-before<=8,"large spawn lists are sampled ("..(worldCalls-before).." world lookups)")

-- Leather: the reviewed skinning list is local to two starting zones only.
T.area=148;player.map=1439;T.sourceCache={}
check(T.FindSource(2318).label=="Skin: Moonstalker","in Darkshore the local skinning candidate is used")
T.area=12;player.map=1429;T.sourceCache={}
check(T.FindSource(2318).label=="Skin beasts near your level" and not T.FindSource(2318).spot,"elsewhere leather gives the skinning hint, not a Darkshore pin")
T.area=141;player.map=1438;T.sourceCache={}

-- Gathered items: the node or smelt and its skill, worded for gatherers and non-gatherers.
check(T.FindSource(2447).label=="Herb: Peacebloom (Herbalism 1)" and T.FindSource(2447).detail:find("Without Herbalism",1,true),"herb for a non-herbalist")
T.skills={[182]={rank=10,cap=75}};T.sourceCache={}
check(T.FindSource(2447).detail:find("Herbalism tab",1,true),"herb for a herbalist points at the tab")
T.skills={};T.sourceCache={}
check(T.FindSource(2770).label=="Mine: Copper Vein (Mining 1)","ore maps to its vein")
check(T.FindSource(2835).label=="Mine: Copper Vein (Mining 1)" and T.FindSource(2835).detail:find("Rough Stone is gathered from Copper Vein",1,true),"stone maps to its vein")
check(T.FindSource(2840).label=="Smelt: Copper Ore (Mining 1)","bars are smelted")
local action,text,source=T.MaterialAdvice({item=2447,have=0,need=5,missing=5},"Alchemy to skill 10","Minor Arcane Elixir")
check(source=="Herb: Peacebloom (Herbalism 1)" and not text:find("Click",1,true),"the row uses the gather hint")

-- Herb and ore nodes: gatherers with enough skill get the nearest node; others get the skill they need.
local objects={[60]={name="Peacebloom",spawns={[148]={{30,30}},[141]={{80,80}}}},[61]={name="Mageroyal",spawns={[141]={{52,52}}}},
    [62]={name="Battered Chest",spawns={[141]={{50,51}}}}}
local objectDrops={[2447]={60,62},[785]={61}}
names[785]="Mageroyal";names[818]="Tigerseye"
T.qdb.Object={name=function(id) return objects[id] and objects[id].name end,spawns=function(id) return objects[id] and objects[id].spawns end}
T.qdb.Item.objectDrops=function(id) return objectDrops[id] end
T.skills={[182]={name="Herbalism",rank=20,cap=75}};T.sourceCache={}
found=T.FindSource(2447)
check(found.spot and found.spot.kind=="node" and found.spot.area==141 and found.label=="Herb: Peacebloom","a herbalist gets the nearest Peacebloom node here")
check(found.detail:find("^Nearest Peacebloom node: Teldrassil"),"node detail names the zone and distance")
check(T.ShowSource(2447) and waypoint.uiMapID==1438 and math.abs(waypoint.x-0.80)<1e-9,"a click pins the node")
check(T.FindSource(785).label=="Herb: Mageroyal (Herbalism 50)" and T.FindSource(785).detail:find("Your Herbalism is 20",1,true) and not T.FindSource(785).spot,"a node above your skill is not pinned; the skill is shown")
T.skills={};T.sourceCache={}
check(T.FindSource(2447).label=="Herb: Peacebloom (Herbalism 1)" and not T.FindSource(2447).spot,"no Herbalism: no node pin")
check(T.HasLocalSource(2447),"the planner still counts a local herb node, as before")
check(T.ZoneSource(2447,141)=="From: Battered Chest","the node itself is never named as a creature or chest source")
check(T.FindSource(818).label=="Mine: Copper Vein (Mining 1)" and T.FindSource(818).detail:find("comes now and then from mining",1,true),"gems point at their vein")
T.qdb.Item.objectDrops=function() return nil end;T.sourceCache={}

-- Elites and bosses are ordinary targets; rare spawns are fallbacks. A listed drop next door beats a likelier one far away.
npcs[13]={name="Elite Ogre",spawns={[331]={{12,12}}},friendly="AH",rank=1};npcs[14]={name="Rare Elite",spawns={[331]={{13,13}}},friendly="AH",rank=2}
drops[4444]={[13]=30,[14]=30};names[4444]="Ogre Hide";T.sourceCache={}
check(T.GetSources(4444).npcs[13].tier==1 and T.GetSources(4444).npcs[14].tier==3,"elite is first tier; rare elite is a fallback")
npcs[15]={name="Next Door Boar",spawns={[141]={{52,50}}},friendly="AH"};npcDrops[4444]={15};T.sourceCache={}
check(T.FindSource(4444).spot.name=="Next Door Boar" and T.ZoneSource(4444,141)=="From: Next Door Boar","a listed drop next door wins; row and click agree")
check(T.HasLocalSource(4444),"planner agrees with the row")
drops[4306]={[3]=0.5,[1]=20};T.sourceCache={}
check(not T.HasLocalSource(4306) and T.ZoneSource(4306,141)==nil,"a fallback-only zone is not a local source for the planner either")
drops[4306]={[1]=20,[2]=25,[3]=0.5,[9]=40,[10]=60};drops[4444]=nil;npcDrops[4444]=nil;T.sourceCache={}

-- Fish: this zone's water first, otherwise a fixed choice.
T.area=148;T.sourceCache={}
check(T.FindSource(6291).label=="Fish: inland rivers","this zone's water")
T.area=12;T.sourceCache={}
check(T.FindSource(6291).label=="Fish: Teldrassil Lake Al'Ameth","elsewhere: the first recorded water by zone id")
T.area=141;T.sourceCache={}
check(T.FindSource(7777).label=="Not in the source database","nothing at all is said plainly")
npcs[12]={name="Lost Lurker",spawns={[720]={{-1,-1}}},friendly="AH"};drops[6666]={[12]=50};T.sourceCache={}
check(T.FindSource(6666).label=="Listed without a map location","known but unplaceable is not called missing")
drops[6666]=nil;npcs[12]=nil;T.sourceCache={}
local qdb,dropDB=T.qdb,T.dropDB;T.qdb=nil;T.dropDB=nil
check(T.FindSource(4306).label=="Source database unavailable","no database is never presented as no source")
T.qdb,T.dropDB=qdb,dropDB;T.sourceCache={}

-- The row and the click agree: a zone with only fallbacks defers to a better source elsewhere.
check(T.ZoneSource(4306,141)==nil,"Teldrassil has only a rare and a 0.5% drop: no local row source")
check(T.ZoneSource(4306,331)=="From: Ashenvale Bandit","a likely local drop is named")
check(select(3,T.ZoneSource(6291,148))==false and select(3,T.ZoneSource(4306,331))==true,"water cannot be pinned; a creature can")

-- Zone maps without Questie's zone table: matched by name on the continent maps.
local zoneDB=T.zoneDB;T.zoneDB=nil
check(T.UiMapForArea(1519)==1453 and T.UiMapForArea(148)==1439,"area to map by name, and by the seed table")
T.zoneDB=zoneDB

-- Clicking: a pin in 0-1 coordinates, super-tracked, the map opened, and one chat line.
check(T.ShowSource(4306) and waypoint.uiMapID==1440 and math.abs(waypoint.x-0.10)<1e-9 and math.abs(waypoint.y-0.10)<1e-9,"pin placed at the source")
check(supertracked==true and opened==1440,"pin is super-tracked and the map opens at that zone")
check(printed[#printed]=="Silk Cloth: Ashenvale Bandit, Ashenvale 10.0, 10.0 (about 850 yd). Marked on your map.","chat says where")
T.settings.openMap=false;opened=nil;T.ShowSource(4306);check(opened==nil,"opening the map can be turned off");T.settings.openMap=true
combat=true;opened=nil;T.ShowSource(4306)
check(opened==nil and printed[#printed]:find("Marked on your map. Open the map after combat to see it.",1,true),"no map opening in combat; the pin still goes in")
combat=false
blocked=1440;waypoint=nil
check(not T.ShowSource(4306) and waypoint==nil and printed[#printed]:find("10.0, 10.0",1,true) and not printed[#printed]:find("Marked",1,true),"maps that refuse pins still give coordinates")
blocked=nil
local tomtom,removed={},{}
TomTom={AddWaypoint=function(self,map,x,y,opts) tomtom[#tomtom+1]={self=self,map=map,title=opts.title};return "uid"..#tomtom end,
    RemoveWaypoint=function(self,uid) removed[#removed+1]=uid end}
supertracked=nil
check(T.ShowSource(4306) and tomtom[1].self==TomTom and tomtom[1].map==1440 and tomtom[1].title=="Ashenvale Bandit (Silk Cloth)" and supertracked==nil,"TomTom gets the waypoint and the Blizzard arrow is not doubled")
T.ShowSource(2320);check(removed[1]=="uid1" and #tomtom==2,"the previous TrailMats TomTom waypoint is removed")
TomTom=nil;T.tomtomWaypoint=nil
local count=#printed;waypoint=nil
T.area=12;player.map=1429;T.sourceCache={}
check(not T.ShowSource(2318) and waypoint==nil and printed[count+1]=="Light Leather: Skin beasts near your level.","no coordinates: the hint is printed once and nothing is pinned")
T.area=141;player.map=1438
player.x,player.y=0.505,0.505;npcs[2].spawns={[141]={{51,51}}};T.sourceCache={}
check(T.DistanceText(T.FindSource(4306).spot)=="nearby","a source a few yards away is nearby, not 0 yd")
print("PASS: "..checks.." nearest-source, vendor, map pin and fallback checks")
