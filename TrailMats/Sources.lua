local _, T = ...
T.sourceCache={}

local function read(entity, field, id)
    if not entity or type(entity[field])~="function" then return nil end
    local ok,value=pcall(entity[field],id)
    if ok then return value end
end

function T.ConnectDatabase()
    T.qdb=nil;T.dropDB=nil;T.zoneDB=nil;T.databaseDrops=nil
    local lib=_G.LibQuestieDB
    if lib and lib.RequireContract then
        local ok,compatible=pcall(lib.RequireContract,2)
        if ok and compatible then T.qdb=lib end
    end
    if _G.QuestieLoader and _G.QuestieLoader.ImportModule then
        local ok,drop=pcall(_G.QuestieLoader.ImportModule,_G.QuestieLoader,"DropDB")
        if ok then T.dropDB=drop end
        local zok,zone=pcall(_G.QuestieLoader.ImportModule,_G.QuestieLoader,"ZoneDB")
        if zok then T.zoneDB=zone end
    end
    T.sourceCache={}
end

-- Prefer Questie's decoded table. If its consumer has not initialized, read
-- the installed QuestieDB flavor's own support table once, without a copied DB.
function T.DatabaseDrops()
    if T.databaseDrops then return T.databaseDrops end
    local support=T.qdb and T.qdb.Support
    local data=read(support,"Get","QuestieClassicItemDrops")
    local encoded=data and data.wowheadData
    if type(encoded)=="table" then T.databaseDrops=encoded
    elseif type(encoded)=="string" and loadstring then
        local fn=loadstring(encoded,"TrailMats installed drop data")
        if fn then
            if setfenv then setfenv(fn,{}) end
            local ok,decoded=pcall(fn)
            if ok and type(decoded)=="table" then T.databaseDrops=decoded end
        end
    end
    return T.databaseDrops or {}
end

-- Source strength, shared by the row text (ZoneSource) and the map pin (Locate.lua):
-- 1 likely (drop chance at least MIN_DROP_CHANCE, or a vendor), 2 listed without a chance,
-- 3 fallback only (chests and crates, rarer drops, rare spawns, dungeons the player is not in).
-- Herb and ore nodes are kind "node" with the gathering skill they need; Locate.lua offers them to gatherers.
T.MIN_DROP_CHANCE=2
local WORLD_DROP=50 -- this many creatures without a drop chance means a world drop, not a target

function T.GetSources(item)
    if T.sourceCache[item] then return T.sourceCache[item] end
    -- spots keep every spawn point per source and zone, for the nearest-source lookup in Locate.lua.
    local result={npcs={},objects={},areas={},spots={},bestTier=4,unknownDrops=0}
    local lib=T.qdb
    local ok,faction
    if type(UnitFactionGroup)=="function" then ok,faction=pcall(UnitFactionGroup,"player") end
    local own=ok and (faction=="Alliance" and "A" or faction=="Horde" and "H")
    local function add(area,entry,positions)
        result.areas[area]=result.areas[area] or {}
        result.areas[area][#result.areas[area]+1]=entry
        if type(positions)=="table" then
            local spot={kind=entry.kind,name=entry.name,id=entry.id,evidence=entry.evidence,area=area,points=positions,chance=entry.chance,tier=entry.tier,
                container=entry.container,profession=entry.profession,required=entry.required}
            result.spots[#result.spots+1]=spot
            if entry.kind~="node" and entry.tier<result.bestTier then result.bestTier=entry.tier end
        end
    end
    local function addNPC(id, evidence, areaOverride, chance)
        if type(id)~="number" or id<=0 or result.npcs[id] then return end
        local name=read(lib and lib.Npc,"name",id)
        if not name then return end
        -- A creature friendly only to the player's own faction cannot be attacked: guards, prisoners, nobles.
        if own and read(lib and lib.Npc,"friendlyToFaction",id)==own then return end
        local rank=read(lib and lib.Npc,"rank",id)
        local tier=chance and (chance>=T.MIN_DROP_CHANCE and 1 or 3) or 2
        if rank==2 or rank==4 then tier=3 end -- rare spawns; elites and bosses are ordinary dungeon targets
        if not chance and tier==2 then result.unknownDrops=result.unknownDrops+1 end
        local record={id=id,name=name,evidence=evidence,chance=chance,tier=tier,kind=T.leather[item] and "skin" or "drop"}
        result.npcs[id]=record
        local spawns=read(lib and lib.Npc,"spawns",id)
        if type(spawns)=="table" then
            for area,positions in pairs(spawns) do
                add(area,{name=name,id=id,evidence=evidence,chance=chance,tier=tier,kind=record.kind,position=type(positions)=="table" and positions[1]},positions)
            end
        end
        if areaOverride and not (spawns and spawns[areaOverride]) then add(areaOverride,record) end
    end
    if T.leather[item] then
        -- No skin loot table exists in the public Questie entity schema.
        -- Keep these explicit candidates separate from ordinary loot sources.
        if item==2318 or item==2934 then
            for area,ids in pairs(T.skinCandidates) do
                for _,id in ipairs(ids) do addNPC(id,"Classic skinning candidate",area) end
            end
        end
    elseif not T.fish[item] then
        -- Questie's already decoded Classic table fills gaps such as Linen Cloth and gives drop chances.
        -- Reuse the decoded consumer when present; otherwise use the provider fallback.
        local drops=(T.dropDB and T.dropDB.tableCorrections and T.dropDB.tableCorrections[item]) or
            (T.dropDB and T.dropDB.tableWowhead and T.dropDB.tableWowhead[item]) or T.DatabaseDrops()[item]
        drops=type(drops)=="table" and drops or {}
        local npcs=read(lib and lib.Item,"npcDrops",item)
        for _,id in ipairs(type(npcs)=="table" and npcs or {}) do
            local chance=type(drops[id])=="number" and drops[id]>0 and drops[id] or nil
            addNPC(id,"Questie reference; Forever unverified",nil,chance)
        end
        for id,chance in pairs(drops) do
            if type(chance)=="number" and chance>0 then addNPC(id,"Classic drop reference",nil,chance) end
        end
        local objects=read(lib and lib.Item,"objectDrops",item)
        for _,id in ipairs(type(objects)=="table" and objects or {}) do
            local name=read(lib and lib.Object,"name",id)
            if name then
                -- Herb and ore nodes need a gathering skill; any other object is a chest or crate: a fallback only.
                local profession,required
                if T.NodeRequirement then profession,required=T.NodeRequirement(name) end
                result.objects[id]={name=name,evidence="Questie reference; Forever unverified"}
                local spawns=read(lib and lib.Object,"spawns",id)
                for area,positions in pairs(type(spawns)=="table" and spawns or {}) do
                    add(area,{name=name,id=id,evidence="Questie object reference",kind=profession and "node" or "object",tier=profession and 1 or 3,
                        container=not profession or nil,profession=profession,required=required,position=type(positions)=="table" and positions[1]},positions)
                end
            end
        end
    end
    -- Dozens of creatures without a drop chance (ore, stone, gems) is a world drop: none of them is a target,
    -- so they become fallbacks, and with nothing likelier the item has no single target at all.
    if result.unknownDrops>=WORLD_DROP then
        result.bestTier=4
        for _,list in pairs(result.areas) do for _,e in ipairs(list) do if e.tier==2 and not e.chance then e.tier=3 end end end
        for _,spot in ipairs(result.spots) do
            if spot.tier==2 and not spot.chance then spot.tier=3 end
            if spot.kind~="node" and spot.tier<result.bestTier then result.bestTier=spot.tier end
        end
    end
    result.worldDrop=result.unknownDrops>=WORLD_DROP and result.bestTier>1
    for _,list in pairs(result.areas) do
        table.sort(list,function(a,b) return a.name<b.name end)
    end
    T.sourceCache[item]=result
    return result
end

-- The planner's notion of "can be collected here" matches the row: a herb or ore node here, or what
-- ZoneSource would name (no fallback-only zones, no world drops).
function T.HasLocalSource(item)
    if T.water[T.area] and T.water[T.area][item] then return true end
    local list=T.GetSources(item).areas[T.area]
    if not list then return false end
    for _,e in ipairs(list) do if e.kind=="node" then return true end end
    if T.ZoneSource then return T.ZoneSource(item)~=nil end
    return true
end

function T.SourceText(item, limit)
    if T.vendor[item] then return "Vendor ingredient; raw materials are self-farmed." end
    local water=T.water[T.area] and T.water[T.area][item]
    if water then return "Fish in "..water.." (location reference; Forever yields unverified)." end
    local list=T.GetSources(item).areas[T.area]
    if not list or #list==0 then return "No local source recorded. This does not mean it cannot drop here." end
    local parts={}
    for i=1,math.min(limit or 3,#list) do
        local r=list[i]
        parts[#parts+1]=r.name
    end
    local evidence=list[1].evidence
    return table.concat(parts,", ").." - "..evidence.."."
end

function T.VendorSource(item)
    local lib=T.qdb
    local ids=read(lib and lib.Item,"vendors",item)
    local faction=T.Safe(UnitFactionGroup,"player")
    local letter=faction=="Alliance" and "A" or faction=="Horde" and "H"
    local names,seen={},{}
    for _,id in ipairs(type(ids)=="table" and ids or {}) do
        local spawns=read(lib and lib.Npc,"spawns",id)
        local friendly=read(lib and lib.Npc,"friendlyToFaction",id)
        local allowed=friendly=="AH" or letter and friendly and friendly:find(letter,1,true)
        if allowed and spawns and spawns[T.area] then
            local name=read(lib and lib.Npc,"name",id)
            if name and not seen[name] then names[#names+1]=name;seen[name]=true end
        end
    end
    table.sort(names)
    if #names==0 then return nil end
    local shown={};for i=1,math.min(3,#names) do shown[i]=names[i] end
    return table.concat(shown,", ")
end

-- Every friendly vendor for an item, in any zone, with all its spawn points. Cached with the sources,
-- so reconnecting the database or clearing T.sourceCache drops it too.
function T.VendorSpots(item)
    local key="vendor:"..tostring(item)
    if T.sourceCache[key] then return T.sourceCache[key] end
    local lib=T.qdb;local spots={}
    local ids=read(lib and lib.Item,"vendors",item)
    local faction=T.Safe(UnitFactionGroup,"player")
    local letter=faction=="Alliance" and "A" or faction=="Horde" and "H"
    for _,id in ipairs(type(ids)=="table" and ids or {}) do
        local friendly=read(lib and lib.Npc,"friendlyToFaction",id)
        if friendly=="AH" or letter and type(friendly)=="string" and friendly:find(letter,1,true) then
            local name=read(lib and lib.Npc,"name",id)
            local spawns=read(lib and lib.Npc,"spawns",id)
            if name and type(spawns)=="table" then
                for area,points in pairs(spawns) do
                    if type(points)=="table" then spots[#spots+1]={kind="vendor",name=name,id=id,area=area,points=points,tier=1,evidence="Questie vendor reference"} end
                end
            end
        end
    end
    T.sourceCache[key]=spots
    return spots
end

function T.NPCFromGUID(guid)
    if type(guid)~="string" or not guid:match("^Creature%-") then return nil end
    return tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
end
