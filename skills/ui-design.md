# UI/UX Tasarım Skill

## Control Node Hiyerarşisi

```
Control Node Tree:
├── Root (Control) — Tam ekran
│   ├── MarginContainer — Kenar boşlukları
│   │   └── VBoxContainer — Dikey dizilim
│   │       ├── HBoxContainer — Yatay satır
│   │       │   ├── TextureRect — İkon
│   │       │   └── Label — Metin
│   │       └── PanelContainer — Kutu
│   │           └── GridContainer — Izgara
```

## Anchor Sistemi

| Preset | Açıklama | Kullanım |
|--------|----------|----------|
| `FullRect` | Tam ekran | Arka plan, overlay |
| `TopLeft` | Sol üst | HUD köşesi |
| `TopRight` | Sağ üst | Skor/gold göstergesi |
| `BottomLeft` | Sol alt | Soğuk zaman göstergesi |
| `BottomRight` | Sağ alt | Mini harita |
| `Center` | Ortada | Popup, dialog |
| `TopWide` | Üst geniş | Üst bar |
| `BottomWide` | Alt geniş | Alt bilgi barı |

```gdscript
# Anchor ayarlama
func setup_full_rect(control: Control) -> void:
    control.set_anchors_preset(Control.PRESET_FULL_RECT)
    control.offset_left = 0
    control.offset_top = 0
    control.offset_right = 0
    control.offset_bottom = 0
```

## Container Tipleri

### VBoxContainer (Dikey)
```gdscript
var vbox := VBoxContainer.new()
vbox.add_theme_constant_override("separation", 10)

var label1 := Label.new()
label1.text = "Satır 1"
vbox.add_child(label1)

var label2 := Label.new()
label2.text = "Satır 2"
vbox.add_child(label2)
```

### HBoxContainer (Yatay)
```gdscript
var hbox := HBoxContainer.new()
hbox.add_theme_constant_override("separation", 5)

for i in range(5):
    var slot := TextureRect.new()
    slot.custom_minimum_size = Vector2(64, 64)
    hbox.add_child(slot)
```

### GridContainer (Izgara)
```gdscript
var grid := GridContainer.new()
grid.columns = 4
grid.add_theme_constant_override("h_separation", 8)
grid.add_theme_constant_override("v_separation", 8)

for i in range(16):
    var slot := PanelContainer.new()
    slot.custom_minimum_size = Vector2(80, 80)
    grid.add_child(slot)
```

## Tema Sistemi

```gdscript
# Tema oluşturma
var theme := Theme.new()

# Font
var font: FontFile = preload("res://fonts/game_font.ttf")
theme.default_font = font
theme.default_font_size = 16

# Renkler
theme.set_color("font_color", "Label", Color.WHITE)
theme.set_color("font_hover_color", "Button", Color.YELLOW)
theme.set_color("font_pressed_color", "Button", Color.GREEN)

# StilBox
var panel_style := StyleBoxFlat.new()
panel_style.bg_color = Color(0, 0, 0, 0.7)
panel_style.corner_radius_top_left = 8
panel_style.corner_radius_top_right = 8
panel_style.corner_radius_bottom_left = 8
panel_style.corner_radius_bottom_right = 8
panel_style.content_margin_left = 16
panel_style.content_margin_right = 16
panel_style.content_margin_top = 8
panel_style.content_margin_bottom = 8
theme.set_stylebox("panel", "PanelContainer", panel_style)
```

## HUD Örneği

```gdscript
# health_bar.gd
extends ProgressBar

@export var tween_duration: float = 0.3

func update_health(value: int, max_val: int) -> void:
    var prev_value: float = value
    max_value = max_val
    # Tween animasyonu
    var tween := create_tween()
    tween.tween_property(self, "value", float(value), tween_duration)
    # Renk değişimi
    var ratio: float = float(value) / float(max_val)
    if ratio < 0.3:
        modulate = Color.RED
    elif ratio < 0.6:
        modulate = Color.YELLOW
    else:
        modulate = Color.WHITE
```

## Popup/Dialog

```gdscript
func show_dialog(title: String, message: String) -> void:
    var dialog := AcceptDialog.new()
    dialog.title = title
    dialog.dialog_text = message
    add_child(dialog)
    dialog.popup_centered(Vector2i(400, 200))
    await dialog.confirmed
    dialog.queue_free()

func show_confirm(message: String) -> bool:
    var dialog := ConfirmationDialog.new()
    dialog.dialog_text = message
    add_child(dialog)
    dialog.popup_centered(Vector2i(400, 200))
    await dialog.confirmed
    var result: bool = dialog.visible
    dialog.queue_free()
    return result
```

## Input Display

```gdscript
# Keybind butonu
extends Button

@export var action: StringName = ""

func _ready() -> void:
    text = InputMap.action_get_events(action)[0].as_text_physical_keycode()
    pressed.connect(_on_pressed)

func _on_pressed() -> void:
    text = "Press a key..."
    var event: InputEvent = await InputEvent.new()
    # Wait for input
    set_process_input(true)

func _input(event: InputEvent) -> void:
    if not has_focus():
        return
    if event is InputEventKey and event.pressed:
        InputMap.action_erase_events(action)
        InputMap.action_add_event(action, event)
        text = event.as_text_physical_keycode()
        release_focus()
        set_process_input(false)
```

## UI Animasyonları

```gdscript
# Fade in
func fade_in(control: Control, duration: float = 0.3) -> void:
    control.modulate.a = 0.0
    control.show()
    var tween := create_tween()
    tween.tween_property(control, "modulate:a", 1.0, duration)

# Fade out
func fade_out(control: Control, duration: float = 0.3) -> void:
    var tween := create_tween()
    tween.tween_property(control, "modulate:a", 0.0, duration)
    await tween.finished
    control.hide()

# Slide in from side
func slide_in(control: Control, from: Vector2, duration: float = 0.3) -> void:
    var target_pos: Vector2 = control.position
    control.position = from
    control.show()
    var tween := create_tween()
    tween.tween_property(control, "position", target_pos, duration).set_trans(Tween.TRANS_BACK)
```

## Responsive Tasarım

```gdscript
# Ekran boyutuna göre ölçekleme
func _on_viewport_size_changed() -> void:
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var scale_factor: float = min(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
    scale = Vector2(scale_factor, scale_factor)
```
