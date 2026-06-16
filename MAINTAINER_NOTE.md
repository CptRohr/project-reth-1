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
TimeOfDayFilter
DebugHud
PauseMenu
CalendarManager
SchoolSummary
MobileControls
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
Assets/Shaders/double_dither_transition.gdshader
```

Door nodes own:

```gdscript
target_scene
target_spawn
```

The transition layer now uses a shader-driven double-dither mask instead of a plain alpha fade.

The flow is:

```text
player enters door Area2D -> presses interact -> player movement disabled -> Transition fades out -> SceneManager changes scene -> next map places player at spawn -> Transition fades in
```

Maintenance rules:

- Door-specific settings belong on the door node.
- Scene changing belongs in `SceneManager`.
- Dither transition behavior belongs in `Transition`.
- The shader visual belongs in `Assets/Shaders/double_dither_transition.gdshader`.
- Keep the public methods `Transition.fade_out()` and `Transition.fade_in()` stable so scene changing code stays simple.
- Maps should have a `SpawnPoints` node with named marker children.
- Area scripts should register the current scene with `GameState.set_scene(scene_file_path)`.

## Cutscenes

Reusable cutscene playback lives in:

```text
Managers/cutscene_director.gd
Managers/cutscene_director.md
```

Cutscene content lives with the cutscene scene:

```text
Areas/Cutscenes/opening_cutscene.tscn
Areas/Cutscenes/opening_cutscene.gd
Areas/Cutscenes/opening_cutscene.json
```

Current flow:

```text
cutscene scene loads -> CutsceneDirector reads timeline_path JSON -> actions play staged nodes/captions/fades -> optional skip_steps run -> SceneManager changes scene
```

Maintenance rules:

- Shared cutscene actions belong in `Managers/cutscene_director.gd`.
- JSON timing/content belongs beside the cutscene scene in `Areas/Cutscenes/`.
- Scene-specific staging belongs in that cutscene's local script, such as mapping location names or fitting placeholder backdrops to fullscreen.
- Persistent story milestones from cutscenes should use `GameState.set_flag()`.
- Scene changes at the end of cutscenes should use the JSON `change_scene` action, which calls `SceneManager.transition_to()`.
- Do not make `CutsceneDirector` an autoload unless multiple unrelated systems need to call it globally.

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

## Time Passage Transition

The editable time-passage screen lives in:

```text
Scene/TimePassageTransition.tscn
Managers/time_passage_transition.gd
```

`TimePassageTransition` is an autoloaded `CanvasLayer` used when activities, school, or sleep advance time. It fades to black, runs the `GameState` time change while the screen is covered, shows centered text, then fades back in.

To change the displayed text without editing code:

1. Open `Scene/TimePassageTransition.tscn`.
2. Select the root `TimePassageTransition` node.
3. Edit these Inspector fields:

```text
Activity Text Template
Empty Activity Text Template
New Day Text Template
```

Supported placeholders:

```text
{activity}
{time}
```

Example templates:

```text
{activity} passed
{time}

After {activity}, time moves on...
{time}

A new day begins
{time}
```

Maintenance rules:

- Visual layout, font, text size, and sample text belong in `Scene/TimePassageTransition.tscn`.
- Text templates should be changed from the scene root's Inspector when possible.
- The script should only handle timing, placeholder replacement, and calling the passed state-change callback.
- Keep this separate from `Transition`; `Transition` is for scene changes, while `TimePassageTransition` is for time passing.

## Time-Of-Day Visual Filter

Temporary global time tint lives in:

```text
Managers/time_of_day_filter.gd
Scene/TimeOfDayFilter.tscn
```

`TimeOfDayFilter` is an autoloaded `CanvasLayer` that listens to `GameState.time_block_changed` and `GameState.state_loaded`. It overlays a subtle `ColorRect` tint based on `GameState.time_block`:

```text
Morning: clear
After School: warm yellow
Evening: pink/purple dusk
Night: blue-dark
```

Maintenance rules:

- This layer is intentionally temporary mood lighting until scene-specific evening/night backgrounds or parallax are ready.
- Time still belongs to `GameState`; the filter only reads time and never advances it.
- Keep the filter below UI layers. It currently uses layer `1`, while pause/school/transition/debug UI use higher layers.
- Tune temporary colors in `TIME_BLOCK_TINTS`.
- Later, this can become the manager that broadcasts visual profiles while outdoor scenes handle their own parallax/background swaps.

## Weather Visual Filter

Daily weather data lives in:

```text
data/calendar/weather.json
```

`CalendarData` loads weather by `YYYY-MM-DD`, `CalendarManager` exposes current-day weather, and `GameState` emits `weather_changed` when the active day changes or save data loads. Missing dates mean `clear`.

Visual weather lives in:

```text
Managers/weather_filter.gd
Scene/WeatherFilter.tscn
```

Maintenance rules:

- `TimeOfDayFilter` still owns the final persistent full-screen tint. It composes time-of-day tint with weather tint so filters do not stack.
- `WeatherFilter` owns weather effects: rain lines, full-screen white lightning flashes, and ambient weather loops.
- Rain uses `Audio/SFX/rain loop.wav`; thunderstorm overlays `Audio/SFX/thunderstorm ambience.wav` on top of the rain loop.
- Outdoor scenes get full weather visuals and audio. Indoor scenes under `res://Areas/Indoor/` get weather audio only, with a lower volume and low-pass muffling.
- Tune weather ids, labels, and tint colors in `GameState`; tune rain/lightning/audio placeholders through exported values in `WeatherFilter`.
- Keep weather below UI layers. `WeatherFilter` uses layer `2`; objective/mobile/pause/school/transition/debug UI use much higher layers.

## Audio Settings

Runtime audio settings live in:

```text
Managers/audio_settings.gd
```

`AudioSettings` creates `SFX`, `Music`, and `WeatherSFX` buses at startup, applies saved volumes from `user://audio_settings.json`, and exposes Master/SFX/Music percentage values to the main menu and pause menu settings screens. `WeatherSFX` routes into `SFX` so the SFX slider still controls weather audio.

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

### Dialogue Camera Zoom & Offset

When a dialogue starts with an NPC, the camera smoothly glides and zooms to focus on a position between the player and the NPC.

> [!NOTE]
> This behavior is handled globally in [basic_movement.gd](file:///d:/GAME%20PROJECT/project-reth-1/Scripts/basic_movement.gd) and utilizes Godot `Tween` logic to animate position and zoom.

#### Global Settings on Player

Configure these defaults globally on the child `Player` (`CharacterBody2D`) node inside [player.tscn](file:///d:/GAME%20PROJECT/project-reth-1/Characters/Main%20Character/player.tscn):

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `dialogue_zoom_enabled` | `bool` | `true` | Enable or disable the dialogue zoom effect. |
| `dialogue_zoom_factor` | `float` | `1.25` | Camera zoom multiplier (e.g. `1.25` zooms in by 25%). |
| `dialogue_zoom_duration` | `float` | `0.5` | Transition speed in seconds. |
| `dialogue_camera_blend` | `float` | `0.5` | Camera target blend between Player (`0.0`) and NPC (`1.0`). |
| `dialogue_camera_offset` | `Vector2` | `(0, 0)` | Vector2 offset added to the camera target position. |

#### Per-NPC Overrides

You can customize camera settings for individual NPCs:
1. Select the NPC instance in your scene.
2. In the inspector, check `override_dialogue_camera` to `true`.
3. Set your custom `dialogue_zoom_factor`, `dialogue_camera_blend`, or `dialogue_camera_offset`.

> [!IMPORTANT]
> If you customize settings on an NPC but forget to check `override_dialogue_camera`, a warning message will be printed to the Godot console at runtime:
> `[CAMERA WARNING] NPC has custom settings, but 'override_dialogue_camera' is FALSE! These NPC settings are ignored.`

## Pause Menu And UI

Pause menu lives in:

```text
Managers/pause_menu.gd
Scene/PauseMenu.tscn
```

It is an autoload `CanvasLayer` scene and currently provides:

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

- Pause menu layout belongs in `Scene/PauseMenu.tscn`.
- Pause menu behavior and data refresh belong in `Managers/pause_menu.gd`.
- Pause menu UI can read `GameState` and `CalendarManager`.
- It should not own gameplay rules.
- When adding new visible stats, update `GameState.PLAYER_STATS`; the Stats screen follows that list.

## Mobile Controls

Mobile controls live in:

```text
Managers/mobile_controls.gd
Scene/MobileControls.tscn
```

It is an autoload `CanvasLayer` scene that creates touch buttons at runtime.

Current buttons:

```text
<  -> move_left
>  -> move_right
E  -> interact
|| -> PauseMenu.toggle_pause_menu()
```

Behavior:

- visible on mobile builds
- optionally visible on desktop touchscreens
- hidden on BootScene and MainMenu
- releases held actions when hidden
- uses the existing input action names so player, NPC, door, school, sleep, and activity scripts keep working

Maintenance rules:

- MobileControls should only bridge touch UI into existing actions.
- Do not put movement, quest, stat, save, or scene logic here.
- If a gameplay script uses `Input.is_action_just_pressed("interact")`, the mobile `E` button should trigger it automatically.
- Pause is called directly because `PauseMenu` listens through `_unhandled_input()` instead of polling.

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
Cutscene JSON playback -> CutsceneDirector
Cutscene stage setup -> cutscene-local script
Player movement -> basic_movement.gd
Map setup/spawn placement -> area scripts
Press-E world object -> interactable script
School popup -> SchoolSummary
NPC-specific dialogue choice -> NPC script
Dialogue text -> Dialogic timeline
Pause/settings/stats/calendar UI -> PauseMenu
Mobile touch buttons -> MobileControls
Temporary dev display -> DebugHud
```

## Recommended Future Cleanup

Folder cleanup can happen later:

```text
Managers/
  game_state.gd
  event_manager.gd
  cutscene_director.gd
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
  Cutscenes/
Scene/
Assets/
Audio/
Fonts/
Styles/
```

Do this cleanup only when ready to update scene/script paths carefully. Godot scenes store script paths, so moving files is a real refactor.

## Feature Recipes

### Use CalendarDB

CalendarDB is the local Windows editor in `Custom Software/CalendarDB/`. Run it with:

```bat
Custom Software\CalendarDB\Run CalendarDB.bat
```

It saves gameplay data into:

```text
data/calendar/activities.json
data/calendar/weekly_schedule.json
data/calendar/special_events.json
data/calendar/weather.json
data/npc/npcs.json
```

CalendarDB uses a guided desktop layout:

```text
Top header  = project path plus Open/Reload, Save, Add Row, Duplicate, Delete, Add Sample Data, Help
Left rail   = Start Here plus Calendar, NPC, and Validation navigation
Main area   = Excel-like editable tables
Left card   = validation summary and color legend
Bottom bar  = last load/save result and output folders
```

Use dropdown cells for fields that should not be typed by hand, such as activity ids, NPC ids, Dialogic timelines, scene paths, and single time blocks. For multi-value fields such as available days, available time blocks, NPC appearance days, and NPC appearance time blocks, double-click the cell to open a checklist picker. Leaving every checkbox empty means "any".

Table editing rules:

1. Use `Add Row` to create a blank row in the current editable section.
2. Select a row before using `Duplicate` or `Delete`.
3. Weekly Schedule is fixed to every day/time block; deleting there clears the selected forced slots instead of removing rows.
4. Red cells block save. Yellow cells are warnings, usually an empty broad filter or optional objective without a completion flag.
5. Save only after the validation card says the data is ready.

Use the Weather tab to assign `clear`, `rain`, or `thunderstorm` to a whole `YYYY-MM-DD` story date. Dates not listed in `weather.json` are clear.

Special event objectives live in the `Special Events` tab:

```text
objective_text            = top-screen objective HUD text
objective_required        = blocks optional/stat activities until complete
objective_complete_flag   = GameState flag that marks the objective done
objective_blocked_message = message shown when a blocked activity is touched
```

Required objectives only block activity interactables that pass stat changes through `CalendarManager.can_perform_activity_now()`. They do not block player movement, scene travel, or dialogue. To complete a required objective, set the matching flag with `GameState.set_flag("flag_name", true)` from the event/activity/dialogue flow.

CalendarDB cell colors:

```text
Red    = invalid value or broken reference. Saving is blocked.
Yellow = broad wildcard/empty filter. Usually valid; means "any".
White  = valid value.
```

NPC workflow:

1. Add the NPC in the `NPCs` tab.
2. Add when and where the pre-placed NPC appears in `NPC Appearance`.
3. Add `NPC Dialogue Routes` only for specific overrides.
4. Leave dialogue routes empty when a custom NPC script should handle progression, such as Abang Brewok's first-met, after-met, and later-day behavior.
5. Set the matching `npc_id` export on the pre-placed NPC node in the scene.

Calendar/event workflow:

1. Add the activity first.
2. Reference that activity from weekly schedule or special events.
3. For custom objective HUD text, fill `Objective Text`.
4. For must-do events, enable `Objective Required` and fill `Objective Complete Flag`.
5. Use `Validation` or live red cells to catch bad ids, timelines, scene paths, days, time blocks, and dates.
6. Save JSON and run Godot.

Common CalendarDB workflows:

1. Add an activity: create it in `Activities`, then reference its `id` from Weekly Schedule or Special Events.
2. Add a special-event objective: create the event in `Special Events`, fill `Objective Text`, enable `Objective Required` for must-do events, and set `Objective Complete Flag`.
3. Add NPC appearance: create the NPC in `NPCs`, then add scene/day/time visibility in `NPC Appearance`.
4. Add NPC dialogue route: add a route in `NPC Dialogue Routes` using an existing Dialogic timeline name from `Dialogue/*.dtl`.

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

### Add A New NPC

Follow this step-by-step checklist to register and place a new NPC in the game:

- [ ] **Step 1: Setup the NPC Scene**
  Instance [NPC.tscn](file:///d:/GAME%20PROJECT/project-reth-1/Characters/NPC/NPC.tscn) in your map scene, or create a new inherited scene from it.
  - Set sprite texture, adjust the `CollisionShape2D` bounds inside `InteractionArea`, and position the node.
  - By default, it runs [npc.gd](file:///d:/GAME%20PROJECT/project-reth-1/Characters/NPC/npc.gd). For custom progression logic (like Abang Brewok), extend `npc.gd` with a new script.

- [ ] **Step 2: Register in CalendarDB**
  Run `Custom Software\CalendarDB\Run CalendarDB.bat` and configure:
  - **NPCs Tab**: Add the NPC metadata and set a unique `npc_id`.
  - **NPC Appearance Tab**: Configure when (`day_index`, `time_block`) and where (`scene_path`) the NPC should be visible.
  - **NPC Dialogue Routes Tab**: Map any Dialogic timelines to execute under specific condition flags (leave empty if handled via local NPC scripts).
  - *Save changes in CalendarDB before continuing.*

- [ ] **Step 3: Configure Node in Scene**
  Select your NPC node in the Godot inspector and verify these settings:
  - `npc_id`: Must match the exact ID created in CalendarDB.
  - `timeline_name`: Default Dialogic timeline (e.g., `test` corresponding to [test.dtl](file:///d:/GAME%20PROJECT/project-reth-1/Dialogue/test.dtl)).
  - `timeline_rules`: Optional rule list for choosing timelines dynamically.
  - **Dialogue Camera Override**: Customize camera angles (zoom factor, offset, blend) for this NPC if needed, and make sure to check `override_dialogue_camera`.

- [ ] **Step 4: Verify in Game**
  - Launch the game, play until the scheduled day/time block, and travel to the target scene to confirm the NPC spawned.
  - Move near the NPC, press `E` to interact, and verify that the dialogue starts and camera zoom functions properly.

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
