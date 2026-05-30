# Cutscene Director Tutorial

This guide shows how to make an in-engine cutscene using:

- one Godot scene for the staged visuals
- one small scene-specific script
- one JSON file for the timing and actions

The reusable playback script is:

```text
Managers/cutscene_director.gd
```

The opening cutscene is the first example:

```text
Areas/Cutscenes/opening_cutscene.tscn
Areas/Cutscenes/opening_cutscene.gd
Areas/Cutscenes/opening_cutscene.json
```

## What Goes Where

Use this split:

```text
.tscn file  -> visual stage, characters, props, UI labels
.gd file    -> setup unique to this stage
.json file  -> timing, movement, captions, fades, scene changes
```

Example:

```text
opening_cutscene.tscn has World/Girl and World/BlackCar.
opening_cutscene.gd knows what "forest" or "loft" means.
opening_cutscene.json says when the girl moves, when text appears, and when the scene ends.
```

## Step 1: Create The Cutscene Scene

Create a new scene under:

```text
Areas/Cutscenes/
```

For example:

```text
Areas/Cutscenes/example_cutscene.tscn
```

Use a `Node2D` root. Add whatever staged nodes you need. A simple structure can be:

```text
ExampleCutscene
  Camera2D
  World
    Forest
    Cabin
    Girl
    BlackCar
  Overlay
    Root
      CaptionLabel
      PhonePanel
        MarginContainer
          PhoneLabel
      SkipHint
      BlackScreen
```

Important node names:

```text
Overlay/Root/CaptionLabel
Overlay/Root/PhonePanel
Overlay/Root/PhonePanel/MarginContainer/PhoneLabel
Overlay/Root/SkipHint
Overlay/Root/BlackScreen
```

Those are the default paths used by `CutsceneDirector`. If your scene uses different paths, change the exported paths on the root node in the Inspector.

## Step 2: Attach A Scene Script

Create a script next to the scene:

```text
Areas/Cutscenes/example_cutscene.gd
```

Start with this:

```gdscript
extends "res://Managers/cutscene_director.gd"

@onready var forest: Node2D = $World/Forest
@onready var cabin: Node2D = $World/Cabin


func _on_director_ready() -> void:
	show_location("forest")


func show_location(location_name: String) -> void:
	forest.visible = location_name == "forest"
	cabin.visible = location_name == "cabin"
```

This script does not control the timing. It only tells the cutscene what stage-specific words like `"forest"` or `"cabin"` mean.

## Step 3: Create The JSON Timeline

Create:

```text
Areas/Cutscenes/example_cutscene.json
```

Start with this:

```json
{
  "steps": [
    {"action": "black", "visible": true, "alpha": 1.0},
    {"action": "location", "name": "forest"},
    {"action": "fade_black", "from": 1.0, "to": 0.0, "duration": 0.8},

    {"action": "caption", "text": "The forest is quiet."},
    {"action": "wait", "duration": 2.0},

    {"action": "move", "target": "World/Girl", "from": [-500, 200], "to": [0, 200], "duration": 3.0},
    {"action": "wait", "duration": 3.0},

    {"action": "caption", "text": ""},
    {"action": "black", "visible": true, "alpha": 1.0},
    {"action": "change_scene", "scene": "res://Areas/Indoor/home.tscn"}
  ],
  "skip_steps": [
    {"action": "caption", "text": ""},
    {"action": "black", "visible": true, "alpha": 1.0},
    {"action": "change_scene", "scene": "res://Areas/Indoor/home.tscn"}
  ]
}
```

## Step 4: Connect The JSON To The Scene

Open your cutscene scene.

Select the root node.

In the Inspector, set:

```text
timeline_path = res://Areas/Cutscenes/example_cutscene.json
```

Now the scene will play that JSON when it loads.

## Step 5: Add Skip Support

Put this inside `steps` after the first moment you want skipping to be allowed:

```json
{"action": "allow_skip", "value": true, "show_hint": true}
```

After that, the player can skip using:

```text
Space / click / E / pause input
```

When skipped, the director runs `skip_steps`.

## Step 6: Mark Story Progress

If a cutscene should be remembered by save data, set a flag:

```json
{"action": "set_flag", "name": "example_cutscene_completed", "value": true}
```

Use clear names:

```text
opening_cutscene_completed
met_mystery_girl
saw_black_car
```

## Common Actions

Show a stage location:

```json
{"action": "location", "name": "forest"}
```

Show or hide caption text:

```json
{"action": "caption", "text": "Tok tok tok"}
{"action": "caption", "text": ""}
```

Show phone UI:

```json
{"action": "phone", "visible": true, "text": "No signal"}
{"action": "phone", "visible": false}
```

Move a node:

```json
{"action": "move", "target": "World/Girl", "from": [-560, 195], "to": [-110, 195], "duration": 4.0}
```

Set a node position instantly:

```json
{"action": "position", "target": "World/BlackCar", "position": [220, 212]}
```

Show or hide a node:

```json
{"action": "visible", "target": "World/BlackCar", "value": true}
{"action": "visible", "target": "World/BlackCar", "value": false}
```

Wait:

```json
{"action": "wait", "duration": 2.0}
```

Fade from black:

```json
{"action": "fade_black", "from": 1.0, "to": 0.0, "duration": 0.8}
```

Cut to black:

```json
{"action": "black", "visible": true, "alpha": 1.0}
```

Pulse caption text:

```json
{"action": "caption", "text": "Tok tok tok"}
{"action": "pulse_caption", "count": 3, "delay": 0.48}
```

Call a function from the scene script:

```json
{"action": "call", "method": "reset_opening_stage"}
```

Change scene:

```json
{"action": "change_scene", "scene": "res://Areas/Indoor/home.tscn"}
```

## Copy This Mini Template

```json
{
  "steps": [
    {"action": "black", "visible": true, "alpha": 1.0},
    {"action": "location", "name": "forest"},
    {"action": "fade_black", "from": 1.0, "to": 0.0, "duration": 1.0},
    {"action": "allow_skip", "value": true, "show_hint": true},

    {"action": "caption", "text": "First line."},
    {"action": "wait", "duration": 2.0},
    {"action": "caption", "text": "Second line."},
    {"action": "wait", "duration": 2.0},

    {"action": "set_flag", "name": "example_cutscene_completed", "value": true},
    {"action": "black", "visible": true, "alpha": 1.0},
    {"action": "change_scene", "scene": "res://Areas/Indoor/home.tscn"}
  ],
  "skip_steps": [
    {"action": "caption", "text": ""},
    {"action": "set_flag", "name": "example_cutscene_completed", "value": true},
    {"action": "black", "visible": true, "alpha": 1.0},
    {"action": "change_scene", "scene": "res://Areas/Indoor/home.tscn"}
  ]
}
```

## Troubleshooting

If nothing happens:

- Check `timeline_path` on the scene root.
- Check the JSON file is valid.
- Check the target node path exists, like `World/Girl`.

If a `location` does nothing:

- Add that location name to the cutscene scene script's `show_location()` function.

If a warning mentions a missing target:

- The JSON `target` path does not match the scene tree.

If skip does nothing:

- Make sure the JSON has an `allow_skip` action before the moment where you tested skipping.
