# Data provenance and implementation notes

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
