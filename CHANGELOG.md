# TrailMats changelog

TrailMats is a profession companion for World of Warcraft: Forever. Counts are estimates; nothing is bought, crafted or trained automatically. Dates are tag dates. Downloads: https://github.com/nicholasjprimianomd/TrailMats/releases

## Unreleased

- Auction house prices: the lowest unit buyout of every page you browse is recorded, and a **TrailMats: Scan prices** button under the auction house frame scans the house (a full browse on this client; exact-name searches on the older auction API). **Full scan** appears when the client allows a complete replicate, with a countdown. Prices are shared per faction across your characters, expire after 14 days, and Auctionator or TSM prices are used only when fresher. TrailMats still never bids, buys or posts.
- New **Sell** view (`/tm sell`): **Craft to sell** ranks learned recipes by profit per craft after the auction house cut using full replacement cost of materials, with "needs N prices" for incomplete rows, vendor-only values for bind-on-pickup outputs and a thin-market flag; **Your materials** values held materials at the auction house and at a vendor next to their keep limits, with a `>=` total while anything is unpriced.
- Prices page rows show their source and age (your quote, open vendor, or AH with age); route costs fall through quote > vendor > auction house, taking the cheaper of vendor and auction house for vendor supplies. Item tooltips show the auction price and the stack's value after the cut.
- Options: auction house cut (0-20%, default 5%), neutral auction house (15%), and recording prices while browsing. Opening the auction house in Tanaris, Stranglethorn Vale or Winterspring uses the neutral cut for the session.
- Material rows show one coloured action line per state (collect, buy, craft first, ready, keep) over a thin have/need bar, like a quest objective. Rows are uniform cards that brighten on hover; vendor offers keep a quiet second line.
- Packaging for CurseForge, Wago Addons and GitHub Releases: `.pkgmeta`, a tag-triggered GitHub Actions workflow, this changelog, and TOC metadata (icon, category, website, license).

## 0.11.0 (2026-10-17)

- Minimap button: left-click opens TrailMats, right-click pins the tracker, shift-click opens the settings; drag it around the minimap; hover for the current next step.
- Options page (window button, `/tm options`, or the game's AddOns settings): minimap button, zone notices, tooltip hints, crafting notices, training reminders, optional sound, tab following, tracker lock, window and tracker scale. Shared by all characters; recipes, prices, the selected tab and positions stay per character.
- Crafting notices: one line when your bags cover the whole target for the current recipe, and one when a skill-up means that recipe's target is reached and it is time to switch.
- Training reminders once per login when a profession reaches its trained cap.
- Opening a crafting window selects that profession's tab. Key Bindings > AddOns has bindings for the window, tracker and settings. Escape closes the main window. Unknown `/tm` commands explain themselves.
- Existing zone-notice and tooltip choices carry over to the shared settings on first login.

## 0.10.1 (2026-10-17)

Includes the unreleased 0.8.0 to 0.10.0 work.

- Next step shows what to collect, buy or craft first for one recipe, with a named source and a skill target; the tracker follows the same target.
- Materials replaces Keep: the next recipe's ingredients, including ones you have none of, sources in your current zone, and held materials to save for later.
- Automatic recipe targets replace the batch and manual recipe-cycling controls; targets reuse the reviewed leveling intervals and stop when a recipe turns green or gray.
- Keep up to limits show how much of each held material can still help the supported leveling route.
- Sources come from the installed QuestieDB without waiting for personal loot; raw coordinates and the next-zone selector are removed.
- Fixed: logging in or changing zones could print two zone notices, one of them "Unknown zone".

## 0.7.0 (2026-10-06)

- Short Now / Keep / Plan views, one row of profession tabs, item icons and quantity columns; longer explanations move to hover details and Help.
- This zone lists missing milestone materials with local source references.
- Optional Track window follows one profession while you quest, even with the main window closed.
- Plan separates missing materials, recipe order and prices; Show all includes ingredients covered by bags or earlier planned crafts.
- Observed drops confirm the recorded zone only.

## 0.6.0 (2026-10-06)

- Leveling mats: a recipe sequence and combined material list for the next skill milestone (75, 150, 225) for Leatherworking, Cooking and First Aid; Fishing and Skinning show gathering guidance.
- Prices compares entered copper-per-item quotes and open-vendor offers across supported routes. Unknown costs stay unknown.
- Craft counts are estimates; progression past 225 is marked unverified.

## 0.5.0 (2026-10-06)

- Keep for later view for useful crafting materials, reviewed leveling ranges, and a scrolling interface.
- First portable distribution. The 0.3.0 source is preserved in repository history; the 0.4.0 and 0.5.0 changes arrived together.
