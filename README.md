# GRIT: Iron Directorate

A Metal Slug style run-and-gun shooter, built in Godot 4. This is Game 1 of a planned trilogy.

1944, in an alternate, diesel-choked world. Sergeant "Grit" Calloway of the Allied Special Operations Vanguard is dropped behind enemy lines to fight through the Iron Directorate and bring Supreme Chancellor Vane to justice.

**Current goal:** one complete level, Mission 1 "Operation Breakwater" (a rain-slicked coastal bunker network), ending in a boss fight against the Seewall gun battery.

## Status

| Step | What | State |
| --- | --- | --- |
| 1 | Design doc | Done |
| 2 | Playable prototype with placeholder art | In progress |
| 3 | Full Mission 1 in gray-box art, with the boss | Not started |
| 4 | Final art, sound, menus and desktop builds | Not started |

## Running the game

1. Install [Godot 4.5](https://godotengine.org/download) (the standard build, not .NET).
2. Clone this repo. With GitHub Desktop it lands in `Documents/GitHub/grit-iron-directorate`.
3. Open Godot, click **Import**, and pick the `project.godot` file in that folder.
4. Press **F5** (or the Play button) to run.

## Controls

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move | Arrow keys or A / D | Left stick or D-pad |
| Aim up | Up or W | Up |
| Crouch / aim down in the air | Down or S | Down |
| Jump (Down + Jump drops through planks) | Z or Space | A / Cross |
| Shoot (knife when an enemy is close) | X or J | X / Square |
| Grenade | C or K | B / Circle |
| Pause | Esc or P | Start |
| Fullscreen | F11 | |

## Project layout

```
project.godot            Engine settings (320x180 pixel-perfect, integer scaling)
scripts/autoload/game.gd Global state: score, lives, grenades, input bindings, signals
scripts/player/          Grit: movement, aiming, weapons, knife, grenades, death and respawn
scripts/enemies/         Enemy behavior (rifleman so far)
scripts/projectiles/     Bullets and grenades
scripts/fx/              Explosions
scripts/pickups/         Weapon and grenade crates, POW prisoners
scripts/camera/          Forward-only scrolling camera with screen shake
scripts/level/           Gray-box blocks, backdrop, level goal
scripts/ui/              HUD, pause and game over screens
scenes/                  Scenes matching the scripts above
scenes/levels/test_range.tscn  The prototype test level (main scene)
tests/                   Automated smoke test and screenshot tour
```

All art is drawn in code for now (`_draw()` placeholders). Real pixel art replaces it in step 4.

## Tests

A bot plays the test range and checks that moving, scrolling, shooting, grenades, POW rescues, weapon pickups, death and respawn all work:

```
godot --headless --fixed-fps 60 res://tests/smoke_test.tscn
```

It prints `SMOKE TEST PASSED` and exits with code 0, or lists what failed and exits with code 1.
