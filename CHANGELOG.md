# Changelog

## [1.0.1] - 2026-07-06
The fairness & secrets update.

### Fixed
- **Kill credit is now earned, not witnessed** - a named mob dying near you no
  longer counts unless you (or your group) actually fought it and it wasn't
  tapped by someone else.
- **Solo and "beat something above you" feats are void if an outside player
  helps** - an ungrouped friend healing you or hitting your target now
  disqualifies the attempt, exactly as it should.
- Clicking an achievement link in chat no longer causes a Lua error.
- Your own guild broadcast line is no longer hidden from you.
- Replaced ~20 icon textures that do not exist in the Classic client (blank
  squares); bad icon paths now fall back to a question mark, and `/ia icons`
  audits every icon against the client's files.

### Added
- **Sealed secrets** - hidden achievements are now encrypted in the source.
  Reading the code spoils nothing; each unseals the moment somebody earns it.
- **Cryptic teasers** - masked secrets now show a riddle instead of a generic
  placeholder. Happy hunting.
- **Discovery sync** - hidden-achievement discoveries now reach players who
  were offline when the news broke (exchanged alongside HELLO).
- **Guild chat announcements** for Rare+ earns and discoveries, visible to
  guildmates without the addon (`/ia config guildflex`); addon users see the
  clickable version instead (`/ia config muteflex`).
- New achievement: **Fizzled Out** - defeat Fizzle Darkstorm before level 11
  (the Horde's own Hogger rite). 247 total.
- **`/ia here`** - lists everything still earnable around your current location,
  rarest first, as clickable links.
- **`/ia config`** now shows every toggle with its live ON/OFF state and a
  plain-English description.
- Joining a group now automatically exchanges summaries and discoveries with
  it (throttled) - discoveries hop between guilds through pugs.

### Removed
- `/ia title <name>` - the `/ia titles` dropdown covers it without typos.


## [1.0.0] - 2026-06-30
Initial release.

- **199 hand-crafted achievements** across 11 categories — every one designed to
  be *earned*, not handed out (e.g. "Kill Hogger before level 11", "Clear the
  Deadmines with no one above level 21", "Reach 60 without dying").
- **Rarities & points** — Common / Rare / Epic / Legendary (5 / 10 / 25 / 50).
- **Custom window** — categories with subcategory sections, search, rarity
  filters, progress bars, total points and completion.
- **Polished toast** on earn (rarity-tinted banner, icon ring, shine sweep).
- **Addon titles** — earned from Sagas & deeds, shown on your character sheet,
  tooltip, inspect panel, and over the nameplates of other addon users.
- **Sagas** — meta-achievement chains (zone → continental → *Legend of Azeroth*)
  that grant titles and reuse achievements across the database.
- **Speed runs** — dungeon clear timers and `/played`-based speed-leveling.
- **Multiplayer** — automatic roster sync over guild/party/raid, right-click
  **View Achievements** to inspect any other addon user, and chat announcements
  with clickable achievement links.
- **Hardcore feats** — deathless leveling milestones with anti-cheese failsafes.
- Custom logo, minimap button, slash commands (`/ia`).

Classic Era only — every achievement maps to original Vanilla content.
