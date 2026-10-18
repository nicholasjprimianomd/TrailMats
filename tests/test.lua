-- Lua 5.1 simulation of the actual addon entrypoints, with no game input.
local root=arg[1] or "."
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local timers={}
C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
local function flush()
    local work=timers;timers={};for _,fn in ipairs(work) do fn() end
end
local methods={}
for _,name in ipairs({"SetSize","SetPoint","SetWidth","SetHeight","ClearAllPoints","SetClampedToScreen","SetMovable","EnableMouse","RegisterForDrag","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetJustifyH","SetJustifyV","SetScrollChild","SetOwner","SetAllPoints","SetColorTexture","SetTexture","SetVertexColor","SetOrientation","SetValueStep","SetStatusBarTexture","SetStatusBarColor","LockHighlight","UnlockHighlight",
    "SetFrameStrata","SetFrameLevel","RegisterForClicks","SetHighlightTexture","SetTexCoord","SetObeyStepOnDrag","SetParent"}) do
    methods[name]=function() end
end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function methods:SetScale(s) self.scale=s end
function methods:GetScale() return self.scale or 1 end
function methods:GetEffectiveScale() return 1 end
function methods:GetWidth() return self.width or 140 end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:SetSize(w,h) self.width=w;self.height=h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:SetPoint(...) self.point={...} end
function methods:GetHeight() return self.height or 347 end
function methods:GetStringHeight()
    local n=0
    local plain=(self.text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    for line in plain:gmatch("[^\n]+") do n=n+math.max(1,math.ceil(#line/math.max(1,(self.width or 400)/7))) end
    return n*14
end
function methods:EnableMouseWheel() end
function methods:SetVerticalScroll(value) self.scrollOffset=value end
function methods:GetVerticalScroll() return self.scrollOffset or 0 end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:HookScript(name,fn) self.scripts[name]=fn end
function methods:RegisterEvent(name) self.events[name]=true end
function methods:SetText(text) self.text=text end
function methods:GetText() return self.text end
function methods:Hide() self.shown=false end
function methods:Show() self.shown=true end
function methods:SetShown(show) self.shown=show end
function methods:IsShown() return self.shown end
function methods:GetCenter() return 500,400 end
function methods:GetUnit() return "Moonstalker",self.unit end
function methods:GetItem() return "Item",self.item end
function methods:AddLine(text) self.lines[#self.lines+1]=text end
local function widget() return setmetatable({scripts={},events={},shown=true,lines={}},{__index=methods}) end
function methods:CreateFontString() return widget() end
function methods:CreateTexture() return widget() end
function methods:SetThumbTexture() self.thumb=widget() end
function methods:GetThumbTexture() return self.thumb end
function methods:SetMinMaxValues(low,high) self.min=low;self.max=high end
function methods:SetValue(value)
    self.value=value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end
end
CreateFrame=function() return widget() end
UIParent=widget();WorldFrame=widget();GameTooltip=widget()
GameTooltipTextLeft1=widget()
Minimap=widget();UISpecialFrames={}
local cursorX,cursorY=500,400
GetCursorPosition=function() return cursorX,cursorY end
local shiftDown=false
IsShiftKeyDown=function() return shiftDown end
local optionsPanel,openedOptions=nil,0
InterfaceOptions_AddCategory=function(panel) optionsPanel=panel end
InterfaceOptionsFrame_OpenToCategory=function(panel)
    panel:Show();if panel.scripts.OnShow then panel.scripts.OnShow(panel) end;openedOptions=openedOptions+1
end
local sounds={}
PlaySound=function(id) sounds[#sounds+1]=id end
local messages={}
DEFAULT_CHAT_FRAME={AddMessage=function(_,text) messages[#messages+1]=text end}
SlashCmdList={}
local inventory={[2318]=5,[2589]=3,[6889]=2}
local ranks={[165]=20,[185]=20,[129]=20,[393]=20,[356]=20}
local names={[165]="Leatherworking",[185]="Cooking",[129]="First Aid",[393]="Skinning",[356]="Fishing"}
GetProfessions=function() return 1,nil,3,4,5,6 end -- nil in the second primary slot
local slots={[1]=165,[3]=393,[4]=356,[5]=185,[6]=129}
GetProfessionInfo=function(index) local id=slots[index];return names[id],nil,ranks[id],75,nil,nil,id end
C_Item={GetItemCount=function(id,bank) check(bank==false,"bank excluded");return inventory[id] or 0 end}
local currentMap=1438
C_Map={GetBestMapForUnit=function() return currentMap end,GetMapInfo=function() return {parentMapID=1439} end}
GetRealZoneText=function() return "Test zone" end
local itemNpcs={[6889]={1995},[5465]={1986}}
local npcNames={[1995]="Strigid Owl",[1986]="Webwood Spider",[2069]="Moonstalker",[2002]="Rascal",[2032]="Mangy Nightsaber"}
local npcSpawns={[1995]={[141]={{50,50}}},[1986]={[141]={{40,40}}},[2069]={[148]={{43,40}}},[2002]={[148]={{48,38}}}}
LibQuestieDB={RequireContract=function(v) return v==2 end,
    Item={npcDrops=function(id) return itemNpcs[id] end,objectDrops=function() return {} end},
    Npc={name=function(id) return npcNames[id] end,spawns=function(id) return npcSpawns[id] end}}
QuestieLoader={ImportModule=function(_,name)
    if name=="DropDB" then return {tableWowhead={[2589]={[2002]=20}}} end
    if name=="ZoneDB" then return {GetAreaIdByUiMapId=function(_,map) if map==1440 then return 331 end end} end
end}
local currentGUID="Creature-0-0-0-1-2069-00001"
UnitGUID=function() return currentGUID end
local T={}
for name in io.lines(root.."/TrailMats/TrailMats.toc") do
    if name:match("%.lua$") then assert(loadfile(root.."/TrailMats/"..name))("TrailMats",T) end
end
local function event(name,...)
    check(T.eventFrame.events[name],"registered "..name)
    T.eventFrame.scripts.OnEvent(nil,name,...);flush()
end
MerchantFrame={page=1,selectedTab=1}
MERCHANT_ITEMS_PER_PAGE=10
MerchantItem1ItemButton=widget();MerchantItem2ItemButton=widget()
MerchantFrame_UpdateMerchantInfo=function() end
local hooks={}
hooksecurefunc=function(name,fn) hooks[name]=fn end
local merchant={}
GetMerchantNumItems=function() return #merchant end
GetMerchantItemInfo=function(i) local m=merchant[i];return m.name,nil,m.price,m.pack,m.stock,m.purchasable~=false,true,m.extended,m.currency end
GetMerchantItemLink=function(i) return "|Hitem:"..merchant[i].id.."|h[item]|h" end
GetMerchantItemID=function(i) return merchant[i].id end
BuyMerchantItem=function() error("must never buy") end
DoTradeSkill=function() error("must never craft") end

TrailMatsDB={announce=false} -- a character that turned zone notices off before settings became account-wide
event("ADDON_LOADED","TrailMats");event("PLAYER_LOGIN")
check(T.saved.view=="overview","fresh install starts on Now")
check(not T.tracker:IsShown() and not T.saved.trackProfession,"tracker starts opt-in")
-- Account-wide settings, a minimap button and an options panel, like a standard addon.
check(TrailMatsSettings and T.settings==TrailMatsSettings and T.settings.tooltips==true and T.settings.scale==1,"account-wide settings start from defaults")
check(T.settings.announce==false and T.saved.announce==nil,"old per-character notice setting carries over once");T.settings.announce=true
check(messages[#messages]:find("/tm options",1,true) and T.saved.welcomed,"first login prints a one-time welcome")
check(UISpecialFrames[1]=="TrailMatsWindow","Escape closes the window")
check(BINDING_HEADER_TRAILMATS and BINDING_NAME_TRAILMATS_TOGGLE and BINDING_NAME_TRAILMATS_TRACK,"key binding names registered")
check(T.window.title.text:find(T.version,1,true),"window title shows the version")
local mm=T.minimapButton
check(mm and mm:IsShown() and mm.point[2]==Minimap,"minimap button attached and shown")
local shown=T.window:IsShown()
mm.scripts.OnClick(mm,"LeftButton");check(T.window:IsShown()~=shown,"minimap left-click toggles the window")
mm.scripts.OnClick(mm,"LeftButton");check(T.window:IsShown()==shown,"minimap left-click toggles it back")
mm.scripts.OnClick(mm,"RightButton");check(T.saved.trackProfession==T.SelectedProfession() and T.tracker:IsShown(),"minimap right-click pins the tracker")
mm.scripts.OnClick(mm,"RightButton");check(not T.saved.trackProfession,"minimap right-click unpins it")
GameTooltip.lines={};mm.scripts.OnEnter(mm)
check(table.concat(GameTooltip.lines," "):find("Left-click",1,true) and table.concat(GameTooltip.lines," "):find(T.NextAction(T.SelectedProfession()).text,1,true),"minimap tooltip shows the next step")
cursorX,cursorY=500,480 -- straight above the minimap centre
mm.scripts.OnDragStart(mm);mm.scripts.OnUpdate(mm);mm.scripts.OnDragStop(mm)
check(math.abs(T.settings.minimap.angle-90)<0.01 and math.abs(mm.point[4])<0.01 and math.abs(mm.point[5]-75)<0.01,"dragging saves the angle and keeps the button on the ring")
T.Command("minimap");check(T.settings.minimap.hide and not mm:IsShown(),"/tm minimap hides the button")
T.Command("minimap");check(mm:IsShown(),"/tm minimap shows it again")
check(optionsPanel==T.options and T.options.name=="TrailMats","options panel registered with the interface options")
T.Command("options");check(openedOptions==2 and T.options:IsShown(),"/tm options opens the panel")
shiftDown=true;mm.scripts.OnClick(mm,"LeftButton");shiftDown=false;check(openedOptions==4,"shift-click on the minimap opens settings")
local function control(text) for _,c in ipairs(T.options.controls) do if c.label.text==text then return c end end error("no control "..text) end
local zone=control("Zone notices in chat");check(zone:GetChecked()==true,"checkbox reflects the setting")
zone:SetChecked(false);zone.scripts.OnClick(zone);check(T.settings.announce==false,"checkbox writes the setting")
T.Command("quiet");check(T.settings.announce==true and zone:GetChecked()==true,"/tm quiet still toggles and the panel follows")
local scale=control("Window scale");scale:SetValue(1.2)
check(math.abs(T.window:GetScale()-1.2)<0.001 and math.abs(T.settings.scale-1.2)<0.001 and scale.readout.text=="120%","window scale applies immediately")
local lock=control("Lock the tracker position");lock:SetChecked(true);lock.scripts.OnClick(lock)
T.tracker.scripts.OnDragStart();check(T.settings.lockTracker and not T.tracker.moving,"locked tracker ignores dragging")
T.saved.x=5;T.ResetPositions();check(T.saved.x==nil and T.settings.minimap.angle==220,"Reset positions clears saved offsets")
T.ResetSettings();check(T.settings.scale==1 and T.window:GetScale()==1 and not T.settings.lockTracker and T.settings.minimap.hide==false,"Default settings restores every value")
T.options:Hide()
check(T.plan.future.byItem[2318]~=nil,"held leather has future uses before recipe scan")
check(not T.plan.opportunities[165],"future reference does not grant learned opportunities")
T.window.overview.scripts.OnClick()
check(T.saved.view=="overview","overview button restores live crafting view")
check(T.skills[129] and T.skills[356],"secondary skills survive nil primary slot")
check(T.plan.destination==148 and T.plan.assumed,"Teldrassil defaults explicitly to Darkshore")
check(T.plan.professions[165].state=="ready","crafting 20 can continue in Darkshore")
check(T.plan.professions[129].state=="ready","linen continues in Darkshore")
check(T.plan.professions[185].state=="ready","no Cooking 50 departure requirement")
check(T.plan.professions[356].minimum==1,"Fishing 75 is not an entry requirement")
check(not T.plan.opportunities[165],"no unlearned recipe guesses")
check(T.plan.rows==nil,"no mixed material shopping list")
local before=#messages;event("ZONE_CHANGED");check(#messages==before,"no repeated zone announcement")
-- Loading into Ashenvale: quiet while the zone is unknown, one notice once named, none when Questie's area ID follows.
local liveMap=C_Map;C_Map={};GetRealZoneText=function() return nil end
event("PLAYER_ENTERING_WORLD");check(#messages==before,"no notice before the zone is known")
currentMap=1440;C_Map={GetBestMapForUnit=liveMap.GetBestMapForUnit};GetRealZoneText=function() return "Ashenvale" end
local zoneDB=T.zoneDB;T.zoneDB=nil;event("ZONE_CHANGED_NEW_AREA")
check(#messages==before+1 and messages[#messages]:find("Ashenvale | /tm",1,true),"one notice once the zone is named")
C_Map=liveMap;T.zoneDB=zoneDB;event("ZONE_CHANGED")
check(T.area==331 and #messages==before+1,"area ID arriving later is not a second notice")
currentMap=1438;GetRealZoneText=function() return "Test zone" end;event("ZONE_CHANGED_NEW_AREA")
for _,id in ipairs(T.tabOrder) do check(T.window.tabs[id]:IsShown()==(T.skills[id]~=nil),"possessed professions have tabs, others do not") end
T.window.tabs[129].scripts.OnClick();check(T.saved.profession==129,"tab changes selection")
local function screen()
 local lines={}
 for _,r in ipairs(T.window.rows) do if r:IsShown() then
    lines[#lines+1]=r.label.text
    if r.value and r.value:IsShown() then lines[#lines+1]=r.value.text end
 end end
 return table.concat(lines,"\n")
end
check(not screen():find("Chunk of Boar Meat",1,true),"First Aid tab does not show cooking shopping list")
T.skills[356]=nil;T.Render();check(not T.window.tabs[356]:IsShown(),"unpossessed profession hidden")
T.ReadSkills()
-- Learned recipe must be fresh and skill-up capable.
GetTradeSkillLine=function() return "Leatherworking",ranks[165],75 end
GetNumTradeSkills=function() return 1 end
GetTradeSkillInfo=function() return "Light Armor Kit","optimal" end
GetTradeSkillRecipeLink=function() return "|Henchant:2152|h[Light Armor Kit]|h" end
GetTradeSkillNumReagents=function() return 2 end
GetTradeSkillReagentInfo=function(_,j) return j==1 and "Light Leather" or "Coarse Thread",nil,j==1 and 2 or 1 end
GetTradeSkillReagentItemLink=function(_,j) return "|Hitem:"..(j==1 and 2318 or 2320).."|h[Reagent]|h" end
T.SelectProfession(129);event("TRADE_SKILL_SHOW");check(T.saved.profession==165,"opening a crafting window selects its tab")
T.settings.follow=false;T.SelectProfession(129);event("TRADE_SKILL_SHOW");check(T.saved.profession==129,"tab following can be turned off");T.settings.follow=true
T.SelectProfession(165);event("TRADE_SKILL_SHOW")
local op=T.CurrentOpportunity()
check(op and op.batch==12 and op.stop==30,"automatic estimate reaches recipe switch at 30")
check(op.materials[1].need==24 and op.materials[1].missing==19,"live ingredients times automatic estimate minus bags")
check(op.materials[2].missing==12,"vendor supply tied to exact recipe")
check(screen():find("Get supplies for Light Armor Kit",1,true) and screen():find("Buy 12 more",1,true),"short action uses raw materials already held and shows missing supplies")
check(not screen():find("~",1,true) and not screen():find("[\128-\255]"),"no tilde or unsupported glyphs")
IsTradeSkillLinked=function() return true end
GetTradeSkillReagentInfo=function() return "wrong",nil,999 end
event("TRADE_SKILL_UPDATE");check(T.saved.recipes[2152].mats[2318]==2,"linked recipes ignored")
IsTradeSkillLinked=nil
GetTradeSkillReagentInfo=function(_,j) return j==1 and "Light Leather" or "Coarse Thread",nil,j==1 and 2 or 1 end
ranks[165]=21;T.Refresh(false,false)
check(not T.CurrentOpportunity(),"stale difficulty is never used after skill changes")
ranks[165]=20;T.Refresh(false,false)
T.saved.recipes[2152].difficulty="trivial";T.Refresh(false,false)
check(not T.CurrentOpportunity(),"grey recipes are not suggested")
T.saved.recipes[2152].difficulty="optimal";T.Refresh(false,false)
-- Actual merchant stock uses Forever's nine-return API, not the old seven-return form.
merchant={{id=2320,name="Coarse Thread",price=20,pack=5,stock=-1},{id=2318,name="Light Leather",price=1,pack=1,stock=-1}}
event("MERCHANT_SHOW")
local offers=T.CurrentMerchantSuggestions()
check(#offers==1,"basic supplies only; no farmed material purchases")
check(offers[1].amount==15 and offers[1].cost==60,"pack rounding and total copper cost")
check(offers[1].missing==12 and offers[1].batch==12,"merchant reason explains quantity")
check(T.merchantMarks[1]:IsShown(),"relevant merchant button is marked")
check(T.MerchantText(offers[1]):find("pack size",1,true),"extra pack units explained")
merchant[3]={id=2320,name="Coarse Thread bulk",price=100,pack=100,stock=-1}
event("MERCHANT_UPDATE")
check(T.CurrentMerchantSuggestions()[1].index==1,"prefer lower total cost over misleading cheap bulk unit price")
merchant[3]=nil
merchant[1].extended=true;event("MERCHANT_UPDATE");check(#T.CurrentMerchantSuggestions()==0,"alternate currency excluded")
merchant[1].extended=false;merchant[1].purchasable=false;event("MERCHANT_UPDATE");check(#T.CurrentMerchantSuggestions()==0,"unavailable purchase excluded")
merchant[1].purchasable=true;merchant[1].stock=5;event("MERCHANT_UPDATE");offers=T.CurrentMerchantSuggestions()
check(offers[1].amount==5 and offers[1].remaining==7,"limited stock respected")
merchant[1].stock=-1
inventory[2320]=12;event("BAG_UPDATE_DELAYED")
check(#T.CurrentMerchantSuggestions()==0,"owned supplies remove recommendation")
check(not T.merchantMarks[1]:IsShown(),"stale merchant mark cleared")
inventory[2320]=0;event("BAG_UPDATE_DELAYED")
MerchantFrame.page=2;hooks.MerchantFrame_UpdateMerchantInfo()
check(not T.merchantMarks[1]:IsShown(),"marks do not leak across merchant pages")
MerchantFrame.page=1;MerchantFrame.selectedTab=2;hooks.MerchantFrame_UpdateMerchantInfo()
check(not T.merchantMarks[1]:IsShown(),"buyback is never marked")
MerchantFrame.selectedTab=1
T.window.tabs[129].scripts.OnClick();check(#T.CurrentMerchantSuggestions()==0,"merchant hints follow selected profession")
T.SelectProfession(165);event("MERCHANT_CLOSED")
check(#T.CurrentMerchantSuggestions()==0 and not T.merchantMarks[1]:IsShown(),"merchant close clears stock and marks")
-- Unsupported recipes do not get invented targets; old manual choices are ignored.
T.saved.recipes[999]={profession=165,name="Test alternative",learned=true,rank=20,difficulty="medium",mats={[2318]=1}}
T.saved.selected[165]=999;T.saved.batch=5;T.Refresh(false,false)
check(T.CurrentOpportunity().id==2152 and T.CurrentOpportunity().batch==12,"automatic selection ignores retired settings")
check(T.window.batch==nil and T.CycleBatch==nil,"batch control removed")
check(T.CycleRecipe==nil,"manual recipe cycle removed")
currentMap=1440;inventory[2318]=0;event("ZONE_CHANGED_NEW_AREA")
check(T.area==331,"non-seed map resolves via Questie")
check(not T.CurrentOpportunity(),"no suggestion when missing raw ingredients have no local reference")
check(T.plan.destination==0,"unknown onward route is not guessed")
T.saved.destinations[331]=148;T.Refresh(false,false);check(T.plan.destination==148 and not T.plan.assumed,"manual destination saved by current zone")
currentMap=1439;event("ZONE_CHANGED_NEW_AREA")
check(T.plan.destination==331,"Darkshore assumption is Ashenvale")
check(T.plan.professions[356].minimum==55 and T.plan.professions[356].state=="not_yet","actual fishing breakpoint controls status")
check(T.plan.professions[165].state=="unknown","unreviewed crafting route not called ready")
ranks[356]=55;event("SKILL_LINES_CHANGED");check(T.plan.professions[356].state=="ready","fishing threshold met")
T.ChangeDestination();check(T.plan.destination==406,"destination selector changes route")
-- NPC tooltips are scoped to one profession and report materials, not fake kills.
currentMap=1439;inventory[2318]=0;T.saved.selected[165]=2152;T.Refresh(false,false);T.SelectProfession(165)
GameTooltip.lines={};GameTooltip.trailMatsNPC=nil;T.AddNPCTooltip(GameTooltip,"mouseover")
check(table.concat(GameTooltip.lines," "):find("collect 24 Light Leather",1,true),"NPC shows remaining material for selected recipe")
check(table.concat(GameTooltip.lines," "):find("Kills vary",1,true),"no invented drop-rate kill estimate")
local n=#GameTooltip.lines;T.AddNPCTooltip(GameTooltip,"mouseover");check(#GameTooltip.lines==n,"duplicate tooltip guard")
T.SelectProfession(393);GameTooltip.lines={};T.AddNPCTooltip(GameTooltip,"mouseover")
check(table.concat(GameTooltip.lines," "):find("corpse's actual Skinning",1,true),"Skinning tab has cautious creature hints")
T.SelectProfession(129);GameTooltip.lines={};T.AddNPCTooltip(GameTooltip,"mouseover")
check(#GameTooltip.lines==0,"other profession materials not injected")
-- Herb and vein tooltips name the gathering skill they need; nothing is added for other objects or without the skill.
local unitOf=GameTooltip.GetUnit;GameTooltip.GetUnit=function() end;GameTooltip.GetItem=function() end
T.skills[182]={name="Herbalism",rank=50,cap=75};GameTooltipTextLeft1.text="Briarthorn";GameTooltip.lines={};GameTooltip.trailMatsNode=nil
T.AddNodeTooltip(GameTooltip);check(GameTooltip.lines[1]=="TrailMats: Herbalism 70 needed; you have 50.","herb node tooltip compares the requirement with your skill")
GameTooltipTextLeft1.text="Ooze Covered Silver Vein";GameTooltip.lines={};T.AddNodeTooltip(GameTooltip)
check(GameTooltip.lines[1]=="TrailMats: needs Mining 75.","vein tooltip still names the skill when you lack the profession")
GameTooltipTextLeft1.text="Mailbox";GameTooltip.lines={};T.AddNodeTooltip(GameTooltip);check(#GameTooltip.lines==0,"other objects get no node line")
GameTooltipTextLeft1.text="Briarthorn";GameTooltip.lines={};T.AddNodeTooltip(GameTooltip);T.AddNodeTooltip(GameTooltip);check(#GameTooltip.lines==1,"node line is not duplicated")
T.skills[182]=nil;GameTooltip.GetUnit=unitOf;GameTooltip.GetItem=nil;GameTooltipTextLeft1.text=nil
T.SelectProfession(165);inventory[2318]=99;event("BAG_UPDATE_DELAYED")
check(T.CurrentOpportunity().materials[1].missing==0,"no negative remaining count")
T.ScrollBy(100000);check(T.window.scroll:GetVerticalScroll()==math.max(0,T.window.content:GetHeight()-T.window.scroll:GetHeight()),"scroll bounded below")
T.ScrollBy(-100000);check(T.window.scroll:GetVerticalScroll()==0,"scroll bounded above")
T.window.close.scripts.OnClick();check(T.saved.hidden and not T.window:IsShown(),"Close preserves preference")
T.Command("");check(T.window:IsShown(),"slash command reopens")
local n=#messages;T.Command("bogus");check(#messages==n+1 and messages[#messages]:find("Unknown command",1,true) and T.window:IsShown(),"unknown command explains instead of toggling")
-- Missing database and old settings remain safe.
LibQuestieDB=nil;QuestieLoader=nil;T.qdb=nil;T.dropDB=nil;T.zoneDB=nil
T.ConnectDatabase();T.Refresh(false,false);check(T.plan~=nil,"missing database degrades safely")
-- Skill-ups past the recipe target and reaching the cap each get one notice per login.
ranks[165]=30;T.Refresh(false,false)
check(messages[#messages]:find("Leatherworking 30: Light Armor Kit target reached",1,true),"passing the recipe target says to switch")
ranks[165]=75;T.Refresh(false,false);check(not T.plan.opportunities[165],"trained cap blocks further crafting suggestions")
check(messages[#messages]:find("Leatherworking 75/75: visit a trainer",1,true),"capped profession gets a training reminder")
n=#messages;T.Refresh(false,false);check(#messages==n,"switch and training notices are not repeated")
T.settings.trainReminder=false;ranks[165]=150;T.Refresh(false,false);check(#messages==n,"training reminders can be turned off");T.settings.trainReminder=true
-- Forecasts remain separate from learned recipes and merchant purchases.
ranks[165]=20;ranks[185]=20;ranks[129]=20
inventory[6308]=2;inventory[783]=1;T.saved.recipes={};T.Refresh(false,false)
local future=T.plan.future
check(future.byItem[6308][1].recipe.name=="Bristle Whisker Catfish","unlearned fish recipe has a future use")
check(not future.byItem[6308][1].recipe.learned,"reference recipe is not marked learned")
check(future.byItem[6308][1].recipe.trainRank,"future recipe beyond trained cap prompts training")
check(future.byItem[6308][1].material.need==55,"future reserve covers catfish through 150")
check(future.byItem[6308][1].material.have==2,"future reserve reads current bags")
check(not future.byItem[4289],"vendor salt is not a raw material reserve")
check(not T.plan.opportunities[185],"future fish recipe cannot become a live crafting suggestion")
T.SelectProfession(129);GameTooltip.lines={};GameTooltip.trailMatsItem=nil;GameTooltip.item="|Hitem:6308|h[Fish]|h"
T.AddItemTooltip(GameTooltip)
check(table.concat(GameTooltip.lines," "):find("Bristle Whisker Catfish",1,true),"future item hints cover owned professions across tabs")
local lineCount=#GameTooltip.lines;T.AddItemTooltip(GameTooltip)
check(#GameTooltip.lines==lineCount,"future item hints are not duplicated")
T.Command("keep");check(T.saved.view=="keep" and T.window:IsShown(),"keep command opens future view")
T.saved.batch=1;T.Refresh(false,false);check(T.plan.future.byItem[6308][1].material.need==55,"old batch cannot alter reserves")
T.saved.recipes[9999]={profession=185,name="Bristle Whisker Catfish",learned=true,rank=20,difficulty="trivial",mats={[6308]=1}}
T.Refresh(false,false);check(not T.plan.future.byItem[6308],"fresh grey learned recipe overrides future reference")
T.saved.recipes[9999].difficulty="optimal";T.saved.recipes[9999].mats[6308]=2
T.Refresh(false,false);check(T.plan.future.byItem[6308][1].material.need==110,"recorded recipe quantities override reference")
-- Milestone view and price editor operate through the actual addon entrypoints.
T.saved.recipes={};ranks[129]=20;T.Refresh(false,false);T.SelectProfession(129)
T.window.leveling.scripts.OnClick()
check(T.saved.view=="leveling" and screen():find("20 to 75",1,true),"milestone tab shows the actual next goal")
check(screen():find("Still needed",1,true) and not screen():find("Craft in order",1,true),"material view separates recipes from shopping list")
local function clickRow(text)
    for _,r in ipairs(T.window.rows) do
        if r:IsShown() and r.action and r.action:IsShown() and r.action.text==text then r.action.scripts.OnClick();return end
    end
    error("No visible row button: "..text)
end
clickRow("Recipes")
check(screen():find("Craft in order",1,true) and screen():find("Check recipe",1,true),"recipe page preserves order and availability")
clickRow("Materials")
check(T.window.batch==nil and T.window.prices:IsShown(),"milestone quantities do not inherit optional batch size")
T.ScrollBy(100000);check(T.window.scroll:GetVerticalScroll()==math.max(0,T.window.content:GetHeight()-T.window.scroll:GetHeight()),"long milestone list stays inside scroll bounds")
T.window.prices.scripts.OnClick()
check(screen():find("Peacebloom",1,true) and screen():find("Empty Vial",1,true),"price list includes alternatives, not just selected recipe")
local popup
StaticPopupDialogs={}
StaticPopup_Show=function(name,text,_,data)
    local dialog=widget();dialog.data=data;dialog.EditBox=widget()
    dialog.EditBox.SetFocus=function() end;dialog.EditBox.HighlightText=function() end
    dialog.EditBox.GetParent=function() return dialog end
    popup={dialog=dialog,definition=StaticPopupDialogs[name]}
    popup.definition.OnShow(dialog)
end
T.EditLevelingPrice(2589);popup.dialog.EditBox:SetText("12")
popup.definition.OnAccept(popup.dialog)
check(T.saved.levelingPrices[2589].copper==12,"price popup saves per-item copper")
popup.dialog.EditBox:SetText("invalid");popup.definition.OnAccept(popup.dialog)
check(T.saved.levelingPrices[2589].copper==12,"invalid popup entry preserves old quote")
popup.dialog.EditBox:SetText("");popup.definition.EditBoxOnEnterPressed(popup.dialog.EditBox)
check(T.saved.levelingPrices[2589]==nil and not popup.dialog:IsShown(),"blank enter clears quote and closes popup")
T.window.prices.scripts.OnClick();check(T.window.planPage=="materials","prices button returns to materials")
T.window.keep.scripts.OnClick();check(T.saved.view=="keep" and not T.window.prices:IsShown(),"old keep view still works")
T.Command("mats");check(T.saved.view=="leveling","mats shortcut selects milestone view")
T.SelectProfession(356);check(screen():find("Fish while you quest",1,true) and screen():find("Materials: Cooking",1,true),"gathering tab links the paired profession")
T.SelectProfession(165)
GetTradeSkillItemLink=function() return "|Hitem:2304|h[Light Armor Kit]|h" end
GetTradeSkillNumMade=function() return 2,2 end
event("TRADE_SKILL_SHOW")
check(T.saved.recipes[2152].outputItem==2304 and T.saved.recipes[2152].outputCount==2,"scan captures actual output yield")
-- Compact screens, local targets and an independently pinned tracker.
T.qdb={Item={npcDrops=function(id) return itemNpcs[id] end},
    Npc={name=function(id) return npcNames[id] end,spawns=function(id) return npcSpawns[id] end}}
T.sourceCache={};T.saved.observed={};T.saved.batch=3
T.saved.recipes={[2152]={id=2152,profession=165,name="Light Armor Kit",learned=true,rank=20,difficulty="optimal",mats={[2318]=2,[2320]=1}}}
T.saved.scanned[165]=true
ranks[165]=20;inventory[2318]=0;inventory[2320]=0;currentMap=1439
T.Refresh(false,false);T.SelectProfession(165);T.Command("now")
check(T.NextAction(165).text=="Gather for Light Armor Kit","missing first craft calls for raw materials")
local needs=T.ZoneNeeds(165)
local leather
for _,m in ipairs(needs.here) do if m.item==2318 then leather=m end;check(not T.levelingSupplies[m.item],"local list excludes vendor supplies") end
check(leather and leather.missing>3 and needs.target==30,"tracker and Now share the automatic recipe target")
check(#needs.vendor>0,"vendor needs stay separate")
check(#T.ZoneNeeds(393).here==#needs.here,"Skinning follows Leatherworking material goals")
check(not screen():find("This zone (est.)",1,true),"Now avoids a duplicate material list")
local source,detail=T.ZoneSource(2318)
check(source:find("Moonstalker",1,true) and detail:find("Database sources",1,true),"reference source does not require personal loot")
local databaseSource=source
T.saved.observed[2318]={[2069]={area=148}};T.sourceCache[2318]=nil
source,detail=T.ZoneSource(2318)
check(source==databaseSource and not detail:find("You have looted",1,true) and not detail:find("43, 40",1,true),"personal loot cannot change source recommendations")
npcSpawns[2069][331]={{20,20}};T.sourceCache[2318]=nil
check(T.ZoneSource(2318,331):find("Moonstalker",1,true),"database spawns work in zones without observations")
npcSpawns[2069][331]=nil;T.sourceCache[2318]=nil
T.window.track.scripts.OnClick()
check(T.tracker:IsShown() and T.saved.trackProfession==165,"Track pins selected profession")
check(T.tracker.lines[1].text~="" and T.tracker.zone.text:find("est.",1,true),"tracker shows estimated local count")
T.SelectProfession(129)
check(T.saved.trackProfession==165 and T.tracker.title.text:find("Leatherworking",1,true),"tab change cannot silently repin tracker")
T.window.close.scripts.OnClick()
inventory[2318]=5;inventory[2320]=12;event("BAG_UPDATE_DELAYED")
check(not T.window:IsShown() and T.tracker.action.text=="Craft 2 x Light Armor Kit","bag change updates ready crafts while window closed")
check(T.NextAction(165).text=="Craft 2 x Light Armor Kit","ready count is limited by actual materials")
T.settings.sound=true
inventory[2318]=1000;event("BAG_UPDATE_DELAYED")
check(T.NextAction(165).text=="Craft 12 x Light Armor Kit","ready action stops at automatic target")
check(messages[#messages]:find("Light Armor Kit is ready to craft 12 times (to skill 30)",1,true) and #sounds==1,"bags covering the whole target announce it, with the optional sound")
n=#messages;event("BAG_UPDATE_DELAYED");check(#messages==n and #sounds==1,"ready notice is not repeated")
T.settings.sound=false
for _,m in ipairs(T.ZoneNeeds(165).here) do check(m.item~=2318,"covered material leaves the zone checklist") end
inventory[2318]=0;event("BAG_UPDATE_DELAYED")
T.settings.craftNotices=false;n=#messages;inventory[2318]=1000;event("BAG_UPDATE_DELAYED")
check(#messages==n,"crafting notices can be turned off");T.settings.craftNotices=true
inventory[2318]=0;event("BAG_UPDATE_DELAYED")
C_Map.GetMapInfo=function() return {parentMapID=0} end
currentMap=9999;event("ZONE_CHANGED_NEW_AREA")
check(T.area==0 and #T.ZoneNeeds(165).here==0 and T.tracker.lines[1].text=="","unknown zone clears old local objectives")
currentMap=1439;event("ZONE_CHANGED_NEW_AREA")
check(T.tracker.lines[1].text~="","returning to supported zone restores goals")
T.tracker.open.scripts.OnClick()
check(T.window:IsShown() and T.saved.profession==165 and T.saved.view=="overview","tracker Open selects pinned profession and Now")
ranks[165]=21;T.Refresh(false,false)
check(T.tracker.action.text=="Open Leatherworking to refresh","stale recipes never produce a craft action")
ranks[165]=75;T.Refresh(false,false)
check(T.tracker.action.text=="Train Leatherworking","skill cap gives a training action")
ranks[165]=20;T.Refresh(false,false)
T.tracker.scripts.OnDragStop();check(T.saved.trackX==0 and T.saved.trackY==0,"tracker position persists")
T.tracker.close.scripts.OnClick();check(not T.saved.trackProfession and not T.tracker:IsShown(),"Hide unpins tracker")
T.Command("track");check(T.tracker:IsShown(),"tracker shortcut works")
T.skills[165]=nil;T.RenderTracker();check(not T.tracker:IsShown(),"losing tracked profession hides obsolete tracker")
T.ReadSkills();T.Command("track")

-- Every profession fits in one tab row; detailed explanations stay on hover.
local y=T.window.tabs[165].point[3]
for _,id in ipairs(T.tabOrder) do
    if T.skills[id] then check(T.window.tabs[id].point[3]==y,"profession tabs use a single row")
    else check(not T.window.tabs[id]:IsShown(),"unlearned professions have no tab") end
end
local function wordCount(text) local n=0;for _ in text:gmatch("%S+") do n=n+1 end;return n end
check(wordCount(screen())<130,"Now avoids paragraphs in the main view")
T.window.keep.scripts.OnClick();check(wordCount(screen())<180,"Keep shows concise rows")
T.Command("mats");T.window.planPage="materials";T.Render()
check(not screen():find("Bags allocated",1,true) and not screen():find("guarantee",1,true),"material accounting explanations stay in tooltips")
inventory[2318]=1000;T.Refresh(false,false)
check(not screen():find("Light Leather",1,true),"covered material hidden in missing-only view")
clickRow("Show all")
check(screen():find("Light Leather",1,true) and screen():find("Ready",1,true),"Show all restores covered route ingredients")
clickRow("Missing only");clickRow("Recipes")
local hasAcquisition=false
for _,r in ipairs(T.window.rows) do
    if r:IsShown() and type(r.detail)=="string" and r.detail:find("Obtain the recipe",1,true) then hasAcquisition=true end
end
check(hasAcquisition,"recipe acquisition is preserved in hover details")
clickRow("Materials")
-- Actual rendered item tooltips must stay focused on decisions.
for _,view in ipairs({"overview","leveling","keep"}) do
    T.saved.view=view;T.window.planPage="materials";T.Render()
    for _,r in ipairs(T.window.rows) do
        if r:IsShown() then
            local text=type(r.detail)=="function" and r.detail() or r.detail or ""
            for _,phrase in ipairs({"used:","Made along the way", "Total needed:", "Price needed", "Near "}) do
                check(not text:find(phrase,1,true),"rendered tooltip hides "..phrase)
            end
        end
    end
end
check(T.window.destination==nil,"next-zone control removed from farming flow")
check(T.window.overview.text=="Next step","main view names its purpose")
local chatBefore=#messages;T.Command("help")
check(T.saved.view=="help" and #messages==chatBefore and screen():find("Using TrailMats",1,true),"Help is a page, not chat spam")
T.saved.view="keep";event("ADDON_LOADED","TrailMats")
check(T.saved.view=="keep","existing view choice survives upgrade")
-- Screenshot regression: an empty bag must still produce a useful local list.
GetProfessionInfo=function(index) local id=slots[index];return names[id],nil,ranks[id],150,nil,nil,id end
ranks[129]=72;inventory[2589]=0;T.saved.recipes={};T.saved.observed={};currentMap=1439
T.qdb={Item={npcDrops=function(id) return id==2589 and {2002} or {} end},
    Npc={name=function(id) return npcNames[id] end,spawns=function(id) return npcSpawns[id] end}}
T.sourceCache={}
T.Refresh(false,false);T.SelectProfession(129);T.Command("keep")
check(T.window.keep.text=="Materials","existing Keep view becomes Materials")
check(screen():find("Heavy Linen Bandage",1,true) and screen():find("to skill 80",1,true),"empty bags show efficient recipe and target")
check(screen():find("Linen Cloth",1,true) and screen():find("Collect 32 more",1,true) and screen():find("Rascal",1,true),"empty bags show missing amount and database source")
-- The value column is an action in the row's colour over a have/need bar, not two stacked lines.
local function valueRow(name)
    for _,r in ipairs(T.window.rows) do if r:IsShown() and r.label.text:find(name,1,true) and r.value and r.value:IsShown() then return r end end
    error("no value row: "..name)
end
local linen=valueRow("Linen Cloth")
check(linen.bar:IsShown() and linen.bar.text.text=="0 / 32" and linen.bar.max==32 and linen.bar.value==0,"material rows carry a have/need bar")
check(linen.accent:IsShown() and linen.value.text:find("|cff",1,true) and not linen.value.text:find("Have",1,true),"action line is coloured and no longer repeats the count")
check(T.window.rows[1].heading and not T.window.rows[1].accent:IsShown(),"headings carry no accent strip")
inventory[2589]=10;event("BAG_UPDATE_DELAYED")
check(screen():find("Collect 22 more",1,true),"Materials updates remaining quantity after looting")
check(valueRow("Linen Cloth").bar.text.text=="10 / 32" and valueRow("Linen Cloth").bar.value==10,"the bar follows your bags")
currentMap=9999;event("ZONE_CHANGED_NEW_AREA")
check(screen():find("No listed source",1,true) and not screen():find("Rascal",1,true),"zone without source clears old targets and explains absence")
T.qdb=nil;T.dropDB=nil;T.sourceCache={};T.Render()
check(screen():find("Source database unavailable",1,true),"missing provider is not presented as proof of no source")
print("PASS: "..checks.." assertions covering UI navigation, tracker updates, source evidence, recipes, bags, vendor stock and tooltips")
