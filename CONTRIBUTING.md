# Contributing

## The one rule

Every achievement must be **earned**. If a player gets it automatically by
leveling normally, it does not belong here. "Kill Hogger" is filler;
"Solo Hogger before level 10" is an achievement.

## Adding an achievement

Achievements are pure data - one entry in a `Definitions/Ach_*.lua` file,
no engine changes:

```lua
A{
    id          = "hogger_solo_early",           -- unique, stable
    name        = "Hogger Was the Real Boss",
    description = "Solo Hogger before reaching level 10.",
    category    = "NAMED",                       -- see Definitions/Categories.lua
    rarity      = R.EPIC,                        -- drives points + colour
    trigger     = "KILL",                        -- which evaluator handles it
    icon        = "Interface\Icons\Ability_Druid_Maul",
    conditions  = { mobNames = {"Hogger"}, npcIDs = {448},
                    maxPlayerLevel = 9, solo = true },
}
```

Available triggers and their conditions are documented at the top of
`Core/Triggers.lua`. Prefer `mobNames` + `npcIDs` together: names survive
client-build changes, IDs disambiguate shared names (and add `inZone` when
two creatures share a name - there are two "Princess" mobs in Vanilla!).

## Ground rules for PRs

- English creature/zone names, verified in-game (`/ia verify` with the mob
  targeted tells you if it matches).
- Keep classes balanced: class-gated content ships in sets of nine or not at all.
- No participation trophies, no retail ports. Classic Era content only.
- New trigger types belong in `Core/Triggers.lua` as one evaluator; the
  engine itself should not need changes.

## Testing

There is no Lua test runner; validation is structural (unique ids, resolvable
`requires` chains, TOC completeness). If you change definitions, load the
addon in-game once - registration asserts will catch duplicate ids.
