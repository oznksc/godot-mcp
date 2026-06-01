# Networking Skill

## Multiplayer Tipleri

| Tip | Kullanım | Godot Desteği |
|-----|----------|:------------:|
| Peer-to-Peer | LAN oyunları | Evet |
| Dedicated Server | MMO, büyük oyunlar | Evet |
| Listen Server | Basit çoklu oyuncu | Evet |
| WebSocket | Web tabanlı | Evet |

## ENet Multiplayer

```gdscript
# Sunucu
func start_server() -> void:
    var peer := ENetMultiplayerPeer.new()
    peer.create_server(7777, 10)  # Port 7777, max 10 oyuncu
    multiplayer.multiplayer_peer = peer

# İstemci
func join_server(address: String) -> void:
    var peer := ENetMultiplayerPeer.new()
    peer.create_client(address, 7777)
    multiplayer.multiplayer_peer = peer

# Bağlantı olayları
func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected)
    multiplayer.connection_failed.connect(_on_connection_failed)

func _on_peer_connected(id: int) -> void:
    print("Oyuncu katıldı: ", id)

func _on_peer_disconnected(id: int) -> void:
    print("Ayrıldı: ", id)

func _on_connected() -> void:
    print("Sunucuya bağlanıldı!")

func _on_connection_failed() -> void:
    print("Bağlantı başarısız!")
```

## RPC (Remote Procedure Call)

```gdscript
# Tüm istemcilerde çalışır
@rpc("any_peer", "call_local", "reliable")
func sync_position(pos: Vector2) -> void:
    global_position = pos

# Sadece sunucuda çalışır
@rpc("authority", "call_local", "reliable")
func spawn_enemy(type: String, pos: Vector2) -> void:
    var enemy = ENEMY_SCENES[type].instantiate()
    enemy.global_position = pos
    get_tree().root.add_child(enemy)

# Sadece belirli bir peer'de çalışır
@rpc("peer", "call_local", "reliable")
func damage_player(amount: int) -> void:
    health -= amount

# Unreliable (hızlı, packet kaybı olabilir)
@rpc("any_peer", "call_remote", "unreliable")
func sync_rotation(rot: float) -> void:
    rotation = rot
```

## Oyuncu Yönetimi

```gdscript
# game_manager.gd (Autoload)
extends Node

var players: Dictionary = {}  # {peer_id: player_data}

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
    players[id] = {
        "name": "Player " + str(id),
        "score": 0,
    }
    _spawn_player(id)

func _on_peer_disconnected(id: int) -> void:
    _despawn_player(id)
    players.erase(id)

func _spawn_player(id: int) -> void:
    var player = preload("res://scenes/player.tscn").instantiate()
    player.name = str(id)
    player.set_multiplayer_authority(id)
    $Players.add_child(player)

func _despawn_player(id: int) -> void:
    var player = $Players.get_node_or_null(str(id))
    if player:
        player.queue_free()
```

## Multiplayer Authority

```gdscript
extends CharacterBody2D

func _ready() -> void:
    # Bu node'un sahibi olan peer'ı belirle
    set_multiplayer_authority(name.to_int())

func _physics_process(delta: float) -> void:
    # Sadece kendi karakterini kontrol et
    if not is_multiplayer_authority():
        return

    # Hareket kodu burada
    var direction = Input.get_axis("left", "right")
    velocity.x = direction * SPEED
    move_and_slide()

    # Pozisyonu sync et
    sync_position.rpc(global_position)
```

## Çakışma Yönetimi

```gdscript
# Sunucu tarafı çakışma çözümü
@rpc("authority", "call_local", "reliable")
func resolve_conflict(player_id: int, action: String, data: Dictionary) -> void:
    if not multiplayer.is_server():
        return

    # Tüm müştereklere bildir
    match action:
        "damage":
            var target_id: int = data["target"]
            var amount: int = data["amount"]
            apply_damage_to_player.rpc(target_id, amount)
        "pickup":
            var item_id: int = data["item"]
            pickup_item.rpc(player_id, item_id)
```

## WebMultiplayer (WebSocket)

```gdscript
# WebSocket tabanlı multiplayer
func start_web_server() -> void:
    var peer := WebSocketMultiplayerPeer.new()
    peer.create_server(8080)
    multiplayer.multiplayer_peer = peer

func join_web_server(url: String) -> void:
    var peer := WebSocketMultiplayerPeer.new()
    peer.create_client(url)
    multiplayer.multiplayer_peer = peer
```

## State Sync Patterns

```gdscript
# High-frequency sync (position, rotation)
@rpc("any_peer", "call_remote", "unreliable")
func sync_transform(pos: Vector2, rot: float) -> void:
    if not is_multiplayer_authority():
        global_position = pos
        rotation = rot

# Low-frequency sync (health, score)
@rpc("any_peer", "call_remote", "reliable")
func sync_state(health: int, score: int) -> void:
    if not is_multiplayer_authority():
        self.health = health
        self.score = score

# Periodic sync
var _sync_timer: float = 0.0
const SYNC_INTERVAL: float = 0.1  # 10 Hz

func _process(delta: float) -> void:
    if not is_multiplayer_authority():
        return
    _sync_timer += delta
    if _sync_timer >= SYNC_INTERVAL:
        _sync_timer = 0.0
        sync_transform.rpc(global_position, rotation)
```

## Lag Compensation

```gdscript
# Pozisyon interpolation (geçmiş pozisyonları sakla)
var _position_history: Array[Dictionary] = []

func _process(delta: float) -> void:
    if not is_multiplayer_authority():
        # Geçmiş pozisyonlara bakarak interpolation yap
        var render_time: float = Time.get_ticks_msec() / 1000.0 - 0.1  # 100ms gecikme
        var target_pos: Vector2 = _interpolate_position(render_time)
        global_position = global_position.lerp(target_pos, 0.3)

func _interpolate_position(time: float) -> Vector2:
    # En yakın iki snapshot arasında interpolation
    for i in range(_position_history.size() - 1):
        if _position_history[i]["time"] <= time and _position_history[i+1]["time"] >= time:
            var t: float = (time - _position_history[i]["time"]) / (_position_history[i+1]["time"] - _position_history[i]["time"])
            return _position_history[i]["pos"].lerp(_position_history[i+1]["pos"], t)
    return global_position
```
