# 3D Oyun Kalıpları Skill

## 3D Fizik

### CharacterBody3D (Oyuncu)
```gdscript
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    if direction:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)

    move_and_slide()
```

### Kamera controller (First Person)
```gdscript
extends Camera3D

@export var mouse_sensitivity: float = 0.002
@export var vertical_limit: float = 89.0

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * mouse_sensitivity)
        rotation.x = clamp(rotation.x, deg_to_rad(-vertical_limit), deg_to_rad(vertical_limit))
```

### Third Person Camera
```gdscript
extends Node3D

@export var target: Node3D
@export var distance: float = 5.0
@export var height: float = 2.0
@export var smoothing: float = 5.0

func _process(delta: float) -> void:
    if not target:
        return
    var target_pos: Vector3 = target.global_position + Vector3(0, height, 0)
    var desired_pos: Vector3 = target_pos - target.global_basis.z * distance
    global_position = global_position.lerp(desired_pos, smoothing * delta)
    look_at(target_pos, Vector3.UP)
```

## Işıklandırma

### Three-Point Lighting
```gdscript
# Key Light (Ana ışık)
@onready var key_light: DirectionalLight3D = $KeyLight
# Fill Light (Dolgu ışığı)
@onready var fill_light: DirectionalLight3D = $FillLight
# Back Light (Arkadan ışık)
@onready var back_light: DirectionalLight3D = $BackLight

func setup_three_point() -> void:
    key_light.light_energy = 1.0
    fill_light.light_energy = 0.3
    back_light.light_energy = 0.5
```

### Day/Night Cycle
```gdscript
@export var sun: DirectionalLight3D
@export var day_duration: float = 120.0  # saniye
var time_of_day: float = 0.0

func _process(delta: float) -> void:
    time_of_day += delta / day_duration
    if time_of_day >= 1.0:
        time_of_day = 0.0
    # Sun rotation
    sun.rotation.x = -time_of_day * TAU
    # Color temperature
    var warmth: float = sin(time_of_day * PI)
    sun.light_color = Color(1.0, lerpf(0.8, 1.0, warmth), lerpf(0.6, 1.0, warmth))
    sun.light_energy = lerpf(0.2, 1.2, warmth)
```

## Material ve Shader

### Spatial Material
```gdscript
var mat: StandardMaterial3D = StandardMaterial3D.new()
mat.albedo_color = Color.RED
mat.metallic = 0.8
mat.roughness = 0.2
mat.albedo_texture = preload("res://texture.png")
mesh.set_surface_override_material(0, mat)
```

### PBR Properties
| Property | Değer | Etki |
|----------|-------|------|
| Metallic | 0.0-1.0 | Metaliklik |
| Roughness | 0.0-1.0 | Pürüzlülük |
| Albedo | Renk | Ana renk |
| Normal Map | Texture | Yüzey detayı |
| Emission | Renk | Işıldama |

## NavMesh Yürüme

```gdscript
extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
var target_position: Vector3

func set_target(pos: Vector3) -> void:
    target_position = pos
    nav_agent.target_position = pos

func _physics_process(_delta: float) -> void:
    if nav_agent.is_navigation_finished():
        return
    var next_pos: Vector3 = nav_agent.get_next_path_position()
    var direction: Vector3 = (next_pos - global_position).normalized()
    velocity = direction * 5.0
    move_and_slide()
    # Look at direction
    if velocity.length() > 0.1:
        look_at(global_position + Vector3(velocity.x, 0, velocity.z).normalized(), Vector3.UP)
```

## 3D Collision Layer Rehberi

| Layer | Amaç |
|-------|------|
| 1 | Player |
| 2 | Enemy |
| 3 | Player Projectile |
| 4 | Enemy Projectile |
| 5 | Environment/Wall |
| 6 | Pickup/Item |
| 7 | Trigger Area |
| 8 | Vehicle |

## LOD (Level of Detail)

```gdscript
# Uzaktaki nesneleri basitleştir
@export var lod_distances: Array[float] = [10.0, 30.0, 60.0]
@onready var meshes: Array[MeshInstance3D] = [$HighDetail, $MediumDetail, $LowDetail]

func update_lod(camera_pos: Vector3) -> void:
    var dist: float = global_position.distance_to(camera_pos)
    for i in range(meshes.size()):
        meshes[i].visible = dist < lod_distances[i] if i == 0 else dist >= lod_distances[i-1] and dist < lod_distances[i]
    # En uzaktaki
    if meshes.size() > 0:
        meshes[-1].visible = dist >= lod_distances[-1] if lod_distances.size() > 0 else true
```

## Shadow Settings

```gdscript
# Directional shadow setup
func setup_shadow(light: DirectionalLight3D) -> void:
    light.shadow_enabled = true
    light.shadow_opacity = 0.8
    light.shadow_blur = 1.5
    # Cascaded shadow map
    light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
    light.directional_shadow_max_distance = 100.0
```
