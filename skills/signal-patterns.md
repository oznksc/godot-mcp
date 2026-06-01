# Sinyal Kalıpları Skill

## Godot 4'te Sinyaller

Sinyaller Godot'un event-driven mimarisinin temelidir. Observer pattern uygulamasıdır.

## Sinyal Tanımlama

```gdscript
# Basit sinyal
signal died

# Parametreli sinyal
signal health_changed(old_health: int, new_health: int)

# Array parametreli
signal items_collected(items: Array[String])
```

## Bağlantı Kalıpları

### 1. Editor'den Bağlantı
Node tıklanır → Signals sekmesi → Sinyal seçilir → Hedef node ve method seçilir.

### 2. Kod ile Bağlantı (En Yaygın)
```gdscript
func _ready() -> void:
    # Basit bağlantı
    health_component.died.connect(_on_player_died)

    # Parametreli bağlantı
    health_component.health_changed.connect(_on_health_changed)

    # Bind ile ek parametre
    button.pressed.connect(_on_button_pressed.bind("play"))

    # One-shot bağlantı (bir kez çalışıp disconnect olur)
    animation_player.animation_finished.connect(
        _on_anim_finished, CONNECT_ONE_SHOT
    )

    # Deferred bağlantı (sonraki frame'de çalışır)
    enemy.died.connect(_on_enemy_died, CONNECT_DEFERRED)
```

### 3. Callable Bağlantısı
```gdscript
var callable: Callable = Callable(self, "_on_health_changed")
signal.health_changed.connect(callable)
# Disconnect:
if signal.is_connected(callable):
    signal.disconnect(callable)
```

## Yaygın Sinyal Kalıpları

### Component Pattern
```gdscript
# health_component.gd
signal health_changed(new_health: int)
signal died
signal healed(amount: int)

@export var max_health: int = 100
var health: int:
    set(value):
        var old: int = health
        health = clampi(value, 0, max_health)
        if health != old:
            health_changed.emit(health)
        if health <= 0 and old > 0:
            died.emit()

# player.gd - Bileşeni dinle
func _ready() -> void:
    health_component.died.connect(_on_died)
    health_component.health_changed.connect(_on_health_changed)

func _on_died() -> void:
    # Ölüm animasyonu
    animation_player.play("death")
    # GameManager'a bildir
    GameManager.player_died()
```

### State Machine Pattern
```gdscript
# state_machine.gd
signal state_changed(old_state: State, new_state: State)

var current_state: State:
    set(value):
        var old: State = current_state
        current_state = value
        if old:
            old.exit()
        current_state.enter()
        state_changed.emit(old, current_state)
```

### Input Handling
```gdscript
# Buton bağları
func _ready() -> void:
    $JumpButton.pressed.connect(_on_jump_pressed)
    $PauseButton.pressed.connect(_on_pause_pressed)
    $AttackButton.button_down.connect(_on_attack_start)
    $AttackButton.button_up.connect(_on_attack_end)

func _on_jump_pressed() -> void:
    if is_on_floor():
        velocity.y = jump_velocity
```

### Enemy Detection
```gdscript
# Detection area sinyalleri
func _ready() -> void:
    detection_area.body_entered.connect(_on_body_entered)
    detection_area.body_exited.connect(_on_body_exited)
    detection_area.area_entered.connect(_on_area_entered)

var tracked_bodies: Array[Node2D] = []

func _on_body_entered(body: Node2D) -> void:
    if body is Player:
        tracked_bodies.append(body)

func _on_body_exited(body: Node2D) -> void:
    tracked_bodies.erase(body)

func get_closest_player() -> Player:
    var closest: Player = null
    var min_dist: float = INF
    for body in tracked_bodies:
        var dist: float = global_position.distance_to(body.global_position)
        if dist < min_dist:
            min_dist = dist
            closest = body
    return closest
```

## Custom Signal Emit Kalıpları

```gdscript
# Emit with validation
func take_damage(amount: int) -> void:
    if is_invulnerable:
        return
    health -= amount
    damage_taken.emit(amount, global_position)
    # Animasyon tetikle
    animation_player.play("hurt")

# Emit with data
func collect_item(item: Item) -> void:
    inventory.append(item)
    item_collected.emit(item.item_name, item.quantity)
    item.queue_free()
```

## Signal vs Callback Karşılaştırması

```gdscript
# ❌ Yanlış - Tight coupling
func take_damage(amount: int) -> void:
    health -= amount
    health_bar.update(health)  # Doğrudan referans
    game_manager.score -= 10   # Doğrudan referans

# ✅ Doğru - Loose coupling
func take_damage(amount: int) -> void:
    health -= amount
    health_changed.emit(health)  # Kimse dinliyorsa

# health_bar.gd
func _ready() -> void:
    player.health_changed.connect(update)

# game_manager.gd
func _ready() -> void:
    player.health_changed.connect(_on_player_health_changed)
```

## Hata Ayıklama

```gdscript
# Bağlantı kontrolü
if signal.is_connected(callable):
    signal.disconnect(callable)

# Tüm bağlantıları listele
for connection in signal.get_connections():
    print(connection["callable"])

# Yaygın hata: Bağlantı sonrası disconnect
signal.died.connect(_on_died)  # Bağla
signal.died.disconnect(_on_died)  # Hemen kesme!
```
