# Ses Sistemi Skill

## Audio Bus Yapısı

```
Master
├── Music (Volume: -6dB)
│   ├── BGM
│   └── Ambient
├── SFX (Volume: 0dB)
│   ├── Combat
│   ├── UI
│   └── Footsteps
└── Voice (Volume: 0dB)
    ├── Dialogue
    └── Narration
```

## AudioStreamPlayer Kullanımı

### 2D Ses
```gdscript
@onready var sfx_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

func play_sfx(stream: AudioStream) -> void:
    sfx_player.stream = stream
    sfx_player.play()

# Konum bazlı ses
func play_positional_sfx(pos: Vector2, stream: AudioStream) -> void:
    var player := AudioStreamPlayer2D.new()
    player.stream = stream
    player.global_position = pos
    player.max_distance = 500.0
    add_child(player)
    player.play()
    await player.finished
    player.queue_free()
```

### 3D Ses
```gdscript
@onready var ambient_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

# 3D ses ayarları
func setup_3d_audio(player: AudioStreamPlayer3D) -> void:
    player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    player.max_distance = 50.0
    player.unit_size = 10.0
    player.max_db = 3.0
    player.min_db = -80.0
```

## Bus Yapılandırma

```gdscript
# Bus seviyesi ayarlama
func set_bus_volume(bus_name: String, volume_db: float) -> void:
    var bus_idx: int = AudioServer.get_bus_index(bus_name)
    if bus_idx >= 0:
        AudioServer.set_bus_volume_db(bus_idx, volume_db)

# Mute
func toggle_mute(bus_name: String) -> void:
    var bus_idx: int = AudioServer.get_bus_index(bus_name)
    if bus_idx >= 0:
        AudioServer.set_bus_mute(bus_idx, not AudioServer.is_bus_mute(bus_idx))

# Efekt ekleme
func add_reverb_to_bus(bus_name: String) -> void:
    var bus_idx: int = AudioServer.get_bus_index(bus_name)
    if bus_idx >= 0:
        var effect := AudioEffectReverb.new()
        AudioServer.add_bus_effect(bus_idx, effect)
```

## Müzik Sistemi

```gdscript
# music_manager.gd (Autoload)
extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var crossfade_player: AudioStreamPlayer = $CrossfadePlayer

var current_track: String = ""

func play_track(track: AudioStream, fade_time: float = 1.0) -> void:
    if current_track == track.resource_path:
        return

    current_track = track.resource_path

    # Crossfade
    crossfade_player.stream = music_player.stream
    crossfade_player.play(music_player.get_playback_position())
    crossfade_player.volume_db = 0.0

    music_player.stream = track
    music_player.volume_db = -80.0
    music_player.play()

    var tween := create_tween().set_parallel(true)
    tween.tween_property(music_player, "volume_db", 0.0, fade_time)
    tween.tween_property(crossfade_player, "volume_db", -80.0, fade_time)
    await tween.finished
    crossfade_player.stop()
```

## Ses Efektleri Kütüphanesi

```gdscript
# audio_library.gd
class_name AudioLibrary
extends Resource

@export var sfx: Dictionary = {
    "hit": preload("res://audio/sfx/hit.wav"),
    "jump": preload("res://audio/sfx/jump.wav"),
    "coin": preload("res://audio/sfx/coin.wav"),
    "death": preload("res://audio/sfx/death.wav"),
}

var _players: Array[AudioStreamPlayer2D] = []

func play_sfx(node: Node, sfx_name: String, volume: float = 0.0) -> void:
    if not sfx.has(sfx_name):
        return

    var player := AudioStreamPlayer2D.new()
    player.stream = sfx[sfx_name]
    player.volume_db = volume
    node.add_child(player)
    player.play()

    # Bitince temizle
    player.finished.connect(player.queue_free)
```

## Müzik Transitional

```gdscript
# Battle music transition
func enter_battle() -> void:
    MusicManager.play_track(preload("res://audio/music/battle.ogg"), 0.5)

func exit_battle() -> void:
    MusicManager.play_track(preload("res://audio/music/exploration.ogg"), 1.0)

# Dynamic music
func update_music_intensity(intensity: float) -> void:
    # Layer-based music
    for i in range(AudioServer.bus_count):
        var bus_name: String = AudioServer.get_bus_name(i)
        if bus_name.begins_with("MusicLayer"):
            var layer: int = int(bus_name.right(1))
            var target_vol: float = 0.0 if layer <= intensity else -80.0
            var tween := create_tween()
            tween.tween_property(
                AudioServer, "get_bus_volume_db(%d)" % i,
                target_vol, 0.5
            )
```

## Footstep Sistemi

```gdscript
# footstep_emitter.gd
extends Node3D

@export var footstep_sounds: Array[AudioStream] = []
@export var interval: float = 0.4

var _timer: float = 0.0
var _player: CharacterBody3D

func _ready() -> void:
    _player = get_parent() as CharacterBody3D

func _process(delta: float) -> void:
    if not _player:
        return

    if _player.is_on_floor() and _player.velocity.length() > 0.5:
        _timer += delta
        if _timer >= interval:
            _timer = 0.0
            _play_footstep()
    else:
        _timer = interval * 0.8

func _play_footstep() -> void:
    if footstep_sounds.is_empty():
        return
    var sound: AudioStream = footstep_sounds[randi() % footstep_sounds.size()]
    var player := AudioStreamPlayer3D.new()
    player.stream = sound
    player.pitch_scale = randf_range(0.9, 1.1)
    player.global_position = global_position
    add_child(player)
    player.play()
    player.finished.connect(player.queue_free)
```

## Sesi Azaltma (Ducking)

```gdscript
# Dialogue sırasında müziği azalt
func play_dialogue() -> void:
    var music_bus: int = AudioServer.get_bus_index("Music")
    var original_vol: float = AudioServer.get_bus_volume_db(music_bus)

    var tween := create_tween()
    tween.tween_method(func(vol): AudioServer.set_bus_volume_db(music_bus, vol), original_vol, -12.0, 0.3)

    await dialogue_finished

    tween = create_tween()
    tween.tween_method(func(vol): AudioServer.set_bus_volume_db(music_bus, vol), -12.0, original_vol, 0.3)
```
