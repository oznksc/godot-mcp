# Export/Deploy Skill

## Export Preset Yapılandırma

### Export Preset Dosyası (`export_presets.cfg`)
```ini
[preset.0]
name="Windows Desktop"
platform="Windows Desktop"
runnable=true
export_filter=0
include_filter=""
exclude_filter=""

[preset.0.options]
custom_template/debug=""
custom_template/release=""
binary_format/embed_pck=true
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
```

## Platform Bazlı Ayarlar

### Windows
```ini
[preset.0.options]
binary_format/embed_pck=true
texture_format/s3tc_bptc=true
codesign/enable=false
application/modify_resources=false
application/icon=""
application/console_wrapper_icon=""
application/file_version=""
application/product_version=""
application/company_name=""
application/product_name=""
application/file_description=""
application/copyright=""
application/trademarks=""
application/d3d12_agility_sdk_multiarch=true
```

### macOS
```ini
[preset.0.options]
custom_template/debug=""
custom_template/release=""
application/modify_resources=false
application/code_sign=true
application/codesign_identifier=""
application/entitlements=""
application/icon=""
application/icon_interpolation=4
application/bundle_identifier=""
application/short_version="1.0"
application/version="1.0.0"
application/copyright=""
display/high_res=true
privacy/microphone_usage_description=""
privacy/camera_usage_description=""
```

### Linux
```ini
[preset.0.options]
custom_template/debug=""
custom_template/release=""
binary_format/embed_pck=true
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
```

### Android
```ini
[preset.0.options]
custom_template/debug=""
custom_template/release=""
gradle_build/use_gradle_build=false
gradle_build/export_format=0
architectures/armeabi-v7a=true
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=false
keystore/debug=""
keystore/debug_user=""
keystore/debug_password=""
keystore/release=""
keystore/release_user=""
keystore/release_password=""
package/unique_name="com.company.game"
package/name="Game Name"
package/signed=true
package/classify_as_game=true
screen/immersive_mode=true
screen/support_small=true
screen/support_normal=true
screen/support_large=true
screen/support_xlarge=true
```

### iOS
```ini
[preset.0.options]
custom_template/debug=""
custom_template/release=""
application/app_store_management_id=""
application/apple_id=""
application/apple_team_id=""
application/code_sign_identity="iPhone Developer"
application/provisioning_profile_uuid=""
application/export_method="app-store"
application/supports_i_pad=true
application/supports_iphone=true
application/exit_on_suspension=false
capabilities/accesses_motion=true
capabilities/nfc_reading_usage="NFC tag data is used for game features"
```

### Web
```ini
[preset.0.options]
variant/extensions_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
progressive_web_app/offline_page=""
progressive_web_app/display=1
progressive_web_app/orientation=0
progressive_web_app/icon_144x144=""
progressive_web_app/icon_180x180=""
progressive_web_app/icon_512x512=""
progressive_web_app/background_color=Color(0, 0, 0, 1)
```

## Export Script

```gdscript
# export_game.gd - EditorScript olarak çalıştır
extends EditorScript

func _run() -> void:
    var presets: Array = EditorExport.export_presets
    for preset in presets:
        print("Exporting: ", preset.name)
        var err: Error = EditorExport.export_packager.pack(preset, "build/" + preset.name + ".exe")
        if err != OK:
            print("Export failed: ", error_string(err))
        else:
            print("Export successful!")
```

## CI/CD Export (GitHub Actions)

```yaml
# .github/workflows/export.yml
name: Export Game
on:
  push:
    tags: ['v*']

jobs:
  export:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Export Godot Game
        uses: firebelley/godot-export@v5
        with:
          godot_executable_download_url: https://github.com/godotengine/godot/releases/download/4.4/Godot_v4.4-stable_linux.x86_64.zip
          godot_template_download_url: https://github.com/godotengine/godot/releases/download/4.4/Godot_v4.4-stable_export_templates.tpz
          export_path: build
          wine_enabled: false
```

## Build Optimizasyonu

```gdscript
# PCK dosyasını gömme
# Project Settings > General > Compression
# Paket sıkıştırma: FastCompression veya GZip

# Texture import ayarları (her platform için)
# Import dock > Texture > Compression:
# - Desktop: VRAM Compressed (S3TC/BPTC)
# - Mobile: VRAM Compressed (ETC2/ASTC)
# - Web: Lossy

# GDScript optimize
# Project Settings > Debug > Verbose: false
# Project Settings > Editor > Update Mode: Idle
```

## PCK Yönetimi

```gdscript
# PCK dosyası oluştur
func create_pck(version: String) -> void:
    var packer := PCKPacker.new()
    var err: Error = packer.pck_open("game_" + version + ".pck")
    if err != OK:
        return
    # Dosyaları ekle
    packer.add_file("res://scenes/main.tscn", "scenes/main.tscn")
    packer.add_file("res://scripts/player.gd", "scripts/player.gd")
    packer.commit()

# PCK oku
func list_pck_contents(path: String) -> void:
    var packer := PCKPacker.new()
    # PCK header bilgilerini oku
```

## Multiplayer Export

```gdscript
# Dedicated server build
# Export preset'te "Export as dedicated server" seçeneği
# Ya da custom template ile:

# Kod içi kontrol
func is_dedicated_server() -> bool:
    return DisplayServer.get_name() == "headless" or OS.has_feature("dedicated_server")

func _ready() -> void:
    if is_dedicated_server():
        # Sadece sunucu mantığını çalıştır
        _start_server_only()
    else:
        # İstemci + sunucu
        _start_full_game()
```

## Version Management

```gdscript
# version_manager.gd
extends Node

const VERSION_FILE: String = "res://version.cfg"

func get_version() -> String:
    var config := ConfigFile.new()
    if config.load(VERSION_FILE) == OK:
        return config.get_value("version", "number", "1.0.0")
    return "1.0.0"

func set_version(version: String) -> void:
    var config := ConfigFile.new()
    config.set_value("version", "number", version)
    config.save(VERSION_FILE)

# Export öncesi version bump
func bump_version(part: String = "patch") -> String:
    var current: String = get_version()
    var parts: PackedStringArray = current.split(".")
    match part:
        "major":
            parts[0] = str(parts[0].to_int() + 1)
            parts[1] = "0"
            parts[2] = "0"
        "minor":
            parts[1] = str(parts[1].to_int() + 1)
            parts[2] = "0"
        "patch":
            parts[2] = str(parts[2].to_int() + 1)
    var new_version: String = ".".join(parts)
    set_version(new_version)
    return new_version
```
