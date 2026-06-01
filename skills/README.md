# Godot Skills Index

Bu klasör Godot MCP projesi için AI bilgi modülleri içerir.

## Mevcut Skill'ler

| Dosya | Konu | Açıklama |
|-------|------|----------|
| `gdscript.md` | GDScript | Kodlama standartları, kalıplar, yaygın hatalar |
| `scene-architecture.md` | Sahne Mimarisi | Node hiyerarşisi, prefab, organizasyon |
| `signal-patterns.md` | Sinyal Kalıpları | Event-driven mimari, bağlantı kalıpları |
| `performance.md` | Performans | Profiling, optimizasyon, hafıza yönetimi |
| `2d-patterns.md` | 2D Oyun | 2D fizik, kamera, tilemap, platformer |
| `3d-patterns.md` | 3D Oyun | 3D fizik, ışık, materyal, NavMesh |
| `ui-design.md` | UI/UX | Control node'ları, tema, responsive tasarım |
| `physics.md` | Fizik | Collision, RigidBody, CharacterBody, Area |
| `animation.md` | Animasyon | AnimationPlayer, Tween, Transition |
| `audio.md` | Ses | Audio bus, müzik, positional ses |
| `networking.md` | Networking | Multiplayer, RPC, state sync |
| `export.md` | Export | Platform ayarları, CI/CD, build optimizasyonu |

## Kullanım

Bu skill'ler MCP server'daki `godot_*` prompt'ları ile tetiklenebilir veya AI asistanı
dogrudan bu dosyaları referans alarak Godot geliştirme yardımı sağlayabilir.

## Yeni Skill Ekleme

Yeni bir skill eklemek için:
1. `skills/` klasörüne `konu.md` dosyası oluştur
2. Bu index dosyasına ekle
3. MCP server'a yeni bir prompt olarak da eklenebilir
