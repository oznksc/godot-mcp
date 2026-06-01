# 2D Oyun Kalıpları Skill

## 2D Fizik

### CharacterBody2D (Oyuncu/Düşman)
```gdscript
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
    # Yerçekimi
    if not is_on_floor():
        velocity.y += gravity * delta

    # Zıplama
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Hareket
    var direction: float = Input.get_axis("move_left", "move_right")
    velocity.x = direction * SPEED

    move_and_slide()
```

### RigidBody2D (Fizik Nesneleri)
```gdscript
extends RigidBody2D

func _ready() -> void:
    gravity_scale = 1.0
    linear_damp = 0.5
    angular_damp = 0.5
    contact_monitor = true
    max_contacts_reported = 4

func apply_explosion_force(center: Vector2, force: float) -> void:
    var direction: Vector2 = (global_position - center).normalized()
    var distance: float = global_position.distance_to(center)
    var impulse: float = force / max(distance, 1.0)
    apply_central_impulse(direction * impulse)
```

### Area2D (Tetikleme)
```gdscript
extends Area2D

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
    if body is Player:
        body.take_damage(10)

func _on_body_exited(body: Node2D) -> void:
    if body is Player:
        body.heal(5)
```

## 2D Kamera

```gdscript
extends Camera2D

@export var target: Node2D
@export var smoothing: float = 5.0
@export var look_ahead: float = 50.0

func _ready() -> void:
    make_current()

func _process(delta: float) -> void:
    if not target:
        return

    var target_pos: Vector2 = target.global_position

    # Look ahead
    if target is CharacterBody2D:
        target_pos.x += target.velocity.normalized().x * look_ahead

    # Smoothing
    global_position = global_position.lerp(target_pos, smoothing * delta)
```

### Camera Limits
```gdscript
func setup_camera_limits(camera: Camera2D, level_bounds: Rect2) -> void:
    camera.limit_left = int(level_bounds.position.x)
    camera.limit_top = int(level_bounds.position.y)
    camera.limit_right = int(level_bounds.end.x)
    camera.limit_bottom = int(level_bounds.end.y)
```

## TileMap Kullanımı

```gdscript
# TileMap'e tile ekleme
func place_tile(tilemap: TileMapLayer, pos: Vector2i, source_id: int, atlas: Vector2i) -> void:
    tilemap.set_cell(pos, source_id, atlas)

# Tile okuma
func get_tile_at(tilemap: TileMapLayer, pos: Vector2i) -> int:
    return tilemap.get_cell_source_id(pos)

# TileCoords'tan world pozisyonuna
func tile_to_world(tilemap: TileMapLayer, tile_pos: Vector2i) -> Vector2:
    return tilemap.map_to_local(tile_pos)
```

## Sprite Animasyonu

```gdscript
# AnimatedSprite2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func play_idle() -> void:
    sprite.play("idle")

func play_walk(direction: float) -> void:
    sprite.flip_h = direction < 0
    sprite.play("walk")

func play_death() -> void:
    sprite.play("death")
    await sprite.animation_finished
    queue_free()
```

## Parallax Arka Plan

```gdscript
extends ParallaxBackground

@export var scroll_speed: float = 1.0

func _process(delta: float) -> void:
    scroll_offset.x -= scroll_speed * delta
```

## 2D Collision Layer Rehberi

| Layer | Amaç |
|-------|------|
| 1 | Player |
| 2 | Enemy |
| 3 | Player Bullet |
| 4 | Enemy Bullet |
| 5 | Environment/Wall |
| 6 | Item/Collectible |
| 7 | Trigger Area |

## 2D Tilemap Collision

```
TileMapLayer
├── Ground (Floor tiles - no collision)
├── Walls (Collision tiles)
├── OneWayPlatform (One-way collision)
└── TriggerZones (Area2D based)
```

## Platformer Hareket Kalıpları

### Coyote Time
```gdscript
var coyote_timer: float = 0.0
const COYOTE_TIME: float = 0.1

func _physics_process(delta: float) -> void:
    if is_on_floor():
        coyote_timer = COYOTE_TIME
    else:
        coyote_timer -= delta

    if Input.is_action_just_pressed("jump") and coyote_timer > 0:
        velocity.y = JUMP_VELOCITY
        coyote_timer = 0.0
```

### Jump Buffer
```gdscript
var jump_buffer_timer: float = 0.0
const JUMP_BUFFER_TIME: float = 0.1

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        jump_buffer_timer = JUMP_BUFFER_TIME

func _physics_process(delta: float) -> void:
    jump_buffer_timer -= delta
    if jump_buffer_timer > 0 and is_on_floor():
        velocity.y = JUMP_VELOCITY
        jump_buffer_timer = 0.0
```

### Double Jump
```gdscript
var can_double_jump: bool = true

func _physics_process(delta: float) -> void:
    if is_on_floor():
        can_double_jump = true

    if Input.is_action_just_pressed("jump"):
        if is_on_floor():
            velocity.y = JUMP_VELOCITY
        elif can_double_jump:
            velocity.y = JUMP_VELOCITY * 0.8
            can_double_jump = false
```
