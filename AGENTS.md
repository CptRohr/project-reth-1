# AGENTS.md

## Read first
- `MAINTAINER_NOTE.md` is main source of repo rules.
- `project.godot` is source of truth for autoloads, input map, main scene.
- `README.md` is summary only.

## Verify
- No automated tests here. Verify in Godot Editor.
- Do not invent CLI test commands.
- `data/calendar/` and `data/npc/` are driven by `Custom Software/CalendarDB/Run CalendarDB.bat`; keep JSON/schema refs intact.

## GDScript rules
- Godot treats warning-level issues as errors here.
- Use explicit types for values from JSON, `Dictionary`, and untyped returns.

## Architecture rules
- Persistent state lives in `Managers/game_state.gd`; new save data must go in both `to_save_data()` and `load_from_data()`.
- Time advances through `GameState` / `TimePassageTransition`, not ad hoc timers.
- Press-E interaction belongs on interactable object, not player movement.
- `Scripts/basic_movement.gd` owns player movement and dialogue camera zoom.
- `TimeOfDayFilter` owns time-block sky/tint/brightness; `WeatherFilter` owns rain, flashes, and weather audio.
- Dialogic timelines live under `Dialogue/`; do not hardcode dialogue text in GDScript.
- Custom NPC dialogue camera settings only apply when `override_dialogue_camera = true`.
