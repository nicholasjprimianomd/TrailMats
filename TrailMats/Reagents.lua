local _, T = ...
-- Alt-click on a reagent in the game's own crafting window pins its nearest source, as a click on a
-- TrailMats material row does. The Forever client loads Blizzard_Professions (the Mainline window,
-- flavor "camelot"): ProfessionsFrame.CraftingPage.SchematicForm takes one ProfessionsReagentSlotTemplate
-- per reagent from a frame pool every time a recipe is shown (Init), and the slot's base Init clears the
-- button's OnEnter, OnClick and OnMouseDown before fresh handlers go on (plain click: nothing for a fixed
-- reagent; Shift: chat link). A HookScript hook lives only until that handler is replaced or cleared, so
-- the click goes on OnMouseUp, which Blizzard never sets, and the tooltip line is hooked again after
-- every Init. Older clients keep the named TradeSkillReagent1..8 and CraftReagent1..8 buttons, whose XML
-- handlers are never replaced, so those are hooked once. Only hooksecurefunc and HookScript are used,
-- no field is written on a Blizzard frame, and the bookkeeping is weak so pooled frames can be collected.
local CLICK="Alt-click"
local mouseHooked=setmetatable({},{__mode="k"})  -- button -> true once OnMouseUp carries the click
local enterHooked=setmetatable({},{__mode="k"})  -- button -> the OnEnter handler the tooltip hook was added to
local forms=setmetatable({},{__mode="k"})        -- schematic form -> true once its Init is hooked
local legacy={}                                   -- global button name -> true once hooked

local function modified()
    return IsAltKeyDown and IsAltKeyDown() and not (IsShiftKeyDown and IsShiftKeyDown()) and not (IsControlKeyDown and IsControlKeyDown())
end

-- The item in a schematic-form slot: fixed basic reagents only (one listed item, the Forever case).
-- Quality choices and optional reagents open the game's own dialog or flyout on a left click, and
-- currencies have no item, so those give nil and are left alone.
function T.ReagentSlotItem(slot)
    local schematic=T.Safe(slot and slot.GetReagentSlotSchematic,slot)
    if type(schematic)~="table" then return nil end
    local basic=Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic
    if basic and schematic.reagentType~=basic then return nil end
    local reagents=schematic.reagents
    if type(reagents)~="table" or #reagents~=1 or type(reagents[1])~="table" then return nil end
    local item=reagents[1].itemID
    if type(item)=="number" and item>0 then return item end
    return nil
end

local function click(item,mouse)
    if mouse~="LeftButton" or not item or not modified() then return false end
    T.ShowSource(item)
    return true
end

-- One line under the game's reagent tooltip, only when that tooltip is up for this button.
local function hint(owner,item)
    local tip=GameTooltip
    if not item or not tip or not tip.IsShown or not tip:IsShown() then return end
    if tip.GetOwner and tip:GetOwner()~=owner then return end
    tip:AddLine(T.ClickHint(item,CLICK),0.6,0.8,1,true)
    tip:Show()
end

local function hookSlot(slot)
    local button=type(slot)=="table" and slot.Button
    if type(button)~="table" or type(button.HookScript)~="function" then return end
    if not mouseHooked[button] then
        mouseHooked[button]=true
        button:HookScript("OnMouseUp",function(_,mouse) click(T.ReagentSlotItem(slot),mouse) end)
    end
    -- Blizzard clears OnEnter on every Init, taking the hook with it; the handler identity says whether
    -- this button still carries the hook, so a repeated pass never stacks a second line.
    local current=type(button.GetScript)=="function" and button:GetScript("OnEnter") or nil
    if enterHooked[button]==nil or enterHooked[button]~=current then
        button:HookScript("OnEnter",function(self) hint(self,T.ReagentSlotItem(slot)) end)
        current=type(button.GetScript)=="function" and button:GetScript("OnEnter") or nil
        enterHooked[button]=current or false
    end
end

-- Every slot the form currently shows.
function T.HookReagentSlots(form)
    local pool=type(form)=="table" and form.reagentSlotPool
    if type(pool)=="table" and type(pool.EnumerateActive)=="function" then
        local iterate,state,first=T.Safe(pool.EnumerateActive,pool)
        if type(iterate)=="function" then for slot in iterate,state,first do hookSlot(slot) end end
    elseif type(form)=="table" and type(form.GetSlots)=="function" then
        for _,slot in ipairs(T.Safe(form.GetSlots,form) or {}) do hookSlot(slot) end
    end
end

local function hookForm(form)
    if type(form)~="table" or forms[form] or type(form.Init)~="function" or type(hooksecurefunc)~="function" then return false end
    forms[form]=true
    hooksecurefunc(form,"Init",function(self) T.HookReagentSlots(self) end)
    T.HookReagentSlots(form)
    return true
end

-- Legacy windows: the reagent link of the selected recipe, as the game's own handlers read it.
local function legacyItem(prefix,index)
    local link
    if prefix=="TradeSkillReagent" then
        local selected=TradeSkillFrame and TradeSkillFrame.selectedSkill
        link=selected and T.Safe(GetTradeSkillReagentItemLink,selected,index)
    else
        local selected=T.Safe(GetCraftSelectionIndex)
        link=selected and T.Safe(GetCraftReagentItemLink,selected,index)
    end
    return type(link)=="string" and tonumber(link:match("item:(%d+)")) or nil
end
local function hookLegacy(prefix,count)
    local hooked=false
    for i=1,count do
        local name=prefix..i
        local button=_G[name]
        if not legacy[name] and type(button)=="table" and type(button.HookScript)=="function" then
            legacy[name]=true;hooked=true
            button:HookScript("OnClick",function(_,mouse) click(legacyItem(prefix,i),mouse) end)
            button:HookScript("OnEnter",function(self) hint(self,legacyItem(prefix,i)) end)
        end
    end
    return hooked
end

-- Hooks whatever crafting window exists: the Mainline ProfessionsFrame and its linked-recipe inspect
-- frame, or the older TradeSkill and Craft windows. These are load-on-demand, so Core calls this when
-- any add-on loads and when a crafting window opens; repeated calls hook nothing twice. Returns true
-- when something new was hooked.
function T.InstallReagentHooks()
    local hooked=false
    local crafting=ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
    if hookForm(crafting) then hooked=true end
    if hookForm(InspectRecipeFrame and InspectRecipeFrame.SchematicForm) then hooked=true end
    if hookLegacy("TradeSkillReagent",MAX_TRADE_SKILL_REAGENTS or 8) then hooked=true end
    if hookLegacy("CraftReagent",MAX_CRAFT_REAGENTS or 8) then hooked=true end
    return hooked
end
