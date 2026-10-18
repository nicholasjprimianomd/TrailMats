-- Auction house capture, the price cascade and profit math, independent of the UI mock.
-- Two harnesses share one process: a legacy QueryAuctionItems client, then a modern C_AuctionHouse client.
local root=arg[1] or "."
local clock=1000000
time=function() return clock end
local T={saved={recipes={},levelingPrices={},scanned={},selected={},observed={},destinations={}},skills={},
    settings={auctionCut=0.05,neutralAuctionHouse=false,recordPrices=true}}
T.Refresh=function() end
local bags={}
local methods={}
for _,name in ipairs({"SetSize","SetJustifyH","ClearAllPoints","SetEnabled"}) do methods[name]=function() end end
function methods:SetPoint(...) self.point={...} end
function methods:SetText(text) self.text=text end
function methods:SetShown(v) self.shown=v end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:RegisterEvent(name) self.events[name]=true end
local function widget() return setmetatable({scripts={},events={},shown=true},{__index=methods}) end
function methods:CreateFontString() return widget() end
CreateFrame=function() return widget() end
UnitFactionGroup=function() return "Alliance" end
C_Item={GetItemCount=function(id) return bags[id] or 0 end}
local itemFacts={[2304]={name="Light Armor Kit",sell=25,bind=0},[9999]={name="Soulbound Gizmo",sell=300,bind=1},
    [2318]={sell=5,bind=0},[2320]={sell=1,bind=0},[2934]={sell=1,bind=0}}
GetItemInfo=function(id)
    local f=itemFacts[id];if not f then return nil end
    return f.name or T.items[id],nil,nil,nil,nil,nil,nil,nil,nil,nil,f.sell,nil,nil,f.bind
end
-- Read-only auction house: every selling, bidding and buying entry point errors if reached.
local forbidden=0
local function never(name) return function() forbidden=forbidden+1;error(name.." must never be called") end end
for _,name in ipairs({"PlaceAuctionBid","BuyoutAuction","PostAuction","StartAuction","CancelAuction"}) do _G[name]=never(name) end
for _,name in ipairs({"Data","Ranges","Future","LevelingData","Leveling","Automatic","Planner","Client","Actions","Auction","Profit"}) do
    assert(loadfile(root.."/TrailMats/"..name..".lua"))("TrailMats",T)
end
local checks=0
local function check(ok,label) assert(ok,label);checks=checks+1 end
local frame=T.auctionFrame
local function event(name,...) frame.scripts.OnEvent(frame,name,...) end
local function tick() frame.scripts.OnUpdate(frame,0.1) end
local function near(a,b) return math.abs(a-b)<1e-9 end
for _,name in ipairs({"AUCTION_HOUSE_SHOW","AUCTION_HOUSE_CLOSED","AUCTION_ITEM_LIST_UPDATE","REPLICATE_ITEM_LIST_UPDATE",
    "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED","AUCTION_HOUSE_BROWSE_RESULTS_ADDED","COMMODITY_SEARCH_RESULTS_UPDATED","ITEM_SEARCH_RESULTS_UPDATED"}) do
    check(frame.events[name],"own frame registers "..name)
end
check(T.AuctionBackend()==nil,"no auction API means no backend")

-- Legacy page parsing: the 18-return GetAuctionItemInfo, bid-only rows, empty stacks and partial rows.
local rows,total={},0
GetNumAuctionItems=function(kind) check(kind=="list","reads the browse list");return #rows,total end
GetAuctionItemInfo=function(kind,i)
    local r=rows[i]
    return r.name or "Item",nil,r.count,1,true,1,"",1,1,r.buyout,0,nil,nil,"Seller",nil,0,r.item,r.hasAllInfo~=false
end
rows={{item=2318,count=20,buyout=400},{item=2318,count=1,buyout=15},{item=2318,count=5,buyout=0},{item=2318,count=0,buyout=100},
    {item=2318,count=1,buyout=5,hasAllInfo=false},{item=2589,count=3,buyout=10}}
local page=T.ReadAuctionList()
check(page[2318].c==15 and page[2318].n==2,"page keeps the lowest unit buyout; bid-only, empty and partial rows are ignored")
check(near(page[2589].c,10/3) and page[2589].n==1,"fractional unit prices are kept")

-- Store merge rules and the account-wide, faction-keyed table.
T.LoadPrices()
check(TrailMatsPrices.Alliance==T.prices and T.AuctionKey()=="Alliance","store is TrailMatsPrices[faction]")
T.MergePrices({[2318]={c=15,n=2}})
check(T.prices[2318].c==15 and T.prices[2318].a==clock and T.prices[2318].n==2,"entry is {c,a,n}")
clock=clock+60;T.MergePrices({[2318]={c=20,n=1}})
check(T.prices[2318].c==15 and T.prices[2318].a==clock-60,"a newer higher price does not overwrite within ten minutes")
T.MergePrices({[2318]={c=12,n=1}})
check(T.prices[2318].c==12 and T.prices[2318].a==clock,"a lower price overwrites")
clock=clock+601;T.MergePrices({[2318]={c=30,n=4}})
check(T.prices[2318].c==30 and T.prices[2318].n==4 and T.prices[2318].a==clock,"an observation older than ten minutes is replaced")
T.MergePrices({[2318]={c=0,n=1},[2589]={c=-1}})
check(T.prices[2318].c==30 and T.prices[2589]==nil,"zero and negative prices are never stored")

-- Reading: expiry, age text and the cut.
local ah=T.AuctionPrice(2318)
check(ah.copper==30 and ah.source=="AH" and ah.listings==4 and ah.at==clock,"own store is read as AH")
check(T.AgeText(clock)=="just now" and T.AgeText(clock-12*60)=="12 min ago" and T.AgeText(clock-3*3600-5)=="3 h ago" and T.AgeText(clock-2*86400-5)=="2 d ago","age text")
clock=clock+14*86400+1
check(T.AuctionPrice(2318)==nil and T.AuctionSummary().count==0,"entries older than 14 days are unknown")
clock=clock-14*86400-1
check(T.AuctionSummary().count==1 and T.AuctionSummary().newest==clock,"summary counts live entries for this faction")
check(T.AuctionCut()==0.05,"default cut is 5%")
T.settings.auctionCut=0.08;check(near(T.AuctionCut(),0.08),"cut follows the setting")
T.settings.neutralAuctionHouse=true;check(T.AuctionCut()==0.15,"neutral setting forces 15%");T.settings.neutralAuctionHouse=false
T.settings.auctionCut=0.05

-- LevelingCost cascade: quote > open vendor packs > auction house, with labels.
T.skills={[129]={rank=20,cap=75}}
T.prices[2589]={c=10,a=clock,n=5}
local cost,label=T.LevelingCost(2589,6)
check(cost==60 and label=="AH, just now","auction price fills the cascade with its age")
T.prices[2589].a=clock-7200;cost,label=T.LevelingCost(2589,6);check(cost==60 and label=="AH, 2 h ago","label carries the observation age")
T.prices[2589].c=10/3;check(T.LevelingCost(2589,6)==20 and T.LevelingCost(2589,5)==17,"fractional units total then round up")
-- 7/3*27 is 63.000000000000007 in floating point and 120*(4/3-1)*0.95 is 37.99999999999999: whole coppers must stay whole.
T.prices[2589].c=7/3;check(T.LevelingCost(2589,27)==63 and T.CeilCopper(7/3*27)==63 and T.FloorCopper(120*(4/3-1)*0.95)==38,"float noise in a fractional unit never adds or drops a copper")
check(T.CeilCopper(63.001)==64 and T.FloorCopper(37.999)==37 and T.CeilCopper(63)==63 and T.FloorCopper(38)==38,"real fractions and exact integers round as before")
T.saved.levelingPrices[2589]={copper=7/3};check(T.LevelingCost(2589,27)==63,"a fractional quote rounds the same way")
T.prices[2589].c=10/3
T.saved.levelingPrices[2589]={copper=5};cost,label=T.LevelingCost(2589,6);check(cost==30 and label=="Your unit price","quote beats the auction house")
T.saved.levelingPrices={}
T.merchantStock={{item=2678,quantity=5,price=7,available=-1}}
T.prices[2678]={c=1,a=clock,n=2};cost,label=T.LevelingCost(2678,6);check(cost==6 and label=="AH, just now","cheaper auction house wins for a vendor supply")
T.prices[2678].c=3;cost,label=T.LevelingCost(2678,6);check(cost==14 and label=="Open vendor; whole packs","cheaper vendor wins when both are known")
T.prices[2678]=nil;cost,label=T.LevelingCost(2678,6);check(cost==14 and label:find("Open vendor",1,true),"vendor alone when the auction house is unknown")
T.merchantStock={};T.prices[2678]={c=3,a=clock,n=2};check(T.LevelingCost(2678,6)==18,"auction house alone when no vendor is open")
T.prices[2678]=nil;cost,label=T.LevelingCost(2678,6);check(cost==nil and label=="Price needed","nothing known stays unknown")
local unit,source=T.BuyUnit(2589);check(near(unit,10/3) and source=="AH, 2 h ago","BuyUnit exposes the unit price and label")
T.merchantStock={{item=2678,quantity=5,price=20,available=-1}};T.prices[2678]={c=10,a=clock,n=1}
unit,source=T.BuyUnit(2678);check(unit==4 and source=="Open vendor","BuyUnit takes the cheaper vendor unit")
T.prices[2678].c=2;unit,source=T.BuyUnit(2678);check(unit==2 and source=="AH, just now","BuyUnit takes the cheaper auction unit")
T.merchantStock={};T.prices[2678]=nil;T.prices[2589]=nil

-- Legacy scan queue through the auction frame controls.
local sent={}
QueryAuctionItems=function(...) sent[#sent+1]={n=select("#",...),...} end
local canQuery,canQueryAll=false,false
CanSendAuctionQuery=function() return canQuery,canQueryAll end
check(T.AuctionBackend()=="legacy","QueryAuctionItems without C_AuctionHouse selects the legacy backend")
T.skills={[165]={rank=20,cap=75,name="Leatherworking"}}
T.saved.recipes[2152]={id=2152,profession=165,name="Light Armor Kit",learned=true,rank=20,difficulty="optimal",mats={[2318]=2,[2320]=1},outputItem=2304,outputCount=2}
T.saved.recipes[4444]={id=4444,profession=165,name="Unnamed thing",learned=true,rank=20,difficulty="optimal",mats={[777777]=1},outputItem=888888}
T.saved.recipes[5555]={id=5555,profession=185,name="Cooking thing",learned=true,rank=20,difficulty="optimal",mats={[6889]=1}}
T.plan={opportunities={},leveling={[165]={priceItems={2318,2934}}},future={byItem={},byProfession={}}}
local items=T.AuctionScanItems()
check(#items==4 and items[1]==2304 and items[2]==2318 and items[3]==2320 and items[4]==2934,"scan list: plan items, learned outputs and reagents, deduped, unnamed and unowned dropped")
check(#T.AuctionScanItems(185)==0,"profession filter respects owned skills")
AuctionFrame=widget();T.area=148
event("AUCTION_HOUSE_SHOW")
check(T.auctionButton and T.auctionButton.text=="TrailMats: Scan prices" and T.auctionButton.point and T.auctionButton.point[2]==AuctionFrame,"scan button is created on the legacy frame once")
check(T.neutralAuctionHouse==false and not T.fullScanButton:IsShown(),"faction house, and no Full scan without ReplicateItems")
T.auctionButton.scripts.OnClick()
check(T.auctionScan and T.auctionScan.backend=="legacy" and T.auctionScan.total==4 and T.AuctionStatus()=="Scanning 0/4","click starts the legacy scan")
tick();check(#sent==0,"no query while CanSendAuctionQuery is false")
canQuery=true;tick()
check(#sent==1 and sent[1][1]=="Light Armor Kit" and sent[1][4]==0 and sent[1][7]==false and sent[1][8]==true and sent[1].n==8,"exact-name query: page 0, getAll false, exactMatch true as the 8th argument")
check(T.AuctionStatus()=="Scanning 0/4: Light Armor Kit" and T.AuctionProgress().item==2304,"progress names the item")
tick();check(#sent==1,"waits for the page before the next query")
local function fill(item,count,unitPrice) rows={};for i=1,count do rows[i]={item=item,count=1,buyout=unitPrice+i} end end
fill(2304,50,1000);total=1000;event("AUCTION_ITEM_LIST_UPDATE")
check(T.prices[2304].c==1001 and T.prices[2304].n==50,"page recorded")
tick();check(#sent==2 and sent[2][4]==1 and sent[2][1]=="Light Armor Kit","a full page with more results fetches page 1")
event("AUCTION_ITEM_LIST_UPDATE");tick();event("AUCTION_ITEM_LIST_UPDATE");tick()
check(#sent==4 and sent[4][4]==3,"pages 2 and 3 follow")
event("AUCTION_ITEM_LIST_UPDATE");tick()
check(#sent==5 and sent[5][1]=="Light Leather" and sent[5][4]==0 and T.auctionScan.done==1,"paging stops after four pages and moves on")
fill(2318,50,100);total=60;event("AUCTION_ITEM_LIST_UPDATE");tick()
check(sent[6][4]==1,"second page while the total is not exhausted")
fill(2318,10,100);event("AUCTION_ITEM_LIST_UPDATE");tick()
check(sent[7][1]=="Coarse Thread" and sent[7][4]==0 and T.auctionScan.done==2,"paging stops when the total is exhausted")
rows={};total=0;event("AUCTION_ITEM_LIST_UPDATE")
check(T.auctionScan.unlisted==1 and T.auctionScan.done==3,"an empty result counts as not listed")
tick();check(sent[8][1]=="Ruined Leather Scraps","last item queried")
event("AUCTION_HOUSE_CLOSED")
check(T.auctionScan==nil and T.prices[2304].c==1001 and T.prices[2318].c==30 and frame.scripts.OnUpdate==nil,"closing the auction house stops the scan and keeps the data (the earlier lower leather price stands)")
event("AUCTION_HOUSE_SHOW");T.StartAuctionScan();tick();check(#sent==9,"a new scan starts from the first item")
fill(2304,3,900);event("AUCTION_ITEM_LIST_UPDATE")
for _=1,3 do tick();rows={};total=0;event("AUCTION_ITEM_LIST_UPDATE") end
check(T.auctionScan.done==4,"all items processed");tick()
check(T.auctionScan==nil and T.auctionResult=="Done: 1 prices, 3 not listed" and T.auctionStatus.text=="Done: 1 prices, 3 not listed","finished scan reports prices and unlisted items")
check(T.auctionButton.text=="TrailMats: Scan prices","button text returns after the scan")
T.StartAuctionScan();T.auctionButton.scripts.OnClick()
check(T.auctionScan==nil and T.auctionResult=="Stopped: 0 prices kept","second click stops the scan")
-- Passive capture while browsing respects the setting; an explicit scan records regardless.
T.prices[2589]=nil;fill(2589,2,40);total=2
T.settings.recordPrices=false;event("AUCTION_ITEM_LIST_UPDATE");check(T.prices[2589]==nil,"recording off: browsing is not captured")
T.settings.recordPrices=true;event("AUCTION_ITEM_LIST_UPDATE");check(T.prices[2589].c==41,"recording on: browsing is captured")
T.settings.recordPrices=false;T.StartAuctionScan();tick();fill(2304,1,700);event("AUCTION_ITEM_LIST_UPDATE")
check(T.prices[2304].c==701,"the scan records even with passive capture off");T.StopAuctionScan();T.settings.recordPrices=true
-- Neutral houses set the session flag from the Questie area id.
T.area=440;event("AUCTION_HOUSE_SHOW");check(T.neutralAuctionHouse==true and T.AuctionCut()==0.15,"Tanaris auction house uses the 15% cut for the session")
T.area=148;event("AUCTION_HOUSE_SHOW");check(T.neutralAuctionHouse==false and T.AuctionCut()==0.05,"faction house restores the setting")
event("AUCTION_HOUSE_CLOSED")

-- Profit formula examples.
T.saved.recipes[4444]=nil;T.saved.recipes[5555]=nil
T.prices[2318]={c=100,a=clock,n=9};T.prices[2320]={c=10,a=clock,n=4};T.prices[2304]={c=1000,a=clock,n=5};T.prices[2934]=nil;T.prices[2589]=nil
local p=T.CraftProfit(T.saved.recipes[2152])
check(p.n==2 and p.cost==210 and p.value==1898 and p.profit==1688 and not p.thin,"profit = 2*(1000-1)*0.95 - (2*100+10)")
T.settings.neutralAuctionHouse=true;p=T.CraftProfit(T.saved.recipes[2152]);check(p.value==1698 and p.profit==1488,"15% cut");T.settings.neutralAuctionHouse=false
T.prices[2320]=nil;p=T.CraftProfit(T.saved.recipes[2152])
check(p.profit==nil and #p.missing==1 and p.missing[1]=="Coarse Thread" and p.cost==200,"an unknown reagent gives nil with the missing count, never 0")
T.merchantStock={{item=2320,quantity=5,price=20,available=-1}};T.prices[2320]={c=10,a=clock,n=1}
p=T.CraftProfit(T.saved.recipes[2152]);check(p.cost==204 and p.profit==1694 and p.mats[2].label=="Open vendor","vendor-cheaper reagent is bought from the vendor")
T.merchantStock={}
T.prices[2304].n=2;p=T.CraftProfit(T.saved.recipes[2152]);check(p.thin==true and p.profit==1688,"fewer than three listings flags a thin market but keeps the value")
T.prices[2304].n=nil;p=T.CraftProfit(T.saved.recipes[2152]);check(not p.thin,"unknown listing count is not flagged")
T.saved.recipes[6666]={id=6666,profession=165,name="Eleven leather",learned=true,rank=20,difficulty="optimal",mats={[2318]=11},outputItem=2304,outputCount=1}
T.prices[2318].c=25/11;p=T.CraftProfit(T.saved.recipes[6666])
check(p.cost==25 and p.value==949 and p.profit==924,"eleven units at 25c per eleven cost exactly 25c: float noise does not add a copper")
check(T.ProfitDetail(p):find("9s 49c after the 5% cut",1,true),"tooltip sale value is the same rounded figure")
T.prices[2318].c=100;T.saved.recipes[6666]=nil
T.prices[2304].n=5;T.prices[2304].c=120;p=T.CraftProfit(T.saved.recipes[2152])
check(p.value==226 and p.profit==16,"small positive profit")
T.prices[2304].c=20;p=T.CraftProfit(T.saved.recipes[2152]);check(p.vendorBetter and p.value==50 and p.profit==-160,"vendor sale used when it beats the auction value; loss is negative")
T.prices[2304].c=1000
T.saved.recipes[7777]={id=7777,profession=165,name="Soulbound Gizmo",learned=true,rank=20,difficulty="optimal",mats={[2318]=1},outputItem=9999,outputCount=1}
T.prices[9999]={c=5000,a=clock,n=9}
p=T.CraftProfit(T.saved.recipes[7777]);check(p.bop and p.vendorOnly and p.value==300 and p.profit==200 and not p.ah,"bind-on-pickup output is valued at the vendor only")
T.saved.recipes[8888]={id=8888,profession=165,name="Mystery",learned=true,rank=20,difficulty="optimal",mats={[2934]=3},outputItem=2304,outputCount=1}
local list=T.SellRecipes(165)
check(#list==3 and list[1].name=="Light Armor Kit" and list[2].name=="Soulbound Gizmo" and list[3].name=="Mystery" and list[3].profit==nil,"priced recipes rank by profit; unknown last")
check(T.Signed(1688)=="+16s 88c" and T.Signed(-35)=="-35c" and T.Signed(0)=="0c","signed money tags")
check(T.ProfitDetail(list[1]):find("even for materials in your bags",1,true) and T.ProfitDetail(list[3]):find("Missing prices: Ruined Leather Scraps",1,true),"tooltips explain replacement cost and missing prices")

-- Bag value totals with keep limits.
bags={[2318]=99,[2934]=10,[2320]=5}
T.plan.future.byItem[2318]={{material={need=30},recipe={name="Light Armor Kit",profession=165},parts={}}}
local mats,totals=T.SellMaterials(165)
check(#mats==2 and mats[1].item==2318 and mats[1].ahValue==9310 and mats[1].vendorValue==495 and mats[1].keep==30 and mats[1].spare==69,"held leather valued after the cut with keep and spare")
check(mats[2].item==2934 and mats[2].ahValue==nil and totals.ah==9310 and totals.unpriced==1 and totals.vendor==505,"unpriced scraps are counted, not zeroed; vendor supplies are excluded")
bags[2318]=120;T.prices[2318].c=4/3;mats,totals=T.SellMaterials(165)
check(mats[1].ahValue==38 and totals.ah==38,"120 units at 4/3c are worth exactly 38c after the cut: float noise does not drop a copper")
bags[2318]=99;T.prices[2318].c=100
local lines={}
local function collect(text,detail,_,_,opts) lines[#lines+1]=text..(opts and opts.value and ("\n"..opts.value) or "") end
T.RenderSell(165,collect)
local screen=table.concat(lines,"\n")
check(screen:find("Craft to sell: Leatherworking",1,true) and screen:find("+16s 88c",1,true) and screen:find("needs 1 price",1,true),"Sell view lists profits and missing prices")
check(screen:find("AH >= 93s 10c (1 item unpriced)",1,true) and screen:find("Keep up to 30 | Spare 69",1,true),"totals carry >= while anything is unpriced")
check(not screen:lower():find("safe to sell",1,true),"nothing is labelled safe to sell")
check(T.RenderSell(393,collect)==nil and table.concat(lines,"\n"):find("Craft to sell: Leatherworking",1,true),"gathering tab shows its crafting partner")
T.prices={};lines={};T.RenderSell(165,collect)
check(table.concat(lines,"\n"):find("No auction prices yet. Open the auction house and click Scan prices.",1,true),"status row without prices")
T.LoadPrices();T.prices[2318]={c=100,a=clock,n=9}

-- Auctionator and TSM are used only when fresher, and never as 0.
local ext,extAge={},{}
Auctionator={API={v1={GetAuctionPriceByItemID=function(caller,id) check(caller=="TrailMats","caller id passed");return ext[id] end,
    GetAuctionAgeByItemID=function(_,id) return extAge[id] end}}}
T.prices[2318].a=clock-3600
ext[2318]=80;extAge[2318]=1;ah=T.AuctionPrice(2318);check(ah.copper==100 and ah.source=="AH","older Auctionator price loses to own data")
-- Auctionator ages are whole days, so "0 days" counts as half a day old: an own price from an hour ago still wins.
extAge[2318]=0;ah=T.AuctionPrice(2318);check(ah.copper==100 and ah.source=="AH","day-old Auctionator price does not outrank own data from this hour")
T.prices[2318].a=clock-2*86400;ah=T.AuctionPrice(2318);check(ah.copper==80 and ah.source=="Auctionator" and ah.at==clock-43200,"fresher Auctionator price wins with its label")
T.prices[2318].a=clock-3600
ext[2318]=0;check(T.AuctionPrice(2318).source=="AH","Auctionator 0 is unknown, not a price")
ext[2318]=nil;check(T.AuctionPrice(2318).copper==100,"Auctionator nil is unknown")
ext[2934]=0;check(T.AuctionPrice(2934)==nil,"no own data and Auctionator 0 stays nil")
local tsm={}
TSM_API={GetCustomPriceValue=function(key,s) check(key=="DBMinBuyout" and s:match("^i:%d+$"),"TSM price string");return tsm[s] end}
check(T.AuctionPrice(2318).source=="AH","TSM nil leaves own data")
tsm["i:2318"]=0;check(T.AuctionPrice(2318).source=="AH","TSM 0 is unknown")
tsm["i:2318"]=70;ah=T.AuctionPrice(2318);check(ah.copper==70 and ah.source=="TSM" and ah.at==clock,"TSM price counts as fresh at read time and is labelled")
cost,label=T.LevelingCost(2318,2);check(cost==140 and label=="TSM","TSM label has no age")
Auctionator=nil;TSM_API=nil

-- Modern harness: C_AuctionHouse browse, passive search capture and the replicate full scan.
QueryAuctionItems=nil;CanSendAuctionQuery=nil;AuctionFrame=nil;AuctionHouseFrame=widget()
Enum={AuctionHouseSortOrder={Price=0,Name=1}}
local browse={results={},full=false,sent={},more=0,ready=true}
local commodity,itemResults={},{}
local replicate={rows={},requested=0}
C_AuctionHouse={
    SendBrowseQuery=function(q) browse.sent[#browse.sent+1]=q end,
    RequestMoreBrowseResults=function() browse.more=browse.more+1 end,
    HasFullBrowseResults=function() return browse.full end,
    GetBrowseResults=function() return browse.results end,
    IsThrottledMessageSystemReady=function() return browse.ready end,
    GetNumCommoditySearchResults=function(id) return #(commodity[id] or {}) end,
    GetCommoditySearchResultInfo=function(id,i) return commodity[id][i] end,
    GetNumItemSearchResults=function(key) return #(itemResults[key.itemID] or {}) end,
    GetItemSearchResultInfo=function(key,i) return itemResults[key.itemID][i] end,
    ReplicateItems=function() replicate.requested=replicate.requested+1 end,
    GetNumReplicateItems=function() return #replicate.rows end,
    GetReplicateItemInfo=function(i)
        local r=replicate.rows[i+1] -- 0-based index per the documentation's "number" (not luaIndex) type
        check(r,"replicate index in range")
        return nil,nil,r.count,1,nil,1,nil,1,1,r.buyout,0,nil,nil,nil,nil,0,r.item,false
    end,
    PostItem=never("PostItem"),PostCommodity=never("PostCommodity"),PlaceBid=never("PlaceBid"),
    StartCommoditiesPurchase=never("StartCommoditiesPurchase"),ConfirmCommoditiesPurchase=never("ConfirmCommoditiesPurchase"),CancelAuction=never("CancelAuction"),
}
check(T.AuctionBackend()=="modern","C_AuctionHouse.SendBrowseQuery selects the modern backend")
T.prices={};T.LoadPrices()
event("AUCTION_HOUSE_SHOW")
check(T.fullScanButton:IsShown() and T.FullScanState().ready,"Full scan offered when ReplicateItems exists")
browse.ready=false;T.auctionButton.scripts.OnClick()
check(T.auctionScan.backend=="modern" and #browse.sent==0,"browse waits for the throttle")
-- The player's own search finishing (or failing) while the scan still waits for the throttle is recorded but is not the scan's result.
browse.results={{itemKey={itemID=2592},minPrice=30,totalQuantity=4}};browse.full=true
event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
check(T.prices[2592].c==30 and T.auctionScan and T.auctionScan.pending=="browse" and #browse.sent==0 and T.AuctionStatus()=="Scanning: 0 items so far","a foreign browse result is captured but leaves the scan waiting for its own browse")
event("AUCTION_HOUSE_BROWSE_FAILURE");check(T.auctionScan and T.auctionScan.pending=="browse","a foreign browse failure does not end a scan that has sent nothing")
browse.full=false;browse.ready=true;event("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
check(#browse.sent==1 and browse.sent[1].searchString=="" and browse.sent[1].sorts[1].sortOrder==1 and browse.sent[1].sorts[1].reverseSort==false,"empty browse query sorted by name")
-- A dropped throttled message is resent once the throttle clears instead of leaving the scan waiting forever.
browse.ready=false;event("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED")
check(T.auctionScan and not T.auctionScan.waiting and T.auctionScan.pending=="browse" and #browse.sent==1,"dropped browse goes back to pending")
browse.ready=true;event("AUCTION_HOUSE_THROTTLED_SYSTEM_READY");check(#browse.sent==2 and T.auctionScan.waiting,"dropped browse is sent again")
browse.results={{itemKey={itemID=2318},minPrice=50,totalQuantity=10},{itemKey={itemID=2318,itemLevel=5},minPrice=40,totalQuantity=1},{itemKey={itemID=2589},minPrice=0,totalQuantity=3}}
browse.ready=false;event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
check(T.prices[2318].c==40 and T.prices[2318].n==nil and T.prices[2589]==nil,"minimum across item keys per item id; zero prices skipped; listings unknown")
check(T.auctionScan and browse.more==0 and T.auctionScan.pending=="more" and T.AuctionStatus()=="Scanning: 1 items so far","partial results queue a request for more behind the throttle")
browse.full=true;event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
check(T.auctionScan and T.auctionScan.pending=="more" and browse.more==0,"a foreign full result between pages does not finish the scan")
browse.ready=true;event("AUCTION_HOUSE_THROTTLED_SYSTEM_READY");check(browse.more==1 and T.auctionScan.waiting,"more results requested once the throttle clears")
event("AUCTION_HOUSE_BROWSE_RESULTS_ADDED",{{itemKey={itemID=2304},minPrice=900,totalQuantity=2}})
check(T.prices[2304].c==900 and T.auctionScan==nil and T.auctionResult=="Done: 2 prices","added rows merge and the full result finishes the scan")
commodity[2592]={{itemID=2592,quantity=5,unitPrice=30},{itemID=2592,quantity=1,unitPrice=25}}
event("COMMODITY_SEARCH_RESULTS_UPDATED",2592);check(T.prices[2592].c==25 and T.prices[2592].n==2,"commodity search results are captured with listing counts")
itemResults[2304]={{quantity=1,buyoutAmount=nil},{quantity=1,buyoutAmount=850},{quantity=2,buyoutAmount=1800}}
event("ITEM_SEARCH_RESULTS_UPDATED",{itemID=2304});check(T.prices[2304].c==850 and T.prices[2304].n==2,"item search results skip bid-only rows")
T.settings.recordPrices=false;commodity[2592][2].unitPrice=1;event("COMMODITY_SEARCH_RESULTS_UPDATED",2592);check(T.prices[2592].c==25,"passive capture off on the modern backend too");T.settings.recordPrices=true
T.StartAuctionScan();event("AUCTION_HOUSE_BROWSE_FAILURE");check(T.auctionScan==nil and T.auctionResult:find("Browse failed",1,true),"browse failure ends the scan")
for i=1,1200 do replicate.rows[i]={item=i%3==0 and 2934 or 2318,count=i%5+1,buyout=(i%5+1)*(10+i%7)} end
check(T.StartFullScan() and replicate.requested==1 and T.auctionScan.backend=="replicate" and T.AuctionStatus()=="Full scan: waiting for the list","full scan calls ReplicateItems")
check(not T.FullScanState().ready and not T.StartFullScan(),"no second full scan while one runs")
event("REPLICATE_ITEM_LIST_UPDATE");tick()
check(T.auctionScan.index==500 and T.AuctionStatus()=="Full scan: 500/1200","500 rows per frame")
tick();tick()
check(T.auctionScan==nil and T.auctionResult=="Done: 2 prices" and T.prices[2318].c==10 and T.prices[2934].c==10,"replicate rows aggregate the lowest unit buyout per item")
check(T.AuctionStatus()=="Done: 2 prices | Full scan available in 15:00","cooldown countdown after a full scan")
clock=clock+320;check(T.AuctionStatus():find("Full scan available in 9:40",1,true),"countdown counts down")
clock=clock+600;check(T.FullScanState().ready and T.AuctionStatus()=="Done: 2 prices","full scan available again after 15 minutes")
-- Stopping a full scan early keeps the rows already read.
T.prices[2318]=nil;T.prices[2934]=nil
check(T.StartFullScan(),"second full scan starts after the cooldown");event("REPLICATE_ITEM_LIST_UPDATE");tick()
T.StopAuctionScan()
check(T.auctionScan==nil and T.auctionResult=="Stopped: 2 prices kept" and T.prices[2318].c==10 and T.prices[2934].c==10,"stopped full scan keeps the rows it had read")
event("AUCTION_HOUSE_CLOSED")
check(forbidden==0,"no bid, buyout, post or cancel call was ever made")
print("PASS: "..checks.." auction capture, scan queue, cascade, profit, bag value and interop checks")
