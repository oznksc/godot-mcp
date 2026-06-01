# Animasyon Skill

## AnimationPlayer vs AnimationTree

| Özellik | AnimationPlayer | AnimationTree |
|---------|----------------:|--------------:|
| Basit animasyonlar | Evet | Evet |
| Blend/Transition | Hayır | Evet |
| State Machine | Hayır | Evet |
| karmaşık animasyonlar | Hayır | Evet |

## AnimationPlayer Kullanımı

### Kod ile Animasyon Oluşturma
```gdscript
func create_walk_animation(player: AnimationPlayer) -> void:
    var anim := Animation.new()
    anim.length = 0.5

    # Position track
    var track_idx: int = anim.add_track(Animation.TYPE_VALUE)
    anim.track_set_path(track_idx, "Sprite2D:position")
    anim.track_insert_key(track_idx, 0.0, Vector2(0, 0))
    anim.track_insert_key(track_idx, 0.25, Vector2(10, -5))
    anim.track_insert_key(track_idx, 0.5, Vector2(0, 0))

    player.add_animation("walk", anim)
```

### Animasyon Oynatma
```gdscript
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func play_idle() -> void:
    anim_player.play("idle")

func play_walk() -> void:
    anim_player.play("walk")

func play_hurt() -> void:
    anim_player.play("hurt")
    await anim_player.animation_finished
    play_idle()
```

## AnimationTree State Machine

```
AnimationTree
└── StateMachine (AnimationNodeStateMachine)
    ├── Idle → Walk (transition)
    ├── Walk → Run (transition)
    ├── Walk → Idle (transition)
    ├── Any → Hurt (transition)
    └── Any → Death (transition)
```

```gdscript
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/playback"]

func _ready() -> void:
    anim_tree.active = true

func play_state(state_name: String) -> void:
    state_machine.travel(state_name)

# Blend parameter
func set_blend_parameter(value: float) -> void:
    anim_tree["parameters/Idle/Walk/blend_amount"] = value
```

## Root Motion

```gdscript
# AnimationTree'de root motion etkinleştir
# AnimationTree > Root Motion = True

@onready var anim_tree: AnimationTree = $AnimationTree

func _physics_process(delta: float) -> void:
    var velocity: Vector3 = anim_tree.get_root_motion_position() / delta
    # Hareketi animasyondan al
```

## Tween Animasyonları

```gdscript
# Basit tween
func tween_position(node: Node2D, target: Vector2, duration: float) -> void:
    var tween := create_tween()
    tween.tween_property(node, "position", target, duration)
    await tween.finished

# Zincir tween
func tween_sequence(node: Node2D) -> void:
    var tween := create_tween()
    tween.tween_property(node, "position:x", 100.0, 0.5)
    tween.tween_property(node, "position:y", 100.0, 0.5)
    tween.tween_property(node, "rotation", TAU, 1.0)
    await tween.finished

# Parallel tween
func tween_parallel(node: Node2D) -> void:
    var tween := create_tween().set_parallel(true)
    tween.tween_property(node, "position", Vector2(100, 100), 1.0)
    tween.tween_property(node, "rotation", TAU, 1.0)
    tween.tween_property(node, "scale", Vector2(2, 2), 1.0)
    await tween.finished
```

## Callback Tween

```gdscript
func tween_with_callbacks(node: Node2D) -> void:
    var tween := create_tween()
    tween.tween_callback(Callable(self, "_on_midpoint"))
    tween.tween_property(node, "position:x", 100.0, 0.5)
    tween.tween_callback(Callable(self, "_on_complete"))

func _on_midpoint() -> void:
    print("Yolda!")

func _on_complete() -> void:
    print("Tamamlandı!")
```

## Transition Patterns

```gdscript
# AnimationTree transition kuralları
func setup_transitions(anim_tree: AnimationTree) -> void:
    var state_machine: AnimationNodeStateMachine = anim_tree.get("parameters/playback")

    # Idle → Walk
    var idle_to_walk: AnimationNodeStateMachineTransition = state_machine.get_transition_resource("Idle→Walk")
    idle_to_walk.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
    idle_to_walk.advance_condition = &"is_moving"

    # Any → Hurt
    state_machine.add_transition("Any", "Hurt", "hurt")
```

## Squash & Stretch

```gdscript
# Zıplama squash/stretch
func jump_squash(sprite: Node2D) -> void:
    var tween := create_tween()
    # Stretch (zıplarken)
    tween.tween_property(sprite, "scale", Vector2(0.8, 1.2), 0.1)
    # Squash (havadayken)
    tween.tween_property(sprite, "scale", Vector2(1.1, 0.9), 0.2)
    # Normal (düşerken)
    tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
```

## Procedural Animation

```gdscript
# Weapon bob
func weapon_bob(node: Node2D, delta: float, speed: float) -> void:
    var time: float = Time.get_ticks_msec() / 1000.0
    node.position.x = sin(time * speed) * 2.0
    node.position.y = abs(sin(time * speed * 2.0)) * 1.0

# Camera shake
func camera_shake(camera: Camera2D, intensity: float, duration: float) -> void:
    var original_pos: Vector2 = camera.position
    var tween := create_tween()
    for i in range(int(duration * 20)):
        var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
        tween.tween_property(camera, "position", original_pos + offset, 0.05)
    tween.tween_property(camera, "position", original_pos, 0.1)
```
