# TrailMats 0.5.0

A small zone profession companion for WoW Forever. It offers opportunities, not chores. It never crafts or buys anything.

## Install or update

Download `TrailMats-0.5.0.zip` from this repository's Releases page. Extract its `TrailMats` folder into your WoW Forever `Interface/AddOns` folder. Keep Questie and QuestieDB installed separately for source references. Restart WoW after installing this update, enable the addon, then type `/tm` or `/tm keep`.

The repository's source folder is `TrailMats/`. Do not copy the repository's outer folder into AddOns. Existing per-character settings are preserved.

## Keep for later (0.5.0)

After restarting WoW, type `/tm keep`. The new **Keep for later** view is selected by default on upgrading. **Overview** returns to the existing live crafting suggestions and departure advice.

- Save fish and pickups for basic recipes even if you have not learned the recipes yet. The view shows materials currently in your bags, the recipe they support, a recommended skill band, and whether to train, buy a recipe, or pursue an optional quest. **Not recorded as learned** does not mean you definitely lack it; open the profession to refresh the record.
- Recipes with the greatest proportion of raw materials already in your bags come first. Cheap vendor supplies are listed separately from that proportion. Learned recipe quantities override the reference quantities.
- **Batch: 1 / 3 / 5** controls the suggested starting reserve. The amount to set aside is bounded by what you actually hold. Each row is an option for one batch; alternative uses of the same material are not summed. The addon never marks extra or unlisted items as safe to sell.
- Fishing's keep view shows uses for your Cooking profession. Skinning's keep view shows uses for Leatherworking. Learn the corresponding crafting profession first if it is absent. Bag and loot item tooltips include future uses across all your owned supported professions, regardless of the active tab. New pickups can get a hint before they appear in the held-material list.
- The reviewed catalog covers 25 early basic recipes: fish/meat/egg Cooking, leatherworking and bandages, plus the optional Alliance spider-kabob quest recipe. It includes later uses of Cured Light Hide. It is not a complete crafting database. Fish use includes smallfish, mackerel, mud snapper, albacore and catfish; current bands extend through Cooking 150, Leatherworking 115 and First Aid 150.
- Future recipes remain visible across a trained skill cap; the view prompts training when appropriate. Recipes past their reviewed leveling band drop out unless a fresh learned recipe remains non-grey. A current grey recipe overrides the reference. This is leveling reserve advice, not a claim that older food or materials have no other use.

Future advice does not change the requirement that **Overview** crafting opportunities be learned and freshly scanned. It does not change merchant purchase suggestions to include speculative future recipes. Bags only; bank, mail and alts are not counted.

Validation: the prior Lua 5.1 regression checks and new tests passed for unlearned forecasts, recipe sources, material coverage, vendor supplies, live quantity overrides, grey recipes, faction restrictions, profession ownership, caps, intermediate materials, global item tooltips, duplicate suppression, view switching and batch changes. Installed files are checked against the tested build. In-game visual verification remains outstanding.

## Use

1. Restart WoW after installing or updating, enable TrailMats and QuestieDB, then type `/tm`.
2. Choose your profession tab: Leatherworking, Skinning, Fishing, Cooking, or First Aid. Only professions you possess appear.
3. Open that profession's normal crafting window once. TrailMats suggests only recipes actually recorded as learned and capable of skill-ups at your current skill. Reopen it after gaining skill if the suggestion disappears. Clear restrictive recipe filters if needed.
4. **Crafting opportunity** explains the recipe and ingredients for an optional small batch. **Batch: 3** cycles through 1, 3, and 5 crafts. **Another recipe** appears when alternatives are available. You are never expected to make every option.
5. Each ingredient shows **Have / Need** and **Collect** or **Ready in bags**. Hover for source evidence and coordinates. Matching creature tooltips show how much material to collect for the currently selected profession. Kills are variable; no kill quota is invented.
6. At a vendor, relevant basic supplies for the selected recipe receive a **TrailMats** label above their item icon. Hover the item, or read **At this vendor** in TrailMats, for the suggested quantity, actual total price, and reason. Pack sizes and limited stock are respected. Farmed raw materials are never suggested for purchase. Nothing is purchased automatically.
7. **Before leaving** shows departure context. **Departure details** explains the rule and evidence. The next-zone button cycles destinations; defaults are explicitly marked assumed. No numeric goal is invented for unreviewed routes.
8. Scroll with the wheel or drag the scrollbar thumb. The scrollbar hides when all content fits, and tabs remember their own scroll positions for the session. Drag the title bar to move the window. **Close** hides it; `/tm` brings it back.
9. **Recommended leveling range** shows a reviewed crafting band and the next step. The skill bar shows your current skill against your trained cap; it is not an efficiency score. Fishing shows a recommended base-skill range with the named lure needed at its lower end, alongside the effective-skill no-escape target. Skinning shows named-beast coverage, explicitly labeled as a Classic reference.

`/tm keep`, `/tm help`, `/tm refresh`, `/tm quiet` (zone notices), `/tm tips` (tooltips), `/tm auto` (reset destination and recipe choices), `/tm status`.

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

0.4.0 was checked with a Lua 5.1 runtime and simulated WoW APIs: syntax, fishing requirements versus efficiency, range boundaries, recipe freshness, bag-cache invalidation, ranking, skill caps, scrollbar bounds and dragging, remembered tab positions, row reuse, hidden-window refresh and lazy source tooltips. These checks do not replace a visual check in the game. The earlier 0.3.0 validation covered merchant pack rounding/prices/stock and database references; the merchant logic is unchanged.

## 0.4.0 changes

- Separate minimum departure requirements and optional efficiency guidance. Reviewed crafting bands currently cover Leatherworking through 75, Cooking through 100 and First Aid through 150; beyond those ranges, live suggestions remain available but numeric guidance says not assessed.
- Fishing base ranges: 50-75 for Darkshore, Barrens, Westfall and Loch Modan (Shiny Bauble at the low end); 100-150 for Ashenvale and Stonetalon (Nightcrawlers at the low end). Targets are 75 and 150 effective skill respectively. Bonuses are not automatically detected.
- Persistent skill header, progress bar, selected-tab highlight, alternating row backgrounds and compact material counts. Mouse wheel and proportional draggable scrollbar replace the two scroll buttons.
- Bag quantities are cached only within one plan build. Source details are computed when hovered. Hidden windows skip layout work, then render the latest plan on opening. Recipe ranking normalizes ingredient availability so extra reagent types do not boost a recipe's score. Skill changes rescan the currently open profession.

Restart WoW, then type `/tm` to load the installed update. In-game appearance and interaction have not been visually verified in this session.

## Development checks

Run from the repository root with Lua 5.1:

```sh
luac5.1 -p TrailMats/*.lua
lua5.1 tests/test.lua .
```

The regression harness uses simulated WoW APIs, including the 0.5.0 widgets and future-material view. It does not verify in-game appearance. Optional source-data integration checks require Python, `cbor2`, and separately installed Questie/QuestieDB:

```sh
python tests/real_database.py "/path/to/World of Warcraft/_classic_beta_/Interface/AddOns"
```

Version 0.5.0 was imported from the updated Drive bundle on October 6, 2026. The original 0.3.0 source is retained in Git history. The 0.4.0 and 0.5.0 changes were delivered together; no intermediate 0.4.0 snapshot is available here.
