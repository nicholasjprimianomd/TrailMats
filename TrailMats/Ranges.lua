local _, T = ...

-- Reviewed Forever references, 2026-10-05. These are advisory leveling bands,
-- not zone-entry gates, exact skill-up probabilities, or a cheapest-route claim.
T.skillBands = {
    [165] = {
        {1,30,"Light Leather from scraps, or Light Armor Kit"},
        {30,55,"Cured Light Hide; keep the cured hides for later recipes"},
        {55,75,"Embossed Leather Gloves"},
    },
    [185] = {
        {1,50,"Starter foods using eggs, smallfish, mackerel or meat"},
        {50,100,"Longjaw Mud Snapper or Rainbow Fin Albacore"},
    },
    [129] = {
        {1,40,"Linen Bandage"},
        {40,75,"Heavy Linen Bandage"},
        {75,80,"Heavy Linen Bandage as a short bridge; green crafts may waste cloth"},
        {80,115,"Wool Bandage"},
        {115,150,"Heavy Wool Bandage"},
    },
}
T.recipeBands = {
    [2152]={1,30}, [3756]={55,75},
    [8604]={1,50}, [6412]={1,50}, [7751]={1,50}, [7752]={1,50},
    [2538]={1,50}, [2540]={1,50}, [7753]={50,100}, [7827]={50,100},
    [3275]={1,40}, [3276]={40,75}, [3277]={80,115},
}
T.fishingEfficiency = {
    [141]={minimum=1,target=25,low=1,lure="Shiny Bauble (+25)"},
    [148]={minimum=1,target=75,low=50,lure="Shiny Bauble (+25)"},
    [17]={minimum=1,target=75,low=50,lure="Shiny Bauble (+25)"},
    [40]={minimum=1,target=75,low=50,lure="Shiny Bauble (+25)"},
    [38]={minimum=1,target=75,low=50,lure="Shiny Bauble (+25)"},
    [331]={minimum=55,target=150,low=100,lure="Nightcrawlers (+50)"},
    [406]={minimum=55,target=150,low=100,lure="Nightcrawlers (+50)"},
}

-- Gathering node requirements from Wowhead's Forever database (Quick Facts "Requires Herbalism (N)" /
-- "Requires Mining (N)" on each object page, listings /forever/objects/herbs and /forever/objects/mineral-veins,
-- read 2026-10-18). Classic values are unchanged; NEW marks objects added in Forever. Beta-era data.
T.herbNodes = { -- objectId = {name, requires}
    [1618]={"Peacebloom",1}, [1617]={"Silverleaf",1}, [656160]={"Wilted Peacebloom",1}, [656161]={"Stunted Silverleaf",1}, -- NEW x2
    [1619]={"Earthroot",15}, [1620]={"Mageroyal",50}, [1621]={"Briarthorn",70}, [2045]={"Stranglekelp",85},
    [1622]={"Bruiseweed",100}, [1623]={"Wild Steelbloom",115}, [1628]={"Grave Moss",120}, [1624]={"Kingsblood",125},
    [439557]={"Nightmare Moss",125}, [2041]={"Liferoot",150}, [2042]={"Fadeleaf",160}, [2046]={"Goldthorn",170},
    [2043]={"Khadgar's Whisker",185}, [2044]={"Wintersbite",195}, [439627]={"Dreamroot",205}, [2866]={"Firebloom",205},
    [180165]={"Purple Lotus",210}, [176642]={"Arthas' Tears",220}, [180164]={"Sungrass",230}, [142143]={"Blindweed",235},
    [142144]={"Ghost Mushroom",245}, [142145]={"Gromsblood",250}, [439810]={"Moonroot",250}, [439762]={"Star Lotus",250},
    [176638]={"Golden Sansam",260}, [180168]={"Dreamfoil",270}, [176586]={"Mountain Silversage",280},
    [176587]={"Plaguebloom",285}, [176588]={"Icecap",290}, [176589]={"Black Lotus",300},
}
T.miningNodes = { -- objectId = {name, requires}; "Ooze Covered" variants share their base node's requirement
    [1731]={"Copper Vein",1}, [562111]={"Poor Copper Vein",1}, -- NEW
    [1732]={"Tin Vein",65}, [1733]={"Silver Vein",75}, [1735]={"Iron Deposit",125}, [181109]={"Gold Vein",155},
    [150079]={"Mithril Deposit",175}, [181108]={"Truesilver Deposit",230}, [165658]={"Dark Iron Deposit",230},
    [324]={"Small Thorium Vein",245}, [175404]={"Rich Thorium Vein",275}, [566779]={"Heavy Thorium Vein",300}, -- NEW
}
-- Zone bands from the Wowhead Forever Herbalism and Mining overviews (updated 2026/10/11); tested to 225 in the beta.
T.gatherBands = {
    [182] = {
        {1,70,"Starter zones: Peacebloom, Silverleaf, Earthroot, Mageroyal"},
        {70,115,"Darkshore, Loch Modan or Silverpine: Briarthorn, Stranglekelp, Bruiseweed"},
        {115,170,"Hillsbrad, Wetlands or Stonetalon: Wild Steelbloom, Kingsblood, Liferoot"},
        {170,205,"Stranglethorn or Arathi: Goldthorn, Khadgar's Whisker"},
        {205,225,"Alterac, Tanaris or Searing Gorge: Firebloom, Purple Lotus, Arthas' Tears"},
    },
    [186] = {
        {1,65,"Starter zones: Copper"},
        {65,125,"Ashenvale, Redridge, the Barrens or Thousand Needles: Tin and Silver"},
        {125,175,"Arathi, Desolace, Stranglethorn or Thousand Needles: Iron and Gold"},
        {175,225,"Azshara, Tanaris or the Hinterlands: Mithril"},
    },
}
local nodeNames
-- Returns the gathering profession and skill a named herb or vein needs, or nil for anything else.
function T.NodeRequirement(name)
    if not nodeNames then
        nodeNames={}
        for _,n in pairs(T.herbNodes) do nodeNames[n[1]]={182,n[2]} end
        for _,n in pairs(T.miningNodes) do nodeNames[n[1]]={186,n[2]} end
    end
    local entry=name and (nodeNames[name] or nodeNames[name:gsub("^Ooze Covered ","")])
    if entry then return entry[1],entry[2] end
end

function T.RangeAdvice(id,destination)
    local s=T.skills[id]
    if not s then return nil end
    if id==356 then
        local area=destination~=0 and destination or T.area
        local r=T.fishingEfficiency[area]
        if not r then return {title="Fishing efficiency: not assessed",text="No reviewed catch target for this zone."} end
        local zone=T.destinationNames[area] or (T.zones[area] and T.zones[area].name) or "this zone"
        return {title="Efficient Fishing in "..zone..": "..r.low.."-"..r.target.." base skill",
            text="Minimum: "..r.minimum.." effective. No-escape target: "..r.target.." effective.\n"..
                "Lower end needs "..r.lure.."; upper end needs no bonus. Higher skill is also fine.",
            detail="Forever fishing guide (Oct 4). Pole, lure and food bonuses are not measured. The range assumes the named lure stays active; it is not a required departure level.",
            note=s.rank>=r.target and "No-escape target met with base skill." or
                (s.rank>=r.low and "Within the recommended base range; check your active bonuses." or "Below the recommended base range; bonuses may still cover the gap.")}
    elseif id==393 then
        if destination==148 or destination==331 then
            local low,high,beasts=10,20,"Thistle Bears (levels 11-12)"
            if destination==331 then low,high,beasts=90,100,"Ghostpaw Runners (levels 19-20)" end
            return {title="Target coverage: "..low.."-"..high.." Skinning",
                text="For "..beasts..", aim for "..high.."+ to cover both levels. Higher skill remains usable.",
                note="Classic reference; confirm the actual Forever corpse requirement.",
                detail="This range describes requirements of the named beasts only. It is not a verified optimal skill-up band or a requirement for every beast in the zone."}
        end
        return {title="Skinning efficiency: not assessed",text="Follow eligible beasts on your route; no verified numeric optimal range for this destination."}
    end
    local bands=T.skillBands[id] or T.gatherBands[id] or {}
    local gathering=T.gatherBands[id]~=nil
    for i,b in ipairs(bands) do
        if s.rank<b[2] then
            local nextBand=bands[i+1]
            return {title=(gathering and "Where to gather at skill " or "Recommended leveling range: ")..b[1].."-"..b[2],text=b[3]..".",
                note=nextBand and ("Next at "..b[2]..": "..nextBand[3]..".") or "Beyond this band: no reviewed range in TrailMats yet.",
                detail=gathering and "Wowhead Forever gathering overview (Oct 11). Node skill requirements are shown on each node's tooltip. Zones are suggestions, not requirements." or
                    "Forever leveling guide reference, Oct 5. Learn the recipe first. Live recipe color and available materials take priority. These are skill ranges for crafting, not levels required before leaving a zone."}
        end
    end
    return {title="Recommended leveling range: not assessed",text="No reviewed numeric band at your current skill. Use your live orange/yellow recipe options below."}
end
