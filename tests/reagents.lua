-- Alt-click on reagent slots in the game's crafting window: the Mainline schematic form, whose pooled
-- slots get their handlers cleared and reset on every recipe, and the older TradeSkill and Craft buttons.
local root=arg[1] or "."
local T={saved={recipes={},levelingPrices={},scanned={}},skills={},settings={openMap=true},area=141,zoneName="Teldrassil"}
T.Safe=function(fn,...) if type(fn)~="function" then return nil end local r={pcall(fn,...)};if not r[1] then return nil end;return unpack(r,2) end
local printed={}
T.Print=function(text) printed[#printed+1]=text end
UnitFactionGroup=function() return "Alliance" end
GetTime=function() return 1000 end
for _,name in ipairs({"Data","Ranges","LevelingData","Sources","Locate","Actions","UI","Reagents"}) do
    assert(loadfile(root.."/TrailMats/"..name..".lua"))("TrailMats",T)
end
local names={[4306]="Silk Cloth",[2320]="Coarse Thread",[7777]="Odd Trinket",[4339]="Bolt of Silk Cloth"}
T.ItemName=function(item) return names[item] or T.items[item] or ("Item #"..item) end
local checks=0
local function check(ok,label) assert(ok,label);checks=checks+1 end

-- World: one zone, a creature that drops Silk Cloth and a vendor for Coarse Thread.
CreateVector2D=function(x,y) return {x=x,y=y} end
Enum={UIMapType={Continent=2,Zone=3},CraftingReagentType={Basic=1,Modifying=2,Finishing=3}}
local player={map=1438,x=0.5,y=0.5}
local waypoint,opened
C_Map={
    GetBestMapForUnit=function() return player.map end,
    GetPlayerMapPosition=function() return {GetXY=function() return player.x,player.y end} end,
    GetWorldPosFromMapPos=function(map,v) if map==1438 then return 1,{x=v.x*1000,y=v.y*1000} end end,
    GetMapInfo=function(map) return {mapType=map==1414 and 2 or 3,parentMapID=map==1438 and 1414 or nil} end,
    GetAreaInfo=function(area) return area==141 and "Teldrassil" or nil end,
    SetUserWaypoint=function(point) waypoint=point end,
    GetMapChildrenInfo=function() return {} end,
}
UiMapPoint={CreateFromCoordinates=function(map,x,y) return {uiMapID=map,x=x,y=y} end}
C_SuperTrack={SetSuperTrackedUserWaypoint=function() end}
OpenWorldMap=function(map) opened=map end
InCombatLockdown=function() return false end
local npcs={[1]={name="Timberling Bark Ripper",spawns={[141]={{30,40}}},friendly="AH"},[2]={name="Dolanaar Supplier",spawns={[141]={{55,60}}},friendly="A"}}
T.qdb={
    Item={npcDrops=function() return nil end,objectDrops=function() return nil end,vendors=function(id) return id==2320 and {2} or nil end},
    Npc={name=function(id) return npcs[id] and npcs[id].name end,spawns=function(id) return npcs[id] and npcs[id].spawns end,
        friendlyToFaction=function(id) return npcs[id] and npcs[id].friendly end,rank=function() return nil end},
}
T.dropDB={tableWowhead={[4306]={[1]=25}}}
T.zoneDB={GetUiMapIdByAreaId=function(_,area) return area==141 and 1438 or nil end,GetDungeonLocation=function() return nil end}
local function pinnedAt(x,y) return waypoint and waypoint.uiMapID==1438 and math.abs(waypoint.x-x)<1e-9 and math.abs(waypoint.y-y)<1e-9 end

-- Modifier keys and widgets. SetScript replaces a handler and drops its hooks; HookScript appends, or
-- acts as SetScript when there is no handler (API ScriptRegion HookScript).
local alt,shift,ctrl=false,false,false
IsAltKeyDown=function() return alt end;IsShiftKeyDown=function() return shift end;IsControlKeyDown=function() return ctrl end
local function widget()
    local w={base={},hooks={}}
    function w:SetScript(name,fn) self.base[name]=fn;self.hooks[name]={} end
    function w:HookScript(name,fn) if self.base[name] then table.insert(self.hooks[name],fn) else self.base[name]=fn;self.hooks[name]={} end end
    function w:GetScript(name) return self.base[name] end
    function w:Fire(name,...) local base=self.base[name];if base then base(self,...) end;for _,fn in ipairs(self.hooks[name] or {}) do fn(self,...) end end
    function w:Handlers(name) return (self.base[name] and 1 or 0)+#(self.hooks[name] or {}) end
    return w
end
local function press(button,mouse) button:Fire("OnMouseDown",mouse);button:Fire("OnMouseUp",mouse);button:Fire("OnClick",mouse) end
GameTooltip={lines={},shown=false}
function GameTooltip:SetOwner(owner) self.owner=owner;self.lines={};self.shown=false end
function GameTooltip:AddLine(text) self.lines[#self.lines+1]=text end
function GameTooltip:SetRecipeReagentItem(recipe,slot) self.lines[#self.lines+1]="reagent "..recipe..":"..slot end
function GameTooltip:SetTradeSkillItem(skill,slot) self.lines[#self.lines+1]="tradeskill "..skill..":"..slot end
function GameTooltip:Show() self.shown=true end
function GameTooltip:Hide() self.shown=false;self.owner=nil;self.lines={} end
function GameTooltip:IsShown() return self.shown end
function GameTooltip:GetOwner() return self.owner end

-- The schematic form as Blizzard_ProfessionsRecipeSchematicForm.lua builds it: a pool of slot frames,
-- released and re-acquired on every Init; each slot's Init clears the button's OnEnter, OnClick and
-- OnMouseDown (Blizzard_ProfessionsRecipeSlotBase.lua) before the form sets new ones per reagent kind.
local links,dialogs,flyouts={},{},{}
local function slotFrame()
    local slot={Button=widget(),loading=false}
    function slot:Init(schematic)
        self.Button:SetScript("OnEnter",nil);self.Button:SetScript("OnClick",nil);self.Button:SetScript("OnMouseDown",nil)
        self.schematic=schematic
    end
    function slot:GetReagentSlotSchematic() return self.schematic end
    function slot:IsLoading() return self.loading end
    return slot
end
local function schematicForm()
    local form={inits=0,slots={}}
    local pool={free={},active={}}
    function pool:Acquire() local slot=table.remove(self.free) or slotFrame();self.active[slot]=true;return slot end
    function pool:ReleaseAll() for slot in pairs(self.active) do self.free[#self.free+1]=slot end;self.active={} end
    function pool:EnumerateActive() return pairs(self.active) end
    form.reagentSlotPool=pool
    function form:Init(recipe)
        self.inits=self.inits+1
        self.reagentSlotPool:ReleaseAll();self.slots={}
        for index,schematic in ipairs(recipe.slots) do
            local slot=self.reagentSlotPool:Acquire();slot:Init(schematic);self.slots[index]=slot
            local button=slot.Button
            if schematic.reagentType==Enum.CraftingReagentType.Basic then
                if #schematic.reagents>1 then -- a quality choice: a left click opens the quality dialog
                    button:SetScript("OnClick",function(_,mouse) if shift then links[#links+1]=schematic.reagents[1].itemID elseif mouse=="LeftButton" then dialogs[#dialogs+1]=index end end)
                else -- a fixed reagent: Shift links it, anything else does nothing
                    button:SetScript("OnClick",function() if shift then links[#links+1]=schematic.reagents[1].itemID end end)
                end
                button:SetScript("OnEnter",function(self) if slot:IsLoading() then return end GameTooltip:SetOwner(self);GameTooltip:SetRecipeReagentItem(recipe.id,index);GameTooltip:Show() end)
            else -- an optional reagent: a left press opens the flyout
                button:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self);GameTooltip:AddLine("optional");GameTooltip:Show() end)
                button:SetScript("OnMouseDown",function(_,mouse) if mouse=="LeftButton" then flyouts[#flyouts+1]=index end end)
            end
        end
    end
    return form
end

-- Nothing to hook yet: no error, nothing installed.
check(T.InstallReagentHooks()==false,"without a crafting window there is nothing to hook")
hooksecurefunc=function(target,name,fn) local original=target[name];target[name]=function(...) original(...);fn(...) end end
local form=schematicForm();ProfessionsFrame={CraftingPage={SchematicForm=form}}
local inspect=schematicForm();InspectRecipeFrame={SchematicForm=inspect}
check(T.InstallReagentHooks()==true,"the schematic form is hooked once it exists")
check(T.InstallReagentHooks()==false,"a second install hooks nothing again")

-- A recipe with two fixed reagents: the slot items resolve and the tooltip gains one line after Blizzard's.
local silk={reagentType=1,reagents={{itemID=4306}},quantityRequired=2}
local thread={reagentType=1,reagents={{itemID=2320}},quantityRequired=1}
form:Init({id=3839,slots={silk,thread}})
local b1,b2=form.slots[1].Button,form.slots[2].Button
check(T.ReagentSlotItem(form.slots[1])==4306 and T.ReagentSlotItem(form.slots[2])==2320,"fixed reagents resolve to their item")
b1:Fire("OnEnter")
check(#GameTooltip.lines==2 and GameTooltip.lines[1]=="reagent 3839:1" and GameTooltip.lines[2]=="Alt-click: mark it on your map.","the reagent tooltip gains one Alt-click line after the game's own")
GameTooltip:Hide()

-- Unmodified and Shift clicks stay the game's; only Alt with the left button pins.
press(b1,"LeftButton");check(waypoint==nil and #printed==0,"a plain click pins nothing")
shift=true;press(b1,"LeftButton");shift=false;check(links[1]==4306 and waypoint==nil,"Shift-click still links the reagent and pins nothing")
alt=true
press(b1,"RightButton");check(waypoint==nil,"Alt with the right button pins nothing")
shift=true;press(b1,"LeftButton");shift=false;check(#links==2 and waypoint==nil,"Shift+Alt stays the game's chat link")
ctrl=true;press(b1,"LeftButton");ctrl=false;check(waypoint==nil and #printed==0,"Ctrl+Alt pins nothing")
press(b1,"LeftButton")
check(pinnedAt(0.30,0.40) and opened==1438,"Alt-click pins the reagent's nearest source and opens its map")
check(printed[#printed]:find("^Silk Cloth: Timberling Bark Ripper, Teldrassil 30.0, 40.0") and printed[#printed]:find("Marked on your map",1,true),"chat says where")
check(#links==2 and #dialogs==0 and #flyouts==0,"the game's own click actions did not fire")
waypoint=nil;press(b2,"LeftButton");check(pinnedAt(0.55,0.60),"the second slot pins its vendor")
alt=false

-- Showing another recipe reuses the pooled frames; the game resets their handlers and the hooks follow without piling up.
form:Init({id=2963,slots={thread}})
local b=form.slots[1].Button
check(b==b1 or b==b2,"pooled slot frames are reused")
check(b:Handlers("OnMouseUp")==1 and b:Handlers("OnEnter")==2,"one click hook and one tooltip hook after a reset")
b:Fire("OnEnter");check(#GameTooltip.lines==2 and GameTooltip.lines[2]=="Alt-click: mark it on your map.","the tooltip line appears once after the reset");GameTooltip:Hide()
alt=true;waypoint=nil;press(b,"LeftButton");alt=false;check(pinnedAt(0.55,0.60),"Alt-click after a reset pins the new reagent")
form:Init({id=2963,slots={thread}});form:Init({id=3839,slots={silk,thread}})
for _,slot in ipairs(form.slots) do check(slot.Button:Handlers("OnMouseUp")==1 and slot.Button:Handlers("OnEnter")==2,"hooks do not accumulate over recipes") end
T.HookReagentSlots(form)
for _,slot in ipairs(form.slots) do check(slot.Button:Handlers("OnEnter")==2,"a repeated pass without a reset adds nothing") end

-- Quality choices, optional reagents and currencies are left to the game.
local quality={reagentType=1,reagents={{itemID=4306},{itemID=4339}}}
local optional={reagentType=2,reagents={{itemID=2320}}}
local currency={reagentType=1,reagents={{currencyID=1}}}
form:Init({id=1,slots={quality,optional,currency}})
alt=true;waypoint=nil
for i=1,3 do press(form.slots[i].Button,"LeftButton");form.slots[i].Button:Fire("OnEnter") end
alt=false
check(waypoint==nil and #dialogs==1 and #flyouts==1,"Alt-click leaves quality dialogs, flyouts and currencies to the game")
check(not table.concat(GameTooltip.lines," "):find("Alt-click",1,true),"no click line on slots that cannot be pinned");GameTooltip:Hide()

-- A slot still loading its items shows no tooltip, so nothing is added to one.
form:Init({id=3839,slots={silk}});form.slots[1].loading=true;form.slots[1].Button:Fire("OnEnter")
check(not GameTooltip:IsShown() and #GameTooltip.lines==0,"no line while the slot is loading")
form.slots[1].loading=false

-- No mapped source: the tooltip says so, and the click prints the hint instead of pinning.
form:Init({id=5,slots={{reagentType=1,reagents={{itemID=7777}}}}})
form.slots[1].Button:Fire("OnEnter");check(GameTooltip.lines[2]=="Alt-click: show where to get it in chat.","the tooltip names the chat fallback");GameTooltip:Hide()
alt=true;waypoint=nil;local count=#printed;press(form.slots[1].Button,"LeftButton");alt=false
check(waypoint==nil and printed[count+1]=="Odd Trinket: Not in the source database.","an unplaceable reagent prints the hint once")

-- The linked-recipe inspect form gets the same hook.
inspect:Init({id=3839,slots={silk}});alt=true;waypoint=nil;press(inspect.slots[1].Button,"LeftButton");alt=false
check(pinnedAt(0.30,0.40),"reagents of an inspected recipe pin too")

-- Without the modifier functions nothing can pin.
local altKey=IsAltKeyDown;IsAltKeyDown=nil;waypoint=nil;press(inspect.slots[1].Button,"LeftButton");IsAltKeyDown=altKey
check(waypoint==nil,"a client without IsAltKeyDown never pins")

-- Older windows: named buttons with XML handlers that are never replaced, hooked once each.
local handled={}
HandleModifiedItemClick=function(link) handled[#handled+1]=link end
TradeSkillFrame={selectedSkill=4}
GetTradeSkillReagentItemLink=function(skill,i) return skill==4 and ({"|Hitem:4306|h[Silk Cloth]|h","|Hitem:2320|h[Coarse Thread]|h"})[i] or nil end
for i=1,2 do
    local button=widget()
    button:SetScript("OnClick",function() HandleModifiedItemClick(GetTradeSkillReagentItemLink(TradeSkillFrame.selectedSkill,i)) end)
    button:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self);GameTooltip:SetTradeSkillItem(TradeSkillFrame.selectedSkill,i);GameTooltip:Show() end)
    _G["TradeSkillReagent"..i]=button
end
GetCraftSelectionIndex=function() return 2 end
GetCraftReagentItemLink=function(craft,i) return craft==2 and i==1 and "|Hitem:2320|h[Coarse Thread]|h" or nil end
CraftReagent1=widget()
CraftReagent1:SetScript("OnClick",function() end)
CraftReagent1:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self);GameTooltip:AddLine("craft reagent");GameTooltip:Show() end)
check(T.InstallReagentHooks()==true,"the older reagent buttons are hooked when they appear")
press(TradeSkillReagent1,"LeftButton");check(handled[1]=="|Hitem:4306|h[Silk Cloth]|h" and waypoint==nil,"a plain click runs only the game's handler")
alt=true;waypoint=nil;press(TradeSkillReagent1,"LeftButton");alt=false
check(pinnedAt(0.30,0.40) and #handled==2,"Alt-click on a TradeSkill reagent pins it after the game's handler")
TradeSkillReagent1:Fire("OnEnter");check(#GameTooltip.lines==2 and GameTooltip.lines[1]=="tradeskill 4:1" and GameTooltip.lines[2]=="Alt-click: mark it on your map.","the TradeSkill reagent tooltip gains the line");GameTooltip:Hide()
alt=true;waypoint=nil;press(CraftReagent1,"LeftButton");alt=false;check(pinnedAt(0.55,0.60),"Alt-click on a Craft reagent pins it")
alt=true;waypoint=nil;press(TradeSkillReagent2,"LeftButton");alt=false;check(pinnedAt(0.55,0.60),"each button reads its own reagent index")
check(T.InstallReagentHooks()==false and TradeSkillReagent1:Handlers("OnClick")==2 and TradeSkillReagent1:Handlers("OnEnter")==2,"the older buttons are hooked once")
TradeSkillFrame.selectedSkill=9;alt=true;waypoint=nil;local before=#printed;press(TradeSkillReagent1,"LeftButton");alt=false
check(waypoint==nil and #printed==before,"no reagent link, no pin and no message")
print("PASS: "..checks.." crafting window reagent click, tooltip and handler reset checks")
