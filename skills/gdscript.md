# GDScript Skill — Kodlama Rehberi

## Temel Kurallar

### İsimlendirme
- **Sınıflar**: PascalCase — `PlayerController`, `EnemySpawner`
- **Değişkenler**: snake_case — `move_speed`, `current_health`
- **Fonksiyonlar**: snake_case — `take_damage()`, `get_closest_enemy()`
- **Sabitler**: UPPER_SNAKE — `MAX_SPEED`, `GRAVITY`
- **Sinyaller**: snake_case, fiil — `health_changed`, `died`, `item_picked_up`
- **Özel değişkenler**: `_` ile başla — `_velocity`, `_is_alive`

### Type Hints (Zorunlu)
```gdscript
# Doğru
var speed: float = 200.0
var inventory: Array[String] = []
var target: Node2D = null

func take_damage(amount: int) -> void:
    health -= amount

func get_nearest_enemy() -> Enemy:
    return closest_enemy

# Yanlış
var speed = 200.0  # Type hint yok
```

### Enum Kullanımı
```gdscript
enum State { IDLE, RUNNING, JUMPING, FALLING }
var current_state: State = State.IDLE

enum Weapon { SWORD, BOW, STAFF }
var equipped_weapon: Weapon = Weapon.SWORD
```

## Fonksiyon Kalıpları

### Getter/Setter
```gdscript
var health: int:
    set(value):
        health = clampi(value, 0, max_health)
        health_changed.emit(health)
    get:
        return health
```

### Builder Pattern
```gdscript
static func create_enemy(type: StringName, pos: Vector2) -> Enemy:
    var enemy: Enemy = ENEMY_SCENES[type].instantiate()
    enemy.global_position = pos
    return enemy
```

### Early Return
```gdscript
func interact(target: Node2D) -> void:
    if not target is Player:
        return
    if not can_interact:
        return
    if inventory.size() >= max_slots:
        return
    # Asıl mantık burada
    _pick_up_item(target)
```

## Yaygın Hatalar

### 1. Null Reference
```gdscript
# Yanlış
var node = get_node("Player")
node.health -= 10  # node null olabilir

# Doğru
var node := get_node_or_null("Player") as Node2D
if node:
    node.health -= 10
```

### 2. Signal Disconnect Hataları
```gdscript
# Yanlış - connect edilmemiş signal'ı disconnect etmeye çalışma
signal.d.disconnect(callable)  # Hata!

# Doğru
if signal.is_connected(callable):
    signal.disconnect(callable)
```

### 3. Frame-based Hatalar
```gdscript
# Yanlış - _process'de her frame node arama
func _process(_delta: float) -> void:
    var enemy = get_closest_enemy()  # Her frame!

# Doğru - Cache'le
var _cached_enemy: Enemy

func _ready() -> void:
    _cached_enemy = get_closest_enemy()

func _process(_delta: float) -> void:
    if _cached_enemy and not _cached_enemy.is_inside_tree():
        _cached_enemy = get_closest_enemy()
```

### 4. String Comparison
```gdscript
# Yanlış
if enemy.type == "goblin":  # Yavaş

# Doğru
if enemy.type == &"goblin":  # StringName, hızlı
```

## Performans İpuçları

```gdscript
# Node arama - get_node() kullan, path'i kaydet
@onready var health_bar: ProgressBar = %HealthBar

# Array processing
var enemies: Array[Enemy] = []

# Yanlış
for i in range(enemies.size()):
    var enemy = enemies[i]

# Doğru (iterative)
for enemy in enemies:
    enemy.take_damage(10)

# Group kullanımı
func _ready() -> void:
    add_to_group("enemies")

func get_all_enemies() -> Array[Node]:
    return get_tree().get_nodes_in_group("enemies")
```

## Sınıf Şablonları

```gdscript
class_name HealthComponent
extends Node

signal health_changed(new_health: int)
signal died

@export var max_health: int = 100
var health: int

func _ready() -> void:
    health = max_health

func take_damage(amount: int) -> void:
    health = clampi(health - amount, 0, max_health)
    health_changed.emit(health)
    if health <= 0:
        died.emit()

func heal(amount: int) -> void:
    health = clampi(health + amount, 0, max_health)
    health_changed.emit(health)
```
