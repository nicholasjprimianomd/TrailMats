# TrailMats 0.3.0

A small zone profession companion for WoW Forever. It offers opportunities, not chores. It never crafts or buys anything.

## Use

1. Updating this installation: type `/reload`, then `/tm`. For a new addon installation on another machine, restart WoW once and enable TrailMats and QuestieDB.
2. Choose your profession tab: Leatherworking, Skinning, Fishing, Cooking, or First Aid. Only professions you possess appear.
3. Open that profession's normal crafting window once. TrailMats suggests only recipes actually recorded as learned and capable of skill-ups at your current skill. Reopen it after gaining skill if the suggestion disappears. Clear restrictive recipe filters if needed.
4. An **easy option** explains the recipe and ingredients for an optional small batch. **Batch: 3** cycles through 1, 3, and 5 crafts. **Another recipe** appears when alternatives are available. You are never expected to make every option.
5. Each ingredient shows **In bags**, **For this batch**, and **Collect**. Hover for source evidence and coordinates. Matching creature tooltips show how much material to collect for the currently selected profession. Kills are variable; no kill quota is invented.
6. At a vendor, relevant basic supplies for the selected recipe receive a **TrailMats** label above their item icon. Hover the item, or read **At this vendor** in TrailMats, for the suggested quantity, actual total price, and reason. Pack sizes and limited stock are respected. Farmed raw materials are never suggested for purchase. Nothing is purchased automatically.
7. **Before leaving** shows departure context. **Departure details** explains the rule and evidence. The next-zone button cycles destinations; defaults are explicitly marked assumed. No numeric goal is invented for unreviewed routes.
8. Scroll with the wheel or labeled buttons. Drag the window to move it. **Close** hides it; `/tm` brings it back.

`/tm help`, `/tm refresh`, `/tm quiet` (zone notices), `/tm tips` (tooltips), `/tm auto` (reset destination and recipe choices), `/tm status`.

## What the advice means

- Batch sizes are a user-controlled convenience, not a promised number of skill-ups or a departure stockpile. There are no next-multiple-of-ten targets and no combined shopping list.
- A suggestion requires a fresh recipe record at the current skill and either enough raw ingredients in bags or source references in the current zone. Grey, unlearned, stale and capped recipes do not produce suggestions. Orange/yellow recipes and ingredients already held are favored. No global cheapest recipe claim is made.
- Vendor prices are read only from the currently open merchant. Special currencies, unpurchasable and out-of-stock items are excluded. When duplicate supply listings exist, coverage and total outlay determine the choice. Prices do not establish global bargains. Suggestions follow the currently selected profession tab.
- Creature/source and skinning references include Classic data and are explicitly labeled. No observed Forever drop rate or number of kills is inferred. Skinning-tab creature hints tell you to check the corpse's actual requirement. No nameplate modifications are made.
- Water hints cover Teldrassil and Darkshore. Fishing and Skinning have advice instead of arbitrary catch/kill quotas. Fishing camping crafts are not planned by this version.
- Reviewed early crafting continuity is focused on entering Darkshore: Light Leather, Linen Cloth and starter Cooking ingredients remain available by reference. Higher skills or other destinations may say **Not assessed**. That is not a claim that you are blocked.
- Fishing departure references distinguish entry skill from the higher no-escape level. Darkshore starts at skill 1; Ashenvale and Stonetalon at 55. Equipment/lure bonuses are not measured, so below-threshold status explicitly refers to unboosted skill.
- Skinning has no single zone-wide minimum. Target-specific Classic examples (Thistle Bears or Ghostpaw Runners) are labeled as references, never mandatory departure thresholds.
- English seed names, bag inventory only, no bank/mail/alt counts. Profession skill readiness is not character-level or combat-safety advice. No promise of avoiding all future backtracking; route data is deliberately limited rather than fabricated.

## Validation

`lua5.1 tests/test.lua .` and `python tests/real_database.py` validate simulated client calls, profession tabs, departure states, recipe freshness, quantities, vendor pack rounding/prices/stock, source data, tooltips, and scroll boundaries. `luac5.1 -p TrailMats/*.lua` checks syntax. Merchant API order and item-button names were checked against Blizzard's classic_beta UI-source mirror.

The original screenshot showed glyph and scrollbar problems. The 0.3.0 interface uses font-safe plain labels, individual tabs, wrapped rows and a bounded scrolling area. This version has not been visually verified inside the game.
