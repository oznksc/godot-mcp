# Sahne Mimarisi Skill

## Temel Prensip: "Composition over Inheritance"

Godot'da her şey Node'lardan oluşur. Sahne = Node ağacı. Miras yerine kompozisyon kullanın.

## Node Hiyerarşisi Kalıpları

### Oyuncu Sahne Yapısı
```
Player (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
├── HealthComponent (Node)
├── HitboxComponent (Area2D)
│   └── CollisionShape2D
├── HurtboxComponent (Area2D)
│   └── CollisionShape2D
├── Camera2D
└── UI
    └── HealthBar (ProgressBar)
```

### Düşman Sahne Yapısı
```
Enemy (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
├── HealthComponent
├── HitboxComponent
├── HurtboxComponent
├── NavigationAgent2D
├── DetectionArea (Area2D)
│   └── CollisionShape2D
└── StateMachine (Node)
    ├── IdleState
    ├── ChaseState
    └── AttackState
```

### UI Sahne Yapısı
```
HUD (CanvasLayer)
├── MarginContainer
│   └── VBoxContainer
│       ├── HBoxContainer
│       │   ├── TextureRect (Icon)
│       │   └── ProgressBar (HealthBar)
│       ├── Label (ScoreLabel)
│       └── VBoxContainer (InventorySlots)
│           ├── InventorySlot
│           ├── InventorySlot
│           └── InventorySlot
```

## Component Pattern

### Sağlık Bileşeni
```gdscript
# health_component.gd
class_name HealthComponent
extends Node

signal health_changed(new_health: int)
signal died

@export var max_health: int = 100
@onready var health: int = max_health

func take_damage(amount: int) -> void:
    health = clampi(health - amount, 0, max_health)
    health_changed.emit(health)
    if health <= 0:
        died.emit()

func heal(amount: int) -> void:
    health = clampi(health + amount, 0, max_health)
    health_changed.emit(health)
```

### Hasar Bileşeni
```gdscript
# damage_component.gd
class_name DamageComponent
extends Node

@export var damage: int = 10

func _on_body_entered(body: Node2D) -> void:
    if body.has_method("take_damage"):
        body.take_damage(damage)
```

## Prefab (Sahne İçeren Sahne) Kullanımı

```gdscript
# Bir sahneyi başka sahneye instance olarak ekle
var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

func shoot() -> void:
    var bullet: Bullet = bullet_scene.instantiate()
    bullet.global_position = muzzle.global_position
    bullet.direction = global_position.direction_to(target.global_position)
    get_tree().root.add_child(bullet)
```

## Sahne Organizasyonu

```
project/
├── scenes/
│   ├── player/
│   │   ├── player.tscn
│   │   └── player.gd
│   ├── enemies/
│   │   ├── goblin/
│   │   │   ├── goblin.tscn
│   │   │   └── goblin.gd
│   │   └── skeleton/
│   ├── levels/
│   │   ├── level_01.tscn
│   │   └── level_02.tscn
│   └── ui/
│       ├── hud.tscn
│       └── menu.tscn
├── scripts/
│   ├── components/
│   │   ├── health_component.gd
│   │   └── damage_component.gd
│   └── autoload/
│       ├── game_manager.gd
│       └── audio_manager.gd
├── resources/
│   ├── weapons/
│   └── items/
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
└── addons/
```

## Root Node Seçimi

| Sahne Tipi | Root Node | Neden |
|------------|-----------|-------|
| 2D Oyun | Node2D | Basit 2D transform |
| 2D UI | Control | UI layout sistemi |
| 3D Oyun | Node3D | 3D transform |
| Global Menü | CanvasLayer | Overlay katmanı |
| GameManager | Node (script) | Sadece script, görsel yok |
| Level | Node2D / Node3D | Çocukları organize et |

## Sahne Connection Kalıpları

### Autoload (Global Singleton)
```gdscript
# game_manager.gd (Autoload olarak ekle)
extends Node

signal game_over
signal score_changed(new_score: int)

var score: int = 0:
    set(value):
        score = value
        score_changed.emit(score)

func add_score(points: int) -> void:
    score += points
```

### Grup Kullanımı
```gdscript
# Tüm düşmanları bul
func get_all_enemies() -> Array[Node]:
    return get_tree().get_nodes_in_group("enemies")

# Düşman oluşturulunca gruba ekle
func _ready() -> void:
    add_to_group("enemies")
```
