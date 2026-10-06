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
    for i,b in ipairs(T.skillBands[id] or {}) do
        if s.rank<b[2] then
            local nextBand=T.skillBands[id][i+1]
            return {title="Recommended leveling range: "..b[1].."-"..b[2],text=b[3]..".",
                note=nextBand and ("Next at "..b[2]..": "..nextBand[3]..".") or "Beyond this band: no reviewed range in TrailMats yet.",
                detail="Forever leveling guide reference, Oct 5. Learn the recipe first. Live recipe color and available materials take priority. These are skill ranges for crafting, not levels required before leaving a zone."}
        end
    end
    return {title="Recommended leveling range: not assessed",text="No reviewed numeric band at your current skill. Use your live orange/yellow recipe options below."}
end
