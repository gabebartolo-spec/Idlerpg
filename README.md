# Idle RPG — fresh start

This branch intentionally replaces the previous **Vesperbell** prototype with a much smaller foundation.

## Direction

- **Godot 4.7.2**
- **Android / portrait first**
- **Low-poly 3D**, inspired by the readable simplicity of early 3D MMOs rather than copied assets or environments.
- Core fantasy: make an adventurer, send them out, come back to progress, loot and stories, improve the build, repeat.
- **Gacha is a major progression pillar.** The foundation starts with reusable Gear, Companion and Relic banners rather than hard-wiring one loot box.
- Keep the first playable loop tiny. Do not rebuild a giant content architecture before the runtime and phone experience are proven.

## Current prototype

The main scene creates a tiny primitive 3D test world and a portrait summon interface.

Gacha currently has:
- Gear Cache
- Companion Pact
- Relic Vault
- 1x and 10x pulls
- 1% legendary base rate
- hard legendary pity on pull 90
- a shared token wallet

These numbers are prototype values, not monetisation decisions.

## Debug tools

Debug/editor builds expose a **Dev tools** panel with:

- **Infinite gacha tokens** — pulls cost nothing while enabled.
- **+10,000 tokens**
- **100-pull stress test**
- **Reset pity counters**

These tools are gated behind Godot debug/editor state and are not intended for release builds.

## Next build order

1. Prove the primitive 3D scene and touch UI on Android.
2. Add the actual idle expedition timer + offline resolution.
3. Turn gacha results into usable gear/companions/relics.
4. Add inventory/equip decisions.
5. Only then expand zones, classes, combat depth and content.

The old Vesperbell implementation remains recoverable from Git history. It should not be copied forward wholesale.

## Tests

```sh
scripts/run_tests.sh
```

The current test covers normal token spending, insufficient funds, debug infinite-token pulls, 100-pull stress usage and hard pity.
