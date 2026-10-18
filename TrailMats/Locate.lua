local _, T = ...
-- Where to get a material when this zone has no source: the nearest database spawn anywhere,
-- and a map pin for it. Spawn points are QuestieDB zone percentages (0-100) keyed by Questie area
-- id; they go on that zone's UI map the way Questie places its own pins (ZoneDB:GetUiMapIdByAreaId,
-- no Era projection, because the Forever flavor ships its own entity data).
-- Source strength (tier) comes from Sources.lua and is shared with the row text.
local SAMPLE=6       -- spawn points checked per source and zone; enough to find the near side of a camp
local TTL=30         -- seconds a nearest result is reused for one item in one zone
local NEARBY=15      -- yards under which a source is simply "nearby"
local worldCache,continentCache,zoneMaps={},{},nil

local function now() return T.Safe(GetTime) or T.Safe(time) or 0 end

function T.UiMapForArea(area)
    if type(area)~="number" then return nil end
    for map,a in pairs(T.mapAreas or {}) do if a==area then return map end end
    local map=T.Safe(T.zoneDB and T.zoneDB.GetUiMapIdByAreaId,T.zoneDB,area)
    if type(map)=="number" then return map end
    -- Without Questie's zone table, match the area's name against the two continents' zone maps.
    local name=T.Safe(C_Map and C_Map.GetAreaInfo,area)
    if type(name)~="string" then return nil end
    if not zoneMaps then
        zoneMaps={}
        local zoneType=Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
        for _,continent in ipairs({1414,1415}) do -- Kalimdor, Eastern Kingdoms
            for _,info in ipairs(T.Safe(C_Map and C_Map.GetMapChildrenInfo,continent,zoneType,true) or {}) do
                if info.name and info.mapID and not zoneMaps[info.name] then zoneMaps[info.name]=info.mapID end
            end
        end
    end
    return zoneMaps[name]
end

function T.AreaName(area)
    if T.zones[area] then return T.zones[area].name end
    local name=T.Safe(C_Map and C_Map.GetAreaInfo,area)
    if type(name)=="string" and name~="" then return name end
    local map=T.UiMapForArea(area)
    local info=map and C_Map and T.Safe(C_Map.GetMapInfo,map)
    return info and info.name or (T.destinationNames or {})[area] or "another zone"
end

-- The continent map a UI map belongs to, walking its parents; used when world positions are unavailable.
local function continentOf(map)
    if not map then return nil end
    if continentCache[map]~=nil then return continentCache[map] or nil end
    local continentType=Enum and Enum.UIMapType and Enum.UIMapType.Continent or 2
    local id,found=map,false
    for _=1,6 do
        local info=T.Safe(C_Map and C_Map.GetMapInfo,id)
        if type(info)~="table" then break end
        if info.mapType==continentType then found=id;break end
        id=info.parentMapID
        if not id or id==0 then break end
    end
    continentCache[map]=found
    return found or nil
end

-- World position in yards {c=continent,x,y} for a map position in 0-1, or nil when the client cannot say.
local function toWorld(map,x,y,fresh)
    if not (map and C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
    local key=not fresh and (map..":"..x..":"..y)
    if key and worldCache[key]~=nil then return worldCache[key] or nil end
    local continent,pos=T.Safe(C_Map.GetWorldPosFromMapPos,map,CreateVector2D(x,y))
    local wx,wy
    if type(pos)=="table" then
        wx,wy=pos.x,pos.y
        if not wx and pos.GetXY then wx,wy=pos:GetXY() end
    end
    local w=continent and wx and wy and {c=continent,x=wx,y=wy} or false
    if key then worldCache[key]=w end
    return w or nil
end

-- {world, continent map} for the player; world is nil inside instances, where the client reports no position.
function T.PlayerWorld()
    local map=T.Safe(C_Map and C_Map.GetBestMapForUnit,"player")
    local here={continent=continentOf(map)}
    local pos=map and T.Safe(C_Map.GetPlayerMapPosition,map,"player")
    if type(pos)=="table" then
        local x,y=pos.x,pos.y
        if not x and pos.GetXY then x,y=pos:GetXY() end
        if x and y then here.world=toWorld(map,x,y,true) end
    end
    return here
end

-- Points of a spot as {area,x,y,dungeon}; dungeon spawns (-1,-1) become the dungeon's entrances.
local function points(spot)
    local list={}
    for _,p in ipairs(spot.points or {}) do
        if type(p)=="table" and type(p[1])=="number" and type(p[2])=="number" and p[1]>=0 and p[2]>=0 then list[#list+1]={spot.area,p[1],p[2]} end
    end
    if #list==0 then
        for _,entrance in ipairs(T.Safe(T.zoneDB and T.zoneDB.GetDungeonLocation,T.zoneDB,spot.area) or {}) do
            if type(entrance)=="table" and type(entrance[1])=="number" then list[#list+1]={entrance[1],entrance[2],entrance[3],spot.area} end
        end
    end
    return list
end

-- Lower is better: {place, class, distance}. place 0 is this continent (or this zone), 1 unknown, 2 another
-- continent. class 1 is a good source (tiers 1 and 2: a likely or listed drop, a vendor, a node), 2 a fallback;
-- among good sources the closer wins, so a listed drop next door beats a likelier one across the continent.
local function better(a,b)
    for i=1,3 do if a[i]~=b[i] then return a[i]<b[i] end end
    return false
end

-- The best spot for the player: the strongest tier available, then the closest. Inside a dungeon its own
-- spawns come first; without positions this zone, then this continent, come first.
function T.NearestSpot(spots,here)
    if not spots or not spots[1] then return nil end
    here=here or T.PlayerWorld()
    local best,bestKey
    for _,s in ipairs(spots) do
        local list=points(s)
        local step=math.max(1,math.floor(#list/SAMPLE))
        for i=1,#list,step do
            local p=list[i]
            local inside=p[4] and p[4]==T.area
            local tier=s.tier or 2
            if p[4] and not inside then tier=math.max(tier,3) end -- a dungeon you are not in is a last resort
            local map=T.UiMapForArea(p[1])
            local place,distance,measured=1,1e9,nil
            local w=not inside and here.world and map and toWorld(map,p[2]/100,p[3]/100)
            if w and w.c==here.world.c then
                measured=math.sqrt((w.x-here.world.x)^2+(w.y-here.world.y)^2);place,distance=0,measured
            elseif w then place=2
            elseif inside or p[1]==T.area then place,distance=0,0 -- no position: this zone (or this dungeon) first
            elseif here.continent and map then
                local c=continentOf(map)
                if c then place=c==here.continent and 0 or 2 end
            end
            local key={place,tier>=3 and 2 or 1,distance}
            local tie=bestKey and not better(key,bestKey) and not better(bestKey,key)
            if not best or better(key,bestKey) or (tie and ((s.chance or 0)>(best.chance or 0) or ((s.chance or 0)==(best.chance or 0) and s.name<best.name))) then
                bestKey=key
                best={name=s.name,kind=s.kind,evidence=s.evidence,chance=s.chance,tier=tier,area=p[1],x=p[2],y=p[3],map=map,
                    dungeon=p[4],distance=measured,otherContinent=place==2 or nil}
            end
        end
    end
    return best
end

function T.DistanceText(spot)
    if spot.distance then
        if spot.distance<NEARBY then return "nearby" end
        return "about "..(math.floor(spot.distance/10+0.5)*10).." yd"
    end
    if spot.otherContinent then return "on another continent" end
end

-- Herbs and ore come from nodes; stone and gems from veins; bars from smelting. Skill levels from Ranges.lua's
-- node tables and the Wowhead Forever Mining overview (smelting); gem veins are the Classic mining tables.
local stones={[2835]="Copper Vein",[2836]="Tin Vein",[2838]="Iron Deposit",[7912]="Mithril Deposit",[12365]="Small Thorium Vein",
    [774]="Copper Vein",[818]="Copper Vein",[1210]="Tin Vein",[1206]="Tin Vein",[1705]="Silver Vein",[1529]="Iron Deposit",
    [3864]="Iron Deposit",[7909]="Mithril Deposit",[7910]="Mithril Deposit"}
local gems={[774]=true,[818]=true,[1210]=true,[1206]=true,[1705]=true,[1529]=true,[3864]=true,[7909]=true,[7910]=true}
local bars={[2840]={"Copper Ore",1},[3576]={"Tin Ore",65},[2841]={"Copper Bar and Tin Bar",65},[2842]={"Silver Ore",75},
    [3575]={"Iron Ore",125},[3577]={"Gold Ore",155},[3859]={"Iron Bar and Coal",165},[3860]={"Mithril Ore",175},
    [6037]={"Truesilver Ore",230},[12359]={"Thorium Ore",250}}
local function gatherInfo(item)
    if bars[item] then return {smelt=bars[item][1],profession=186,required=bars[item][2]} end
    if not T.NodeRequirement then return nil end
    local name=T.ItemName(item)
    local candidates=stones[item] and {stones[item]} or {name,(name:gsub(" Ore$"," Vein")),(name:gsub(" Ore$"," Deposit")),(name:gsub("^Thorium Ore$","Small Thorium Vein"))}
    for _,n in ipairs(candidates) do
        local profession,required=T.NodeRequirement(n)
        if profession then return {node=n,profession=profession,required=required,gem=gems[item]} end
    end
end
local function gatherHint(item,g)
    local skill=T.professions[g.profession].name
    local has=T.skills and T.skills[g.profession]
    local need=skill.." "..g.required
    if g.smelt then
        return {label="Smelt: "..g.smelt.." ("..need..")",
            detail="Smelted from "..g.smelt.." by miners ("..need..")."..(has and "" or " Without Mining, buy it at the auction house.")}
    end
    local what=g.profession==182 and "Herb: " or "Mine: "
    local low=has and has.rank<g.required
    return {label=what..g.node.." ("..need..")",
        detail=T.ItemName(item)..(g.gem and " comes now and then from mining " or " is gathered from ")..g.node.." nodes ("..need..")."..
            (low and (" Your "..skill.." is "..has.rank..".") or has and (" The "..skill.." tab shows where to gather at your skill.") or
            (" Without "..skill..", buy it at the auction house."))}
end
-- Herbs, ore, stone, gems and bars: the nearest node the player can gather (QuestieDB lists node spawns),
-- otherwise the node and skill it needs, or the smelt. nil for anything that is not gathered.
function T.GatherSource(item,fresh)
    local g=gatherInfo(item)
    if not g then return nil end
    T.sourceCache=T.sourceCache or {}
    local key="gather:"..tostring(item)
    local cached=T.sourceCache[key]
    if not fresh and cached and cached.area==T.area and now()-cached.at<TTL then return cached.found end
    local found=T.GatherNode(item,g)
    T.sourceCache[key]={found=found,area=T.area,at=now()}
    return found
end
function T.GatherNode(item,g)
    local hint=gatherHint(item,g)
    local skill=T.skills and T.skills[g.profession]
    if g.smelt or not skill or skill.rank<g.required or not T.qdb then return hint end
    local nodes={}
    for _,s in ipairs(T.GetSources(item).spots or {}) do
        if s.kind=="node" and s.profession==g.profession and (s.required or 0)<=skill.rank then nodes[#nodes+1]=s end
    end
    local spot=T.NearestSpot(nodes)
    if not spot then return hint end
    local zone=T.AreaName(spot.area)
    local distance=T.DistanceText(spot)
    return {spot=spot,label=(g.profession==182 and "Herb: " or "Mine: ")..spot.name..(spot.area~=T.area and (", "..zone) or ""),
        detail=(spot.distance and "Nearest " or "A ")..spot.name.." node: "..zone..(distance and (", "..distance) or "").."."..
            (g.gem and (" "..T.ItemName(item).." comes now and then from mining it.") or "")}
end

local prefix={vendor="Buy from: ",skin="Skin: ",drop="From: ",object="From: "}

-- {label, detail, spot} for an item: the best database source anywhere, or an honest hint when the
-- database has none. fresh skips the short cache so a click always uses the player's current position.
function T.FindSource(item,fresh)
    T.sourceCache=T.sourceCache or {}
    if not T.qdb and not T.dropDB then
        return {label="Source database unavailable",detail="Install or enable Questie for creature, object and vendor locations."}
    end
    local key="nearest:"..tostring(item)
    local cached=T.sourceCache[key]
    if not fresh and cached and cached.area==T.area and now()-cached.at<TTL then return cached.found end
    local found=T.GatherSource(item,fresh)
    if not found then
        local supply=T.levelingSupplies[item]
        local vendors=T.VendorSpots and T.VendorSpots(item) or {}
        local sources=T.GetSources(item)
        local spots=sources.spots or {}
        if T.leather[item] then
            -- Skinning candidates are a reviewed list for two starting zones only, not a world map of leather.
            local here={};for _,s in ipairs(spots) do if s.area==T.area then here[#here+1]=s end end
            spots=here
        end
        local spot=supply and T.NearestSpot(vendors) or nil
        if not spot and not sources.worldDrop then spot=T.NearestSpot(spots) end
        if not spot and not supply then spot=T.NearestSpot(vendors) end
        if spot then
            local zone=T.AreaName(spot.area)
            local dungeon=spot.dungeon and T.AreaName(spot.dungeon)
            local distance=T.DistanceText(spot)
            local located=spot.distance or spot.area==T.area or (spot.dungeon and spot.dungeon==T.area)
            found={spot=spot,label=(prefix[spot.kind] or "From: ")..spot.name..(dungeon and (" ("..dungeon..")") or "")..
                    ((spot.area~=T.area or dungeon) and (", "..zone) or ""),
                detail=(spot.kind=="vendor" and (located and "Nearest vendor: " or "A vendor: ") or (located and "Nearest database source: " or "A database source: "))..
                    spot.name.." in "..(dungeon and (dungeon..", entrance in "..zone) or zone)..(distance and (", "..distance) or "").."."..
                    (spot.evidence and (" "..spot.evidence..".") or "")}
        elseif sources.worldDrop then
            found={label="World drop from many creatures",detail="The database lists "..sources.unknownDrops.." creatures that can drop it, none a reliable target. Check the auction house."}
        elseif T.fish[item] then
            local waters=T.water[T.area]
            if waters and waters[item] then found={label="Fish: "..waters[item],detail="Fishing reference for this zone; catches vary."}
            else
                local areas={}
                for area,w in pairs(T.water or {}) do if w[item] then areas[#areas+1]=area end end
                table.sort(areas)
                found=areas[1] and {label="Fish: "..T.AreaName(areas[1]).." "..T.water[areas[1]][item],detail="Fishing reference; catches vary."} or
                    {label="Caught by fishing",detail="No catch locations for this fish in the database; it comes from fishing pools and open water."}
            end
        elseif T.leather[item] then
            found={label="Skin beasts near your level",detail="No skinning list in the database for this leather; beasts around its level give it when skinned."}
        elseif supply then
            found={label="Trade or profession supply vendor",detail="No vendor for this item in the database; trade and profession supply vendors usually sell it."}
        elseif next(sources.npcs or {}) or next(sources.objects or {}) then
            found={label="Listed without a map location",detail="The database knows creatures or objects with this item but not where they are (for example a dungeon without a recorded entrance)."}
        else
            found={label="Not in the source database",detail="QuestieDB has no creature, object or vendor record for this item. It may come from containers, quests or crafting."}
        end
    end
    T.sourceCache[key]={found=found,area=T.area,at=now()}
    return found
end

-- Pins the point. TomTom, when installed, gets it instead of a second Blizzard arrow; its previous
-- TrailMats waypoint is removed so pins do not pile up.
function T.MarkMap(map,x,y,title)
    if not map then return false end
    local tomtom=false
    if TomTom and type(TomTom.AddWaypoint)=="function" then
        if T.tomtomWaypoint and type(TomTom.RemoveWaypoint)=="function" then T.Safe(TomTom.RemoveWaypoint,TomTom,T.tomtomWaypoint) end
        local uid=T.Safe(TomTom.AddWaypoint,TomTom,map,x,y,{title=title,persistent=false,minimap=true,world=true})
        if uid then T.tomtomWaypoint=uid;tomtom=true end
    end
    local pinned=false
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local allowed=not C_Map.CanSetUserWaypointOnMap or T.Safe(C_Map.CanSetUserWaypointOnMap,map)
        local point=allowed and T.Safe(UiMapPoint.CreateFromCoordinates,map,x,y)
        if point and pcall(C_Map.SetUserWaypoint,point) then
            pinned=true
            if not tomtom and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then T.Safe(C_SuperTrack.SetSuperTrackedUserWaypoint,true) end
        end
    end
    return pinned or tomtom
end

-- Opening UI panels from addon code is blocked in combat (ShowUIPanel refuses and shows "Interface action
-- failed"), so the map only opens out of combat; an open map just changes zone.
function T.OpenMap(map)
    if not map then return false end
    if WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown() and WorldMapFrame.SetMapID then
        T.Safe(WorldMapFrame.SetMapID,WorldMapFrame,map);return true
    end
    if InCombatLockdown and InCombatLockdown() then return false end
    if type(OpenWorldMap)=="function" then T.Safe(OpenWorldMap,map);return true end
    if WorldMapFrame and WorldMapFrame.SetMapID and ToggleWorldMap then
        T.Safe(ToggleWorldMap);T.Safe(WorldMapFrame.SetMapID,WorldMapFrame,map);return true
    end
    return false
end

-- Click handler for material rows and tracker lines: pin the source and say where it is.
function T.ShowSource(item)
    local found=T.FindSource(item,true)
    local spot=found.spot
    local name=T.ItemName(item)
    if not spot or not spot.map then
        T.Print(name..": "..found.label..".")
        return false
    end
    local marked=T.MarkMap(spot.map,spot.x/100,spot.y/100,spot.name.." ("..name..")")
    local note=""
    if T.settings.openMap~=false and not T.OpenMap(spot.map) then note=" Open the map after combat to see it." end
    local distance=T.DistanceText(spot)
    local dungeon=spot.dungeon and (" ("..T.AreaName(spot.dungeon).." entrance)") or ""
    T.Print(name..": "..spot.name..dungeon..", "..T.AreaName(spot.area).." "..string.format("%.1f, %.1f",spot.x,spot.y)..
        (distance and (" ("..distance..")") or "")..(marked and ". Marked on your map." or ".")..(marked and note or ""))
    return marked
end
