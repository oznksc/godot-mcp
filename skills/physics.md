# Fizik Sistemi Skill

## Fizik Node Karşılaştırması

| Node | Kullanım | Fizik Motoru |
|------|----------|:------------:|
| CharacterBody2D/3D | Oyuncu, NPC | Manuel |
| RigidBody2D/3D | Kutu, top, serbest nesne | Fizik motoru |
| StaticBody2D/3D | Duvar, zemin | Sabit |
| Area2D/3D | Tetikleme alanı | Hayır |

## CharacterBody (Manuel Kontrol)

```gdscript
extends CharacterBody3D

const SPEED = 5.0
const ACCELERATION = 10.0
const FRICTION = 8.0

func _physics_process(delta: float) -> void:
    var input_dir: Vector2 = Input.get_vector("left", "right", "forward", "back")
    var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    if direction:
        velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION * delta)
        velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCELERATION * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
        velocity.z = move_toward(velocity.z, 0, FRICTION * delta)

    # Yerçekimi
    if not is_on_floor():
        velocity.y -= 9.8 * delta

    move_and_slide()
```

### Wall Sliding
```gdscript
func _physics_process(delta: float) -> void:
    # ... hareket kodu
    move_and_slide()

    # Duvar kontrolü
    if is_on_wall():
        var wall_normal: Vector3 = get_wall_normal()
        # Duvara yapışma
        if velocity.y < 0:
            velocity.y *= 0.8  # Yavaş kayma
```

## RigidBody (Fizik Motoru)

```gdscript
extends RigidBody3D

func _ready() -> void:
    gravity_scale = 1.0
    linear_damp = 0.5
    angular_damp = 0.5

func apply_force_at_point(force: Vector3, point: Vector3) -> void:
    apply_impulse(force, point - global_position)

func explode(center: Vector3, force: float, radius: float) -> void:
    var dir: Vector3 = (global_position - center).normalized()
    var dist: float = global_position.distance_to(center)
    var strength: float = force * (1.0 - dist / radius)
    if strength > 0:
        apply_central_impulse(dir * strength)
```

## Collision Layer Rehberi

| Layer | İsim | Collision Mask |
|-------|------|:-------------:|
| 1 | Player | 2,5,6,7 |
| 2 | Enemy | 1,3,5 |
| 3 | Player Bullet | 2,5 |
| 4 | Enemy Bullet | 1,5 |
| 5 | Environment | Hepsi |
| 6 | Item | 1 |
| 7 | Trigger | — |

## Collision Shape Rehberi

| Shape | Kullanım | Performans |
|-------|----------|:----------:|
| RectangleShape2D | Kutular, platformlar | En hızlı |
| CircleShape2D | Top, küre | Çok hızlı |
| CapsuleShape2D | Karakterler | Hızlı |
| ConvexPolygonShape2D | Karmaşık şekiller | Orta |
| ConcavePolygonShape2D | Detaylı ortam | Yavaş |
| BoxShape3D | Kutular | En hızlı |
| SphereShape3D | Küreler | Çok hızlı |

## Collision Detection

```gdscript
# Area2D ile tespit
func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.has_method("take_damage"):
        body.take_damage(damage)
```

## Raycast Kullanımı

```gdscript
# 2D Raycast
@onready var ray: RayCast2D = $RayCast2D

func check_ground() -> bool:
    ray.force_raycast_update()
    return ray.is_colliding()

func get_ground_normal() -> Vector2:
    ray.force_raycast_update()
    if ray.is_colliding():
        return ray.get_collision_normal()
    return Vector2.UP
```

## One-Way Collision

```gdscript
# Platform için one-way collision
# CollisionShape2D > one_way_collision = true
# Sadece yukarıdan geçilir

func _on_one_way_platform_body_entered(body: Node2D) -> void:
    if body is CharacterBody2D:
        if body.velocity.y < 0:
            # Oyuncu aşağıdan geliyor, çarpışmayı yok say
            body.set_collision_mask_value(5, false)
            await get_tree().create_timer(0.2).timeout
            body.set_collision_mask_value(5, true)
```

## Physics Material

```gdscript
# Zıplayan top
var mat: PhysicsMaterial = PhysicsMaterial.new()
mat.bounce = 0.8
mat.friction = 0.3
$RigidBody2D.physics_material_override = mat

# Buz yüzeyi
var ice_mat: PhysicsMaterial = PhysicsMaterial.new()
ice_mat.friction = 0.05
ice_mat.bounce = 0.1
```

## Buoyancy (Suda Yüzdürme)

```gdscript
func _on_water_area_body_entered(body: Node3D) -> void:
    if body is RigidBody3D:
        body.gravity_scale = 0.3
        body.linear_damp = 2.0

func _on_water_area_body_exited(body: Node3D) -> void:
    if body is RigidBody3D:
        body.gravity_scale = 1.0
        body.linear_damp = 0.5
```

## Spring Joint

```gdscript
# RigidBody3D'yi sabit noktaya bağla
func create_spring(body: RigidBody3D, anchor: Vector3, stiffness: float) -> void:
    var joint := DampedSpringJoint3D.new()
    joint.node_a = body.get_path()
    joint.node_b = get_path()
    joint.rest_length = 1.0
    # Spring parametreleri via physics process
```
