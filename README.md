# Inri's Achievements!

A handcrafted achievement system for **World of Warcraft Classic**, designed to
feel like something Blizzard could have shipped at launch. Every achievement is
meant to represent a genuine accomplishment — *"I actually earned this"* — never
a participation trophy.

> 247 hand-written achievements across 12 categories, fully data-driven and
> built to scale to 400+ without touching core logic. 37 wearable **titles**,
> **Saga meta-chains**, hidden achievements with first-discoverer credit,
> guild leaderboard, speed runs, Rare Radar, and peer-to-peer sync.
>
> **Note:** an English game client is required — kill achievements match
> creature names, which differ on localized clients.

---

## Design philosophy

Achievements must be *earned*, not handed out. Compare:

| ❌ Bad (automatic)     | ✅ Good (earned)                                   |
|------------------------|----------------------------------------------------|
| Kill Hogger            | Kill Hogger before level 11 / solo before level 10 |
| Complete the Deadmines | Complete the Deadmines with no one above level 21  |
| Learn a profession     | Reach 300 skill (Artisan)                           |
| Reach level 5          | Defeat an enemy 10 levels above you                 |

Quality over quantity. No filler.

---

## Rarities & points

| Rarity     | Points | Colour  |
|------------|:------:|---------|
| Common     |   5    | grey    |
| Rare       |   10   | blue    |
| Epic       |   25   | purple  |
| Legendary  |   50   | orange  |

Legendary achievements (Ragnaros, C'Thun, Kel'Thuzad, Exalted with the Brood of
Nozdormu, *The Immortal* — reach 60 deathless) are intended to be genuinely
hard.

---

## Architecture

```
InrisAchievements/
├── InrisAchievements.toc      Load order
├── Localization/
│   └── enUS.lua               All user-facing strings (ns.L)
├── Core/
│   ├── Constants.lua          Rarities, points, opcodes, tunables
│   ├── Util.lua               Stateless helpers (GUID parsing, colour, packing)
│   ├── Database.lua           SavedVariables - the ONLY writer of saved data
│   ├── Engine.lua             Registry + event routing + completion
│   ├── Triggers.lua           One evaluator per trigger type (game logic)
│   ├── Events.lua             Blizzard events -> engine triggers
│   └── Init.lua               Bootstrap + slash commands
├── Definitions/
│   ├── Categories.lua         Category list
│   └── Ach_*.lua              Achievement data (edit ONE file to add one)
├── Networking/
│   └── Comm.lua               Peer-to-peer sync (no external libs)
├── UI/
│   ├── Templates.xml          Reusable widget templates
│   ├── Toast.lua              Earned-achievement toast + queue
│   ├── MainFrame.lua          The browser window
│   ├── Inspect.lua            "View Achievements" on other players
│   └── Minimap.lua            Minimap button
└── Assets/                    (icons use Blizzard's built-in textures)
```

### How it flows

```
Blizzard event ─▶ Events.lua ─▶ Engine:Dispatch(triggerType, payload)
                                     │
                                     ├─ for each achievement watching that
                                     │  trigger (indexed, not a full scan)
                                     ├─ class-gate + dependency check
                                     ├─ Triggers.lua evaluator decides "hit?"
                                     └─ Engine applies result by progress type
                                            │
                                            ├─ Database persists progress
                                            ├─ Toast pops      (callback)
                                            ├─ UI refreshes    (callback)
                                            └─ Comm broadcasts (on level/earn)
```

The engine **never** needs editing to add an achievement. It only needs editing
to add a brand-new *kind* of progress tracking — and that's one evaluator in
`Triggers.lua`.

---

## Adding an achievement (the whole point)

Open the matching `Definitions/Ach_*.lua` and add one entry:

```lua
A{
    id          = "hogger_solo_early",      -- unique
    name        = "Hogger Was the Real Boss",
    description = "Solo Hogger before reaching level 10.",
    category    = "NAMED",                  -- see Categories.lua
    subcategory = "Elwynn & Westfall",
    rarity      = R.EPIC,                    -- drives points + colour
    trigger     = "KILL",                   -- which evaluator handles it
    icon        = "Interface\\Icons\\Ability_Druid_Maul",
    conditions  = { npcIDs = {448}, mobNames = {"Hogger"}, maxPlayerLevel = 9, solo = true },
}
```

That's it. No core changes, no UI changes, no networking changes.

### Trigger types available today

| Trigger      | Earned when…                              | Key conditions |
|--------------|-------------------------------------------|----------------|
| `KILL`       | a creature dies to you/your group         | `npcIDs`, `mobNames`, `maxPlayerLevel`, `solo`, `minLevelAbove`, `maxGroupLevel`, `classification`, `withoutKilling(Names)` |
| `LEVEL`      | you reach a level                         | `level`, `noDeaths` |
| `EXPLORE`    | a zone/subzone becomes current            | `zones` |
| `REP`        | a reputation standing changes             | `faction`/`factionID`, `standing` |
| `QUEST`      | a quest is turned in                      | `questID`/`questIDs`, `maxPlayerLevel` |
| `SKILL`      | a profession rank changes                 | `skill`, `rank` |
| `KILLSTREAK` | N kills within 10 seconds                 | `count` |
| `POINTS`     | total points cross a threshold            | `points` |
| `META`       | all `requires` achievements are complete  | `requires` |

### Progress types

`BOOLEAN` (done/not), `COUNTER` (accumulate to `target`), `PROGRESS` (value vs
`target`, e.g. reputation/skill bars), `STAGED` (named sub-steps, all required —
e.g. *visit all six capitals*).

---

## Titles & Sagas (the endgame)

Classic Era addons can't grant real Blizzard titles — but addon-to-addon we can,
and we aren't limited to Blizzard's list. A title is declared on the achievement
that grants it:

```lua
title = { text = "The Defias Nemesis", rarity = R.EPIC },
```

Complete the achievement → unlock the title. Pick which one you display
(`/ia title`, or the **Titles** button in the window). Your active title is
broadcast in the network summary and shown **rarity-coloured** on your unit
tooltip and inspect profile to anyone else running the addon — so an orange
title instantly signals something extraordinary.

**Sagas** (`Definitions/Ach_Series.lua`) are `META` chains that grant titles and
*reuse* leaf achievement IDs, so one kill counts toward its zone Saga, the
continental Saga, and the grand finale at once:

```
Zone Sagas ─▶ Defender of Elwynn · Hero of Westfall · The Dusk Stalker · The Jungle King
Named Sagas ─▶ The Defias Nemesis · The Scarlet Executioner · Master Hunter · The Dragonslayer
Continental ─▶ Champion of the Eastern Kingdoms
Grand finale ─▶ Legend of Azeroth   (only a handful per server will ever wear it)
```

Hidden achievements can grant **secret titles** (e.g. *Leeroy*) — masked until
earned, then revealed on your profile.

## Multiplayer / sync

Players running the addon discover each other automatically over `GUILD`,
`PARTY`, and `RAID` addon channels (prefix `INRIACH`). Summaries (points, count,
class, faction, highest rarity, version) are throttled; full achievement dumps
are only sent on explicit request (the inspect feature) and are chunked to stay
under the message-size limit.

**Inspect:** right-click another player → **View Achievements** (or
`/ia inspect <name>`). If they don't have the addon, the option reports
gracefully. The profile shows points, completion, notable (epic+) achievements,
and recent earns.

---

## Saved variables

Definitions live in code; only *progress* is saved.

* `InrisAchievementsCharDB` — per character: identity, points, deaths, per-id
  progress, recent list.
* `InrisAchievementsDB` — account-wide: settings (sound/toast/sharing/minimap)
  and the networked roster cache.

Account-wide achievements are a natural future extension: add an account
progress table in `Database.lua` — no other layer needs to change.

---

## Slash commands

```
/ia                 open the window
/ia search <text>   open and search
/ia stats           print points to chat
/ia inspect <name>  view another player's profile
/ia titles          open the title picker
/ia title <name>    equip a title  (/ia title clear to remove)
/ia sync            force a roster sync
/ia config sound|toast|guild   toggle options
/ia reset confirm   wipe THIS character's progress
```

Aliases: `/inri`, `/achievements`.

---

## Scaling to 400+

The foundation is built for it:

* Achievements are indexed by trigger type, so an event only wakes the handful
  of achievements that care — adding hundreds doesn't slow event handling.
* Adding an achievement is a single data entry; adding a category is one line.
* New mechanics are isolated to a single evaluator in `Triggers.lua`.
* The network layer transmits IDs, not definitions, so the wire cost of more
  achievements is just a few more integers.

Future-ready hooks already designed for: guild achievements, seasonal/event
achievements, account-wide progress, and expanded leaderboards.
