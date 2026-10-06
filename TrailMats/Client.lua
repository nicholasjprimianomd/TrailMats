local _, T = ...
local function safe(fn,...)
    if type(fn)~="function" then return nil end
    local result={pcall(fn,...)}
    if not result[1] then return nil end
    return unpack(result,2)
end
T.Safe=safe

function T.ItemName(item)
    return safe(C_Item and C_Item.GetItemNameByID,item) or safe(GetItemInfo,item) or T.items[item] or ("Item #"..item)
end
function T.Count(item)
    return safe(C_Item and C_Item.GetItemCount,item,false,false,false) or safe(GetItemCount,item,false,false) or 0
end

function T.ReadSkills()
    local skills={}
    if GetProfessions and GetProfessionInfo then
        local indexes={GetProfessions()}
        for _,index in pairs(indexes) do
            local name,_,rank,cap,_,_,line=GetProfessionInfo(index)
            if T.professions[line] and type(rank)=="number" then skills[line]={name=name,rank=rank,cap=cap or rank} end
        end
    end
    if not next(skills) and GetNumSkillLines and GetSkillLineInfo then
        for i=1,GetNumSkillLines() do
            local name,header,_,rank,_,_,cap=GetSkillLineInfo(i)
            for id,profession in pairs(T.professions) do
                if not header and name==profession.name then skills[id]={name=name,rank=rank,cap=cap} end
            end
        end
    end
    T.skills=skills
    return skills
end

function T.ReadZone()
    local map=safe(C_Map and C_Map.GetBestMapForUnit,"player")
    local area=T.mapAreas[map]
    if not area then
        local function lookup(id)
            return T.mapAreas[id] or safe(T.zoneDB and T.zoneDB.GetAreaIdByUiMapId,T.zoneDB,id)
        end
        area=lookup(map)
        local parent=map
        for _=1,5 do
            if area then break end
            local info=safe(C_Map and C_Map.GetMapInfo,parent)
            parent=info and info.parentMapID
            if not parent or parent==0 then break end
            area=lookup(parent)
        end
    end
    T.map=map
    T.area=area or 0
    T.zoneName=(T.zones[T.area] and T.zones[T.area].name) or safe(GetRealZoneText) or "Unknown zone"
end

local function storeRecipe(id,profession,name,mats,difficulty,rank)
    if not id or not T.professions[profession] or not next(mats) then return end
    local seed=false
    for _,base in ipairs(T.recipes) do if base.id==id then seed=true;break end end
    T.saved.recipes[id]={id=id,profession=profession,name=name,mats=mats,
        difficulty=difficulty,rank=rank,learned=true,seed=seed}
    for item in pairs(mats) do
        T.items[item]=T.ItemName(item)
    end
end

function T.ScanRecipes()
    -- Never learn from another character's linked or guild profession window.
    local c=C_TradeSkillUI
    if safe(IsTradeSkillLinked) or safe(IsTradeSkillGuild) or
        safe(c and c.IsTradeSkillLinked) or safe(c and c.IsTradeSkillGuild) then return end
    if GetTradeSkillLine and GetNumTradeSkills and GetTradeSkillInfo then
        local name,rank=GetTradeSkillLine()
        local profession
        for id,s in pairs(T.skills or {}) do if s.name==name then profession=id end end
        if profession then
            local scanned=0
            for i=1,GetNumTradeSkills() do
                local recipeName,difficulty=GetTradeSkillInfo(i)
                if difficulty~="header" then
                    local link=safe(GetTradeSkillRecipeLink,i)
                    local id=link and tonumber(link:match("enchant:(%d+)") or link:match("spell:(%d+)"))
                    if not id then
                        for _,base in ipairs(T.recipes) do if base.name==recipeName then id=base.id;break end end
                    end
                    id=id or (recipeName and ("live:"..profession..":"..recipeName))
                    local mats,complete={},true
                    for j=1,(safe(GetTradeSkillNumReagents,i) or 0) do
                        local _,_,required=safe(GetTradeSkillReagentInfo,i,j)
                        local reagent=safe(GetTradeSkillReagentItemLink,i,j)
                        local item=reagent and tonumber(reagent:match("item:(%d+)"))
                        if item and required then mats[item]=required else complete=false end
                    end
                    if complete then storeRecipe(id,profession,recipeName,mats,difficulty,rank);scanned=scanned+1 end
                end
            end
            if scanned>0 then T.saved.scanned[profession]=true end
            return
        end
    end
    if not c or not c.GetAllRecipeIDs or not c.GetRecipeInfo then return end
    local info=safe(c.GetBaseProfessionInfo) or safe(c.GetChildProfessionInfo)
    local profession=info and (info.parentProfessionID or info.professionID)
    if not T.professions[profession] then
        for id,s in pairs(T.skills or {}) do if info and s.name==info.professionName then profession=id end end
    end
    local skill=T.skills and T.skills[profession]
    if not skill then return end
    local colours={[0]="optimal",[1]="medium",[2]="easy",[3]="trivial"}
    for _,id in ipairs(safe(c.GetAllRecipeIDs) or {}) do
        local recipe=safe(c.GetRecipeInfo,id)
        if recipe and recipe.learned then
            local mats,complete={},true
            local schematic=safe(c.GetRecipeSchematic,id,false)
            if schematic and schematic.reagentSlotSchematics then
                for _,slot in ipairs(schematic.reagentSlotSchematics) do
                    if (slot.quantityRequired or 0)>0 then
                        if slot.reagents and #slot.reagents==1 and slot.reagents[1].itemID then
                            mats[slot.reagents[1].itemID]=slot.quantityRequired
                        else complete=false end
                    end
                end
            elseif c.GetRecipeNumReagents and c.GetRecipeReagentInfo then
                for j=1,(safe(c.GetRecipeNumReagents,id) or 0) do
                    local _,_,required=safe(c.GetRecipeReagentInfo,id,j)
                    local link=safe(c.GetRecipeReagentItemLink,id,j)
                    local item=link and tonumber(link:match("item:(%d+)"))
                    if item and required then mats[item]=required else complete=false end
                end
            else complete=false end
            if complete and next(mats) then
                storeRecipe(id,profession,recipe.name,mats,colours[recipe.relativeDifficulty] or recipe.difficulty,skill.rank)
                T.saved.scanned[profession]=true
            end
        elseif recipe and recipe.learned==false then
            T.saved.recipes[id]={profession=profession,learned=false}
        end
    end
end
