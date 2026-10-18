local _, T = ...
-- Reviewed Forever routes for the trade professions beyond the original three, researched 2026-10-17/18
-- from the wow-professions.com/forever guides (bands, craft counts) and wowhead.com/forever spell pages
-- (reagents, ids, outputs, sources), then run through the planner for every starting skill. See SOURCES.md.
-- Bands are planning intervals, not exact learning requirements or colour tables. Routes past 225 are
-- kept for later but T.levelingLimit stays at 225 until they are tested on a live client.
local recipe,edge=T.DefineRecipe,T.DefineEdge
for _,p in ipairs({171,164,333,197,202}) do T.levelingEdges[p]=T.levelingEdges[p] or {} end

-- ===== Alchemy (171) =====
-- Alchemy (171) leveling data for TrailMats, researched 2026-10-17/18 against the Forever beta.
-- Guide (bands, craft counts, alternatives, vendors): https://www.wow-professions.com/forever/alchemy-leveling-guide
-- Reagents and item ids: each recipe line cites its wowhead.com/forever spell page; item ids were cross-read from the
-- Listview data of https://www.wowhead.com/forever/spells/professions/alchemy.
-- Forever moved the six Healing Potions to First Aid (guide; https://www.warcrafttavern.com/forever/guides/alchemy/;
-- https://www.icy-veins.com/wow-forever/news/healing-potions-now-crafted-by-first-aid-in-wow-forever/), so the
-- Classic 1-10 and 290-300 healing-potion steps are replaced by Minor Arcane Elixir / Elixir of Minor Force and Major Frenzy Potion.
-- Herbs, Firefin Snapper and Stonescale Eel are gathered (herbalism/fishing); only the vials are vendor supplies.
-- Output counts: the Listview gives 1 for every potion/elixir and 2 for Fire Oil and Stonescale Oil (guide: "You get 2 oils from every craft"); the live scanner overrides these.
-- Sources: starter recipes (Minor Arcane Elixir, Elixir of Minor Force, Elixir of Minor Defense) are granted with Apprentice Alchemy
-- (seemeta "Learned automatically with the profession rank"; wowhead lists no trainer), so they keep the default "Trainer" source.
recipe("al-minor-arcane-elixir",171,"Minor Arcane Elixir",{[2447]=1,[3371]=1}) -- https://www.wowhead.com/forever/spell=1245246/minor-arcane-elixir (new in Forever; Listview: orange 1, yellow 10, gray 15, no trainer listed; granted automatically with Apprentice Alchemy per https://seemeta.com/en/wow-forever/professions/alchemy, and the guide uses it from skill 1)
recipe("al-elixir-of-minor-force",171,"Elixir of Minor Force",{[765]=1,[3371]=1}) -- https://www.wowhead.com/forever/spell=1245250/elixir-of-minor-force (new in Forever; granted automatically with Apprentice Alchemy per seemeta; Listview: orange 1, yellow 10, gray 15, no trainer listed)
recipe("al-elixir-of-minor-defense",171,"Elixir of Minor Defense",{[765]=1,[2447]=1,[3371]=1}) -- https://www.wowhead.com/forever/spell=7183/elixir-of-minor-defense (Listview: Requires 1, yellow 55, gray 95, no trainer listed; granted automatically with Apprentice Alchemy per seemeta; a Classic trainer recipe)
recipe("al-minor-mana-potion",171,"Minor Mana Potion",{[785]=1,[2447]=1,[3371]=1}) -- https://www.wowhead.com/forever/spell=2331/minor-mana-potion (Listview: Requires 25, trainer, 1s)
recipe("al-elixir-of-minor-fortitude",171,"Elixir of Minor Fortitude",{[2449]=2,[2447]=1,[3371]=1}) -- https://www.wowhead.com/forever/spell=2334/elixir-of-minor-fortitude (Listview: Requires 50, trainer, 2s50c)
recipe("al-elixir-of-wisdom",171,"Elixir of Wisdom",{[785]=1,[2450]=2,[3371]=1},"Journeyman trainer") -- https://www.wowhead.com/forever/spell=3171/elixir-of-wisdom (Listview: Requires 90, trainer, 5s; guide: keep them for Tailoring's Gloves of Meditation)
recipe("al-lesser-mana-potion",171,"Lesser Mana Potion",{[785]=1,[3820]=1,[3371]=1},"Journeyman trainer") -- https://www.wowhead.com/forever/spell=3173/lesser-mana-potion (Listview: Requires 120, yellow 145, green 165, trainer, 15s)
recipe("al-fire-oil",171,"Fire Oil",{[6359]=2,[3371]=1},"Journeyman trainer",{6371,2}) -- https://www.wowhead.com/forever/spell=7837/fire-oil (Listview: Requires 130, creates 2, trainer, 10s; Firefin Snapper is fished)
recipe("al-elixir-of-fire-power",171,"Elixir of Fire Power",{[6371]=2,[3356]=1,[3372]=1},"Journeyman trainer") -- https://www.wowhead.com/forever/spell=7845/elixir-of-fire-power (Listview: Requires 140, trainer, 30s; the page also inlines Fire Oil's own reagents, which are not part of this recipe)
recipe("al-mana-potion",171,"Mana Potion",{[3820]=1,[3356]=1,[3372]=1},"Expert trainer") -- https://www.wowhead.com/forever/spell=3452/mana-potion (Listview: Requires 160, yellow 180, trainer, 50s)
recipe("al-nature-protection-potion",171,"Nature Protection Potion",{[3357]=1,[3820]=1,[3372]=1},"Vendor recipe: Bronk or Logannas (Feralas), Glyx Brewright (Stranglethorn Vale), Alchemist Pestlezugg (Tanaris); bind on pickup") -- https://www.wowhead.com/forever/spell=7259/nature-protection-potion (Listview: Requires 190, yellow 210, green 230, source vendor; vendor names from the guide)
recipe("al-draught-of-detect-undead",171,"Draught of Detect Undead",{[8836]=1,[8925]=1},"Artisan trainer") -- https://www.wowhead.com/forever/spell=11460/draught-of-detect-undead (Forever name of Elixir of Detect Undead; Listview: Requires 230, yellow 245, green 265, trainer, 50s)
recipe("al-superior-mana-potion",171,"Superior Mana Potion",{[8838]=2,[8839]=2,[8925]=1},"Vendor recipe: Algernon (Undercity) or Ulthir (Darnassus)") -- https://www.wowhead.com/forever/spell=17553/superior-mana-potion (Listview: Requires 260, yellow 275, green 295, source vendor; vendor names from the guide)
recipe("al-stonescale-oil",171,"Stonescale Oil",{[13422]=1,[3372]=1},"Artisan trainer",{13423,2}) -- https://www.wowhead.com/forever/spell=17551/stonescale-oil (Listview: Requires 250, yellow 250, green 255, gray 260, creates 2, trainer, 1g50s; preparation for Elixir of Greater Defense only, the guide gives it no band; Stonescale Eel is fished)
recipe("al-elixir-of-greater-defense",171,"Elixir of Greater Defense",{[13423]=2,[8838]=1,[8925]=1},"Vendor recipe: Kor'geld (Orgrimmar) or Soolie Berryfizz (Ironforge)") -- https://www.wowhead.com/forever/spell=17554/elixir-of-greater-defense (Forever name of Classic Elixir of Superior Defense, item 13445; the guide still calls the recipe item "Recipe: Elixir of Superior Defense"; Listview: Requires 265, yellow 280, green 300, source vendor; the page also inlines Stonescale Oil's own reagents, which are not part of this recipe)
recipe("al-elixir-of-shadow-power",171,"Elixir of Shadow Power",{[8845]=3,[8925]=1},"Vendor recipe: Algernon (Undercity) or Maria Lumere (Stormwind City)") -- https://www.wowhead.com/forever/spell=11476/elixir-of-shadow-power (Listview: Requires 250, yellow 265, green 285, gray 305, source vendor; vendor names from the guide)
recipe("al-major-frenzy-potion",171,"Major Frenzy Potion",{[13466]=3,[8839]=2,[18256]=1},"Vendor recipe: Apothecary Durelle (Durotar Supply and Logistics camp west of the Crossroads, the Barrens) or Nina Surefire (Azeroth Commerce Authority camp, Three Corners, Redridge Mountains); Honored, 240 Merchant's Favor; bind on pickup") -- https://www.wowhead.com/forever/spell=1251740/major-frenzy-potion (new in Forever; Listview: Requires 290, yellow 295, green 297, gray 300, source vendor; vendor rows "Recipe: Major Frenzy Potion ... Honored Alchemy (290) 240x Merchant's Favor" at https://www.wow-professions.com/forever/npc/apothecary-durelle and https://www.wow-professions.com/forever/npc/nina-surefire)
-- Apprentice (1-55)
edge(171,1,10,9,"al-minor-arcane-elixir") -- guide 1-10: 9x https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,1,10,9,"al-elixir-of-minor-force") -- guide 1-10 alternative: 9x if Silverleaf is cheaper than Peacebloom https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,10,55,45,"al-elixir-of-minor-defense") -- guide 10-55: 45x https://www.wow-professions.com/forever/alchemy-leveling-guide
-- Journeyman (55-150); Journeyman Alchemy needs skill 50 and level 10
edge(171,55,65,10,"al-minor-mana-potion") -- guide 55-65: 10x https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,65,90,27,"al-elixir-of-minor-fortitude") -- guide 65-90: 27x, yellow from 80 so the last 10 points take a few more https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,90,120,30,"al-elixir-of-wisdom") -- guide 90-120: 30x https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,120,130,10,"al-lesser-mana-potion") -- guide 120-130: 10x https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,130,150,20,"al-fire-oil") -- guide 130-150: 20x (40 oils), keep 30 for Elixir of Fire Power https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,130,150,20,"al-lesser-mana-potion") -- guide 130-150 alternative: 20x if Firefin Snapper is expensive or scarce https://www.wow-professions.com/forever/alchemy-leveling-guide
-- Expert (150-225); Expert Alchemy needs skill 125 and level 20, taught only by Doctor Herbert Halsey (Undercity) or Ainethil (Darnassus)
edge(171,150,165,15,"al-elixir-of-fire-power") -- guide 150-165: 15x using the 30 kept Fire Oil https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,150,165,22,"al-lesser-mana-potion") -- guide 150-165 alternative: 22x if you skipped Fire Oil (yellow from 145, green 165) https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,165,195,36,"al-mana-potion") -- guide 165-195: 36x https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,195,225,36,"al-nature-protection-potion") -- guide 195-225: 36x https://www.wow-professions.com/forever/alchemy-leveling-guide
-- Artisan (225-300); Artisan Alchemy needs skill 200 and level 35 (Rogvar, Stonard / Kylanna Windwhisper, Feathermoon). The guide marks everything from here as untested on the beta (level cap).
edge(171,225,230,12,"al-nature-protection-potion") -- guide 225-230: 12x https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,230,265,45,"al-draught-of-detect-undead") -- guide 230-265: 45x, yellow from 245 so expect a few extra https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,265,275,10,"al-superior-mana-potion") -- guide 265-275: 10x https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,275,290,20,"al-superior-mana-potion") -- guide 275-290 option 1 of 3: 20x (already yellow) https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,275,290,17,"al-elixir-of-greater-defense") -- guide 275-290 option 2 of 3: 17x needing 34 Stonescale Oil (17 oil crafts via conversion), yellow from 280 https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,275,290,27,"al-elixir-of-shadow-power") -- guide 275-290 option 3 of 3: 27x (already yellow, green from 285) https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,290,300,17,"al-major-frenzy-potion") -- guide 290-300: 17x, the only Merchant's Favor recipe that reaches 300; yellow from 295 https://www.wow-professions.com/forever/alchemy-leveling-guide
edge(171,290,300,15,"al-elixir-of-greater-defense") -- guide 290-300 alternative without a count ("keep making any of the three recipes above"); 15 is an estimate for 10 yellow points (yellow 280-300), not a guide figure https://www.wow-professions.com/forever/alchemy-leveling-guide
-- No faction-only recipes: every vendor recipe above has a Horde and an Alliance (or neutral) seller, so no T.levelingRecipes[key].faction assignments.
local names={[765]="Silverleaf",[785]="Mageroyal",[2447]="Peacebloom",[2449]="Earthroot",[2450]="Briarthorn",
    [3356]="Kingsblood",[3357]="Liferoot",[3820]="Stranglekelp",[6359]="Firefin Snapper",[6371]="Fire Oil",
    [8836]="Arthas' Tears",[8838]="Sungrass",[8839]="Blindweed",[8845]="Ghost Mushroom",
    [13422]="Stonescale Eel",[13423]="Stonescale Oil",[13466]="Plaguebloom",
    [3371]="Empty Vial",[3372]="Leaded Vial",[8925]="Crystal Vial",[18256]="Imbued Vial"}
for id,name in pairs(names) do T.items[id]=name end
-- Conversions: oils crafted on demand when a later recipe needs more than the route produced.
-- Vendor supplies: the four vials, sold by Alchemy Supply / Trade Supply vendors near every trainer
-- (https://www.wowhead.com/forever/item=3372/leaded-vial 39 zones, https://www.wowhead.com/forever/item=8925/crystal-vial 37 zones,
-- https://www.wowhead.com/forever/item=18256/imbued-vial 25 zones; Empty Vial 3371 is already a supply in LevelingData.lua).

-- ===== Blacksmithing (164) =====
-- Blacksmithing (skill line 164) leveling data for TrailMats, researched 2026-10-17/18 against the Forever beta (client 1.60.1).
-- Bands, craft counts, alternatives and keep notes: https://www.wow-professions.com/forever/blacksmithing-leveling-guide
--   (author tested to 225; "The part past 225 can't be tested on the beta right now", so there are no edges above 225).
-- Reagents and item ids: each recipe cites its https://www.wowhead.com/forever/spell=<id> page; the same reagents were re-read from
--   Wowhead's Forever tooltip data (https://nether.wowhead.com/tooltip/spell/<id>?dataEnv=16&locale=0) on 2026-10-18.
-- Trainer source and colour thresholds: https://seemeta.com/en/wow-forever/professions/blacksmithing (game version 1.60.1 beta, updated 2026-10-17).
--   Forever spell pages and tooltips carry no "Requires Blacksmithing" line and no trainer list, so learn levels rest on seemeta alone.
-- Bars are Mining smelts and are treated as gathered raw materials. Blacksmith Hammer (item 5956) is a tool, not a reagent.
-- Output counts: Forever tooltips print "(2)" after every created item, armor included, where Classic tooltips print nothing, so that
--   figure is not a yield. The guide's arithmetic is one stone per craft (30 crafts = 30 Rough Grinding Stone, 16 kept for 8 gauntlets x2,
--   36 Coarse Grinding Stone for 18 bracers x2, 20 Heavy Grinding Stone for 10 bracers x2). The live scanner overrides this.
-- Apprentice 1-75 (any Blacksmithing trainer; Journeyman needs skill 50 and level 10, trained in the capitals)
recipe("bs-rough-sharpening-stone",164,"Rough Sharpening Stone",{[2835]=1}) -- https://www.wowhead.com/forever/spell=2660/rough-sharpening-stone : Rough Stone 2835 x1 -> item 2862; seemeta: learned automatically with the profession rank, yellow 15 / green 35 / grey 55
recipe("bs-rough-grinding-stone",164,"Rough Grinding Stone",{[2835]=2},"Trainer",{3470,1}) -- https://www.wowhead.com/forever/spell=3320/rough-grinding-stone : Rough Stone x2 -> 3470; seemeta: trainer, yellow 45 / green 65 / grey 85
recipe("bs-coarse-grinding-stone",164,"Coarse Grinding Stone",{[2836]=2},"Trainer",{3478,1}) -- https://www.wowhead.com/forever/spell=3326/coarse-grinding-stone : Coarse Stone 2836 x2 -> 3478; seemeta: trainer, yellow 50 / green 63 / grey 75 (the guide crafts it 50-67, yellow then green; the learn level is shown by neither source)
recipe("bs-runed-copper-gauntlets",164,"Runed Copper Gauntlets",{[2840]=8,[3470]=2}) -- https://www.wowhead.com/forever/spell=3323/runed-copper-gauntlets : Copper Bar 2840 x8, Rough Grinding Stone x2 -> 3472; seemeta: trainer, yellow 75 / green 95 / grey 115
-- Journeyman 75-150 (capital trainers)
recipe("bs-runed-copper-belt",164,"Runed Copper Belt",{[2840]=10},"Trainer") -- https://www.wowhead.com/forever/spell=2666/runed-copper-belt : Copper Bar x10 -> 2857; guide: Journeyman; seemeta: trainer, orange 80 / yellow 85 / green 105 / grey 125 (seemeta's 80 conflicts with the guide's tested 75-80 band; unconfirmed)
recipe("bs-silver-rod",164,"Silver Rod",{[2842]=1,[3470]=2},"Trainer") -- https://www.wowhead.com/forever/spell=7818/silver-rod : Silver Bar 2842 x1, Rough Grinding Stone x2 -> 6338; guide: Journeyman alternative at 75; seemeta: trainer, yellow 80 / green 83 / grey 85
recipe("bs-rough-bronze-leggings",164,"Rough Bronze Leggings",{[2841]=6},"Trainer") -- https://www.wowhead.com/forever/spell=2668/rough-bronze-leggings : Bronze Bar 2841 x6 -> 2865; guide: Journeyman; seemeta: trainer, orange 95 / yellow 120 / green 135 / grey 150 (conflicts with the guide's tested 80-95 band; unconfirmed)
recipe("bs-patterned-bronze-bracers",164,"Patterned Bronze Bracers",{[2841]=5,[3478]=2},"Trainer") -- https://www.wowhead.com/forever/spell=2672/patterned-bronze-bracers : Bronze Bar x5, Coarse Grinding Stone x2 -> 2868; guide: Journeyman; seemeta: trainer, orange 120 / yellow 125 / green 140 / grey 155 (conflicts with the guide's tested 95-100 band; unconfirmed)
recipe("bs-heavy-grinding-stone",164,"Heavy Grinding Stone",{[2838]=3},"Trainer",{3486,1}) -- https://www.wowhead.com/forever/spell=3337/heavy-grinding-stone : Heavy Stone 2838 x3 -> 3486; seemeta: trainer, yellow 100 / green 113 / grey 125
recipe("bs-bronze-shortsword",164,"Bronze Shortsword",{[2841]=5,[2880]=4,[2319]=2},"Trainer") -- https://www.wowhead.com/forever/spell=2742/bronze-shortsword : Bronze Bar x5, Weak Flux 2880 x4, Medium Leather 2319 x2 -> 2850; seemeta: trainer, orange 95 / yellow 125 / green 140 / grey 155
recipe("bs-bronze-warhammer",164,"Bronze Warhammer",{[2841]=8,[3466]=1,[2319]=1},"Trainer") -- https://www.wowhead.com/forever/spell=9985/bronze-warhammer : Bronze Bar x8, Strong Flux 3466 x1, Medium Leather x1 -> 7956 (9986/9987 are Greatsword/Battle Axe); seemeta: trainer, yellow 155 / green 170 / grey 185; the guide crafts it 140-165 across the Expert training at 150
-- Expert 150-215 (Saru Steelfury, Orgrimmar / Bengus Deepforge, Ironforge; needs skill 125, level 20, 50 silver)
recipe("bs-green-iron-bracers",164,"Green Iron Bracers",{[3575]=6,[2605]=1},"Expert trainer") -- https://www.wowhead.com/forever/spell=3501/green-iron-bracers : Iron Bar 3575 x6, Green Dye 2605 x1 -> 3835; seemeta: trainer, yellow 165 / green 178 / grey 190; Green Dye from Tamar (Orgrimmar) or Bombus Finespindle (Ironforge) per the guide
recipe("bs-golden-scale-bracers",164,"Golden Scale Bracers",{[3859]=5,[3486]=2},"Expert trainer") -- https://www.wowhead.com/forever/spell=7223/golden-scale-bracers : Steel Bar 3859 x5, Heavy Grinding Stone x2 -> 6040; seemeta: trainer, yellow 185 / green 198 / grey 210
recipe("bs-mithril-plate-pants",164,"Mithril Plate Pants",{[3860]=12},"Expert trainer") -- https://www.wowhead.com/forever/spell=9931/mithril-plate-pants : Mithril Bar 3860 x12 -> 7920; Forever name of Classic spell 9931 "Mithril Scale Pants" (Classic tooltip, dataEnv=4); seemeta: trainer, yellow 205 / green 215 / grey 225
recipe("bs-steel-breastplate",164,"Steel Breastplate",{[3859]=16,[3486]=3},"Expert trainer") -- https://www.wowhead.com/forever/spell=9916/steel-breastplate : Steel Bar x16, Heavy Grinding Stone x3 -> 7963; seemeta: trainer, yellow 200 / green 213 / grey 225
recipe("bs-steel-plate-helm",164,"Steel Plate Helm",{[3859]=14,[7966]=1},"Expert trainer") -- https://www.wowhead.com/forever/spell=9935/steel-plate-helm : Steel Bar x14, Solid Grinding Stone 7966 x1 -> 7922; seemeta: trainer, yellow 210 / green 220 / grey 230
recipe("bs-solid-grinding-stone",164,"Solid Grinding Stone",{[7912]=4},"Expert trainer",{7966,1}) -- https://www.wowhead.com/forever/spell=9920/solid-grinding-stone : Solid Stone 7912 x4 -> 7966; seemeta: trainer, yellow 175 / green 180 / grey 185; preparation only, the guide gives it no band
-- Artisan section 215-225 (Brikk Keencraft, Booty Bay, both factions; needs skill 200, level 35)
recipe("bs-heavy-mithril-breastplate",164,"Heavy Mithril Breastplate",{[3860]=16},"Artisan trainer") -- https://www.wowhead.com/forever/spell=9959/heavy-mithril-breastplate : Mithril Bar x16 -> 7930; seemeta: trainer, yellow 225 / green 235 / grey 245; placed under the guide's Artisan heading, which trainer rank teaches it is unconfirmed
recipe("bs-mithril-spurs",164,"Mithril Spurs",{[3860]=4,[7966]=3},"Plans: Mithril Spurs (world drop; check the Auction House)") -- https://www.wowhead.com/forever/spell=9964/mithril-spurs : Mithril Bar x4, Solid Grinding Stone x3 -> 7969; Plans item 7989 https://www.wowhead.com/forever/item=7989/plans-mithril-spurs requires Blacksmithing 210 on Forever (235 on Classic); seemeta: Plans: Mithril Spurs skill 210, yellow 230 / green 240 / grey 250; world-drop source is the guide's statement only
edge(164,1,25,30,"bs-rough-sharpening-stone") -- guide 1-25: "30x Rough Sharpening Stone - 30 Rough Stone" https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,25,50,30,"bs-rough-grinding-stone") -- guide 25-50: "30x Rough Grinding Stone - 60 Rough Stone"; keep 26 (16 for the gauntlets, 10 for Silver Rods at 75) https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,50,67,36,"bs-coarse-grinding-stone") -- guide 50-67: "36x Coarse Grinding Stone - 72 Coarse Stone"; make all 36 for the bracers at 95 and 112 https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,67,75,8,"bs-runed-copper-gauntlets") -- guide 67-75: "8x Runed Copper Gauntlets - 64 Copper Bar, 16 Rough Grinding Stone"; Blacksmith Hammer needed from here on https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,75,80,5,"bs-runed-copper-belt") -- guide 75-80: "5x Runed Copper Belt - 50 Copper Bar" https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,75,80,5,"bs-silver-rod") -- guide 75-80 alternative: "5x Silver Rod instead (1 Silver Bar, 2 Rough Grinding Stone each)" if you have Silver Bars or one costs less than 10 Copper Bars https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,80,95,15,"bs-rough-bronze-leggings") -- guide 80-95: "15x Rough Bronze Leggings - 90 Bronze Bar" https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,95,100,5,"bs-patterned-bronze-bracers") -- guide 95-100: "5x Patterned Bronze Bracers - 25 Bronze Bar, 10 Coarse Grinding Stone" https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,100,112,20,"bs-heavy-grinding-stone") -- guide 100-112: "20x Heavy Grinding Stone - 60 Heavy Stone"; keep all 20 for Golden Scale Bracers at 175 https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,112,125,13,"bs-patterned-bronze-bracers") -- guide 112-125: "13x Patterned Bronze Bracers - 65 Bronze Bar, 26 Coarse Grinding Stone" https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,125,140,24,"bs-bronze-shortsword") -- guide 125-140: "24x Bronze Shortsword - 120 Bronze Bar, 96 Weak Flux, 48 Medium Leather" https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,140,150,10,"bs-bronze-warhammer") -- guide 140-150: "10x Bronze Warhammer - 80 Bronze Bar, 10 Strong Flux, 10 Medium Leather" https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,150,165,19,"bs-bronze-warhammer") -- guide 150-165: "19x Bronze Warhammer - 152 Bronze Bar, 19 Strong Flux, 19 Medium Leather" https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,165,175,15,"bs-green-iron-bracers") -- guide 165-175: "15x Green Iron Bracers - 90 Iron Bar, 15 Green Dye" https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,175,185,10,"bs-golden-scale-bracers") -- guide 175-185: "10x Golden Scale Bracers - 50 Steel Bar, 20 Heavy Grinding Stone"; uses the stones made at 100 https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,185,215,36,"bs-mithril-plate-pants") -- guide 185-215: "36x Mithril Plate Pants - 432 Mithril Bar" https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,185,200,15,"bs-steel-breastplate") -- guide 185-200 alternative: "15x Steel Breastplate - 240 Steel Bar, 45 Heavy Grinding Stone (135 Heavy Stone)" if 432 Mithril Bar cost more than about 478 Steel Bar, 135 Heavy Stone and 68 Solid Stone https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,200,215,17,"bs-steel-plate-helm") -- guide 200-215 alternative: "17x Steel Plate Helm - 238 Steel Bar, 17 Solid Grinding Stone (68 Solid Stone)"; same condition https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,215,225,10,"bs-heavy-mithril-breastplate") -- guide 215-225: "10x Heavy Mithril Breastplate - 160 Mithril Bar" https://www.wow-professions.com/forever/blacksmithing-leveling-guide
edge(164,215,225,10,"bs-mithril-spurs") -- guide 215-225 alternative: "10x Mithril Spurs - 40 Mithril Bar, 30 Solid Grinding Stone (120 Solid Stone)" only with Plans: Mithril Spurs https://www.wow-professions.com/forever/blacksmithing-leveling-guide
-- No faction-only recipe on this route: trainers differ by faction, recipes do not, and Green Dye has a vendor in each capital. No edges above 225: the guide publishes none for Forever.
local names={[2835]="Rough Stone",[2836]="Coarse Stone",[2838]="Heavy Stone",[7912]="Solid Stone",
    [2840]="Copper Bar",[2841]="Bronze Bar",[2842]="Silver Bar",[3575]="Iron Bar",[3859]="Steel Bar",[3860]="Mithril Bar",
    [2880]="Weak Flux",[3466]="Strong Flux",[2605]="Green Dye",[3857]="Coal",
    [3470]="Rough Grinding Stone",[3478]="Coarse Grinding Stone",[3486]="Heavy Grinding Stone",[7966]="Solid Grinding Stone"} -- 2319 Medium Leather is already in Data.lua
for id,name in pairs(names) do T.items[id]=name end

-- ===== Enchanting (333) =====
-- Enchanting (skill line 333) leveling data for TrailMats. Researched 2026-10-17, re-verified 2026-10-18.
-- Bands and craft counts: https://www.wow-professions.com/forever/enchanting-leveling-guide (beta route; the 225-300 section is marked "not tested yet" there).
-- Reagents and item ids: each recipe's https://www.wowhead.com/forever/spell=<id> page, read 2026-10-18 (ids in the trailing comments). Second source for the route: https://thewowdb.com/wow-forever/guides/professions/enchanting/ and https://seemeta.com/en/wow-forever/professions/enchanting (beta 1.60.1 recipe dump, updated 2026-10-17).
-- Bands are planning intervals, not exact learning requirements or color tables.

-- Apprentice 1-70 (capital or starting-zone trainer; no level requirement)
recipe("en-copper-rod",333,"Runed Copper Rod",{[6217]=1,[247786]=1},"Trainer",{6218,1}) -- spell 7421: Copper Rod 6217 x1, Mote of Magic 247786 x1 -> Runed Copper Rod 6218 (Forever: no Strange Dust/essence); same tuple on the guide and seemeta; https://www.wowhead.com/forever/spell=7421
recipe("en-bracer-inf-stam",333,"Enchant Bracer - Inferior Stamina",{[247786]=1},"Trainer") -- spell 7418 (Classic id of Enchant Bracer - Minor Health; Forever name Inferior Stamina): Mote of Magic x1; https://www.wowhead.com/forever/spell=7418
recipe("en-bracer-deflect",333,"Enchant Bracer - Minor Deflect",{[10938]=1},"Trainer") -- spell 7428: Lesser Magic Essence 10938 x1; https://www.wowhead.com/forever/spell=7428
recipe("en-chest-inf-stam",333,"Enchant Chest - Inferior Stamina",{[10940]=1},"Trainer") -- spell 7420 (Classic id of Enchant Chest - Minor Health; Forever name Inferior Stamina): Strange Dust 10940 x1; https://www.wowhead.com/forever/spell=7420
-- Journeyman 70-150 (capital trainers; Journeyman needs skill 50, level 10)
recipe("en-chest-absorb",333,"Enchant Chest - Minor Absorption",{[10938]=1},"Trainer") -- spell 7426: Lesser Magic Essence x1 only (Classic also took Strange Dust; Forever page and guide list essence only); https://www.wowhead.com/forever/spell=7426
recipe("en-bracer-min-stam",333,"Enchant Bracer - Minor Stamina",{[10940]=2},"Trainer") -- spell 7457: Strange Dust x2; https://www.wowhead.com/forever/spell=7457
recipe("en-cloak-prot",333,"Enchant Cloak - Minor Protection",{[10940]=2},"Trainer") -- spell 7771: Strange Dust x2; https://www.wowhead.com/forever/spell=7771
recipe("en-silver-rod",333,"Runed Silver Rod",{[6338]=1,[10940]=3,[10938]=4,[1210]=1},"Trainer",{6339,1}) -- spell 7795: Silver Rod 6338 x1 (Blacksmithing spell 7818, buy on AH), Strange Dust x3, Lesser Magic Essence x4, Shadowgem 1210 x1 -> Runed Silver Rod 6339; does not consume the Runed Copper Rod on Forever; https://www.wowhead.com/forever/spell=7795
recipe("en-2h-intellect",333,"Enchant 2H Weapon - Lesser Intellect",{[10938]=4},"Vendor formula: Kithas (Orgrimmar), Nata Dawnstrider (Thunder Bluff), Leo Sarn (Silverpine Forest), Tilli Thistlefuzz (Ironforge)") -- spell 7793: Lesser Magic Essence x4; formula item 6349 sold in Thunder Bluff, Orgrimmar, Ironforge, Silverpine Forest (both factions); https://www.wowhead.com/forever/spell=7793 https://www.wowhead.com/forever/item=6349
recipe("en-boots-min-stam",333,"Enchant Boots - Minor Stamina",{[10940]=4},"Trainer") -- spell 7863: Strange Dust x4; https://www.wowhead.com/forever/spell=7863
recipe("en-bracer-less-stam",333,"Enchant Bracer - Lesser Stamina",{[11083]=1},"Trainer") -- spell 13501: Soul Dust 11083 x1; https://www.wowhead.com/forever/spell=13501
-- Expert 150-225 (Hgarth, Sun Rock Retreat, Stonetalon Mountains for Horde; Kitta Firewind, Tower of Azora, Elwynn Forest for Alliance; needs skill 125, level 20)
recipe("en-golden-rod",333,"Runed Golden Rod",{[11128]=1,[5500]=1,[11082]=1,[11083]=1},"Expert trainer",{11130,1}) -- spell 13628: Golden Rod 11128 x1 (Blacksmithing spell 14379, buy on AH), Iridescent Pearl 5500 x1, Greater Astral Essence 11082 x1, Soul Dust x1 -> Runed Golden Rod 11130 (Forever halves the Classic essence/dust counts; guide agrees); https://www.wowhead.com/forever/spell=13628
recipe("en-minor-mana-oil",333,"Minor Mana Oil",{[11083]=1,[17034]=2,[3372]=1},"Vendor formula: Kithas (Orgrimmar), Nata Dawnstrider (Thunder Bluff), Thaddeus Webb (Undercity), Vaean (Darnassus), Tilli Thistlefuzz (Ironforge), Jessara Cordell (Stormwind City)",{20745,1}) -- spell 25125: Soul Dust x1, Maple Seed 17034 x2, Leaded Vial 3372 x1 -> Minor Mana Oil 20745; formula item 20752 sold in both factions' capitals plus Silithus, Silverpine, Zephras Isle; https://www.wowhead.com/forever/spell=25125 https://www.wowhead.com/forever/item=20752
recipe("en-boots-less-agi",333,"Enchant Boots - Lesser Agility",{[11083]=1},"Expert trainer") -- spell 13637: Soul Dust x1; https://www.wowhead.com/forever/spell=13637
recipe("en-bracer-str",333,"Enchant Bracer - Strength",{[11137]=1},"Expert trainer") -- spell 13661: Vision Dust 11137 x1; https://www.wowhead.com/forever/spell=13661
recipe("en-truesilver-rod",333,"Runed Truesilver Rod",{[11144]=1,[7971]=1,[11135]=1,[11137]=1},"Expert trainer",{11145,1}) -- spell 13702: Truesilver Rod 11144 x1 (Blacksmithing spell 14380, buy on AH), Black Pearl 7971 x1, Greater Mystic Essence 11135 x1, Vision Dust x1 -> Runed Truesilver Rod 11145 (Forever halves the Classic essence/dust counts; guide agrees); https://www.wowhead.com/forever/spell=13702
recipe("en-lesser-wizard-oil",333,"Lesser Wizard Oil",{[11137]=1,[17035]=2,[3372]=1},"Vendor formula: Kithas (Orgrimmar), Nata Dawnstrider (Thunder Bluff), Thaddeus Webb (Undercity), Vaean (Darnassus), Tilli Thistlefuzz (Ironforge), Jessara Cordell (Stormwind City)",{20746,1}) -- spell 25126: Vision Dust x1, Stranglethorn Seed 17035 x2, Leaded Vial x1 -> Lesser Wizard Oil 20746; formula item 20753, same vendors as Minor Mana Oil; https://www.wowhead.com/forever/spell=25126 https://www.wowhead.com/forever/item=20753
recipe("en-cloak-gdef",333,"Enchant Cloak - Greater Defense",{[11137]=1},"Expert trainer") -- spell 13746: Vision Dust x1; https://www.wowhead.com/forever/spell=13746
-- Artisan 225-300 (Annora, Uldaman, Badlands; needs skill 200, level 35; guide section untested in beta)
recipe("en-gloves-agi",333,"Enchant Gloves - Agility",{[11137]=1},"Expert or Artisan trainer") -- spell 13815: Vision Dust x1; Classic teaches it at 220 from Hgarth, Kitta Firewind and Annora; Forever trainer lists not published, unconfirmed; https://www.wowhead.com/forever/spell=13815
recipe("en-boots-stam",333,"Enchant Boots - Stamina",{[11137]=2},"Expert or Artisan trainer") -- spell 13836: Vision Dust x2; Classic teaches it at 225 from Hgarth, Kitta Firewind and Annora; Forever trainer lists not published, unconfirmed; https://www.wowhead.com/forever/spell=13836
recipe("en-chest-sup-stam",333,"Enchant Chest - Superior Stamina",{[11137]=3},"Expert or Artisan trainer; unconfirmed") -- spell 13858 (Classic id of Enchant Chest - Superior Health, Annora at 230; Forever name Superior Stamina): Vision Dust x3; https://www.wowhead.com/forever/spell=13858
recipe("en-lesser-mana-oil",333,"Lesser Mana Oil",{[11176]=1,[8831]=1,[8925]=1},"Vendor formula: Kania (Cenarion Hold inn, Silithus)",{20747,1}) -- spell 25127: Dream Dust 11176 x1, Purple Lotus 8831 x1, Crystal Vial 8925 x1 -> Lesser Mana Oil 20747; formula item 20754 sold in Silithus (and listed for Blackrock Depths); https://www.wowhead.com/forever/spell=25127 https://www.wowhead.com/forever/item=20754
recipe("en-bracer-gstr",333,"Enchant Bracer - Greater Strength",{[11176]=1,[11174]=2},"Artisan trainer") -- spell 13939: Dream Dust x1, Lesser Nether Essence 11174 x2; guide and TheWoWDB list it in Annora's table at 240; https://www.wowhead.com/forever/spell=13939
recipe("en-shield-gstam",333,"Enchant Shield - Greater Stamina",{[11176]=6},"Vendor formula: Daniel Bartlett (Undercity), Mythrin'dir (Darnassus); binds on pickup") -- spell 20017: Dream Dust x6; formula item 16217 sold in Undercity and Darnassus (both factions); BoP per guide and TheWoWDB, not shown on the item page; https://www.wowhead.com/forever/spell=20017 https://www.wowhead.com/forever/item=16217
recipe("en-arcanite-rod",333,"Runed Arcanite Rod",{[16206]=1,[13926]=1,[16204]=10,[16203]=4,[14343]=4,[14344]=2},"Vendor formula: Lorelae Wintersong (Nighthaven, Moonglade)",{16207,1}) -- spell 20051: Arcanite Rod 16206 x1 (Blacksmithing spell 20201, buy on AH), Golden Pearl 13926 x1, Illusion Dust 16204 x10, Greater Eternal Essence 16203 x4, Small Brilliant Shard 14343 x4, Large Brilliant Shard 14344 x2 -> Runed Arcanite Rod 16207; formula item 16243 sold in Moonglade; https://www.wowhead.com/forever/spell=20051 https://www.wowhead.com/forever/item=16243
recipe("en-cloak-sdef",333,"Enchant Cloak - Superior Defense",{[16204]=8},"Vendor formula: Lorelae Wintersong (Nighthaven, Moonglade)") -- spell 20015: Illusion Dust x8; formula item 16224 sold in Moonglade; https://www.wowhead.com/forever/spell=20015 https://www.wowhead.com/forever/item=16224

-- Bands and counts: https://www.wow-professions.com/forever/enchanting-leveling-guide unless noted. Alternatives in the same band are separate edges.
edge(333,1,2,1,"en-copper-rod") -- guide 1-2: 1 craft
edge(333,2,20,18,"en-bracer-inf-stam") -- guide 2-20: 18 crafts
edge(333,20,70,50,"en-bracer-deflect") -- guide 20-70 essence option: 50 crafts
edge(333,20,70,50,"en-chest-inf-stam") -- guide 20-70 dust option: 50 crafts
edge(333,70,100,33,"en-chest-absorb") -- guide 70-100 essence path: 33 crafts
edge(333,70,100,30,"en-bracer-min-stam") -- guide 70-100 dust path: 30 crafts
edge(333,100,109,18,"en-chest-absorb") -- guide 100-109 essence path: 18 crafts (guide count already allows for the yellow tail)
edge(333,100,109,9,"en-cloak-prot") -- guide 100-109 dust path: 9 crafts
edge(333,109,110,1,"en-silver-rod") -- guide 109-110: 1 craft, both paths
edge(333,110,130,20,"en-2h-intellect") -- guide 110-130 essence path: 20 crafts
edge(333,110,130,32,"en-cloak-prot") -- guide 110-130 dust path / no-formula alternative: 32 crafts
edge(333,130,150,32,"en-2h-intellect") -- guide 130-150 essence path: 32 crafts
edge(333,130,150,20,"en-boots-min-stam") -- guide 130-150 dust path / no-formula alternative: 20 crafts
edge(333,130,150,20,"en-bracer-less-stam") -- guide 130-150 alternative "if Soul Dust is cheaper than 80 Strange Dust": 20 crafts
edge(333,150,151,1,"en-golden-rod") -- guide 150-151: 1 craft
edge(333,151,165,16,"en-minor-mana-oil") -- guide 151-165: 16 crafts
edge(333,165,185,22,"en-boots-less-agi") -- guide 165-185: 22 crafts
edge(333,185,200,15,"en-bracer-str") -- guide 185-200: 15 crafts
edge(333,185,200,22,"en-boots-less-agi") -- guide beta note on the 165-185 step: "keep making these until 200, it takes around 22 more" (Soul Dust cheaper than Vision Dust at the beta cap)
edge(333,200,201,1,"en-truesilver-rod") -- guide 200-201: 1 craft
edge(333,201,220,25,"en-lesser-wizard-oil") -- guide 201-220: 25 crafts
edge(333,220,225,5,"en-cloak-gdef") -- guide 220-225: 5 crafts
edge(333,225,230,5,"en-gloves-agi") -- guide 225-230: 5 crafts (Artisan section untested in beta; TheWoWDB agrees, yellow at 230)
edge(333,230,235,5,"en-boots-stam") -- guide 230-235: 5 crafts (untested; TheWoWDB agrees, yellow at 235)
edge(333,235,250,20,"en-chest-sup-stam") -- guide 235-250: 20 crafts (untested; TheWoWDB agrees, yellow at 240)
edge(333,250,265,20,"en-lesser-mana-oil") -- guide 250-265: 20 crafts (untested; TheWoWDB agrees, yellow at 260)
edge(333,250,265,20,"en-bracer-gstr") -- guide 250-265 "if you don't have Purple Lotus" alternative, no count given there; 20 crafts from https://thewowdb.com/wow-forever/guides/professions/enchanting/ (yellow at 260, read 2026-10-18)
edge(333,265,294,32,"en-shield-gstam") -- guide 265-294: 32 crafts (untested; TheWoWDB agrees, yellow at 285)
edge(333,294,295,1,"en-arcanite-rod") -- guide 294-295: 1 craft (untested)
edge(333,295,300,5,"en-cloak-sdef") -- guide 295-300: 5 crafts (untested; TheWoWDB agrees)
edge(333,295,300,8,"en-shield-gstam") -- guide 295-300 alternative "if you have a lot of Dream Dust or Illusion Dust is really expensive", no count on the guide or TheWoWDB; estimate 8 crafts for this 5-point band because the recipe is yellow from 285 (265-294 averages 1.1 crafts/point while orange)

local names={[6217]="Copper Rod",[247786]="Mote of Magic",[6218]="Runed Copper Rod",
    [10938]="Lesser Magic Essence",[10940]="Strange Dust",[6338]="Silver Rod",[1210]="Shadowgem",
    [6339]="Runed Silver Rod",[11083]="Soul Dust",[11128]="Golden Rod",[5500]="Iridescent Pearl",
    [11082]="Greater Astral Essence",[11130]="Runed Golden Rod",[17034]="Maple Seed",[3372]="Leaded Vial",
    [20745]="Minor Mana Oil",[11137]="Vision Dust",[11144]="Truesilver Rod",[7971]="Black Pearl",
    [11135]="Greater Mystic Essence",[11145]="Runed Truesilver Rod",[17035]="Stranglethorn Seed",
    [20746]="Lesser Wizard Oil",[11176]="Dream Dust",[8831]="Purple Lotus",[8925]="Crystal Vial",
    [20747]="Lesser Mana Oil",[11174]="Lesser Nether Essence",[16206]="Arcanite Rod",[13926]="Golden Pearl",
    [16204]="Illusion Dust",[16203]="Greater Eternal Essence",[14343]="Small Brilliant Shard",
    [14344]="Large Brilliant Shard",[16207]="Runed Arcanite Rod"}
for id,name in pairs(names) do T.items[id]=name end
-- Vendor reagents, each confirmed on its Forever item page's vendor-location list 2026-10-18: Copper Rod and Mote of Magic (Enchanting Supply vendors beside the trainers), Maple Seed and Stranglethorn Seed (general reagent vendors), Leaded Vial and Crystal Vial (alchemy supply vendors).
-- The Silver, Golden, Truesilver and Arcanite rods are Blacksmithing crafts (spells 7818, 14379, 14380, 20201), not vendor items. No route recipe consumes another route recipe's output, so there are no conversions.

-- ===== Tailoring (197) =====
recipe("ta-bolt-linen",197,"Bolt of Linen Cloth",{[2589]=2},"Trainer",{2996,1}) -- https://www.wowhead.com/forever/spell=2963/bolt-of-linen-cloth (2x Linen Cloth 2589 -> 2996) ; learned with Apprentice Tailoring per https://seemeta.com/en/wow-forever/professions/tailoring (1.60.1 beta; yellow 25 / green 38 / grey 50) ; conversion 2996 -> ta-bolt-linen ; guide crafts it 1-30
recipe("ta-linen-belt",197,"Linen Belt",{[2996]=1,[2320]=1},"Trainer") -- https://www.wowhead.com/forever/spell=8776/linen-belt (1x Bolt of Linen Cloth 2996, 1x Coarse Thread 2320) ; seemeta: no recipe item, trainer; yellow 50 / green 68 / grey 85 ; guide 30-55
recipe("ta-bolt-wool",197,"Bolt of Woolen Cloth",{[2592]=3},"Trainer",{2997,1}) -- https://www.wowhead.com/forever/spell=2964/bolt-of-woolen-cloth (3x Wool Cloth 2592 -> 2997) ; seemeta: trainer; yellow 70 / green 78 / grey 85 ; conversion 2997 -> ta-bolt-wool ; guide 55-80, learn Journeyman (skill 50, level 10) first
recipe("ta-woolen-cape",197,"Woolen Cape",{[2997]=1,[2321]=1},"Trainer") -- https://www.wowhead.com/forever/spell=2402/woolen-cape (1x Bolt of Woolen Cloth 2997, 1x Fine Thread 2321) ; seemeta: trainer; yellow 80 / green 98 / grey 115 ; guide 80-95
recipe("ta-ds-shoulders",197,"Double-stitched Woolen Shoulders",{[2997]=3,[2321]=2},"Trainer") -- https://www.wowhead.com/forever/spell=3848/double-stitched-woolen-shoulders (3x Bolt of Woolen Cloth 2997, 2x Fine Thread 2321; item 4314 is spelled "Double-Stitched", the spell is "Double-stitched") ; seemeta: trainer; yellow 110 / green 128 / grey 145 ; guide 95-100, 120-125 and the 100-125 beta alternative
recipe("ta-bolt-silk",197,"Bolt of Silk Cloth",{[4306]=4},"Trainer",{4305,1}) -- https://www.wowhead.com/forever/spell=3839/bolt-of-silk-cloth (4x Silk Cloth 4306 -> 4305) ; seemeta: trainer; yellow 110 / green 115 / grey 120 (Forever: guide crafts it 100-120, Classic needed skill 125) ; conversion 4305 -> ta-bolt-silk
recipe("ta-gloves-meditation",197,"Gloves of Meditation",{[2997]=4,[2321]=3,[3383]=1},"Trainer") -- https://www.wowhead.com/forever/spell=3852/gloves-of-meditation (4x Bolt of Woolen Cloth 2997, 3x Fine Thread 2321, 1x Elixir of Wisdom 3383; the page expands 3383 to Alchemy spell 3171 Mageroyal+Briarthorn+Empty Vial, so it is AH/Alchemy, not vendor) ; seemeta: trainer; yellow 125 / green 140 / grey 155 ; guide 125-140 ("yellow the whole way") and the 140-150 alternative; the guide's Expert visit (Forever Expert needs skill 125, level 20, 50s) is placed right before this step
recipe("ta-bolt-mageweave",197,"Bolt of Mageweave",{[4338]=5},"Trainer",{4339,1}) -- https://www.wowhead.com/forever/spell=3865/bolt-of-mageweave (5x Mageweave Cloth 4338 -> 4339) ; seemeta: no recipe item, trainer; yellow 145 / green 148 / grey 150 (Classic needed 175) ; conversion 4339 -> ta-bolt-mageweave ; guide 140-150 crafts it below skill 150, so it is a sub-Expert recipe (rank unconfirmed, see notes); beta note: Mageweave Cloth is rare, the guide says buy bolts on the AH
recipe("ta-crimson-vest",197,"Crimson Silk Vest",{[4305]=4,[2604]=2,[2321]=2},"Expert trainer") -- https://www.wowhead.com/forever/spell=8791/crimson-silk-vest (4x Bolt of Silk Cloth 4305, 2x Red Dye 2604, 2x Fine Thread 2321) ; seemeta: no recipe item, trainer; yellow 170 / green 180 / grey 190, so skill >150 and Expert rank ; guide 150-170
recipe("ta-crimson-pants",197,"Crimson Silk Pantaloons",{[4305]=4,[2604]=2,[4291]=2},"Expert trainer") -- https://www.wowhead.com/forever/spell=8799/crimson-silk-pantaloons (4x Bolt of Silk Cloth 4305, 2x Red Dye 2604, 2x Silken Thread 4291) ; seemeta: trainer; yellow 180 / green 190 / grey 200 ; guide 170-190 ("yellow at 180")
recipe("ta-red-shirt",197,"Red Swashbuckler's Shirt",{[4305]=3,[2604]=2,[4291]=1},"Trainer") -- https://www.wowhead.com/forever/spell=8489/red-swashbucklers-shirt (3x Bolt of Silk Cloth 4305, 2x Red Dye 2604, 1x Silken Thread 4291); trainer recipe at 140, verified 2026-10-18
recipe("ta-black-mw-gloves",197,"Black Mageweave Gloves",{[4339]=2,[8343]=2},"Expert trainer") -- https://www.wowhead.com/forever/spell=12053/black-mageweave-gloves (2x Bolt of Mageweave 4339, 2x Heavy Silken Thread 8343) ; seemeta: trainer; yellow 195 / green 210 / grey 225 ; guide 190-215
recipe("ta-mageweave-bag",197,"Mageweave Bag",{[4339]=4,[4291]=2},"Expert trainer") -- https://www.wowhead.com/forever/spell=12065/mageweave-bag (4x Bolt of Mageweave 4339, 2x Silken Thread 4291) ; seemeta row read on 2026-10-17: trainer; yellow 205 / green 220 / grey 235 (green for the last five points, hence 26 crafts) ; guide 215-225
edge(197,1,30,30,"ta-bolt-linen") -- https://www.wow-professions.com/forever/tailoring-leveling-guide 1-30: "30x Bolt of Linen Cloth - 60 Linen Cloth"; keep every bolt for the belts
edge(197,30,55,28,"ta-linen-belt") -- guide 30-55: "28x Linen Belt - 28 Bolt of Linen Cloth, 28 Coarse Thread" (https://www.wow-professions.com/forever/tailoring-leveling-guide)
edge(197,55,80,45,"ta-bolt-wool") -- guide 55-80: "45x Bolt of Woolen Cloth - 135 Wool Cloth"; the guide totals 153 bolts until 140, the rest are extra intermediate crafts (https://www.wow-professions.com/forever/tailoring-leveling-guide, re-read 2026-10-18)
edge(197,80,95,22,"ta-woolen-cape") -- guide 80-95: "22x Woolen Cape - 22 Bolt of Woolen Cloth, 22 Fine Thread" (https://www.wow-professions.com/forever/tailoring-leveling-guide)
edge(197,95,100,5,"ta-ds-shoulders") -- guide 95-100: "5x Double-stitched Woolen Shoulders - 15 Bolt of Woolen Cloth, 10 Fine Thread" (https://www.wow-professions.com/forever/tailoring-leveling-guide)
edge(197,100,120,54,"ta-bolt-silk") -- guide 100-120: "54x Bolt of Silk Cloth - 216 Silk Cloth"; 184 bolts needed until 190, the rest are extra intermediate crafts (guide revised between 2026-10-17 and 10-18: was 40x; https://www.wow-professions.com/forever/tailoring-leveling-guide)
edge(197,100,125,29,"ta-ds-shoulders") -- guide beta alternative 100-125 (skip the bolts if not levelling past 150): "29x Double-stitched Woolen Shoulders - 87 Bolt of Woolen Cloth, 58 Fine Thread" (https://www.wow-professions.com/forever/tailoring-leveling-guide)
edge(197,120,125,5,"ta-gloves-meditation") -- guide 120-125 (2026-10-18): "5x Gloves of Meditation - 20 Bolt of Woolen Cloth, 15 Fine Thread, 5 Elixir of Wisdom" (https://www.wow-professions.com/forever/tailoring-leveling-guide)
edge(197,120,125,8,"ta-ds-shoulders") -- alternative without Elixir of Wisdom: Double-stitched Woolen Shoulders stay yellow through 125 (seemeta); 8 crafts is an estimate
edge(197,125,140,24,"ta-gloves-meditation") -- guide 125-140: "24x Gloves of Meditation - 96 Bolt of Woolen Cloth, 72 Fine Thread, 24 Elixir of Wisdom"; "yellow the whole way, so you might need a few more" (revised from 20x; https://www.wow-professions.com/forever/tailoring-leveling-guide)
edge(197,140,150,23,"ta-bolt-mageweave") -- guide 140-150: "23x Bolt of Mageweave - 115 Mageweave Cloth"; 180 bolts needed by 225, the rest are extra intermediate crafts (revised from 17x; https://www.wow-professions.com/forever/tailoring-leveling-guide)
edge(197,140,150,10,"ta-red-shirt") -- guide alternative 140-150 when Mageweave Cloth is scarce: "10x Red Swashbuckler's Shirt - 30 Bolt of Silk Cloth, 20 Red Dye, 10 Silken Thread" (https://www.wow-professions.com/forever/tailoring-leveling-guide)
edge(197,150,170,20,"ta-crimson-vest") -- guide 150-170: "20x Crimson Silk Vest - 80 Bolt of Silk Cloth, 40 Red Dye, 40 Fine Thread" (https://www.wow-professions.com/forever/tailoring-leveling-guide)
edge(197,170,190,26,"ta-crimson-pants") -- guide 170-190: "26x Crimson Silk Pantaloons - 104 Bolt of Silk Cloth, 52 Red Dye, 52 Silken Thread"; "turn yellow at 180, so you might need a few more" (revised from 24x; https://www.wow-professions.com/forever/tailoring-leveling-guide)
edge(197,190,215,38,"ta-black-mw-gloves") -- guide 190-215: "38x Black Mageweave Gloves - 76 Bolt of Mageweave, 76 Heavy Silken Thread" (https://www.wow-professions.com/forever/tailoring-leveling-guide)
edge(197,215,225,26,"ta-mageweave-bag") -- guide 215-225: "26x Mageweave Bag - 104 Bolt of Mageweave, 52 Silken Thread"; last step published, Artisan 225-300 "can't be tested on the beta right now" (https://www.wow-professions.com/forever/tailoring-leveling-guide)
local names={[2996]="Bolt of Linen Cloth",[2997]="Bolt of Woolen Cloth",[4305]="Bolt of Silk Cloth",[4339]="Bolt of Mageweave",
    [2321]="Fine Thread",[8343]="Heavy Silken Thread",[2604]="Red Dye",[3383]="Elixir of Wisdom"} -- 2589, 2592, 2320 are named in Data.lua; 4306, 4338, 4291 already in the LevelingData names block
for id,name in pairs(names) do T.items[id]=name end

-- ===== Engineering (202) =====
-- Engineering (skill line 202) leveling data for TrailMats, researched 2026-10-17/18 against the Forever beta (client 1.60.1).
-- Bands, craft counts, alternatives, keep notes and schematic vendors: https://www.wow-professions.com/forever/engineering-leveling-guide
--   (re-read 2026-10-18). The author walked 1-215 on the beta: "the beta
--   stops at 225 right now" and "The route after 225 is not tested yet"; 215-300 is the Classic route carried over unchanged, kept here
--   because the guide publishes it. Shopping list 1-225 / 225-300 totals are reproduced by the edges below.
-- Reagents and item ids: each recipe cites its https://www.wowhead.com/forever/spell=<id> page (all 28 read 2026-10-18; the page markdown
--   inlines the reagent tree of sub-recipes, e.g. Smelt Copper under Copper Bar, which is not part of the recipe) and the same reagents were
--   re-read from Wowhead's Forever tooltip data (https://nether.wowhead.com/tooltip/spell/<id>?dataEnv=16&locale=0). Forever spell pages carry no "Requires Engineering" line and no trainer list; the tooltips do carry the former.
-- Learn levels, colours and trainer source: https://seemeta.com/en/wow-forever/professions/engineering (game version 1.60.1 beta, updated
--   2026-10-17): "No recipe item, usually learned from a trainer" unless noted. Its colour digits print without separators, so a split
--   marked "(split)" follows the row structure and the Classic pattern. https://thewowdb.com/wow-forever/guides/professions/engineering/
--   (client 1.60.1.70205) was read on 2026-10-17 for the same values and answered HTTP 503 on every 2026-10-18 re-check; figures
--   attributed to it alone are single-source.
-- Yields: Forever tooltips print a count one higher than the real yield for every recipe (Rough Blasting Powder "(2)", Blacksmithing armor
--   "(2)"), so yields come from the guide's arithmetic (60 Rough Stone -> 60 powder for 30 bombs x2, 120 Solid Stone -> 60 powder,
--   120 Mithril Bar -> 40 casings: one per craft for every intermediate) and from seemeta's bold yield numbers (Rough Copper Bomb 2,
--   Coarse Dynamite 2, Silver Contact 5, Gold Power Core 3, Iron Grenade 3, Hi-Explosive Bomb 4). Live scans override reference outputs (Leveling.lua).
-- Bars are Mining smelts and stones are Mining by-products; both are gathered raw materials here. Blacksmith Hammer (5956), Arclight Spanner
--   (6219) and Gyromatic Micro-Adjustor (10498) are tools, not reagents; the two crafted tools are one-craft edges because the guide levels
--   through them. Weak Flux (2880) is the only vendor supply consumed on this route (Wooden Stock 4399 / Heavy Stock 4400 are gun parts
--   no route recipe uses). The Gnome racial no longer gives +15 Engineering in Forever (guide), so no race adjustment applies.
-- Apprentice (guide heading 1-50; any Engineering trainer, no level requirement in Forever; Journeyman needs skill 50 and level 10)
recipe("eg-rough-powder",202,"Rough Blasting Powder",{[2835]=1},"Trainer",{4357,1}) -- https://www.wowhead.com/forever/spell=3918/rough-blasting-powder : Rough Stone 2835 x1 -> 4357; seemeta: learned automatically with the profession rank, orange 1 / yellow 20 / green 30 / grey 40 (thewowdb 2026-10-17: yellow 20, grey 40); guide: keep all 60 for the bombs at 51
recipe("eg-copper-bolts",202,"Handful of Copper Bolts",{[2840]=1},"Trainer",{4359,1}) -- https://www.wowhead.com/forever/spell=3922/handful-of-copper-bolts : Copper Bar 2840 x1 -> 4359; tool Blacksmith Hammer; seemeta (split): trainer, yellow 45 / green 53 / grey 60; guide: keep all 30 for the bombs
recipe("eg-spanner",202,"Arclight Spanner",{[2840]=6},"Trainer") -- https://www.wowhead.com/forever/spell=7430/arclight-spanner : Copper Bar x6 -> 6219; tooltip "Requires Engineering (50)"; seemeta (split): trainer, yellow 70 / green 80 / grey 90; a tool, keep it; not consumed, so no output
recipe("eg-rough-bomb",202,"Rough Copper Bomb",{[2840]=1,[4359]=1,[4357]=2,[2589]=1},"Trainer") -- https://www.wowhead.com/forever/spell=3923/rough-copper-bomb : Copper Bar x1, Handful of Copper Bolts x1, Rough Blasting Powder x2, Linen Cloth 2589 x1 -> 4360; tooltip "Requires Engineering (30)"; seemeta (split): trainer, yield 2, yellow 60 / green 75 / grey 90 (guide: "yellow from 60")
-- Journeyman (guide heading 50-150; the rank is needed to pass 75: Nogg, Orgrimmar / Franklin Lloyd, Undercity / Lilliam Sparkspindle, Stormwind / Trixie Quikswitch, Ironforge / Finbus Geargrind, Duskwood)
recipe("eg-coarse-powder",202,"Coarse Blasting Powder",{[2836]=1},"Trainer",{4364,1}) -- https://www.wowhead.com/forever/spell=3929/coarse-blasting-powder : Coarse Stone 2836 x1 -> 4364; seemeta: trainer, yellow 85 / green 90 / grey 95; guide: keep all 60 for the dynamite at 90
recipe("eg-coarse-dynamite",202,"Coarse Dynamite",{[4364]=3,[2589]=1},"Trainer") -- https://www.wowhead.com/forever/spell=3931/coarse-dynamite : Coarse Blasting Powder x3, Linen Cloth x1 -> 4365; tooltip "Requires Engineering (75)"; seemeta (split): trainer, yield 2 (Classic 1; thewowdb 2026-10-17 also 2), yellow 90 / green 98 / grey 105
recipe("eg-silver-contact",202,"Silver Contact",{[2842]=1},"Trainer") -- https://www.wowhead.com/forever/spell=3973/silver-contact : Silver Bar 2842 x1 -> 4404; seemeta (split): trainer, yield 5, yellow 110 / green 125 / grey 140; not consumed on this route, so no output
recipe("eg-tiger-goggles",202,"Flying Tiger Goggles",{[2318]=6,[818]=2},"Trainer") -- https://www.wowhead.com/forever/spell=3934/flying-tiger-goggles : Light Leather 2318 x6, Tigerseye 818 x2 -> 4368; tooltip "Requires Engineering (100)"; tool Arclight Spanner; seemeta (split): trainer, yellow 130 / green 145 / grey 160
recipe("eg-bronze-tube",202,"Bronze Tube",{[2841]=2,[2880]=1},"Trainer",{4371,1}) -- https://www.wowhead.com/forever/spell=3938/bronze-tube : Bronze Bar 2841 x2, Weak Flux 2880 x1 -> 4371; seemeta (split): trainer, yellow 105 / green 130 / grey 155 (guide: "yellow the whole way"); Weak Flux is sold by Engineering Supply vendors near the trainer (guide; https://www.wowhead.com/forever/item=2880/weak-flux lists vendors in dozens of zones)
recipe("eg-standard-scope",202,"Standard Scope",{[4371]=1,[1206]=1},"Trainer") -- https://www.wowhead.com/forever/spell=3978/standard-scope : Bronze Tube x1, Moss Agate 1206 x1 -> 4406; tool Arclight Spanner; seemeta (split): trainer, yellow 135 / green 148 / grey 160
recipe("eg-heavy-powder",202,"Heavy Blasting Powder",{[2838]=1},"Trainer",{4377,1}) -- https://www.wowhead.com/forever/spell=3945/heavy-blasting-powder : Heavy Stone 2838 x1 -> 4377; seemeta (split): trainer, yellow 125 / green 135 / grey 145 (thewowdb 2026-10-17: yellow 125, grey 145)
recipe("eg-gizmo",202,"Whirring Bronze Gizmo",{[2841]=2,[2592]=1},"Trainer",{4375,1}) -- https://www.wowhead.com/forever/spell=3942/whirring-bronze-gizmo : Bronze Bar x2, Wool Cloth 2592 x1 -> 4375; tools Blacksmith Hammer, Arclight Spanner; seemeta (split): trainer, yellow 125 / green 150 / grey 175; the guide crafts it 135-150
recipe("eg-framework",202,"Bronze Framework",{[2841]=2,[2319]=1,[2592]=1},"Trainer",{4382,1}) -- https://www.wowhead.com/forever/spell=3953/bronze-framework : Bronze Bar x2, Medium Leather 2319 x1, Wool Cloth x1 -> 4382; seemeta (split): trainer, yellow 145 / green 170 / grey 195; the guide crafts it 150-160 under its Expert heading, learnable from a Journeyman trainer at 145 (seemeta)
-- Expert (150-200): Roxxik, Orgrimmar / Springspindle Fizzlegear, Ironforge; needs skill 125, level 20, 50 silver (guide)
recipe("eg-sheep",202,"Explosive Sheep",{[4382]=1,[4375]=1,[4377]=2,[2592]=2},"Expert trainer") -- https://www.wowhead.com/forever/spell=3955/explosive-sheep : Bronze Framework x1, Whirring Bronze Gizmo x1, Heavy Blasting Powder x2, Wool Cloth x2 -> 4384; tooltip "Requires Engineering (150)"; tools Blacksmith Hammer, Arclight Spanner; seemeta (split): trainer, yellow 175 / green 188 / grey 200; guide: keep 5 for the Goblin Engineering quest at 200
recipe("eg-solid-powder",202,"Solid Blasting Powder",{[7912]=2},"Expert trainer",{10505,1}) -- https://www.wowhead.com/forever/spell=12585/solid-blasting-powder : Solid Stone 7912 x2 -> 10505; seemeta: trainer, yellow 175 / green 185 / grey 195 (thewowdb 2026-10-17: yellow 175, grey 195); guide: save them for Unstable Trigger and Hi-Explosive Bomb
recipe("eg-iron-grenade",202,"Iron Grenade",{[3575]=1,[4377]=1,[4306]=1},"Expert trainer") -- https://www.wowhead.com/forever/spell=3962/iron-grenade : Iron Bar 3575 x1, Heavy Blasting Powder x1, Silk Cloth 4306 x1 -> 4390; tooltip "Requires Engineering (175)"; seemeta (split): trainer, yield 3 (Classic 2; thewowdb 2026-10-17 also 3), yellow 175 / green 195 / grey 215; seemeta's row was read twice as "Heavy Blasting Powder 3", which the spell page, the tooltip and the guide (20 grenades = 20 powder) all contradict, so 1 is kept
recipe("eg-micro-adjustor",202,"Gyromatic Micro-Adjustor",{[3859]=4},"Expert trainer") -- https://www.wowhead.com/forever/spell=12590/gyromatic-micro-adjustor : Steel Bar 3859 x4 -> 10498; seemeta: trainer, yellow 175 / green 195 / grey 215; a tool, keep it; not consumed, so no output
recipe("eg-mithril-tube",202,"Mithril Tube",{[3860]=3},"Expert trainer") -- https://www.wowhead.com/forever/spell=12589/mithril-tube : Mithril Bar 3860 x3 -> 10559; seemeta: trainer, yellow 195 / green 215 / grey 235; guide: keep all 6 for the Gnomish Engineering quest at 200; no route recipe consumes it, so no output
-- Artisan (200-300): Buzzek Bracketswing, Gadgetzan (Tanaris), both factions; needs skill 200 and level 35, and "He also teaches the recipes above 200" (guide)
recipe("eg-trigger",202,"Unstable Trigger",{[3860]=1,[4338]=1,[10505]=1},"Artisan trainer",{10560,1}) -- https://www.wowhead.com/forever/spell=12591/unstable-trigger : Mithril Bar x1, Mageweave Cloth 4338 x1, Solid Blasting Powder x1 -> 10560; tools Blacksmith Hammer, Arclight Spanner; seemeta (split): trainer, yellow 200 / green 220 / grey 240; guide: Buzzek teaches it, keep all 20 for the bombs at 238
recipe("eg-casing",202,"Mithril Casing",{[3860]=3},"Artisan trainer",{10561,1}) -- https://www.wowhead.com/forever/spell=12599/mithril-casing : Mithril Bar x3 -> 10561; tools Blacksmith Hammer, Arclight Spanner; seemeta (split): trainer, yellow 215 / green 235 / grey 255; guide: keep 40 for the bombs
recipe("eg-hi-explosive",202,"Hi-Explosive Bomb",{[10561]=2,[10560]=1,[10505]=2},"Artisan trainer") -- https://www.wowhead.com/forever/spell=12619/hi-explosive-bomb : Mithril Casing x2, Unstable Trigger x1, Solid Blasting Powder x2 -> 10562; tooltip "Requires Engineering (235)"; seemeta: trainer, yield 4, yellow 235 / green 255 / grey 275
recipe("eg-dense-powder",202,"Dense Blasting Powder",{[12365]=2},"Artisan trainer") -- https://www.wowhead.com/forever/spell=19788/dense-blasting-powder : Dense Stone 12365 x2 -> 15992; seemeta: trainer, yellow 250 / green 255 / grey 260 (guide: "yellow from 250, so you might need more than 30"); not consumed on this route, so no output
recipe("eg-widget",202,"Thorium Widget",{[12359]=3,[14047]=1},"Vendor schematic: Sovik (Orgrimmar) or Gearcutter Cogspinner (Ironforge)") -- https://www.wowhead.com/forever/spell=19791/thorium-widget : Thorium Bar 12359 x3, Runecloth 14047 x1 -> 15994; tools Blacksmith Hammer, Arclight Spanner; https://www.wowhead.com/forever/item=16042/schematic-thorium-widget "Requires Engineering (260)", not bound, "can be purchased in Orgrimmar (3) and Ironforge (2)"; seemeta: Schematic: Thorium Widget skill 260, orange 260 / yellow 280 / green 290 / grey 300; vendor names from the guide; not consumed on this route
recipe("eg-thorium-tube",202,"Thorium Tube",{[12359]=6},"Vendor schematic: Xizzer Fizzbolt (Everlook, Winterspring); bind on pickup") -- https://www.wowhead.com/forever/spell=19795/thorium-tube : Thorium Bar x6 -> 16000; https://www.wowhead.com/forever/item=16047/schematic-thorium-tube "Binds when picked up", "Requires Engineering (275)", "can be purchased in Winterspring (2) and Riverglades"; seemeta: Schematic: Thorium Tube skill 275, orange 275 / yellow 295 / green 305 / grey 315; guide: "buy it with the character that levels Engineering"
-- Off-route intermediates from the task hint; no edge uses them, they exist so the planner can convert them if a later recipe needs them.
recipe("eg-copper-tube",202,"Copper Tube",{[2840]=2,[2880]=1},"Trainer",{4361,1}) -- https://www.wowhead.com/forever/spell=3924/copper-tube : Copper Bar x2, Weak Flux x1 -> 4361; seemeta (split): trainer, yellow 80 / green 95 / grey 110
recipe("eg-iron-strut",202,"Iron Strut",{[3575]=2},"Trainer",{4387,1}) -- https://www.wowhead.com/forever/spell=3958/iron-strut : Iron Bar x2 -> 4387; seemeta: trainer, yellow 160 / green 170 / grey 180
recipe("eg-power-core",202,"Gold Power Core",{[3577]=1},"Trainer",{10558,3}) -- https://www.wowhead.com/forever/spell=12584/gold-power-core : Gold Bar 3577 x1 -> 10558; seemeta: trainer, bold yield 3, yellow 150 / green 170 / grey 190; the Forever tooltip prints "(4)", one higher as for every recipe
recipe("eg-gyrochronatom",202,"Gyrochronatom",{[3575]=1,[10558]=1},"Trainer",{4389,1}) -- https://www.wowhead.com/forever/spell=3961/gyrochronatom : Iron Bar x1, Gold Power Core x1 -> 4389; seemeta: trainer, yellow 170 / green 190 / grey 210
-- Edges: whole-band guide counts; the planner scales them to the skill actually covered (Leveling.lua).
edge(202,1,30,60,"eg-rough-powder") -- guide 1-30: "60x Rough Blasting Powder - 60 Rough Stone"; keep all 60 for the bombs at 51 https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,30,50,30,"eg-copper-bolts") -- guide 30-50: "30x Handful of Copper Bolts - 30 Copper Bar"; keep all 30 for the bombs https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,50,51,1,"eg-spanner") -- guide 50-51: "1x Arclight Spanner - 6 Copper Bar"; a tool for later recipes, keep it https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,51,75,30,"eg-rough-bomb") -- guide 51-75: "30x Rough Copper Bomb - 30 Copper Bar, 30 Handful of Copper Bolts, 60 Rough Blasting Powder, 30 Linen Cloth"; yellow from 60, may overshoot or fall short of 75, learn Journeyman first https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,75,90,60,"eg-coarse-powder") -- guide 75-90: "60x Coarse Blasting Powder - 60 Coarse Stone"; keep all 60 for the dynamite at 90 https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,90,100,20,"eg-coarse-dynamite") -- guide 90-100: "20x Coarse Dynamite - 60 Coarse Blasting Powder, 20 Linen Cloth" https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,100,105,5,"eg-silver-contact") -- guide 100-105: "5x Silver Contact - 5 Silver Bar" https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,100,105,5,"eg-tiger-goggles") -- guide 100-105 alternative "If Silver Bar is expensive": "5x Flying Tiger Goggles - 30 Light Leather, 10 Tigerseye" https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,105,125,25,"eg-bronze-tube") -- guide 105-125: "25x Bronze Tube - 50 Bronze Bar, 25 Weak Flux"; yellow the whole way, if a few points short start the scopes instead https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,125,135,10,"eg-standard-scope") -- guide 125-135: "10x Standard Scope - 10 Bronze Tube, 10 Moss Agate"; uses 10 of the tubes just made https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,125,135,20,"eg-heavy-powder") -- guide 125-135 alternative "if you don't have any Moss Agate, or it's really expensive": Heavy Blasting Powder with no count given; 20 crafts is an estimate for 10 yellow/green points (seemeta yellow 125, green 135), not a guide figure https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,135,145,30,"eg-heavy-powder") -- guide 135-150 "Make both of these ... in the same order": "30x Heavy Blasting Powder - 30 Heavy Stone"; split at its grey point 145 (seemeta/thewowdb), keep all 30 for the sheep https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,145,150,15,"eg-gizmo") -- guide 135-150 second half: "15x Whirring Bronze Gizmo - 30 Bronze Bar, 15 Wool Cloth"; keep all 15 for the sheep; the 145 split is a modelling choice, the guide gives one 135-150 band https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,150,160,15,"eg-framework") -- guide 150-160: "15x Bronze Framework - 30 Bronze Bar, 15 Medium Leather, 15 Wool Cloth"; keep all 15 for the sheep, "will probably take you past 160" https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,160,175,15,"eg-sheep") -- guide 160-175: "15x Explosive Sheep - 30 Heavy Blasting Powder, 15 Whirring Bronze Gizmo, 15 Bronze Framework, 30 Wool Cloth"; keep 5 for Goblin Engineering https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,175,194,60,"eg-solid-powder") -- guide 175-194: "60x Solid Blasting Powder - 120 Solid Stone"; save them, 20 go into Unstable Trigger and 40 into Hi-Explosive Bomb https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,175,194,20,"eg-iron-grenade") -- guide 175-194 beta alternative ("Solid Stone is expensive right now"): "10x Solid Blasting Powder - 20 Solid Stone" then "20x Iron Grenade - 20 Iron Bar, 20 Heavy Blasting Powder, 20 Silk Cloth"; the 10 powders are made on demand by conversion for Unstable Trigger and get no skill credit https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,194,195,1,"eg-micro-adjustor") -- guide 194-195: "1x Gyromatic Micro-Adjustor - 4 Steel Bar"; a tool, keep it; if short of 195 craft a few more Iron Grenade https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,195,200,6,"eg-mithril-tube") -- guide 195-200: "6x Mithril Tube - 18 Mithril Bar"; keep all 6 for Gnomish Engineering https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,200,215,20,"eg-trigger") -- guide 200-215: "20x Unstable Trigger - 20 Mithril Bar, 20 Mageweave Cloth, 20 Solid Blasting Powder"; keep all 20 for the bombs at 238; last band the author tested on the beta https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,215,238,40,"eg-casing") -- guide 215-238: "40x Mithril Casing - 120 Mithril Bar"; keep 40 for the bombs; "The route after 225 is not tested yet" https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,238,250,20,"eg-hi-explosive") -- guide 238-250: "20x Hi-Explosive Bomb - 40 Mithril Casing, 20 Unstable Trigger, 40 Solid Blasting Powder"; untested on the beta https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,250,260,30,"eg-dense-powder") -- guide 250-260: "30x Dense Blasting Powder - 60 Dense Stone"; "yellow from 250, so you might need more than 30"; untested on the beta https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,260,285,35,"eg-widget") -- guide 260-285: "35x Thorium Widget - 105 Thorium Bar, 35 Runecloth"; schematic from Sovik (Orgrimmar) or Gearcutter Cogspinner (Ironforge); untested on the beta https://www.wow-professions.com/forever/engineering-leveling-guide
edge(202,285,300,20,"eg-thorium-tube") -- guide 285-300: "20x Thorium Tube - 120 Thorium Bar"; schematic from Xizzer Fizzbolt (Everlook), bind on pickup; untested on the beta https://www.wow-professions.com/forever/engineering-leveling-guide
-- No faction-only recipe on this route: trainers differ by faction, recipes do not, and each schematic has a Horde and an Alliance or neutral seller,
-- so there are no T.levelingRecipes[key].faction assignments. The guide's 200-300 route uses no Gnomish- or Goblin-only recipe, so the
-- specialisation adds no per-branch alternative edges; only the keep notes (5 Explosive Sheep, 6 Mithril Tube) refer to it.
local names={[2835]="Rough Stone",[2836]="Coarse Stone",[2838]="Heavy Stone",[7912]="Solid Stone",[12365]="Dense Stone",
    [2840]="Copper Bar",[2841]="Bronze Bar",[2842]="Silver Bar",[3575]="Iron Bar",[3577]="Gold Bar",[3859]="Steel Bar",
    [3860]="Mithril Bar",[12359]="Thorium Bar",[818]="Tigerseye",[14047]="Runecloth",[2880]="Weak Flux",
    [4357]="Rough Blasting Powder",[4359]="Handful of Copper Bolts",[4364]="Coarse Blasting Powder",[4371]="Bronze Tube",
    [4377]="Heavy Blasting Powder",[4375]="Whirring Bronze Gizmo",[4382]="Bronze Framework",[10505]="Solid Blasting Powder",
    [10560]="Unstable Trigger",[10561]="Mithril Casing",[4361]="Copper Tube",[4387]="Iron Strut",[10558]="Gold Power Core",
    [4389]="Gyrochronatom"} -- 2589 Linen Cloth, 2592 Wool Cloth, 2318 Light Leather, 2319 Medium Leather, 1206 Moss Agate, 4306 Silk Cloth and 4338 Mageweave Cloth are already named in Data.lua or LevelingData.lua
for id,name in pairs(names) do T.items[id]=name end
-- Delivered separately (not assigned here): supplies 2880 Weak Flux; conversions 4357 eg-rough-powder, 4359 eg-copper-bolts,
-- 4364 eg-coarse-powder, 4371 eg-bronze-tube, 4377 eg-heavy-powder, 4375 eg-gizmo, 4382 eg-framework, 10505 eg-solid-powder,
-- 10560 eg-trigger, 10561 eg-casing, 4361 eg-copper-tube, 4387 eg-iron-strut, 10558 eg-power-core, 4389 eg-gyrochronatom.

-- Intermediates the routes may have to prepare, vendor supplies and item names for the new routes.
T.levelingConversions[6371]="al-fire-oil"
T.levelingConversions[13423]="al-stonescale-oil"
T.levelingConversions[3470]="bs-rough-grinding-stone"
T.levelingConversions[3478]="bs-coarse-grinding-stone"
T.levelingConversions[3486]="bs-heavy-grinding-stone"
T.levelingConversions[7966]="bs-solid-grinding-stone"
T.levelingConversions[2996]="ta-bolt-linen"
T.levelingConversions[2997]="ta-bolt-wool"
T.levelingConversions[4305]="ta-bolt-silk"
T.levelingConversions[4339]="ta-bolt-mageweave"
for _,id in ipairs({2320,2321,2604,2605,2880,3371,3372,3466,3857,4291,6217,8343,8925,17034,17035,18256,247786}) do T.levelingSupplies[id]=true end
for id,name in pairs({[765]="Silverleaf",[785]="Mageroyal",[1210]="Shadowgem",[2320]="Coarse Thread",[2321]="Fine Thread",[2447]="Peacebloom",[2449]="Earthroot",[2450]="Briarthorn",[2589]="Linen Cloth",[2592]="Wool Cloth",[2604]="Red Dye",[2605]="Green Dye",[2835]="Rough Stone",[2836]="Coarse Stone",[2838]="Heavy Stone",[2840]="Copper Bar",[2841]="Bronze Bar",[2842]="Silver Bar",[2880]="Weak Flux",[2996]="Bolt of Linen Cloth",[2997]="Bolt of Woolen Cloth",[3356]="Kingsblood",[3357]="Liferoot",[3371]="Empty Vial",[3372]="Leaded Vial",[3383]="Elixir of Wisdom",[3466]="Strong Flux",[3470]="Rough Grinding Stone",[3478]="Coarse Grinding Stone",[3486]="Heavy Grinding Stone",[3575]="Iron Bar",[3820]="Stranglekelp",[3857]="Coal",[3859]="Steel Bar",[3860]="Mithril Bar",[4291]="Silken Thread",[4305]="Bolt of Silk Cloth",[4306]="Silk Cloth",[4338]="Mageweave Cloth",[4339]="Bolt of Mageweave",[5500]="Iridescent Pearl",[6217]="Copper Rod",[6218]="Runed Copper Rod",[6338]="Silver Rod",[6339]="Runed Silver Rod",[6359]="Firefin Snapper",[6371]="Fire Oil",[7912]="Solid Stone",[7966]="Solid Grinding Stone",[7971]="Black Pearl",[8343]="Heavy Silken Thread",[8831]="Purple Lotus",[8836]="Arthas' Tears",[8838]="Sungrass",[8839]="Blindweed",[8845]="Ghost Mushroom",[8925]="Crystal Vial",[10938]="Lesser Magic Essence",[10940]="Strange Dust",[11082]="Greater Astral Essence",[11083]="Soul Dust",[11128]="Golden Rod",[11130]="Runed Golden Rod",[11135]="Greater Mystic Essence",[11137]="Vision Dust",[11144]="Truesilver Rod",[11145]="Runed Truesilver Rod",[11174]="Lesser Nether Essence",[11176]="Dream Dust",[13422]="Stonescale Eel",[13423]="Stonescale Oil",[13466]="Plaguebloom",[13926]="Golden Pearl",[14343]="Small Brilliant Shard",[14344]="Large Brilliant Shard",[16203]="Greater Eternal Essence",[16204]="Illusion Dust",[16206]="Arcanite Rod",[16207]="Runed Arcanite Rod",[17034]="Maple Seed",[17035]="Stranglethorn Seed",[18256]="Imbued Vial",[20745]="Minor Mana Oil",[20746]="Lesser Wizard Oil",[20747]="Lesser Mana Oil",[247786]="Mote of Magic"}) do T.items[id]=T.items[id] or name end
-- Engineering intermediates, its vendor supply and item names.
T.levelingConversions[4357]="eg-rough-powder"
T.levelingConversions[4359]="eg-copper-bolts"
T.levelingConversions[4364]="eg-coarse-powder"
T.levelingConversions[4371]="eg-bronze-tube"
T.levelingConversions[4377]="eg-heavy-powder"
T.levelingConversions[4375]="eg-gizmo"
T.levelingConversions[4382]="eg-framework"
T.levelingConversions[10505]="eg-solid-powder"
T.levelingConversions[10560]="eg-trigger"
T.levelingConversions[10561]="eg-casing"
T.levelingConversions[4361]="eg-copper-tube"
T.levelingConversions[4387]="eg-iron-strut"
T.levelingConversions[10558]="eg-power-core"
T.levelingConversions[4389]="eg-gyrochronatom"
for _,id in ipairs({2880}) do T.levelingSupplies[id]=true end
for id,name in pairs({[818]="Tigerseye",[2835]="Rough Stone",[2836]="Coarse Stone",[2838]="Heavy Stone",[2840]="Copper Bar",[2841]="Bronze Bar",[2842]="Silver Bar",[2880]="Weak Flux",[3575]="Iron Bar",[3577]="Gold Bar",[3859]="Steel Bar",[3860]="Mithril Bar",[4357]="Rough Blasting Powder",[4359]="Handful of Copper Bolts",[4361]="Copper Tube",[4364]="Coarse Blasting Powder",[4371]="Bronze Tube",[4375]="Whirring Bronze Gizmo",[4377]="Heavy Blasting Powder",[4382]="Bronze Framework",[4387]="Iron Strut",[4389]="Gyrochronatom",[7912]="Solid Stone",[10505]="Solid Blasting Powder",[10558]="Gold Power Core",[10560]="Unstable Trigger",[10561]="Mithril Casing",[12359]="Thorium Bar",[12365]="Dense Stone",[14047]="Runecloth"}) do T.items[id]=T.items[id] or name end
