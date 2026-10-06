local _, T = ...
T.sourceCache={}

local function read(entity, field, id)
    if not entity or type(entity[field])~="function" then return nil end
    local ok,value=pcall(entity[field],id)
    if ok then return value end
end

function T.ConnectDatabase()
    T.qdb=nil;T.dropDB=nil;T.zoneDB=nil
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

function T.GetSources(item)
    if T.sourceCache[item] then return T.sourceCache[item] end
    local result={npcs={},objects={},areas={}}
    local lib=T.qdb
    local function addNPC(id, evidence, areaOverride)
        if type(id)~="number" or id<=0 then return end
        local name=read(lib and lib.Npc,"name",id) or ("Creature #"..id)
        local record={id=id,name=name,evidence=evidence}
        result.npcs[id]=record
        local spawns=read(lib and lib.Npc,"spawns",id)
        if type(spawns)=="table" then
            for area,positions in pairs(spawns) do
                result.areas[area]=result.areas[area] or {}
                local first=type(positions)=="table" and positions[1]
                if type(first)=="table" and type(first[1])=="number" and type(first[2])=="number" and lib.EraToForever then
                    local ok,x,y=pcall(lib.EraToForever,area,first[1],first[2])
                    if ok then first={x,y} end
                end
                local localEvidence=evidence
                if evidence=="Observed on this character" and area~=areaOverride then
                    localEvidence="Source observed elsewhere; location unverified"
                end
                result.areas[area][#result.areas[area]+1]={name=name,id=id,evidence=localEvidence,position=first}
            end
        end
        if areaOverride and not (spawns and spawns[areaOverride]) then
            result.areas[areaOverride]=result.areas[areaOverride] or {}
            result.areas[areaOverride][#result.areas[areaOverride]+1]=record
        end
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
        local npcs=read(lib and lib.Item,"npcDrops",item)
        for _,id in ipairs(type(npcs)=="table" and npcs or {}) do addNPC(id,"Questie reference; Forever unverified") end
        -- Questie's already decoded Classic table fills gaps such as Linen Cloth.
        -- Never execute source strings or load another copy of its large database.
        local drops=T.dropDB and T.dropDB.tableWowhead and T.dropDB.tableWowhead[item]
        for id,chance in pairs(type(drops)=="table" and drops or {}) do
            if type(chance)=="number" and chance>=1 and not result.npcs[id] then addNPC(id,"Classic drop reference") end
        end
        local objects=read(lib and lib.Item,"objectDrops",item)
        for _,id in ipairs(type(objects)=="table" and objects or {}) do
            local name=read(lib and lib.Object,"name",id)
            if name then
                result.objects[id]={name=name,evidence="Questie reference; Forever unverified"}
                local spawns=read(lib and lib.Object,"spawns",id)
                for area,positions in pairs(type(spawns)=="table" and spawns or {}) do
                    result.areas[area]=result.areas[area] or {}
                    result.areas[area][#result.areas[area]+1]={name=name,evidence="Questie object reference",position=positions[1]}
                end
            end
        end
    end
    for id,observation in pairs((T.saved and T.saved.observed[item]) or {}) do
        addNPC(id,"Observed on this character",observation.area)
    end
    for _,list in pairs(result.areas) do
        table.sort(list,function(a,b) return a.name<b.name end)
    end
    T.sourceCache[item]=result
    return result
end

function T.HasLocalSource(item)
    if T.water[T.area] and T.water[T.area][item] then return true end
    return T.GetSources(item).areas[T.area]~=nil
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
        local position=r.position
        local suffix=""
        if type(position)=="table" and type(position[1])=="number" and type(position[2])=="number" then
            suffix=string.format(" (%.0f, %.0f)",position[1],position[2])
        end
        parts[#parts+1]=r.name..suffix
    end
    local evidence=list[1].evidence
    return table.concat(parts,", ").." - "..evidence.."."
end

function T.NPCFromGUID(guid)
    if type(guid)~="string" or not guid:match("^Creature%-") then return nil end
    return tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
end

function T.ObserveLoot()
    if not GetNumLootItems or not GetLootSourceInfo or not GetLootSlotLink then return end
    for slot=1,GetNumLootItems() do
        local link=GetLootSlotLink(slot)
        local item=link and tonumber(link:match("item:(%d+)"))
        if item and T.items[item] then
            local sources={GetLootSourceInfo(slot)}
            local unique,count=nil,0
            for i=1,#sources,2 do
                local id=T.NPCFromGUID(sources[i])
                if id and id~=unique then unique=id;count=count+1 end
            end
            -- Mixed area-loot cannot safely be attributed to one NPC.
            if count==1 then
                T.saved.observed[item]=T.saved.observed[item] or {}
                T.saved.observed[item][unique]={area=T.area}
                T.sourceCache[item]=nil
            end
        end
    end
end
