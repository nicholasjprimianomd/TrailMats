# TrailMats publishing checklist (owner actions)

Status on 2026-10-17: CurseForge and Wago Addons list World of Warcraft: Forever (game version 1.60.1). WoWInterface does not. Forever beta runs through October 21; launch is November 4, 2026, 3:00 p.m. Pacific.

## 1. Repository preparation

- [ ] Add `.pkgmeta` (provided) at the repo root.
- [ ] Add `.github/workflows/release.yml` (provided).
- [ ] Add `CHANGELOG.md` (provided) at the repo root; keep it current with each release. The whole file becomes the CurseForge changelog and the GitHub release body.
- [ ] Add `.release/` to `.gitignore` (the packager writes there during local test runs).
- [ ] Update `TrailMats/TrailMats.toc` with the lines in `toc-additions.txt` (IDs once known). Bump `## Version:` and `T.version` in `TrailMats/Core.lua` to 0.12.0 together. Run the test suite (`lua5.1 tests/test.lua .` etc.).
- [ ] Optional local dry run (needs `zip` and `jq` installed): download release.sh from https://github.com/BigWigsMods/packager, run `bash release.sh -d` from the repo root, inspect `.release/TrailMats/` and the zip.
- [ ] Commit and push the workflow to `main` in its own push BEFORE pushing a tag (a tag pushed together with the first workflow file does not trigger a run).
- [ ] Capture in-game screenshots (main window, Materials, tracker, options page, minimap button) and make a 400x400 PNG logo (original artwork, not a blank square, not Blizzard art).

## 2. CurseForge (do first)

1. Log in at https://authors.curseforge.com/ (CurseForge/Overwolf account).
2. Create an API token at https://authors.curseforge.com/#/settings/api-tokens. Store it as the GitHub repository secret `CF_API_KEY` (Settings > Secrets and variables > Actions > New repository secret).
3. Start a project at https://authors.curseforge.com/#/projects/create/choose-game: game World of Warcraft, class Addons.
   - Name: `TrailMats` (unique on CurseForge as of 2026-10-17; no version numbers or the word "addon" in the name).
   - Summary: "What to craft, gather and keep while leveling professions in WoW Forever."
   - Description: paste `curseforge-description.md` (English, complete sentences; moderation rejects thin or ungrammatical text).
   - License: MIT License.
   - Main category: Professions. Additional categories (up to 4): Quests & Leveling and profession subcategories such as Leatherworking, Cooking, First Aid.
   - Logo: the 400x400 PNG.
   - Project distribution toggle (License tab): decide whether third-party apps may download the files; default for new projects is chosen here.
4. Upload the first file by hand if the project must exist before the workflow can run: zip from a local dry run (`.release/TrailMats-v0.12.0-forever.zip`), game version 1.60.1 under Forever, release type Release, changelog from CHANGELOG.md. Files sit "Under Review" until a moderator approves; projects need at least one Release file and must not be marked Experimental to appear in the CurseForge app.
   Alternative: create the project without a file, copy the numeric Project ID from the "About Project" box into `## X-Curse-Project-ID:`, then let the workflow upload the first file.
5. Add screenshots on the project's Images page after approval.

## 3. Wago Addons (second)

1. Log in at https://addons.wago.io/ and open the developer dashboard https://addons.wago.io/developers. Create the project there (the form is not publicly documented; expect name, description, license, source link). Confirm the name TrailMats is free (the public slug https://addons.wago.io/addons/trailmats returned 404 on 2026-10-17, but search could not be verified anonymously).
2. Copy the 8-character project ID printed under the addon name into `## X-Wago-ID:`.
3. Create an API key at https://addons.wago.io/account/apikeys and store it as the GitHub secret `WAGO_API_TOKEN`.
4. Wago accepts flavor "forever" with patch 1.60.1; the packager sets `supported_forever_patches` automatically from `## Interface: 16001`.

## 4. WoWInterface (wait)

- WoWInterface's compatibility list (https://api.wowinterface.com/addons/compatible.json) has no Forever entry. The packager skips the forever type for WoWI and then fails the WoWI step if `## X-WoWI-ID` is set.
- Do not add `## X-WoWI-ID` or the `WOWI_API_TOKEN` secret until Forever appears in that list. When it does: create the addon at https://www.wowinterface.com/downloads/filecpl.php, get a token at https://www.wowinterface.com/downloads/filecpl.php?action=apitokens, store it as `WOWI_API_TOKEN`, add the numeric ID from the addon URL (info<ID>-TrailMats) as `## X-WoWI-ID:`.

## 5. GitHub

- [ ] Repository Settings > Actions > General > Workflow permissions: "Read and write permissions" (otherwise the release step reports "Resource not accessible by integration"). The workflow also declares `permissions: contents: write`.
- [ ] Secrets present: `CF_API_KEY`, `WAGO_API_TOKEN` (and later `WOWI_API_TOKEN`). `GITHUB_TOKEN` is automatic.

## 6. First automated release

1. Make sure `## X-Curse-Project-ID` and `## X-Wago-ID` are committed and `## Version: 0.12.0` matches `Core.lua`.
2. Tag and push: `git tag -a v0.12.0 -m "TrailMats 0.12.0" && git push origin v0.12.0`.
3. Watch the Actions run. Expected log lines: "Game version: 1.60.1", "Using manual changelog CHANGELOG.md", "Moving TrailMats/TrailMats to TrailMats", "Creating archive: TrailMats-v0.12.0-forever.zip (v0.12.0-forever)", then uploads to CurseForge, Wago and a GitHub release named `v0.12.0` with the zip and `release.json` attached.
4. Verify on CurseForge that the file shows flavor Forever / 1.60.1 and that the project page lists Questie as an optional dependency; verify the Wago release shows stability stable and patch 1.60.1.
5. Install from the CurseForge app (or the zip) into `_classic_beta_/Interface/AddOns`, confirm `/tm status` prints 0.12.0, and update the README install section to point at CurseForge/Wago.

## 6a. Re-running the packager for an existing tag

Actions > Package and release > Run workflow, enter the tag (for example `v0.12.0`). The packager updates that tag's GitHub release and re-uploads to any site whose token and project ID are now set, so adding the CurseForge or Wago secrets after a release only needs a re-run, not a new tag. Done this way for v0.12.0 on 2026-10-18 after fixing the token variable name (`GITHUB_OAUTH`).

## 7. After launch (November 4, 2026)

- [ ] Run `/dump select(4, GetBuildInfo())` on the live client; if it is not 16001, add the new number to `## Interface:` and release a patch version.
- [ ] Re-check https://api.wowinterface.com/addons/compatible.json for a Forever entry and complete section 4 if present.
- [ ] Keep the public text honest: counts are estimates; nothing is bought, crafted or trained automatically; plans stop at 225.
