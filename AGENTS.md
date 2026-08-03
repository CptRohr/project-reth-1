# AGENTS.md

## Source of truth
- `MAINTAINER_NOTE.md` is main repo guide. Read it before feature work.
- `project.godot` is source for autoloads, input map, and main scene.
- `README.md` is project summary only; trust config and code over prose.

## Repo shape
- Godot 4.7 project.
- Main loop: walk around -> interact -> dialogue/activity/door/school/sleep -> state change -> time passes -> world reacts.
- Core buckets: `Scripts/`, `Managers/`, `Scene/`, `Areas/`, `Characters/`, `Dialogue/`, `UI/`, `Assets/`.
- `android/build/` and `.godot/` contain generated/editor output; do not edit by hand.

## Autoloads
Registered in `project.godot`:
- `SceneManager`
- `Transition`
- `GameState`
- `EventManager`
- `DebugHud`
- `PauseMenu`
- `CalendarManager`
- `SchoolSummary`
- `MobileControls`
- `TimeOfDayFilter`
- `TimePassageTransition`
- `WeatherFilter`
- `AudioSettings`
- `Dialogic`
- `CalendarData`
- `ObjectiveHud`
- `NPCData`

## Architecture rules
- Player movement/animation stays in `Scripts/basic_movement.gd`.
- Press-E interaction belongs on interactable object, not player.
- Persistent state goes in `Managers/game_state.gd`; update both save/load paths for any new persistent field.
- Scene change logic stays in `SceneManager`; transition visuals stay in `Transition`.
- Time advancement goes through `GameState` / `TimePassageTransition`, not ad hoc timers.
- Map scripts stay thin: place player, register scene, spawn local objects/NPCs.
- Cutscene shared logic belongs in `Managers/cutscene_director.gd`; cutscene data stays beside cutscene scene under `Areas/Cutscenes/`.

## Content systems
- Dialogic timelines live under `Dialogue/` and character data under `Characters/`.
- Time blocks: `Morning`, `After School`, `Evening`, `Night`.
- Weather data lives in `data/calendar/weather.json`; daily planner data lives in `data/calendar/activities.json`, `special_events.json`, and `weekly_schedule.json`.
- `TimeOfDayFilter` owns time-block tinting; `WeatherFilter` owns rain/lightning/audio.

## Working notes
- No root package manager manifest found; use Godot/editor or repo-local scripts if present.
- Preserve existing file paths and naming; many refs use `res://` paths from `project.godot`.
- Before editing, inspect nearby scene/script patterns; this repo is content-heavy and many systems are scene-linked.
