# Data provenance and implementation notes

## 0.6.0 milestone planner, checked 2026-10-06

The [Forever Leatherworking](https://www.wow-professions.com/forever/leatherworking-leveling-guide), [Cooking](https://www.wow-professions.com/forever/cooking-leveling-guide), and [First Aid](https://www.wow-professions.com/forever/first-aid-leveling-guide) authors describe research in the beta client. Recipe reagent facts, selected planning bands, and approximate craft counts inform the small factual catalog in LevelingData.lua. The addon independently enumerates eligible sequences to the next milestone and simulates inventory consumption to compare their material cost. It does not bundle guide prose, artwork, third-party code, or a copied full profession database.

Notable Forever-specific fact: [Minor Healing Potion, spell 1244431](https://www.wowhead.com/forever/spell=1244431/minor-healing-potion) uses Peacebloom, Mild Spices, and Empty Vial and is now a First Aid alternative. It is included alongside bandages.

Intermediate inputs and two-item reference yields were separately checked on Wowhead Forever spell records: [Light Leather 2881](https://www.wowhead.com/forever/spell=2881/light-leather), [Cured Light Hide 3816](https://www.wowhead.com/forever/spell=3816/cured-light-hide), [Medium Leather 20648](https://www.wowhead.com/forever/spell=20648/medium-leather), [Cured Medium Hide 3817](https://www.wowhead.com/forever/spell=3817/cured-medium-hide), [Fine Leather Belt 3763](https://www.wowhead.com/forever/spell=3763/fine-leather-belt), [Heavy Leather 20649](https://www.wowhead.com/forever/spell=20649/heavy-leather), and [Cured Heavy Hide 3818](https://www.wowhead.com/forever/spell=3818/cured-heavy-hide). The client scanner records GetTradeSkillItemLink and the minimum GetTradeSkillNumMade yield to override those reference outputs. Reference yields remain unverified on the player's running character until scanned.

Forecast counts are whole-band guide estimates scaled linearly to the remaining interval and rounded up once per step. This is an estimate, not a measured probability curve. Light Armor Kit uses a conservative 33-craft planning allowance for 1-30; the guide gives the alternative but does not give an exact count. Cooking 150-175 omelets uses a 27-craft allowance and 175-225 recipes use 54 to allow for the yellow tail mentioned by the guide. These are explicit planning assumptions, not reported measurements.

[TheWoWDB's independent client-based guide](https://thewowdb.com/wow-forever/guides/professions/leatherworking/) was cross-checked; its recipe acquisition data are incomplete and its skill-up odds are assumed. It was not treated as a verified cheapest route. No realm prices were imported. The inspected later item pages explicitly labeled their reagent rows Retail, so those rows were not used for Forever. Current guides mark later beta progression untested/incomplete; complete milestone coverage stops at 225.

Cost comparisons use only explicit user unit quotes and current merchant offers for supplies, with stock and pack rounding. Zero requires an explicit quote. Recipe books, training, sale proceeds, time and owned-material opportunity cost are excluded. Missing intermediate items are crafted, not optimized against buying them. Different recipes may be combined at reviewed band boundaries; within-band mixtures are not exhaustively searched. Unknown comparison costs remain unknown. There is no global optimality claim.

Every supported starting skill 1-224 is tested for reaching its next milestone without gaps and conserving material allocations. Additional tests cover economics, bag credit, intermediate production, live overrides, factions, cap notices, UI navigation, price dialogs and gathering professions. Actual in-game visuals still require player confirmation.


## 0.5.0 future material reserves, checked 2026-10-05

Future.lua adds a limited basic-recipe reference layer separate from learned/live crafting. Ingredient tuples and trainer/vendor/quest source categories were checked against the same Forever [Cooking](https://www.wow-professions.com/forever/cooking-leveling-guide), [Leatherworking](https://www.wow-professions.com/forever/leatherworking-leveling-guide) and [First Aid](https://www.wow-professions.com/forever/first-aid-leveling-guide) sources. Existing starter tuples are reused. Additions cover leather conversion and curing, belts/pants, catfish, clams, coyote steak, crab cake, pork ribs and heavy wool bandages. No vendor coordinates or precise learning requirements are inferred from the guide's recommended skill bands.

Reserve counts are derived from the user's 1/3/5 craft batch, not copied shopping lists or estimates of crafts to level. Raw-material coverage excludes basic vendor supplies and is capped per ingredient. Held items are suggested regardless of how far ahead their supported future use lies. The catalog remains limited; absence is not evidence that an item should be sold. Source categories describe the reference recipe, and recorded learned reagent quantities take priority. Runtime tests use simulated APIs and do not verify appearance or beta recipe changes inside the live game.

## 0.4.0 efficiency ranges, checked 2026-10-05

- Fishing: the [Forever fishing overview](https://www.wowhead.com/forever/guide/professions/fishing/overview-leveling) gives 75 effective skill for no escapes in Darkshore, Barrens, Westfall and Loch Modan, and 150 in Ashenvale and Stonetalon. Suggested base bands of 50-75 and 100-150 are derived from those targets using Shiny Bauble (+25, usable at 1) and Nightcrawlers (+50, usable at 50). The lower end requires the named active lure; additional bonuses and stronger lures are not modeled. These are convenient options, not a global time optimum.
- Small early crafting bands in Ranges.lua are advisory factual thresholds from the Forever [Leatherworking](https://www.wow-professions.com/forever/leatherworking-leveling-guide), [Cooking](https://www.wow-professions.com/forever/cooking-leveling-guide) and [First Aid](https://www.wow-professions.com/forever/first-aid-leveling-guide) guides. They are not color-transition tables and are not used to infer learned recipes. Heavy Linen 75-80 is explicitly a less efficient bridge. Live difficulty is authoritative for suggestions.
- Skinning ranges 10-20 and 90-100 apply the existing Classic formula to the previously reviewed named beasts. They describe coverage requirements, not a verified Forever skill-up optimum.
- Scrollbar uses the standard Slider/ScrollFrame APIs also present in the installed Questie AceGUI widgets. No widget code was copied. UI changes were exercised under simulated APIs; no in-game visual verification was performed.

Checked 2026-10-05 against local Forever client 1.60.1.70205 (interface 16001).

## Recipe facts

Small manually selected factual seed; no guide text, addon code, database, or route export copied from DFL or Mastercraft.

- Leatherworking: [WoW-Professions Forever guide](https://www.wow-professions.com/forever/leatherworking-leveling-guide), early Light Armor Kit and Embossed Leather Gloves ingredient/skill facts. Seed names support recipe scanning; they are not used to infer learned recipes or craft quotas.
- Cooking: [Forever cooking guide](https://www.wow-professions.com/forever/cooking-leveling-guide); [Kaldorei Spider Kabob client record](https://www.wowhead.com/forever/spell=6412/kaldorei-spider-kabob). Only a few low-level ingredient tuples are retained. No vendor coordinates supplied.
- First Aid: [Forever First Aid guide](https://www.wow-professions.com/forever/first-aid-leveling-guide), Linen/Heavy Linen/Wool ingredient facts and conservative boundaries.
- Optional recipe opportunities require live learned recipes, ingredient quantities, current skill and non-grey difficulty. The user selects a batch of 1, 3 or 5 crafts. These are craft counts, not a skill-up probability model. Legacy seed factors are not used by the planner.

## Source locations

- Read-only integration with installed QuestieDB 1.0.4, public contract 2 (`LibQuestieDB.Item`, `.Npc`, `.Object`) and existing Questie `DropDB.tableWowhead` / `ZoneDB:GetAreaIdByUiMapId`. No bundled copy. The installed Forever TOC loads `support/Forever/DropTables/classicItemDrops.lua`; its provenance stays **Classic**. Entity source references are labeled **Forever unverified**. Missing methods/data degrade to unknown.
- QuestieDB's `EraToForever` projection is used when available for NPC coordinate references. Coordinates remain approximate reference points.
- Skinning: small explicit lists of Teldrassil nightsabers and Darkshore bears/moonstalkers/foreststriders are **Classic candidates**, not asserted skin-loot records. No generic all-beasts rule. Names/coordinates are resolved from QuestieDB; [Nightsaber](https://www.wowhead.com/classic/npc=2042/nightsaber), [Moonstalker](https://www.wowhead.com/classic/npc=2069/moonstalker), [Classic leather reference](https://www.wowhead.com/classic/guide/classic-leather-farming-early-leather).
- Water hints: [Forever Fishing/Cooking guide](https://www.wow-professions.com/forever/fishing-and-cooking-leveling-guide) for Lake Al'Ameth; [smallfish locations](https://www.wowhead.com/forever/item=6291/raw-brilliant-smallfish), [albacore locations](https://www.wowhead.com/forever/item=6361/raw-rainbow-fin-albacore), [mackerel reference](https://www.wowhead.com/forever/item=6303/raw-slitherskin-mackerel). These pages contain legacy observations; URL flavor alone is not confirmation of Forever sampling. Catch rates are not inferred. Separate zone-entry fishing references are documented below.

## Architecture and licenses

[DFL Profession Journal](https://www.curseforge.com/wow/addons/profession-journal) and [Mastercraft](https://www.curseforge.com/wow/addons/mastercraft) list All Rights Reserved. DFL's downloaded release was inspected in the earlier task and again for source/licensing context; its routes and implementation are not reused. Neither addon is installed or required.

TrailMats is new MIT-licensed code. It accesses separately installed Questie/QuestieDB without redistributing their code or datasets. Blizzard's UI code from the [classic_beta UI-source mirror](https://github.com/Gethe/wow-ui-source/tree/classic_beta/Interface/AddOns/Blizzard_TradeSkillUI/Vanilla) was inspected to check legacy trade-skill API names. Reference downloads in `tests/*.reference.lua` are research-only and excluded from installation/distribution.

No game input was sent during implementation. In-game confirmation, tooltip timing, localization beyond English seed labels, and actual skin/fish availability remain to be checked by the player.


## Departure references and merchant UI, checked 2026-10-05

- [Wowhead Forever fishing overview](https://www.wowhead.com/forever/guide/professions/fishing/overview-leveling), updated October 4, lists minimum fishing skill 1 in Darkshore, Barrens, Westfall and Loch Modan; 55 in Ashenvale and Stonetalon. The higher no-escape targets are not departure requirements. Effective skill can include bonuses; TrailMats only compares base skill and makes that limitation explicit.
- [Classic Skinning skill reference](https://www.wowhead.com/skill=393/skinning): below creature level 21, the conventional requirement is max(1, (level-10)*10). This is not independently verified for Forever. Installed QuestieDB level fields list Thistle Bear 2163 at 11-12 and Ghostpaw Runner 3823 at 19-20. Therefore 20 and 100 cover those specific reference targets; neither is encoded as the lowest skill needed to enter the whole zone. Moonstalker Runt is deliberately not used because its public level references conflict.
- Early crafting departure advice is an inference from the recipe facts above and continuing Darkshore sources in the installed database, not an official zone gate. Cooking advice does not imply that an unscanned fish recipe is learned. Beyond the reviewed ranges the addon says Not assessed.
- [Blizzard classic_beta merchant source mirror](https://github.com/Gethe/wow-ui-source/blob/classic_beta/Interface/AddOns/Blizzard_UIPanels_Game/Vanilla/MerchantFrame.lua) confirms the nine-return GetMerchantItemInfo signature (isPurchasable, isUsable, extendedCost at positions 6, 7, 8), page index and MerchantItem slot widgets. Runtime hooks add only labels; they do not recolor or rewrite another addon's settings, buy items or invoke crafting. The reference source is test/research-only and is not distributed.
