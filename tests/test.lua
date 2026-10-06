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
for _,name in ipairs({"SetSize","SetPoint","SetWidth","SetHeight","ClearAllPoints","SetClampedToScreen","SetMovable","EnableMouse","RegisterForDrag","StartMoving","StopMovingOrSizing","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetJustifyH","SetJustifyV","SetScrollChild","SetOwner","SetAllPoints","SetColorTexture","SetTexture","SetVertexColor","SetOrientation","SetValueStep","SetStatusBarTexture","SetStatusBarColor","LockHighlight","UnlockHighlight"}) do
    methods[name]=function() end
end
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
local npcNames={[1995]="Strigid Owl",[1986]="Webwood Spider",[2069]="Moonstalker",[2002]="Rascal"}
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

event("ADDON_LOADED","TrailMats");event("PLAYER_LOGIN")
check(T.saved.view=="overview","fresh install starts on Now")
check(not T.tracker:IsShown() and not T.saved.trackProfession,"tracker starts opt-in")
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
for _,id in ipairs(T.tabOrder) do check(T.window.tabs[id]:IsShown(),"possessed profession has tab") end
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
T.SelectProfession(165);event("TRADE_SKILL_SHOW")
local op=T.CurrentOpportunity()
check(op and op.batch==3,"fresh learned recipe offers optional three crafts")
check(op.materials[1].need==6 and op.materials[1].missing==1,"live ingredients times batch minus bags")
check(op.materials[2].missing==3,"vendor supply tied to exact recipe")
check(screen():find("Get supplies for Light Armor Kit",1,true) and screen():find("Need 3",1,true),"short action uses raw materials already held and shows missing supplies")
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
merchant={{id=2320,name="Coarse Thread",price=20,pack=2,stock=-1},{id=2318,name="Light Leather",price=1,pack=1,stock=-1}}
event("MERCHANT_SHOW")
local offers=T.CurrentMerchantSuggestions()
check(#offers==1,"basic supplies only; no farmed material purchases")
check(offers[1].amount==4 and offers[1].cost==40,"pack rounding and total copper cost")
check(offers[1].missing==3 and offers[1].batch==3,"merchant reason explains quantity")
check(T.merchantMarks[1]:IsShown(),"relevant merchant button is marked")
check(T.MerchantText(offers[1]):find("pack size",1,true),"extra pack units explained")
merchant[3]={id=2320,name="Coarse Thread bulk",price=100,pack=100,stock=-1}
event("MERCHANT_UPDATE")
check(T.CurrentMerchantSuggestions()[1].index==1,"prefer lower total cost over misleading cheap bulk unit price")
merchant[3]=nil
merchant[1].extended=true;event("MERCHANT_UPDATE");check(#T.CurrentMerchantSuggestions()==0,"alternate currency excluded")
merchant[1].extended=false;merchant[1].purchasable=false;event("MERCHANT_UPDATE");check(#T.CurrentMerchantSuggestions()==0,"unavailable purchase excluded")
merchant[1].purchasable=true;merchant[1].stock=2;event("MERCHANT_UPDATE");offers=T.CurrentMerchantSuggestions()
check(offers[1].amount==2 and offers[1].remaining==1,"limited stock respected")
merchant[1].stock=-1
inventory[2320]=3;event("BAG_UPDATE_DELAYED")
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
-- Recipe alternatives, optional batch sizes, and zone source limits.
T.saved.recipes[999]={profession=165,name="Test alternative",learned=true,rank=20,difficulty="medium",mats={[2318]=1}}
T.Refresh(false,false);local original=T.CurrentOpportunity().id
T.CycleRecipe(165);check(T.CurrentOpportunity().id~=original,"alternative button changes only suggestion")
T.CycleBatch();check(T.CurrentOpportunity().batch==5,"batch is user controlled")
T.CycleBatch();check(T.CurrentOpportunity().batch==1,"single-craft option")
T.CycleBatch();check(T.CurrentOpportunity().batch==3,"batch cycle restored")
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
check(table.concat(GameTooltip.lines," "):find("collect 6 Light Leather",1,true),"NPC shows remaining material for selected recipe")
check(table.concat(GameTooltip.lines," "):find("Kills vary",1,true),"no invented drop-rate kill estimate")
local n=#GameTooltip.lines;T.AddNPCTooltip(GameTooltip,"mouseover");check(#GameTooltip.lines==n,"duplicate tooltip guard")
T.SelectProfession(393);GameTooltip.lines={};T.AddNPCTooltip(GameTooltip,"mouseover")
check(table.concat(GameTooltip.lines," "):find("corpse's actual Skinning",1,true),"Skinning tab has cautious creature hints")
T.SelectProfession(129);GameTooltip.lines={};T.AddNPCTooltip(GameTooltip,"mouseover")
check(#GameTooltip.lines==0,"other profession materials not injected")
T.SelectProfession(165);inventory[2318]=99;event("BAG_UPDATE_DELAYED")
check(T.CurrentOpportunity().materials[1].missing==0,"no negative remaining count")
T.ScrollBy(100000);check(T.window.scroll:GetVerticalScroll()==math.max(0,T.window.content:GetHeight()-T.window.scroll:GetHeight()),"scroll bounded below")
T.ScrollBy(-100000);check(T.window.scroll:GetVerticalScroll()==0,"scroll bounded above")
T.window.close.scripts.OnClick();check(T.saved.hidden and not T.window:IsShown(),"Close preserves preference")
T.Command("");check(T.window:IsShown(),"slash command reopens")
-- Missing database and old settings remain safe.
LibQuestieDB=nil;QuestieLoader=nil;T.qdb=nil;T.dropDB=nil;T.zoneDB=nil
T.ConnectDatabase();T.Refresh(false,false);check(T.plan~=nil,"missing database degrades safely")
ranks[165]=75;T.Refresh(false,false);check(not T.plan.opportunities[165],"trained cap blocks further crafting suggestions")
-- Forecasts remain separate from learned recipes and merchant purchases.
ranks[165]=20;ranks[185]=20;ranks[129]=20
inventory[6308]=2;inventory[783]=1;T.saved.recipes={};T.Refresh(false,false)
local future=T.plan.future
check(future.byItem[6308][1].recipe.name=="Bristle Whisker Catfish","unlearned fish recipe has a future use")
check(not future.byItem[6308][1].recipe.learned,"reference recipe is not marked learned")
check(future.byItem[6308][1].recipe.trainRank,"future recipe beyond trained cap prompts training")
check(future.byItem[6308][1].material.need==3,"future reserve respects selected batch")
check(future.byItem[6308][1].material.have==2,"future reserve reads current bags")
check(not future.byItem[4289],"vendor salt is not a raw material reserve")
check(not T.plan.opportunities[185],"future fish recipe cannot become a live crafting suggestion")
T.SelectProfession(129);GameTooltip.lines={};GameTooltip.trailMatsItem=nil;GameTooltip.item="|Hitem:6308|h[Fish]|h"
T.AddItemTooltip(GameTooltip)
check(table.concat(GameTooltip.lines," "):find("Bristle Whisker Catfish",1,true),"future item hints cover owned professions across tabs")
local lineCount=#GameTooltip.lines;T.AddItemTooltip(GameTooltip)
check(#GameTooltip.lines==lineCount,"future item hints are not duplicated")
T.Command("keep");check(T.saved.view=="keep" and T.window:IsShown(),"keep command opens future view")
T.CycleBatch();check(T.plan.future.byItem[6308][1].material.need==5,"batch changes update future reserves")
T.saved.recipes[9999]={profession=185,name="Bristle Whisker Catfish",learned=true,rank=20,difficulty="trivial",mats={[6308]=1}}
T.Refresh(false,false);check(not T.plan.future.byItem[6308],"fresh grey learned recipe overrides future reference")
T.saved.recipes[9999].difficulty="optimal";T.saved.recipes[9999].mats[6308]=2
T.Refresh(false,false);check(T.plan.future.byItem[6308][1].material.need==10,"recorded recipe quantities override reference")
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
check(not T.window.batch:IsShown() and T.window.prices:IsShown(),"milestone quantities do not inherit optional batch size")
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
check(leather and leather.missing>3 and needs.target==75,"local list uses full milestone needs, not batch")
check(#needs.vendor>0,"vendor needs stay separate")
check(#T.ZoneNeeds(393).here==#needs.here,"Skinning follows Leatherworking material goals")
check(screen():find("This zone (est.)",1,true),"forecast remains visibly estimated")
local source,detail=T.ZoneSource(2318)
check(source:find("*",1,true) and detail:find("candidate",1,true),"reference source remains marked")
T.saved.observed[2318]={[2069]={area=148}};T.sourceCache[2318]=nil
source,detail=T.ZoneSource(2318)
check(source=="Moonstalker" and detail:find("Near 43, 40",1,true),"observed local source preferred; coordinates move to hover")
npcSpawns[2069][331]={{20,20}};T.sourceCache[2318]=nil
check(T.ZoneSource(2318,331):find("*",1,true),"an observation does not verify another zone")
npcSpawns[2069][331]=nil;T.sourceCache[2318]=nil
T.window.track.scripts.OnClick()
check(T.tracker:IsShown() and T.saved.trackProfession==165,"Track pins selected profession")
check(T.tracker.lines[1].text~="" and T.tracker.zone.text:find("est.",1,true),"tracker shows estimated local count")
T.SelectProfession(129)
check(T.saved.trackProfession==165 and T.tracker.title.text:find("Leatherworking",1,true),"tab change cannot silently repin tracker")
T.window.close.scripts.OnClick()
inventory[2318]=5;inventory[2320]=3;event("BAG_UPDATE_DELAYED")
check(not T.window:IsShown() and T.tracker.action.text=="Craft 2 x Light Armor Kit","bag change updates ready crafts while window closed")
check(T.NextAction(165).text=="Craft 2 x Light Armor Kit","ready count is limited by actual materials")
inventory[2318]=1000;event("BAG_UPDATE_DELAYED")
check(T.NextAction(165).text=="Craft 3 x Light Armor Kit","ready action never exceeds chosen batch")
for _,m in ipairs(T.ZoneNeeds(165).here) do check(m.item~=2318,"covered material leaves the zone checklist") end
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
for _,id in ipairs(T.tabOrder) do check(T.window.tabs[id].point[3]==y,"profession tabs use a single row") end
local function wordCount(text) local n=0;for _ in text:gmatch("%S+") do n=n+1 end;return n end
check(wordCount(screen())<130,"Now avoids paragraphs in the main view")
T.window.keep.scripts.OnClick();check(wordCount(screen())<180,"Keep shows concise rows")
T.Command("mats");T.window.planPage="materials";T.Render()
check(not screen():find("Bags allocated",1,true) and not screen():find("guarantee",1,true),"material accounting explanations stay in tooltips")
inventory[2318]=1000;T.Refresh(false,false)
check(not screen():find("Light Leather",1,true),"covered material hidden in missing-only view")
clickRow("Show all")
check(screen():find("Light Leather",1,true) and screen():find("Covered",1,true),"Show all restores covered route ingredients")
clickRow("Missing only");clickRow("Recipes")
local hasAcquisition=false
for _,r in ipairs(T.window.rows) do
    if r:IsShown() and type(r.detail)=="string" and r.detail:find("Obtain the recipe",1,true) then hasAcquisition=true end
end
check(hasAcquisition,"recipe acquisition is preserved in hover details")
clickRow("Materials")
local chatBefore=#messages;T.Command("help")
check(T.saved.view=="help" and #messages==chatBefore and screen():find("Using TrailMats",1,true),"Help is a page, not chat spam")
T.saved.view="keep";event("ADDON_LOADED","TrailMats")
check(T.saved.view=="keep","existing view choice survives upgrade")
print("PASS: "..checks.." assertions covering UI navigation, tracker updates, source evidence, recipes, bags, vendor stock and tooltips")
