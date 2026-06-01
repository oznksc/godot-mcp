# Godot MCP Server

A comprehensive Model Context Protocol (MCP) server for Godot 4.4+ game engine integration. Provides AI assistants with full access to Godot's editor capabilities, game patterns, and real open-source game code examples.

## Features

- **122 MCP Tools** — Scene, Node, Script, Resource, Project, Editor, File, Signal, Runtime, Debug, Animation, Shader, Physics, UI, Audio, Lighting, Particles, Import/Export, ClassDB, Skills, Examples
- **12 Skill Modules** — Auto-injected game dev knowledge (GDScript, Signals, Physics, Networking, etc.)
- **15 Open-Source Repositories** — Real game code from GDQuest, Comedot, Thrive, Tabletop Club, and more
- **Real-time WebSocket Bridge** — Bidirectional MCP ↔ Godot Editor communication on port 6505
- **7 MCP Resources** — Live project info, editor state, console output, runtime status
- **6 MCP Prompts** — Pre-built workflows for scene setup, debugging, export, and more

## Architecture

```
AI Client (Claude, etc.)
    ↕ MCP stdio
Godot MCP Server (Node.js/TypeScript)
    ↕ WebSocket (port 6505)
Godot Editor Plugin (GDScript)
    ↕ Godot Editor API
```

## Installation

### Prerequisites

- Node.js 18+
- Godot 4.4+

### Server Setup

```bash
cd godot-mcp/server
npm install
npm run build
```

### Godot Plugin Setup

1. Copy `addons/godot_mcp/` into your Godot project's root directory
2. Open Godot Editor → Project Settings → Plugins
3. Enable the "Godot MCP" plugin
4. The MCP WebSocket server starts on port 6505 automatically

### MCP Client Configuration

Add to your MCP client config (e.g., Claude Desktop):

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["/path/to/godot-mcp/server/dist/index.js"]
    }
  }
}
```

## Skills

Auto-injected based on your query context. Available skills:

| Skill | Description |
|-------|-------------|
| GDScript | Language patterns, best practices, type safety |
| Scene Architecture | Node trees, composition, scene inheritance |
| Signal Patterns | Signals, groups, event bus, decoupling |
| Performance | Optimization, profiling, memory management |
| 2D Patterns | TileMap, Camera2D, 2D physics, particles |
| 3D Patterns | 3D physics, terrain, lighting, CSG |
| UI Design | Control nodes, themes, responsive layout |
| Physics | RigidBody, CharacterBody, Area, joints |
| Animation | AnimationPlayer, AnimationTree, tweens |
| Audio | AudioStreamPlayer, buses, 3D audio |
| Networking | ENet, RPC, authoritative server |
| Export | Build templates, platform config, CI/CD |

## Open-Source Examples

Real code from production Godot games, indexed and searchable:

| Repository | Stars | Focus |
|------------|-------|-------|
| GDQuest Open RPG | ★★★ | RPG combat, inventory, dialogue |
| GDQuest 2D Platformer | ★★★ | Player physics, enemies, level flow |
| GDQuest 3D TPS | ★★★ | Third-person camera, aiming, movement |
| Godot Demo Projects | ★★★ | Official examples for every subsystem |
| Comedot | ★★ | Top-down RPG, health, combat, state machine |
| Thrive | ★★★ | Microbe stage, evolution, complex simulation |
| Tabletop Club | ★★ | Physics-based tabletop, cards, dice |
| Grapple Pack | ★★ | Grappling hook physics, swinging |
| Advanced Movement | ★★ | Character controller components |
| Godot Open RTS | ★★ | RTS units, pathfinding, strategy |
| and 5 more... | | |

## Tool Categories

| Category | Tools | Description |
|----------|-------|-------------|
| Scene | 8 | Create/save/load/close scenes, get scene tree |
| Node | 8 | Add/remove/rename/reparent nodes, set properties |
| Script | 6 | Create/edit scripts, attach to nodes |
| Resource | 5 | Create/load/save/manage resources |
| Project | 7 | Project settings, scan, render size |
| Editor | 6 | Undo/redo, play/stop, open files, fullscreen |
| File | 5 | Read/write/copy/move/delete project files |
| Signal | 4 | Connect/disconnect signals, list connections |
| Runtime | 6 | Execute code, get/set properties, call methods |
| Debug | 5 | Start/stop debugging, breakpoints, step |
| Animation | 6 | Create/manage animations, AnimationPlayer |
| Shader | 5 | Create/edit shaders, set uniforms |
| Physics | 5 | Raycast, shape query, direct body state |
| UI | 6 | Create Control nodes, themes, layouts |
| Audio | 5 | AudioStreamPlayer, buses, play/stop |
| Lighting | 5 | OmniLight, DirectionalLight, Environment |
| Particles | 5 | GPUParticles, CPUParticles, emission |
| Import/Export | 5 | Import resources, export builds |
| ClassDB | 5 | Class info, inheritance, constants |
| Skills | 3 | Query/navigate game dev knowledge |
| Examples | 4 | Find real open-source game code |

## License

MIT
