# TrailMats 0.7.0

What to craft, gather and keep while leveling in WoW Forever.

## Install

Download [TrailMats-0.7.0.zip](https://github.com/nicholasjprimianomd/TrailMats/releases/tag/v0.7.0). Extract the `TrailMats` folder into `Interface/AddOns`, restart WoW, then type `/tm`. Keep Questie and QuestieDB installed separately for source references. Existing character settings are preserved.

Only the inner `TrailMats` folder belongs in AddOns. TrailMats never buys or crafts automatically.

## A shorter interface

Choose a profession, then one of three views:

| View | What it shows |
| --- | --- |
| **Now** | Your next action, batch ingredients and materials to gather in this zone. |
| **Keep** | Useful items in your bags and how much to set aside for one batch. |
| **Plan** | Missing materials to the next 75, 150 or 225 skill milestone. **Show all** includes covered ingredients. |

**Recipes** inside Plan shows the crafting order and recipe availability. **Prices** lets you compare material costs. Hover rows for source locations, ingredient breakdowns and explanations. **Help** keeps the longer guidance off the main screens.

The main window uses one row of profession tabs, item icons with names, and separate quantity columns. `*` marks a guide source or guide-based advice; confirm it in-game. Unlisted materials may still be useful.

## While questing

- Open your profession's crafting window to read learned recipes. **Now** only suggests learned, non-grey recipes scanned at your current skill. Reopen the crafting window after gaining skill if asked to refresh.
- **Craft N** means your bags cover that many crafts, up to the selected **Batch: 1 / 3 / 5**. Otherwise the next action directs you to supplies, gathering or training.
- **This zone (est.)** shows missing materials for the milestone plan that have a source recorded in your current zone. Counts update with your bags and skill. Source names and coordinates are references, not live nearby targets or guaranteed drops.
- Click **Track** for a small, movable list that stays visible while the main window is closed. It remains pinned to that profession when you switch tabs. **Open** returns to its Now view; **Hide** removes the tracker.
- Fishing follows Cooking's material plan; Skinning follows Leatherworking's, when the paired profession is learned. Gathering itself has no invented crafting quota.
- At a vendor, relevant supplies for the current batch receive a short **TrailMats** quantity label. Hover for actual pack price and stock. Raw materials are not suggested for purchase.
- The next-zone button changes your destination. `(auto)` identifies an assumed route. Hover the next-zone advice for requirements, optional skill ranges and source details.

## Plans and prices

Plans cover Leatherworking, Cooking and First Aid through **225**. The next target follows current skill, not the trained cap. At a cap, the plan previews the next milestone and prompts training. Complete routes to 300 are not yet supported.

Materials include vendor supplies and intermediate recipes. **Need** is the amount still missing after allocating bags and outputs from earlier planned crafts. **Covered** can include those planned crafts; it does not mean every ingredient is already in your bags. Hover to see total use, bag allocation and planned production. Recipes are listed in crafting order, including preparation of missing intermediates.

Counts are guide-based estimates. Stop a recipe when its target skill is reached; skill-ups are not guaranteed. Check recipe availability before following a plan. The batch control affects Now and Keep, not the milestone plan.

Under **Prices**, click **Edit** and enter copper per item (100 copper = 1 silver). Blank clears a quote; zero explicitly means free. Quotes are saved per character and dated in the tooltip. There is no automatic Auction House scan. Open-vendor prices supply missing quotes for basic supplies, respecting packs and available stock.

The comparison minimizes estimated additional material spending among supported recipe combinations. Bags reduce purchases. Unknown prices are never treated as zero; incomplete comparisons stay labeled. Without a completely priced route, the planner favors routes with a greater fraction of raw materials already covered.

It does not compare every possible recipe, within-band mixture, or buying versus crafting intermediates. Training, recipe books, farming time, resale income and the value of owned materials are excluded. Update quotes when prices change. [SOURCES.md](SOURCES.md) documents the research and assumptions.

## Limits

Supported professions: Leatherworking, Skinning, Fishing, Cooking and First Aid. Counts use bags only, excluding banks, mail and other characters. English recipe names support reference matching.

Local source coverage depends on Questie/QuestieDB and a small set of fish and skinning references. Classic-derived records remain marked. An observed drop confirms that source only in the zone where it was recorded. There are no inferred kill counts. Early departure guidance is most complete for Teldrassil to Darkshore; unknown routes remain unknown. Profession advice is not a character-level or combat-safety check.

The compact tracker and hover-first layout take inspiration from [Questie](https://www.curseforge.com/wow/addons/questie) and [Profession Shopping List](https://www.curseforge.com/wow/addons/profession-shopping-list). Their code and artwork are not bundled.

## Commands

`/tm` opens or closes the window. `/tm now`, `/tm keep`, `/tm mats` and `/tm help` open a view. `/tm track` toggles the selected profession's tracker.

`/tm refresh` updates recipes and sources; `/tm quiet` toggles zone notices; `/tm tips` toggles item and creature hints; `/tm auto` resets destination and recipe choices; `/tm status` shows the version and database connection.

Drag the title bar to move the main window. Use the wheel or scrollbar for long lists; each view remembers its scroll position for the session.

## Development checks

Run from the repository root with Lua 5.1:

```sh
luac5.1 -p TrailMats/*.lua
lua5.1 tests/test.lua .
lua5.1 tests/leveling.lua .
```

The simulated game tests cover navigation, price editing, tracker updates while the main window is closed, profession and zone changes, source confidence, caps, recipe freshness, material counts, vendor packs and stock. The planner checks every starting skill from 1 through 224 for all three crafting professions, including ingredient accounting, intermediate production and incomplete prices.

Optional integration checks use separately installed Questie/QuestieDB and Python with `cbor2`:

```sh
python tests/real_database.py "/path/to/World of Warcraft/_classic_beta_/Interface/AddOns"
```

Automated checks pass for 0.7.0. In-game appearance and interaction still need a live visual check.

Version 0.5.0 was imported from the updated Drive bundle on October 6, 2026. Original 0.3.0 source is retained in Git history; the 0.4.0 and 0.5.0 changes arrived together.
