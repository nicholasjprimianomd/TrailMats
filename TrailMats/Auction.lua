local addon, T = ...
-- Auction house prices: passive capture while browsing, an explicit scan, and read-only price lookups.
-- TrailMats never bids, buys, posts or cancels auctions. Two backends are chosen at runtime: the modern
-- C_AuctionHouse browse API, or the legacy QueryAuctionItems page API when the modern one is absent.
local frame=CreateFrame("Frame")
T.auctionFrame=frame
local STALE=600        -- a newer observation replaces one older than this even when its price is higher
local EXPIRE=14*86400  -- older entries count as unknown, matching the 14-day convention of other AH addons
local PAGE,MAX_PAGES,BATCH,COOLDOWN=50,4,500,900
local neutralAreas={[440]=true,[33]=true,[618]=true} -- Tanaris, Stranglethorn Vale, Winterspring (Questie area ids)
local tick

local function now() return T.Safe(time) or T.Safe(os and os.time) or 0 end

function T.AuctionKey() return T.Safe(UnitFactionGroup,"player") or "Neutral" end
-- Forever has no realms, so prices are shared by every character of one faction on the account.
function T.LoadPrices()
    _G.TrailMatsPrices=type(_G.TrailMatsPrices)=="table" and _G.TrailMatsPrices or {}
    local key=T.AuctionKey()
    if type(_G.TrailMatsPrices[key])~="table" then _G.TrailMatsPrices[key]={} end
    T.prices=_G.TrailMatsPrices[key];T.pricesKey=key
    return T.prices
end
local function store() return T.prices or T.LoadPrices() end
local function recording() return T.auctionScan~=nil or not T.settings or T.settings.recordPrices~=false end

function T.AuctionBackend()
    if C_AuctionHouse and type(C_AuctionHouse.SendBrowseQuery)=="function" then return "modern" end
    if type(QueryAuctionItems)=="function" then return "legacy" end
end

function T.AgeText(at)
    if type(at)~="number" then return "unknown age" end
    local age=math.max(0,now()-at)
    if age<60 then return "just now" end
    if age<3600 then return math.floor(age/60).." min ago" end
    if age<86400 then return math.floor(age/3600).." h ago" end
    return math.floor(age/86400).." d ago"
end

function T.AuctionCut()
    local s=T.settings or {}
    if s.neutralAuctionHouse or T.neutralAuctionHouse then return 0.15 end
    local cut=tonumber(s.auctionCut)
    if not cut or cut<0 or cut>0.5 then return 0.05 end
    return cut
end
-- Unit prices are fractional (a stack buyout over its count), so a product that is exactly a whole copper can land a hair
-- above or below it in floating point. A real fraction sits at least 1/(100*count) from an integer, so shaving a millionth
-- of a copper before rounding never changes one and never adds or drops a copper.
function T.CeilCopper(x) return math.ceil(x-1e-6) end
function T.FloorCopper(x) return math.floor(x+1e-6) end
function T.DisplayCopper(x) return math.floor(x+0.5) end -- a unit price shown on its own, rounded to the nearest copper

local function valid(copper,at,t)
    return type(copper)=="number" and copper>0 and copper<math.huge and type(at)=="number" and t-at<=EXPIRE
end
-- {copper, at, source, listings} or nil. Own observations first; Auctionator or TSM only when fresher. Never 0.
function T.AuctionPrice(item)
    if type(item)~="number" then return nil end
    local t=now();local best
    local e=store()[item]
    if type(e)=="table" and valid(e.c,e.a,t) then best={copper=e.c,at=e.a,source="AH",listings=e.n} end
    local api=Auctionator and Auctionator.API and Auctionator.API.v1
    if api then
        local price=T.Safe(api.GetAuctionPriceByItemID,"TrailMats",item)
        local days=T.Safe(api.GetAuctionAgeByItemID,"TrailMats",item)
        -- Auctionator reports whole days; count a day-old price as half a day old so a fresher own observation still wins.
        local at=t-((type(days)=="number" and days>=0 and days or 0)+0.5)*86400
        if valid(price,at,t) and (not best or at>best.at) then best={copper=price,at=at,source="Auctionator"} end
    end
    if TSM_API and type(TSM_API.GetCustomPriceValue)=="function" then
        local price=T.Safe(TSM_API.GetCustomPriceValue,"DBMinBuyout","i:"..item)
        if valid(price,t,t) and (not best or t>best.at) then best={copper=price,at=t,source="TSM"} end
    end
    return best
end

function T.AuctionSummary()
    local t=now();local count,newest=0,nil
    for item,e in pairs(store()) do
        if type(item)=="number" and type(e)=="table" and valid(e.c,e.a,t) then
            count=count+1
            if not newest or e.a>newest then newest=e.a end
        end
    end
    return {count=count,newest=newest,key=T.pricesKey or T.AuctionKey()}
end

-- A page is {[itemID]={c=lowest unit buyout, n=listings}}. Bid-only rows (buyout 0) and empty stacks are ignored.
local function addRow(page,item,count,buyout)
    if type(item)~="number" or type(count)~="number" or count<=0 or type(buyout)~="number" or buyout<=0 then return end
    local unit=buyout/count;local e=page[item]
    if not e then page[item]={c=unit,n=1} else e.n=e.n+1;if unit<e.c then e.c=unit end end
end
function T.MergePrices(page,at)
    at=at or now();local s=store()
    for item,p in pairs(page or {}) do
        local e=s[item]
        if type(p.c)=="number" and p.c>0 and (type(e)~="table" or type(e.c)~="number" or p.c<=e.c or at-(tonumber(e.a) or 0)>STALE) then
            s[item]={c=p.c,a=at,n=p.n}
        end
    end
    return page
end

function T.ReadAuctionList()
    local page={}
    local n,total=T.Safe(GetNumAuctionItems,"list")
    n=tonumber(n) or 0
    for i=1,n do
        -- Blizzard_AuctionUI.lua:976 return order; rows without hasAllInfo are skipped as Blizzard does ("Bug 145328").
        local _,_,count,_,_,_,_,_,_,buyout,_,_,_,_,_,_,itemId,hasAllInfo=T.Safe(GetAuctionItemInfo,"list",i)
        if hasAllInfo then addRow(page,itemId,count,buyout) end
    end
    return page,n,tonumber(total) or 0
end
-- AuctionHouseDocumentation.lua:1500-1510 BrowseResultInfo {itemKey, appearanceLink, totalQuantity, minPrice, containsOwnerItem}.
-- Browse rows carry unit quantities, not listing counts, so n stays unknown here.
function T.ReadBrowseResults(results)
    local page={}
    for _,r in ipairs(type(results)=="table" and results or {}) do
        local item=type(r.itemKey)=="table" and r.itemKey.itemID
        if type(item)=="number" and type(r.minPrice)=="number" and r.minPrice>0 and (not page[item] or r.minPrice<page[item].c) then page[item]={c=r.minPrice} end
    end
    return page
end
-- AuctionHouseDocumentation.lua:1512-1528 CommoditySearchResultInfo {itemID, quantity, unitPrice, ...}.
function T.ReadCommodityResults(item)
    local c=C_AuctionHouse;local page={}
    for i=1,(T.Safe(c and c.GetNumCommoditySearchResults,item) or 0) do
        local r=T.Safe(c.GetCommoditySearchResultInfo,item,i)
        if type(r)=="table" then addRow(page,item,1,r.unitPrice) end
    end
    return page
end
-- AuctionHouseDocumentation.lua:1557-1577 ItemSearchResultInfo {itemKey, ..., quantity, ..., buyoutAmount (nil when bid only)}.
function T.ReadItemResults(itemKey)
    local c=C_AuctionHouse;local page={}
    local item=type(itemKey)=="table" and itemKey.itemID
    for i=1,(T.Safe(c and c.GetNumItemSearchResults,itemKey) or 0) do
        local r=T.Safe(c.GetItemSearchResultInfo,itemKey,i)
        if type(r)=="table" then addRow(page,item,r.quantity or 1,r.buyoutAmount) end
    end
    return page
end

-- Everything the planner prices for the owned professions, plus learned recipe outputs and reagents.
function T.AuctionScanItems(profession)
    local set,list={},{}
    local function add(item) if type(item)=="number" then set[item]=true end end
    local function wanted(id) return T.skills and T.skills[id] and (not profession or id==profession) end
    for id in pairs(T.skills or {}) do
        if wanted(id) and T.plan then
            local op=T.plan.opportunities and T.plan.opportunities[id]
            for _,m in ipairs(op and op.materials or {}) do add(m.item) end
            local goal=T.FarmGoal and T.FarmGoal(id)
            for _,m in ipairs(goal and goal.materials or {}) do add(m.item) end
            local p=T.plan.leveling and T.plan.leveling[id]
            for _,item in ipairs(p and p.priceItems or {}) do add(item) end
        end
    end
    for _,r in pairs(T.saved and T.saved.recipes or {}) do
        if type(r)=="table" and r.learned and wanted(r.profession) then
            add(r.outputItem)
            for item in pairs(type(r.mats)=="table" and r.mats or {}) do add(item) end
        end
    end
    for item in pairs(set) do if T.ItemName(item)~="Item #"..item then list[#list+1]=item end end
    table.sort(list)
    return list
end

local function priced(s) local n=0;for _ in pairs(s.found) do n=n+1 end;return n end
-- Rows already read from a replicate list are kept when the scan stops early.
local function keepRead(s)
    if s and s.backend=="replicate" and s.page then
        T.MergePrices(s.page);for item in pairs(s.page) do s.found[item]=true end;s.page=nil
    end
end
local function finish(text)
    T.auctionScan=nil;T.auctionResult=text
    T.UpdateAuctionControls()
    if T.Queue then T.Queue(false,false) elseif T.Render then T.Render() end
end
local function throttleReady()
    local c=C_AuctionHouse
    if c and type(c.IsThrottledMessageSystemReady)=="function" then return T.Safe(c.IsThrottledMessageSystemReady) and true or false end
    return true
end
-- AuctionHouseDocumentation.lua:1431-1440 AuctionHouseBrowseQuery {searchString, sorts, minLevel, maxLevel, filters, itemClassFilters}.
local function browseQuery()
    local sorts={}
    local order=Enum and Enum.AuctionHouseSortOrder
    if order and order.Name~=nil then sorts[1]={sortOrder=order.Name,reverseSort=false} end
    return {searchString="",sorts=sorts,filters={},itemClassFilters={}}
end

function T.StartAuctionScan(profession)
    if T.auctionScan then return false end
    local backend=T.AuctionBackend()
    if not backend then T.auctionResult="No auction house API available";T.UpdateAuctionControls();return false end
    if backend=="modern" then T.auctionScan={backend="modern",pending="browse",found={}}
    else
        local items=T.AuctionScanItems(profession)
        if #items==0 then T.auctionResult="Nothing to scan: open a profession first";T.UpdateAuctionControls();return false end
        T.auctionScan={backend="legacy",queue=items,total=#items,index=0,done=0,page=0,found={},unlisted=0}
    end
    T.auctionResult=nil;frame:SetScript("OnUpdate",tick);tick(frame,0)
    return true
end
function T.StopAuctionScan()
    local s=T.auctionScan
    if s then keepRead(s);finish("Stopped: "..priced(s).." prices kept") end
end
function T.AuctionProgress()
    local s=T.auctionScan
    if not s then return nil end
    return {backend=s.backend,item=s.item,total=s.backend=="legacy" and s.total or s.count,
        done=s.backend=="legacy" and s.done or s.backend=="replicate" and s.index or priced(s)}
end

function T.FullScanState()
    local c=C_AuctionHouse
    if not (c and type(c.ReplicateItems)=="function" and type(c.GetNumReplicateItems)=="function" and type(c.GetReplicateItemInfo)=="function") then return nil end
    local remaining=T.lastFullScan and math.max(0,T.lastFullScan+COOLDOWN-now()) or 0
    local ready=remaining<=0
    if type(CanSendAuctionQuery)=="function" then
        local _,canAll=T.Safe(CanSendAuctionQuery,"list")
        if canAll==false then ready=false elseif canAll==true then ready=true end
    end
    return {ready=ready and not T.auctionScan,remaining=remaining}
end
function T.StartFullScan()
    local state=T.FullScanState()
    if not state or not state.ready then return false end
    if not pcall(C_AuctionHouse.ReplicateItems) then T.auctionResult="Full scan request failed";T.UpdateAuctionControls();return false end
    T.lastFullScan=now();T.auctionResult=nil
    T.auctionScan={backend="replicate",found={},index=0}
    frame:SetScript("OnUpdate",tick);T.UpdateAuctionControls()
    return true
end

local function clock(seconds)
    seconds=math.ceil(seconds)
    return math.floor(seconds/60)..":"..string.format("%02d",seconds%60)
end
function T.AuctionStatus()
    local s=T.auctionScan
    if s then
        if s.backend=="legacy" then return "Scanning "..s.done.."/"..s.total..(s.item and (": "..T.ItemName(s.item)) or "") end
        if s.backend=="modern" then return "Scanning: "..priced(s).." items so far" end
        return s.count and ("Full scan: "..s.index.."/"..s.count) or "Full scan: waiting for the list"
    end
    local text=T.auctionResult
    local full=T.FullScanState()
    if full and not full.ready then
        local wait=full.remaining>0 and ("Full scan available in "..clock(full.remaining)) or "Full scan not available yet"
        text=text and (text.." | "..wait) or wait
    end
    return text or ""
end

local function createControls()
    if T.auctionButton then return end
    local parent=AuctionHouseFrame or AuctionFrame
    if not parent then return end
    local b=CreateFrame("Button","TrailMatsScanButton",parent,"UIPanelButtonTemplate")
    b:SetSize(150,22);b:SetText("TrailMats: Scan prices")
    -- Below the frame's bottom-left corner, right of the Browse/Bids/Auctions tabs (Blizzard_AuctionUI.xml:60-66),
    -- clear of the money frame (xml:87-93) and the bid price input (xml:1347-1353). AuctionHouseFrame keeps its tabs there too.
    b:SetPoint("TOPLEFT",parent,"BOTTOMLEFT",372,-6)
    b:SetScript("OnClick",function() if T.auctionScan then T.StopAuctionScan() else T.StartAuctionScan() end end)
    T.auctionButton=b
    local full=CreateFrame("Button","TrailMatsFullScanButton",parent,"UIPanelButtonTemplate")
    full:SetSize(80,22);full:SetText("Full scan");full:SetPoint("LEFT",b,"RIGHT",4,0)
    full:SetScript("OnClick",function() T.StartFullScan() end)
    T.fullScanButton=full
    local status=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    status:SetJustifyH("LEFT");T.auctionStatus=status
end
function T.UpdateAuctionControls()
    local b=T.auctionButton
    if not b then return end
    b:SetText(T.auctionScan and "TrailMats: Stop scan" or "TrailMats: Scan prices")
    local full=T.FullScanState();local fb=T.fullScanButton
    fb:SetShown(full~=nil)
    if fb.SetEnabled then fb:SetEnabled(full~=nil and full.ready) end
    T.auctionStatus:ClearAllPoints();T.auctionStatus:SetPoint("LEFT",full and fb or b,"RIGHT",8,0)
    T.auctionStatus:SetText(T.AuctionStatus())
end

tick=function(self,elapsed)
    if T.auctionOpen and not T.auctionButton then createControls() end
    local s=T.auctionScan
    if s and s.backend=="legacy" then
        -- Blizzard_AuctionUI.lua:705 polls CanSendAuctionQuery("list") the same way before each page.
        if not s.waiting and T.Safe(CanSendAuctionQuery,"list") then
            if s.page==0 then
                s.index=s.index+1;s.item=s.queue[s.index]
                if not s.item then finish("Done: "..priced(s).." prices, "..s.unlisted.." not listed");return end
            end
            s.waiting=true
            -- Blizzard_AuctionUI.lua:615 QueryAuctionItems(text, minLevel, maxLevel, page, usable, rarity, getAll, exactMatch, filterData).
            if not pcall(QueryAuctionItems,T.ItemName(s.item),nil,nil,s.page,nil,nil,false,true) then s.waiting=false;s.page=0;s.done=s.done+1 end
        end
    elseif s and s.backend=="modern" then
        if s.pending and throttleReady() then
            local what=s.pending;s.pending=nil;s.waiting=true;s.sent=what
            local ok=what=="browse" and pcall(C_AuctionHouse.SendBrowseQuery,browseQuery()) or what=="more" and pcall(C_AuctionHouse.RequestMoreBrowseResults)
            if not ok then finish("Browse failed: "..priced(s).." prices kept");return end
        end
    elseif s and s.backend=="replicate" and s.count then
        local c=C_AuctionHouse
        local last=math.min(s.index+BATCH-1,s.count-1)
        for i=s.index,last do
            -- AuctionHouseDocumentation.lua:576-605 GetReplicateItemInfo(index) returns name, texture, count, qualityID, usable, level,
            -- levelType, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner, ownerFullName, saleStatus,
            -- itemID, hasAllInfo. The index is 0-based; count, buyoutPrice and itemID are set even when hasAllInfo is false.
            local _,_,count,_,_,_,_,_,_,buyout,_,_,_,_,_,_,item=T.Safe(c.GetReplicateItemInfo,i)
            addRow(s.page,item,count,buyout)
        end
        s.index=last+1
        if s.index>=s.count then
            T.MergePrices(s.page)
            for item in pairs(s.page) do s.found[item]=true end
            finish("Done: "..priced(s).." prices");return
        end
    end
    T.auctionElapsed=(T.auctionElapsed or 0)+(elapsed or 0)
    if T.auctionElapsed>=(s and 0.25 or 1) then T.auctionElapsed=0;T.UpdateAuctionControls() end
    if not s and not T.auctionOpen then frame:SetScript("OnUpdate",nil) end
end

local function onEvent(_,event,arg1)
    if event=="ADDON_LOADED" then if arg1==addon then T.LoadPrices() end return end
    if event=="PLAYER_LOGIN" then T.LoadPrices();return end
    local s=T.auctionScan
    if event=="AUCTION_HOUSE_SHOW" then
        T.auctionOpen=true;T.auctionResult=nil;T.LoadPrices()
        T.neutralAuctionHouse=neutralAreas[T.area or 0] or false
        createControls();frame:SetScript("OnUpdate",tick)
    elseif event=="AUCTION_HOUSE_CLOSED" then
        T.auctionOpen=false
        if s then keepRead(s);finish("Stopped: "..priced(s).." prices kept") end
        T.auctionResult=nil;frame:SetScript("OnUpdate",nil)
        if T.Queue then T.Queue(false,false) end
    elseif event=="AUCTION_ITEM_LIST_UPDATE" then
        if not recording() then return end
        local page,n,total=T.ReadAuctionList()
        T.MergePrices(page)
        if s and s.backend=="legacy" and s.waiting then
            for item in pairs(page) do s.found[item]=true end
            s.waiting=false
            if n>=PAGE and total>(s.page+1)*PAGE and s.page+1<MAX_PAGES then s.page=s.page+1
            else
                if not s.found[s.item] then s.unlisted=s.unlisted+1 end
                s.page=0;s.done=s.done+1
            end
        end
    elseif event=="AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event=="AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
        if not recording() then return end
        -- AuctionHouseDocumentation.lua:1063-1074: ADDED carries the new rows; UPDATED means re-read GetBrowseResults().
        local added=event=="AUCTION_HOUSE_BROWSE_RESULTS_ADDED" and type(arg1)=="table" and arg1
        local page=T.ReadBrowseResults(added or T.Safe(C_AuctionHouse and C_AuctionHouse.GetBrowseResults))
        T.MergePrices(page)
        -- Only a result the scan asked for (s.waiting) drives it; the player's own searches are recorded and nothing more.
        if s and s.backend=="modern" and s.waiting then
            for item in pairs(page) do s.found[item]=true end
            s.waiting=false
            if T.Safe(C_AuctionHouse.HasFullBrowseResults) then finish("Done: "..priced(s).." prices") else s.pending="more";tick(frame,0) end
        end
    elseif event=="AUCTION_HOUSE_BROWSE_FAILURE" then
        if s and s.backend=="modern" and s.waiting then finish("Browse failed: "..priced(s).." prices kept") end
    elseif event=="AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
        if s then tick(frame,0) end
    elseif event=="AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED" then
        -- The server dropped our browse request; send the same request again once the throttle clears.
        if s and s.backend=="modern" and s.waiting then s.waiting=false;s.pending=s.sent or "browse" end
    elseif event=="COMMODITY_SEARCH_RESULTS_UPDATED" then
        if recording() then T.MergePrices(T.ReadCommodityResults(arg1)) end
    elseif event=="ITEM_SEARCH_RESULTS_UPDATED" then
        if recording() then T.MergePrices(T.ReadItemResults(arg1)) end
    elseif event=="REPLICATE_ITEM_LIST_UPDATE" then
        if s and s.backend=="replicate" then s.count=T.Safe(C_AuctionHouse.GetNumReplicateItems) or 0;s.index=0;s.page={} end
    end
    T.UpdateAuctionControls()
end
frame:SetScript("OnEvent",onEvent)
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","AUCTION_HOUSE_SHOW","AUCTION_HOUSE_CLOSED","AUCTION_ITEM_LIST_UPDATE","REPLICATE_ITEM_LIST_UPDATE",
    "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED","AUCTION_HOUSE_BROWSE_RESULTS_ADDED","AUCTION_HOUSE_BROWSE_FAILURE","AUCTION_HOUSE_THROTTLED_SYSTEM_READY","AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED",
    "COMMODITY_SEARCH_RESULTS_UPDATED","ITEM_SEARCH_RESULTS_UPDATED"}) do
    pcall(frame.RegisterEvent,frame,event)
end
