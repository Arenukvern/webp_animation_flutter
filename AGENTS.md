# AGENTS.md — webp_animation_flutter

Short map for humans and agents working this Flutter **library** package.

## What this repo is

High-performance animated (and static) WebP rendering for Flutter, with isolate decoding and optional batch/game-loop sync. Status: proof of concept — see README.

## Where truth lives

| Concern | Source |
| --- | --- |
| Public API & usage | `lib/`, README |
| Example app | `example/` |
| Package metadata | `pubspec.yaml` |
| Native quality gates | commands below |
| Stewardship contract | `steward.yaml` (library baseline; harness off) |
| Contributor credit | `.all-contributorsrc` → README Contributors |

## Native gates (SSOT)

Run from the repo root (and `example/` when touching the demo):

```bash
dart analyze
flutter test
```

Do not invent Steward actions that wrap these until repeated friction earns them.

## Skill Steward (library baseline)

This repo adopts Skill Steward as a **library**, not a harness:

1. Optional CLI: `curl -fsSL https://raw.githubusercontent.com/Arenukvern/skill_steward/main/install.sh | bash`
2. Agent skills: `npx skills add arenukvern/skill_steward -a cursor -y` (start with `repo-quality-system-lifecycle`)
3. Prefer `flutter analyze` / `flutter test` over typed `steward` actions while `stewardship.harness.enabled` is `false`

Badge and adoption notes: [Skill Steward](https://github.com/Arenukvern/skill_steward).

## Contributors

Credit is managed with [all-contributors](https://allcontributors.org/). Source of truth: `.all-contributorsrc`. After a merged PR:

```bash
npx all-contributors-cli add <github-login> code
npx all-contributors-cli generate
```

Commit `.all-contributorsrc` and `README.md` together.
