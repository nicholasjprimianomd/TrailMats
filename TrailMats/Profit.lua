local _, T = ...
-- Sell view: profit per craft and the value of held materials, from recorded auction prices.
-- Reference figures only: an asking price is not a sale, and nothing is marked safe to sell.
local gold="|cffffd27f"
local muted="|cffb6c2cc"
local UNDER=1 -- post one copper under the cheapest listing

local function itemInfo(item)
    local r={T.Safe(C_Item and C_Item.GetItemInfo,item)}
    if r[1]==nil then r={T.Safe(GetItemInfo,item)} end
    return r
end
function T.SellPrice(item)
    local v=itemInfo(item)[11]
    return type(v)=="number" and v>=0 and v or nil
end
function T.BindsOnPickup(item) return itemInfo(item)[14]==1 end
function T.Signed(copper)
    if copper>0 then return "+"..T.Money(copper) end
    if copper<0 then return "-"..T.Money(-copper) end
    return T.Money(0)
end
function T.AuctionLabel(ah) return ah.source=="TSM" and "TSM" or (ah.source..", "..T.AgeText(ah.at)) end
local function plural(n,word) return n.." "..word..(n==1 and "" or "s") end
local function percent() return math.floor(T.AuctionCut()*100+0.5).."%" end

function T.VendorUnit(item)
    if not T.levelingSupplies[item] then return nil end
    local best
    for _,v in ipairs(T.merchantStock or {}) do
        if v.item==item and v.available~=0 and type(v.quantity)=="number" and v.quantity>0 and type(v.price)=="number" then
            local unit=v.price/v.quantity
            if not best or unit<best then best=unit end
        end
    end
    return best
end
-- Copper per unit to buy one more: your quote, then the cheaper of the open vendor and the auction house.
function T.BuyUnit(item)
    local quote=T.saved and T.saved.levelingPrices and T.saved.levelingPrices[item]
    if type(quote)=="table" and type(quote.copper)=="number" and quote.copper>=0 and quote.copper<math.huge then return quote.copper,"Your unit price" end
    local vendor=T.VendorUnit(item)
    local ah=T.AuctionPrice(item)
    if vendor and (not ah or vendor<=ah.copper) then return vendor,"Open vendor" end
    if ah then return ah.copper,T.AuctionLabel(ah),ah end
    return nil,"Price needed"
end

local function validMats(mats)
    if type(mats)~="table" or not next(mats) then return false end
    for item,qty in pairs(mats) do
        if type(item)~="number" or type(qty)~="number" or qty<=0 or qty~=qty or qty==math.huge then return false end
    end
    return true
end
-- profit = n * (ahUnit(output) - 1c) * (1 - cut) - sum(qty * buyUnit(mat)); nil while any price is missing.
function T.CraftProfit(r)
    local n=type(r.outputCount)=="number" and r.outputCount>0 and r.outputCount or 1
    local p={recipe=r,name=r.name or tostring(r.id),output=r.outputItem,n=n,cut=T.AuctionCut(),cost=0,missing={},mats={}}
    local items={}
    for item in pairs(r.mats) do items[#items+1]=item end
    table.sort(items)
    for _,item in ipairs(items) do
        local unit,label=T.BuyUnit(item)
        p.mats[#p.mats+1]={item=item,qty=r.mats[item],unit=unit,label=label}
        if unit then p.cost=p.cost+r.mats[item]*unit else p.missing[#p.missing+1]=T.ItemName(item) end
    end
    p.cost=T.CeilCopper(p.cost)
    p.sell=T.SellPrice(p.output)
    p.vendorValue=p.sell and n*p.sell or nil
    p.bop=T.BindsOnPickup(p.output)
    if p.bop then
        if p.vendorValue then p.value=p.vendorValue;p.vendorOnly=true else p.missing[#p.missing+1]=T.ItemName(p.output).." (vendor price)" end
    else
        local ah=T.AuctionPrice(p.output)
        if ah then
            p.ah=ah;p.thin=type(ah.listings)=="number" and ah.listings<3
            p.ahValue=T.FloorCopper(n*math.max(0,ah.copper-UNDER)*(1-p.cut));p.value=p.ahValue
            if p.vendorValue and p.vendorValue>p.value then p.value=p.vendorValue;p.vendorBetter=true end
        else p.missing[#p.missing+1]=T.ItemName(p.output).." (sale price)" end
    end
    if #p.missing==0 then p.profit=p.value-p.cost end
    return p
end
function T.SellRecipes(profession)
    local list={}
    for _,r in pairs(T.saved and T.saved.recipes or {}) do
        if type(r)=="table" and r.profession==profession and r.learned and type(r.outputItem)=="number" and validMats(r.mats) then list[#list+1]=T.CraftProfit(r) end
    end
    table.sort(list,function(a,b)
        if (a.profit~=nil)~=(b.profit~=nil) then return a.profit~=nil end
        if a.profit and b.profit and a.profit~=b.profit then return a.profit>b.profit end
        if #a.missing~=#b.missing then return #a.missing<#b.missing end
        return a.name<b.name
    end)
    return list
end
function T.ProfitDetail(p)
    local lines,mats={},{}
    for _,m in ipairs(p.mats) do
        mats[#mats+1]=m.qty.." "..T.ItemName(m.item)..(m.unit and (" at "..T.Money(math.ceil(m.unit)).." ("..m.label..")") or " (price needed)")
    end
    lines[#lines+1]=(#p.missing>0 and "Known cost so far " or "Cost ")..T.Money(p.cost).." per craft: "..table.concat(mats,", ")..". Full replacement cost, even for materials in your bags."
    if p.ah then
        lines[#lines+1]="Sale: "..p.n.." x "..T.ItemName(p.output).." at "..T.Money(math.floor(p.ah.copper)).." each ("..T.AuctionLabel(p.ah).."); "..
            T.Money(p.ahValue).." after the "..percent().." cut and a 1c undercut."
    end
    if p.vendorValue then lines[#lines+1]="Vendor pays "..T.Money(p.vendorValue).." for "..p.n.."."..(p.vendorBetter and " Used because it beats the auction value." or "") end
    if p.bop then lines[#lines+1]="Binds when picked up: cannot be auctioned." end
    if p.thin then lines[#lines+1]="Thin market: "..plural(p.ah.listings,"listing")..". An asking price is not a sale." end
    if #p.missing>0 then lines[#lines+1]="Missing prices: "..table.concat(p.missing,", ").."." end
    if p.profit then lines[#lines+1]="Profit "..T.Signed(p.profit).." per craft, estimated from asking prices." end
    return table.concat(lines,"\n")
end

-- Held raw materials of the reviewed catalog and learned recipes; vendor supplies are not valued.
function T.SellMaterials(profession)
    local set={}
    for _,e in ipairs(T.levelingEdges and T.levelingEdges[profession] or {}) do
        for item in pairs(e.recipe.mats or {}) do set[item]=true end
    end
    for _,r in pairs(T.saved and T.saved.recipes or {}) do
        if type(r)=="table" and r.profession==profession and r.learned and type(r.mats)=="table" then for item in pairs(r.mats) do set[item]=true end end
    end
    local rows,total={},{ah=0,vendor=0,unpriced=0,noInfo=0}
    local cut=T.AuctionCut()
    for item in pairs(set) do
        local have=type(item)=="number" and not T.levelingSupplies[item] and T.Count(item) or 0
        if have>0 then
            local m={item=item,have=have,ah=T.AuctionPrice(item),sell=T.SellPrice(item)}
            if m.ah then m.ahValue=T.FloorCopper(have*math.max(0,m.ah.copper-UNDER)*(1-cut));total.ah=total.ah+m.ahValue else total.unpriced=total.unpriced+1 end
            if m.sell then m.vendorValue=have*m.sell;total.vendor=total.vendor+m.vendorValue else total.noInfo=total.noInfo+1 end
            local uses=T.plan and T.plan.future and T.plan.future.byItem[item]
            if uses and uses[1] then
                local keep=0
                for _,use in ipairs(uses) do keep=keep+use.material.need end
                m.keep=keep;m.uses=uses
                if have>keep then m.spare=have-keep end
            end
            rows[#rows+1]=m
        end
    end
    table.sort(rows,function(a,b)
        if (a.ahValue or -1)~=(b.ahValue or -1) then return (a.ahValue or -1)>(b.ahValue or -1) end
        return a.item<b.item
    end)
    return rows,total
end
function T.MaterialValueDetail(m)
    local lines={"You have "..m.have.."."}
    if m.ah then lines[#lines+1]="Auction house: "..T.Money(m.ahValue).." after the "..percent().." cut and a 1c undercut ("..T.Money(math.floor(m.ah.copper)).." each, "..T.AuctionLabel(m.ah)..")."
    else lines[#lines+1]="No auction price recorded for this item." end
    if m.vendorValue then lines[#lines+1]="Vendor pays "..T.Money(m.vendorValue).." ("..T.Money(m.sell).." each)." else lines[#lines+1]="Vendor price unknown until the client loads the item." end
    if m.uses then
        local c=m.uses[1].recipe
        lines[#lines+1]="Keep up to "..m.keep.." for "..c.name..((#m.uses>1 or #(m.uses[1].parts or {})>1) and " and later recipes" or "").." (estimated)."
    end
    lines[#lines+1]="Reference values, not sales. Keep limits are estimates; nothing here is marked safe to sell."
    return table.concat(lines,"\n")
end

function T.RenderSell(selected,row)
    local id=T.FutureProfession(selected)
    local name=T.professions[id].name
    local function heading(text,detail) row(gold..text.."|r",detail,nil,nil,{heading=true}) end
    local summary=T.AuctionSummary()
    if summary.count>0 then
        row("Auction prices: "..plural(summary.count,"item").." ("..summary.key..")\n"..muted.."Newest "..T.AgeText(summary.newest).."|r",
            "Lowest unit buyouts recorded while you browsed or scanned, kept for 14 days and shared by your "..summary.key.." characters. Asking prices are not sales. Nothing is posted or bought.")
    else
        row("No auction prices yet. Open the auction house and click Scan prices.",
            "Prices are also recorded while you browse the auction house. Auctionator and TradeSkillMaster prices are used when they are fresher.")
    end
    if not T.skills[id] then row("Learn "..name.." to compare crafts and materials.");return end
    heading("Craft to sell: "..name,"Profit per craft: sale value after the "..percent().." cut and a 1c undercut, minus the full replacement cost of materials, even those in your bags. Unknown prices never count as free.")
    local recipes=T.SellRecipes(id)
    if #recipes==0 then row("No learned recipe with a known output.","Open your profession window so TrailMats can read learned recipes and what they make.") end
    for _,p in ipairs(recipes) do
        local second,value,state
        if p.profit then
            second=p.vendorOnly and "Vendor only" or (p.n.." x "..T.ItemName(p.output).." | "..(p.vendorBetter and "vendor pays more" or T.AuctionLabel(p.ah)))
            if p.thin then second=second.." | thin market: "..plural(p.ah.listings,"listing") end
            value=T.Signed(p.profit).."\n"..(p.vendorOnly and "vendor only" or "per craft")
            state=p.profit>0 and "ready" or p.profit<0 and "buy" or "keep"
        else
            second="Needs "..plural(#p.missing,"price")
            value="?\nneeds "..plural(#p.missing,"price");state="keep"
        end
        local detail=p
        row(p.name.."\n"..muted..second.."|r",function() return T.ProfitDetail(detail) end,nil,nil,{item=p.output,value=value,state=state})
    end
    heading("Your materials","Held "..name.." materials at the auction house after the cut, and what a vendor pays. Keep limits come from the leveling plan; value never changes them.")
    local rows,total=T.SellMaterials(id)
    if #rows==0 then row("No "..name.." materials in your bags.") end
    for _,m in ipairs(rows) do
        local keep=m.keep and ("Keep up to "..m.keep..(m.spare and (" | Spare "..m.spare) or "")) or "No reviewed leveling use listed"
        local value=(m.ahValue and T.Money(m.ahValue) or "AH ?").."\n"..(m.vendorValue and ("vendor "..T.Money(m.vendorValue)) or "vendor ?")
        local detail=m
        row(T.ItemName(m.item).."\n"..muted.."Have "..m.have.." | "..keep.."|r",function() return T.MaterialValueDetail(detail) end,nil,nil,{item=m.item,value=value,state="keep"})
    end
    if #rows>0 then
        local ah="AH "..(total.unpriced>0 and ">= " or "")..T.Money(total.ah)..(total.unpriced>0 and (" ("..plural(total.unpriced,"item").." unpriced)") or "")
        local vendor="Vendor "..(total.noInfo>0 and ">= " or "")..T.Money(total.vendor)
        row(gold.."Total|r\n"..muted..ah.." | "..vendor.."|r","Totals use the lowest asking prices after the cut; unpriced items are left out and marked with >=. Selling is your decision; keep limits are estimates.")
    end
end
