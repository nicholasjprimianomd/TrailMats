TrailMats is a profession companion for World of Warcraft: Forever. It reads the professions and recipes your character already knows and tells you what to collect, buy, craft or keep next while you level.

## What it does

- **Next step**: one recipe at a time, with the action (Collect, Buy, Craft first or Ready), a named source and a skill target.
- **Materials**: the next recipe's ingredients, including ones you have none of, with sources in your current zone and held materials worth keeping for later recipes.
- **Plan**: missing materials to the next 75, 150 or 225 skill milestone, the recipe order, and a price comparison of the routes it knows.
- **Tracker**: a small, movable list that stays visible while you quest; it updates with your bags, skill and zone.
- **Vendor labels**: at a vendor, supplies for the current recipe target get a short quantity label; hover for pack price and stock.
- **Notices**: optional chat lines when your bags cover the current target, when it is time to switch recipes, and when a profession reaches its trained cap.
- Minimap button, an options page (also under the game's AddOns settings), key bindings, and Escape to close.

## Professions covered

Leatherworking, Cooking and First Aid have reviewed plans through skill 225. Skinning and Fishing show gathering guidance that follows the paired crafting plan.

## Sources

Install [Questie](https://www.curseforge.com/wow/addons/questie) (which provides QuestieDB) for creature, object and vendor references. TrailMats reads it at run time and does not include a copy of its data. Without it, TrailMats still plans from your bags and recipes but shows no local sources.

## Please read

- Counts are estimates taken from reviewed leveling guides and scaled to your remaining skill. Skill-ups are not guaranteed; stop when a recipe turns green or reaches the shown target.
- Nothing is bought, crafted or trained automatically. There is no auction house scanning; prices are the quotes you enter plus open vendor offers.
- Counts use your bags only, not the bank, mail or other characters.
- Forever is new; recipe availability and guide coverage can differ from what the addon expects. Data sources and assumptions are listed in SOURCES.md inside the addon folder.

## Commands

`/tm` opens or closes the window. `/tm now`, `/tm mats`, `/tm keep` and `/tm help` change the view. `/tm track` toggles the tracker, `/tm options` opens the settings, `/tm minimap` shows or hides the minimap button, and `/tm status` shows the version and database connection.

## Source, license and feedback

MIT License. Source code, issue tracker and data provenance notes: https://github.com/nicholasjprimianomd/TrailMats
