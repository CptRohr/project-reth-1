# Project Maintainer Note

This project is currently a 2D life-sim/RPG foundation. The main loop is:

```text
walk around -> interact -> dialogue/activity/door/school/sleep -> state changes -> time passes -> world reacts
```

Most code should fit into one of these buckets:

```text
Player
World/Scenes
Interactables
Dialogue/NPCs
Game State
Calendar/Planner
Events
Save/Load
Debug/UI
```

Keep systems small and boring. Before adding a feature, answer:

- Where is the data stored?
- Who is allowed to change it?
- Who only reads it?
- Does it need to be saved?
- Is this reusable behavior or one scene/NPC's special case?

## Current Autoloads

Autoloads are registered in `project.godot`:

```text
SceneManager
Dialogic
Transition
GameState
EventManager
DebugHud
PauseMenu
CalendarManager
SchoolSummary
```

Use autoloads for systems that many scenes need. Do not turn every helper into an autoload.

## Player

Player movement lives in:

```text
Scripts/basic_movement.gd
Characters/Main Character/player.tscn
```

The player script currently handles:

- left/right movement
- gravity and `move_and_slide()`
- sprite facing
- idle/walk animation
- disabling movement while Dialogic timelines run
- simple interaction debug prints

Maintenance rules:

- Movement and animation changes belong here.
- Quest, day, save, stat, activity, and NPC logic do not belong here.
- When movement is disabled, force `idle` so the walk animation does not get stuck.
- Press-E gameplay should usually live on the thing being interacted with, not on the player.

## Scene Transitions

Transition flow lives in:

```text
Scripts/door_transition.gd
Scene/door_transition.tscn
Managers/scene_manager.gd
Managers/transition_layer.gd
Scene/transition_layer.tscn
```

Door nodes own:

```gdscript
target_scene
target_spawn
```

The flow is:

```text
player enters door Area2D -> presses interact -> player movement disabled -> Transition fades out -> SceneManager changes scene -> next map places player at spawn -> Transition fades in
```

Maintenance rules:

- Door-specific settings belong on the door node.
- Scene changing belongs in `SceneManager`.
- Fade animation belongs in `Transition`.
- Maps should have a `SpawnPoints` node with named marker children.
- Area scripts should register the current scene with `GameState.set_scene(scene_file_path)`.

## Maps / Areas

Current map scripts:

```text
Areas/street.gd
Areas/street_2.gd
Areas/Indoor/home.gd
Areas/Indoor/warung.gd
```

They currently:

- find the `SpawnPoints` node
- place the player at `SceneManager.spawn_id` when possible
- save the active scene path into `GameState`

Maintenance rules:

- Area scripts should stay simple.
- They can initialize the map, place the player, and later spawn local NPCs/objects.
- Avoid putting large gameplay systems in map scripts.

## Game State

Persistent game memory lives in:

```text
Managers/game_state.gd
```

It owns:

- `calendar_day_index`
- computed `day`
- `time_block`
- `flags`
- `stats`
- `current_spawn`
- `current_scene`
- save/load conversion

Important signals:

```gdscript
day_changed(new_day)
time_block_changed(new_time_block)
flag_changed(flag_name, value)
stat_changed(stat_name, value, amount)
activity_completed(activity_id, activity_name)
state_loaded
state_changed
```

Maintenance rules:

- If the game must remember something across scenes or saves, put it in `GameState`.
- Do not scatter important state across NPCs or maps.
- Temporary local state can stay on the object that owns it.
- Any new persistent field must be added to both `to_save_data()` and `load_from_data()`.

Common examples:

```gdscript
GameState.set_flag("met_abang_brewok", true)
GameState.get_flag("met_abang_brewok")
GameState.sleep_to_next_day()
GameState.advance_time_block()
GameState.get_stat("Knowledge")
```

## Time System

Time blocks are defined in `GameState.TIME_BLOCKS`:

```text
Morning -> After School -> Evening -> Night -> next day Morning
```

Controlled by:

```gdscript
GameState.set_time_block("after_school")
GameState.advance_time_block()
GameState.sleep_to_next_day()
GameState.perform_activity(activity_id, activity_name, time_blocks_to_advance, stat_changes)
```

Rules:

- Activities advance time.
- School moves from Morning to After School.
- Sleeping advances to the next date, resets time to Morning, and restores Energy.
- If the player spends time doing something in the world, use `activity_interactable.gd`.

## Calendar And Daily Planner

Calendar logic lives in:

```text
Managers/calendar_manager.gd
```

It owns:

- story year display
- story month order
- month lengths
- weekday calculation
- date keys like `"05/12"`
- school day detection
- calendar grid generation
- lightweight daily plan data

Daily plan data currently lives in:

```gdscript
CalendarManager.DAILY_PLANS
```

Each entry is keyed by `"MM/DD"`:

```gdscript
"05/12": {
	"planned_activities": ["Study at library"],
	"objectives": ["Study at library"],
	"reminders": [],
	"events": [],
}
```

Useful APIs:

```gdscript
CalendarManager.get_date_info(day_index)
CalendarManager.get_display_date(day_index)
CalendarManager.get_current_date_key()
CalendarManager.parse_date_key("05/12")
CalendarManager.is_school_day(day_index)
CalendarManager.get_daily_plan(day_index)
CalendarManager.get_current_daily_plan()
CalendarManager.has_daily_plan(day_index)
CalendarManager.get_daily_plan_summary(day_index)
CalendarManager.get_month_grid(month, selected_day_index)
```

Maintenance rules:

- Calendar math and planner data belong in `CalendarManager`.
- `GameState` stores which date the player is on.
- UI only reads calendar data; UI should not own calendar rules.
- For now, planner data is hardcoded for easy editing. Later it can move to JSON or Resources if content grows.

## Stats And Energy

Stats are stored in:

```gdscript
GameState.stats
```

Canonical stats:

```text
Knowledge
Charm
Courage
Social
Creativity
Energy
```

Current rules:

- All stats are clamped to `0..100`.
- New games initialize all stats.
- Energy defaults to `100`.
- Sleeping restores Energy to `100`.
- Other stats should grow slowly through activities.
- Save/load normalizes missing old-save stats into the new stat shape.

Useful APIs:

```gdscript
GameState.get_stat("Knowledge")
GameState.set_stat("Knowledge", 10)
GameState.add_stat("Knowledge", 2)
GameState.get_player_stats()
GameState.can_spend_energy(2)
GameState.spend_energy(2)
GameState.restore_energy()
```

Maintenance rules:

- Do not create separate variables like `knowledge`, `charm`, or `courage` in random scripts.
- Use the exact canonical stat names unless intentionally adding a new stat.
- Update `GameState.PLAYER_STATS` if adding/removing a visible stat.
- Keep Energy as the activity resource; keep long-term growth stats slow.

## Activities

Reusable activity behavior lives in:

```text
Scripts/activity_interactable.gd
```

Attach it to an `Area2D` with a `CollisionShape2D`.

Exported fields:

```gdscript
activity_id
activity_name
time_blocks_to_advance
save_after_activity
once_per_day
stat_changes
energy_cost
minimum_energy
success_message
not_enough_energy_message
```

Current activity flow:

```text
player enters activity Area2D -> presses interact -> once-per-day check -> Energy check -> spend Energy -> mark done today if needed -> GameState.perform_activity() applies stats and advances time -> save -> debug feedback
```

Example activity setup:

```gdscript
activity_id = "study_library"
activity_name = "Studying"
stat_changes = {"Knowledge": 2}
energy_cost = 2
minimum_energy = 2
success_message = "Studied at the library. Knowledge +2. Energy -2."
```

Maintenance rules:

- Reusable "spend time to gain stats" behavior belongs here.
- One-off story logic can use a special script, but should still write persistent state through `GameState`.
- `minimum_energy` defaults conceptually to `energy_cost` when set to `0`.
- Use `once_per_day` for activities that should only run once per calendar day.
- Activity IDs should be stable strings because they are used in flags.

Current sample:

```text
Areas/street.tscn -> PassTimeTest
```

This is configured as a sample Studying activity:

```text
+2 Knowledge, -2 Energy
```

## School

School interaction lives in:

```text
Scripts/school_interactable.gd
Managers/school_summary.gd
```

Flow:

```text
player presses interact at school -> must be Morning -> must be a school day -> SchoolSummary pauses game -> Continue moves time to After School -> optional save
```

Maintenance rules:

- School availability rules belong in `school_interactable.gd` and `CalendarManager`.
- The summary popup belongs in `SchoolSummary`.
- If school starts giving stat rewards later, call `GameState.apply_stat_changes()` or add a small school-specific API in `GameState`.

## Sleep

Sleep interaction lives in:

```text
Scripts/sleep_interactable.gd
```

Attach it to an `Area2D` with a `CollisionShape2D`.

Current behavior:

- pressing interact calls `GameState.sleep_to_next_day()`
- saves after sleeping when `save_after_sleep` is true
- shows a DebugHud message

Maintenance rules:

- Sleep is the main Energy restore point.
- If adding bedtime restrictions, keep the rule in `sleep_interactable.gd` or a small time helper, not in the player.

## Events

Event helpers live in:

```text
Managers/event_manager.gd
```

It handles:

- once-only events
- once-per-day events
- choosing Dialogic timelines from rule dictionaries

Useful APIs:

```gdscript
EventManager.can_run_once("first_meeting")
EventManager.mark_completed("first_meeting")
EventManager.can_run_today("study_library")
EventManager.mark_done_today("study_library")
EventManager.choose_timeline(default_timeline, timeline_rules)
```

Timeline rule fields currently supported:

```text
timeline
day_min
day_max
date
date_min
date_max
weekday
time_block
flags
not_flags
```

Maintenance rules:

- If the question is "can this happen?", ask `EventManager`.
- If the question is "what is the current day/stat/flag?", ask `GameState`.
- Event completion data is stored as flags in `GameState`.

## NPCs And Dialogue

NPC scripts:

```text
Characters/NPC/npc.gd
Characters/NPC/abang_brewok.gd
```

Dialogue timelines:

```text
Dialogue/AbangBrewok.dtl
Dialogue/AbangBrewok_AfterMet.dtl
Dialogue/AbangBrewok_LaterDay.dtl
Dialogue/test.dtl
```

NPC behavior:

- detect when the player is nearby
- press interact to choose/start a Dialogic timeline
- use `EventManager.choose_timeline()` for rule-based dialogue

Abang Brewok currently uses:

```text
met_abang_brewok
met_abang_brewok_day
```

Maintenance rules:

- Dialogue text belongs in Dialogic timelines, not hardcoded in GDScript.
- NPC-specific state selection can live in that NPC script.
- Shared NPC behavior should eventually become a base NPC script.
- Persistent relationship/story state should be written through `GameState` flags or stats.

## Pause Menu And UI

Pause menu lives in:

```text
Managers/pause_menu.gd
```

It is an autoload `CanvasLayer` and currently provides:

- Resume
- Stats
- Calendar
- Settings
- Main Menu
- Quit Game

Stats screen:

- reads `GameState.get_player_stats()`
- displays all stats in `GameState.PLAYER_STATS`
- displays Energy as `current / 100`

Calendar screen:

- reads month grids from `CalendarManager`
- supports Previous, Today, Next, Back
- highlights today
- shows routine labels like School or Free Day
- shows a simple marker/summary for planned dates

Settings:

- resolution selection
- fullscreen toggle
- VSync toggle

Maintenance rules:

- Pause menu UI can read `GameState` and `CalendarManager`.
- It should not own gameplay rules.
- When adding new visible stats, update `GameState.PLAYER_STATS`; the Stats screen follows that list.

## Main Menu

Main menu logic lives in:

```text
Scripts/main_menu.gd
Scene/MainMenu.tscn
```

Current behavior:

- starts a new game
- loads first scene from `first_scene_path`
- exposes basic settings
- quits the game

Maintenance rules:

- Start-new-game setup belongs here only at the entry point.
- Persistent defaults belong in `GameState.reset_game()`.
- Keep settings logic consistent with `PauseMenu`.

## Save / Load

Save/load lives mainly in:

```text
Managers/game_state.gd
Managers/scene_manager.gd
```

Save path:

```text
user://save_game.json
```

Currently saved:

- `calendar_day_index`
- `time_block`
- `flags`
- `stats`
- `current_spawn`
- `current_scene`

Loading:

- supports older `day` saves as a fallback
- converts old `"afternoon"` time block to `"after_school"`
- normalizes stats so old saves gain the new stat defaults

Maintenance rules:

- Persistent data must be included in both `to_save_data()` and `load_from_data()`.
- Temporary object state should not be saved.
- Save format compatibility matters while iterating; add fallbacks when renaming old fields.

## Debug HUD

Debug display lives in:

```text
Managers/debug_hud.gd
```

It currently shows:

- FPS
- date
- time block
- spawn
- scene
- temporary messages
- stats when present

Maintenance rules:

- This is development-only.
- It can stay ugly while systems are being built.
- Use `DebugHud.show_message("text")` for quick feedback.
- Later, hide or replace it with proper UI.

## Strict GDScript Notes

The project/editor is treating some warnings as errors. Be careful with Variant inference.

Prefer explicit types when a value comes from:

- dictionaries
- JSON
- autoload method calls returning `Dictionary`
- `max()` / `min()` when the compiler sees Variant

Examples:

```gdscript
var player_stats: Dictionary = GameState.get_player_stats()
var energy_cost: int = max(amount, 0)
var plan: Dictionary = CalendarManager.get_daily_plan(day_index)
```

Avoid relying on inferred types from dynamic data when editing manager code.

## What Goes Where

Use this rule:

```text
Remembering persistent data -> GameState
Calendar/date/planner data -> CalendarManager
Checking if event can happen -> EventManager
Changing scene -> SceneManager
Fade transition -> Transition
Player movement -> basic_movement.gd
Map setup/spawn placement -> area scripts
Press-E world object -> interactable script
School popup -> SchoolSummary
NPC-specific dialogue choice -> NPC script
Dialogue text -> Dialogic timeline
Pause/settings/stats/calendar UI -> PauseMenu
Temporary dev display -> DebugHud
```

## Recommended Future Cleanup

Folder cleanup can happen later:

```text
Managers/
  game_state.gd
  event_manager.gd
  calendar_manager.gd
  scene_manager.gd
  transition_layer.gd
  pause_menu.gd
  school_summary.gd
  debug_hud.gd

Scripts/
  Player/
    basic_movement.gd
  Interactables/
    activity_interactable.gd
    sleep_interactable.gd
    school_interactable.gd
    door_transition.gd
  UI/
    main_menu.gd
    bootscreen.gd

Characters/
  Main Character/
  NPC/

Dialogue/
Areas/
Scene/
Assets/
Audio/
Fonts/
Styles/
```

Do this cleanup only when ready to update scene/script paths carefully. Godot scenes store script paths, so moving files is a real refactor.

## Feature Recipes

### Add A New Stat

1. Add the stat name to `GameState.PLAYER_STATS`.
2. Decide its default in `GameState.get_default_stat_value()`.
3. Use `GameState.add_stat("StatName", amount)` or activity `stat_changes`.
4. Confirm PauseMenu Stats displays it.
5. Confirm save/load still normalizes old saves.

### Add A New Activity

1. Add an `Area2D` to a map.
2. Add a `CollisionShape2D`.
3. Attach `Scripts/activity_interactable.gd`.
4. Set:

```gdscript
activity_id = "unique_activity_id"
activity_name = "Readable Name"
stat_changes = {"Knowledge": 2}
energy_cost = 2
minimum_energy = 2
time_blocks_to_advance = 1
once_per_day = false
```

5. Add optional feedback messages.
6. Test with enough Energy and low Energy.

### Add A Daily Objective

1. Open `Managers/calendar_manager.gd`.
2. Add or edit a `DAILY_PLANS` entry:

```gdscript
"06/01": {
	"planned_activities": ["Draw after school"],
	"objectives": ["Practice drawing"],
	"reminders": ["Bring sketchbook"],
	"events": [],
}
```

3. Open the pause menu calendar and check that the date shows a plan marker.

### Add An NPC Dialogue Variant

1. Create/edit a Dialogic timeline in `Dialogue/`.
2. Add rules to an NPC's `timeline_rules` export or special NPC script.
3. Use `EventManager` rule fields such as `date`, `weekday`, `time_block`, `flags`, or `not_flags`.
4. Store persistent milestones with `GameState.set_flag()`.

### Add A Door

1. Instance `Scene/door_transition.tscn` or create an `Area2D` with `Scripts/door_transition.gd`.
2. Set `target_scene`.
3. Set `target_spawn`.
4. Ensure the destination map has `SpawnPoints/target_spawn`.

## Golden Rule

Keep gameplay systems predictable:

```text
Data lives in one place.
Rules live near the system they belong to.
UI reads and displays.
Interactables trigger reusable behavior.
NPCs choose dialogue.
Maps stay boring.
```

