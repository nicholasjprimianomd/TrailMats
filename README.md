# TrailMats 0.12.1

What to craft, gather and keep while leveling in WoW Forever.

## Install

Download [TrailMats-v0.12.1-forever.zip](https://github.com/nicholasjprimianomd/TrailMats/releases/tag/v0.12.1). Extract the `TrailMats` folder into `Interface/AddOns`, restart WoW, then type `/tm`. Keep Questie and QuestieDB installed separately for source references. Existing character settings are preserved.

Only the inner `TrailMats` folder belongs in AddOns. TrailMats never buys or crafts automatically.

## A shorter interface

Choose the profession you want to level. **Next step** shows what to farm for one recipe; **Plan** is the optional longer shopping list.

| View | What it shows |
| --- | --- |
| **Next step** | One recipe at a time: Collect, Buy, Craft first, or Ready, with a named source and skill target. |
| **Materials** | What to collect for the next recipe, including empty-bag ingredients, named sources in your current zone, and held materials to save for later. |
| **Plan** | Missing materials to the next 75, 150 or 225 skill milestone. **Show all** includes covered ingredients. |
| **Sell** | Profit per craft for learned recipes and the value of held materials, from recorded auction house prices. |

**Recipes** inside Plan shows the crafting order and recipe availability. **Prices** lets you compare material costs. Hover rows for source locations, ingredient breakdowns and explanations. **Help** keeps the longer guidance off the main screens.

The main window uses one row of profession tabs, item icons with names, and separate quantity columns. Counts are estimates. Unlisted materials may still be useful.

## While questing

- Open your profession's crafting window to read learned recipes. **Next step** only suggests learned orange/yellow recipes with reviewed targets scanned at your current skill. Reopen the crafting window after gaining skill if asked to refresh. In that window, **Alt-click a reagent** to mark its nearest source on your map (see Materials below).
- **Craft N** means your bags cover that many crafts, up to the automatic estimate for the next recipe switch or trained skill cap. Otherwise the next action directs you to supplies, gathering or training.
- The tracker and **Next step** use the same current recipe target. Before a live recipe is available, the first step of the researched plan supplies a preview, including intermediate ingredients. The tracker lists missing ingredients with a recorded source in the current zone. Counts update with your bags and skill. Source names are database references, not live nearby targets or guaranteed drops.
- Click **Pin** for a small, movable list that stays visible while the main window is closed. It remains pinned to that profession when you switch tabs. **Open** returns to its Next step view; **Hide** removes the tracker.
- Fishing follows Cooking's material plan; Skinning follows Leatherworking's, when the paired profession is learned. Gathering itself has no invented crafting quota.
- At a vendor, relevant supplies for the automatic recipe target receive a short **TrailMats** quantity label. Hover for actual pack price and stock. Raw materials are not suggested for purchase.
- Farming sources come from the installed database and reviewed fishing/skinning references, without waiting for personal loot. No raw coordinates or nearest-location claims are shown. The old next-zone selector is removed. Fishing keeps a current-zone skill target.

## Materials in your current zone

**Materials** replaces Keep. It shows the next recipe and estimated skill target, then separates ingredients into **Collect in [zone]**, **Found in other zones**, **Buy supplies**, **Craft first**, and **In your bags**. Each ingredient shows how much more to collect and how much you have. Sources are named creatures, fishing waters, or local faction-compatible vendors where listed.

For example, First Aid 72/150 with no cloth shows Heavy Linen Bandage to skill 80 and an estimated 32 more Linen Cloth. In Darkshore, the installed database lists Blackwood creatures. The amount falls as cloth enters your bags and as your skill increases. Stop at the target or when the recipe turns green; counts are not guaranteed skill-ups.

When an ingredient has no source in your zone, TrailMats looks it up across the whole database and names the best one with its zone, for example **From: Blackwood Pathfinder, Darkshore**. Sources are ranked by how likely they are, then by distance from your position: drops of at least 2% and friendly vendors first, creatures listed without a drop chance next, and chests, crates, rare drops, rare or elite creatures and dungeons you are not in only when nothing better exists. Creatures friendly to your own faction (guards, nobles, prisoners) are never suggested. Items that hundreds of creatures can drop (ore, stone, gems) are called a world drop rather than pointing at one of them. Herbs, ore, stone and gems point a gatherer with enough skill to the nearest node (**Herb: Peacebloom, Elwynn Forest**); without the skill they show the node and the skill it needs (**Herb: Peacebloom (Herbalism 1)**), and bars show their smelt (**Smelt: Copper Ore (Mining 1)**). Leather outside the reviewed starting zones and fish say to skin beasts near your level or to fish. **Source database unavailable** appears only when Questie is not installed or enabled.

**Click any material** (Next step, Materials, Plan, Save for later, or a line on the tracker) to mark its source on your map with a waypoint and the in-world arrow, open the map at that zone, and print the zone and coordinates in chat. With TomTom installed the waypoint goes to TomTom instead of a second arrow. In combat the waypoint is still placed but the map stays closed, because the game blocks add-ons from opening it then. The map opening can be turned off in Options. Hints without coordinates (herbs, ore, leather, fish, world drops) are printed instead; the row tooltip says which a click will do.

The same works in the game's own crafting window: **Alt-click a reagent** of the shown recipe to mark its nearest source, open the map and print the coordinates. Plain clicks and Shift-clicks keep their usual meaning there (Shift links the reagent in chat), and the reagent's tooltip says what Alt-click will do. Reagents with a choice of quality, optional reagents and currencies are left to the game. Linked recipes opened in the inspect window get the same.

At your trained cap, the page asks you to train before continuing. Plans beyond reviewed coverage show a coverage message instead of an empty list.

## Automatic keep limits

**Keep up to 130 / Have 10** means reserve your 10 held units; roughly 130 can still contribute to the supported leveling route. It is not an instruction to gather 120 immediately. The **Save for later recipes** section keeps this advice for held items outside the current recipe. Hover for the useful skill ranges, recipes and quantities behind the total.

The estimate reuses the reviewed counts already in the milestone planner, scales them to remaining skill, and rounds up. For example, at First Aid 20, Linen Cloth includes the remaining Linen Bandage crafts plus later Heavy Linen Bandages through skill 80. The limit falls as skill rises. Live green/gray recipe observations retire inefficient leveling uses, including after a further skill increase.

Successive uses of one material are added; recipes competing for the same skill interval are not added together. Different materials, such as two types of fish, can be alternatives for the same points. Their keep limits are independent upper estimates, so you do not need every limit. Keep preserves inputs for later intermediate crafts, credits their expected production once, and uses owned intermediates to reduce additional preparation.

Future advice can include recipes you have not learned and later training ranks. It does not grant recipes or promise skill-ups. Unreviewed targets stay unknown; coverage stops at 225. Nothing is marked safe to sell merely because it is absent. The existing batch and manual-recipe settings are ignored, and character settings otherwise remain intact.

## Plans and prices

Plans cover Leatherworking, Cooking and First Aid through **225**. The next target follows current skill, not the trained cap. At a cap, the plan previews the next milestone and prompts training. Complete routes to 300 are not yet supported.

Materials include vendor supplies and intermediate recipes. **Collect** or **Buy** is the amount still missing after allocating bags and outputs from earlier planned crafts. **Ready** means the necessary units are in your bags. **Craft first** means an earlier recipe must produce the ingredient. Hover to see how many more to collect or buy and which recipe needs them. If a recipe must make an ingredient first, the row says **Craft first**. Recipes are listed in crafting order, including preparation of missing intermediates.

Counts are guide-based estimates. Stop a recipe when its target skill is reached; skill-ups are not guaranteed. Check recipe availability before following a plan. There is no batch or recipe-cycle control. Next step selects a suitable learned recipe automatically. Stop at the displayed skill or when it turns green, whichever comes first.

Under **Prices**, click **Edit** and enter copper per item (100 copper = 1 silver). Blank clears a quote; zero explicitly means free. Quotes are saved per character and dated in the tooltip. Each row names its source: your quote, the open vendor, or the auction house with the age of that price. Open-vendor prices supply missing quotes for basic supplies, respecting packs and available stock; recorded auction prices fill the rest (see below).

The comparison minimizes estimated additional material spending among supported recipe combinations. Bags reduce purchases. Unknown prices are never treated as zero; incomplete comparisons stay labeled. Without a completely priced route, the planner favors routes with a greater fraction of raw materials already covered.

It does not compare every possible recipe, within-band mixture, or buying versus crafting intermediates. Training, recipe books, farming time, resale income and the value of owned materials are excluded. Update quotes when prices change. [SOURCES.md](SOURCES.md) documents the research and assumptions.

## Professions

TrailMats detects every profession your character knows and shows a tab for each. Reviewed leveling plans exist for all eight crafting professions: Leatherworking, Cooking, First Aid, Alchemy, Blacksmithing, Enchanting, Engineering and Tailoring (through skill 225; the Forever beta could not test further). Skinning, Herbalism, Mining and Fishing are gathering professions: their tabs follow the paired crafting plan (Leatherworking, Alchemy, Blacksmithing, Cooking) and show where to gather at your skill. Hovering a herb or vein shows the skill it needs next to yours.
## Auction house prices and selling

TrailMats reads the auction house; it never bids, buys, posts or cancels anything. Prices are recorded in two ways:

- **While browsing.** Every page of results you view is read for the lowest unit buyout per item (buyout divided by stack size; bid-only listings are ignored). Turn this off under Options with **Record prices while browsing**.
- **Scan prices.** A **TrailMats: Scan prices** button sits under the auction house frame, right of its tabs. On this client it runs one full browse of the auction house, paced by the game's own throttle; on clients with the older auction API it searches each item TrailMats cares about by exact name, up to four pages per item. Click again to stop and keep what was captured. **Full scan** appears when the client allows a complete replicate of the auction list; it shows a countdown until the next one is allowed.

Prices are shared by all your characters of one faction (Forever has no realms) and expire after 14 days. A lower price replaces a stored one at once; a higher price only after ten minutes, so one cheap listing does not vanish behind the next page. When Auctionator or TradeSkillMaster is installed, their price for an item is used only when it is fresher than TrailMats' own, and the source label says so. A price of zero or an unknown price is never treated as free.

The price cascade everywhere is: your quote, then the open vendor, then the auction house, then **Price needed**. Vendor supplies take the cheaper of the vendor and the auction house when both are known, and the vendor alone when the auction house is unknown. Item tooltips show the auction price per unit with its age and, for a stack in your bags, the stack's value after the cut.

**Sell** has two lists per profession. **Craft to sell** ranks learned recipes by profit per craft: the output's lowest auction price minus one copper, after the auction house cut, times the recipe's yield, minus the full replacement cost of every material, even those already in your bags. Recipes with any missing price say **needs N prices** and sort last; outputs that bind when picked up are valued at a vendor only; markets with fewer than three listings are flagged thin. **Your materials** values held raw materials at the auction house after the cut and at a vendor, next to the keep limits from the leveling plan. Totals carry a **>=** prefix while anything is unpriced. These are asking prices, not sales, and nothing is ever labelled safe to sell because of its value.

The cut is 5% by default and adjustable under Options (**Auction house cut**). **Neutral auction house (15% cut)** sets the neutral rate; opening the auction house in Tanaris, Stranglethorn Vale or Winterspring also applies it for the session. Both figures are the published rates and have not been measured on Forever.

## Limits

Counts use bags only, excluding banks, mail and other characters. English recipe names support reference matching.

Local source coverage depends on Questie/QuestieDB and a small set of fish and skinning references. Some provider records retain Classic-derived data, as explained in Help. Database sources do not depend on this character having seen them. There are no inferred kill counts. Early departure guidance is most complete for Teldrassil to Darkshore; unknown routes remain unknown. Profession advice is not a character-level or combat-safety check.

The compact tracker and hover-first layout take inspiration from [Questie](https://www.curseforge.com/wow/addons/questie) and [Profession Shopping List](https://www.curseforge.com/wow/addons/profession-shopping-list). Their code and artwork are not bundled.

## Settings, minimap button and notices

A minimap button opens TrailMats with a left-click, pins the tracker with a right-click and opens the settings with a shift-click. Drag it around the minimap. Escape closes the main window, and **Key Bindings > AddOns** has bindings for the window, the tracker and the settings.

**Options** (the window's Options button, `/tm options`, or the game's AddOns settings) covers the minimap button, zone notices, tooltip hints, crafting notices, training reminders, an optional sound, tab following, the tracker lock, price recording while browsing, the auction house cut and the neutral-house rate, and the window and tracker scale. These settings are shared by all your characters; recipes, prices, the selected tab and window positions stay per character. Opening a crafting window selects that profession's tab.

Crafting notices say when your bags cover the whole target for the current recipe, and when a skill-up means the current recipe's target is reached and it is time to switch. Training reminders appear once per login when a profession reaches its trained cap. Each notice appears once per login for a given target or cap. Nothing is crafted or trained for you.

## Commands

`/tm` opens or closes the window. `/tm now`, `/tm keep`, `/tm mats`, `/tm sell` and `/tm help` open a view. `/tm track` toggles the selected profession's tracker. `/tm options` opens the settings; `/tm minimap` shows or hides the minimap button.

`/tm refresh` updates recipes and sources; `/tm quiet` toggles zone notices; `/tm tips` toggles item and creature hints; `/tm auto` restores automatic destinations; `/tm status` shows the version and database connection.

Drag the title bar to move the main window. Use the wheel or scrollbar for long lists; each view remembers its scroll position for the session.

## Development checks

Run from the repository root with Lua 5.1:

```sh
luac5.1 -p TrailMats/*.lua
lua5.1 tests/test.lua .
lua5.1 tests/leveling.lua .
lua5.1 tests/automatic.lua .
lua5.1 tests/flow.lua .
lua5.1 tests/sources.lua .
lua5.1 tests/professions.lua .
lua5.1 tests/trades.lua .
lua5.1 tests/locate.lua .
lua5.1 tests/auction.lua .
lua5.1 tests/reagents.lua .
```

The simulated game tests cover navigation, price editing, tracker updates while the main window is closed, profession and zone changes, empty-bag checklists, database fallback, local vendors, caps, recipe freshness, material counts, vendor packs and stock. The planner checks every starting skill from 1 through 224 for all three crafting professions, including ingredient accounting, intermediate production and incomplete prices. The auction suite runs both auction house backends against separate mocks: page parsing, store merge rules, the scan queue and its paging limits, expiry, the price cascade, profit examples, bag totals, Auctionator and TSM interop, and that no bid, buyout or post call is ever made. The reagents suite mocks the game's crafting window (the pooled Mainline schematic form, whose button handlers the game resets on every recipe, and the older TradeSkill and Craft buttons) and checks that only Alt-click pins, that plain and Shift clicks stay the game's, and that hooks never stack.

Optional integration checks use separately installed Questie/QuestieDB and Python with `cbor2` (and `lupa` for the Materials check):

```sh
python tests/real_database.py "/path/to/World of Warcraft/_classic_beta_/Interface/AddOns"
python tests/materials_database.py "/path/to/World of Warcraft/_classic_beta_/Interface/AddOns"
```

Automated checks pass for 0.12.1. In-game appearance and interaction still need a live visual check.

Version 0.5.0 was imported from the updated Drive bundle on October 6, 2026. Original 0.3.0 source is retained in Git history; the 0.4.0 and 0.5.0 changes arrived together.
