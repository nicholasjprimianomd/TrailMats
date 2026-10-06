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
for _,name in ipairs({"SetSize","SetPoint","SetWidth","SetHeight","ClearAllPoints","SetClampedToScreen","SetMovable","EnableMouse","RegisterForDrag","StartMoving","StopMovingOrSizing","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetJustifyH","SetJustifyV","SetScrollChild","SetOwner"}) do
    methods[name]=function() end
end
function methods:SetSize(w,h) self.width=w;self.height=h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetHeight() return self.height or 347 end
function methods:GetStringHeight()
    local n=0
    for line in (self.text or ""):gmatch("[^\n]+") do n=n+math.max(1,math.ceil(#line/58)) end
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
 for _,r in ipairs(T.window.rows) do if r:IsShown() then lines[#lines+1]=r.label.text end end
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
check(screen():find("Try 3 crafts of",1,true),"quantity explains what will be made")
check(not screen():find("~",1,true) and not screen():find("[\128-\255]"),"no tilde or unsupported glyphs")
IsTradeSkillLinked=function() return true end
GetTradeSkillReagentInfo=function() return "wrong",nil,999 end
event("TRADE_SKILL_UPDATE");check(T.saved.recipes[2152].mats[2318]==2,"linked recipes ignored")
IsTradeSkillLinked=nil
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
print("PASS: "..checks.." assertions covering tabs, departure states, learned recipes, bags, vendor prices/stock, sources and tooltips")
