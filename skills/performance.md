# Performans Optimizasyonu Skill

## Temel Prensip: "Ölç, Optimiz Et"

Asla tahmin etme. Godot'nun built-in profiler'ını kullan.

## Profiling

### Built-in Profiler
- `Debugger > Monitors` — FPS, Draw Calls, Node sayısı
- `Debugger > Profiler` — CPU kullanımı, fonksiyon süreleri
- `Debugger > Visual Profiler` — GPU zamanlaması

### Kod ile Ölçüm
```gdscript
var start_time: float = Time.get_ticks_usec()
# İşlem
var elapsed: float = Time.get_ticks_usec() - start_time
print("Süre: ", elapsed, " mikrosaniye")
```

## Yaygın Performans Sorunları

### 1. _process vs _physics_process
```gdscript
# ❌ Yanlış - Her frame'de fizik hesabı
func _process(delta: float) -> void:
    if is_on_floor():
        velocity.y = 0

# ✅ Doğru - Fizik için _physics_process
func _physics_process(delta: float) -> void:
    velocity.y += gravity * delta
    move_and_slide()
```

### 2. Node Arama
```gdscript
# ❌ Yanlış - Her frame'de node ara
func _process(_delta: float) -> void:
    var player = get_tree().get_first_node_in_group("player")
    var dir = global_position.direction_to(player.global_position)

# ✅ Doğru - Cache'le
var _player: Node2D

func _ready() -> void:
    _player = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
    if _player and is_instance_valid(_player):
        var dir = global_position.direction_to(_player.global_position)
```

### 3. String İşlemleri
```gdscript
# ❌ Yanlış
if enemy.type == "goblin":
    pass

# ✅ Doğru - StringName
if enemy.type == &"goblin":
    pass

# ❌ Yanlış - String concat
var path = "res://scenes/" + name + ".tscn"

# ✅ Doğru
var path: String = "res://scenes/%s.tscn" % name
```

### 4. Array İşlemleri
```gdscript
# ❌ Yanlış - Size kontrolü her seferinde
for i in range(enemies.size()):
    var enemy = enemies[i]
    if enemy.health <= 0:
        enemies.erase(enemy)

# ✅ Doğru - Ters sırada sil
var to_remove: Array = []
for enemy in enemies:
    if enemy.health <= 0:
        to_remove.append(enemy)
for enemy in to_remove:
    enemies.erase(enemy)

# ✅ En iyi - Filter
enemies = enemies.filter(func(e): return e.health > 0)
```

### 5. Collision Detection
```gdscript
# ❌ Yanlış - Her frame'de area sorgulama
func _process(_delta: float) -> void:
    var bodies = get_overlapping_bodies()  # Her frame!

# ✅ Doğru - Sinyal tabanlı
func _ready() -> void:
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
```

## Görsel Optimizasyon

### Draw Call Azaltma
- `CanvasItem.group_items = true` — Otomatik gruplama
- Texture atlas kullan
- Fewer unique materials = fewer draw calls

### Render Budget
```gdscript
# Uzaktaki nesneleri devre dışı bırak
func _process(_delta: float) -> void:
    var cam_pos: Vector2 = camera.global_position
    for enemy in enemies:
        var dist: float = enemy.global_position.distance_to(cam_pos)
        enemy.visible = dist < 1000.0
        if enemy.has_method("set_physics_process"):
            enemy.set_physics_process(dist < 1000.0)
```

## Hafıza Yönetimi

### Queue Free Zamanlaması
```gdscript
# ❌ Yanlış - Aniden sil
func _on_hit() -> void:
    queue_free()

# ✅ Doğru - Animasyon bekle
func _on_hit() -> void:
    animation_player.play("death")
    # Animasyon bitince sil
    await animation_player.animation_finished
    queue_free()
```

### Resource Caching
```gdscript
# ❌ Yanlış - Her seferinde yükle
func shoot() -> void:
    var bullet = preload("res://bullet.tscn").instantiate()

# ✅ Doğru - @onready ile cache'le
@onready var bullet_scene: PackedScene = preload("res://bullet.tscn")

func shoot() -> void:
    var bullet = bullet_scene.instantiate()
```

## Object Pooling Pattern

```gdscript
# Bullet pool
var bullet_pool: Array[Bullet] = []
var active_bullets: Array[Bullet] = []

func get_bullet() -> Bullet:
    if bullet_pool.size() > 0:
        var bullet: Bullet = bullet_pool.pop_back()
        bullet.show()
        bullet.global_position = muzzle.global_position
        active_bullets.append(bullet)
        return bullet
    var new_bullet: Bullet = bullet_scene.instantiate()
    get_tree().root.add_child(new_bullet)
    active_bullets.append(new_bullet)
    return new_bullet

func return_bullet(bullet: Bullet) -> void:
    active_bullets.erase(bullet)
    bullet.hide()
    bullet.global_position = Vector2(-999, -999)
    bullet_pool.append(bullet)
```

## Monitoring

```gdscript
# FPS göster
func _process(_delta: float) -> void:
    $FPSLabel.text = "FPS: " + str(Engine.get_frames_per_second())

# Node sayacı
func count_nodes() -> int:
    return get_tree().get_node_count()
```
