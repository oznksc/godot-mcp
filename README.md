# Godot MCP

Godot MCP is a Model Context Protocol server for controlling and inspecting a Godot 4.4+ editor project from MCP-compatible AI clients.

The integration has two parts:

- A Node.js MCP server that talks to AI clients over stdio.
- A Godot editor plugin that listens on a local WebSocket port and executes editor commands.

```text
MCP client
  <-> stdio
Node.js MCP server
  <-> ws://127.0.0.1:6505
Godot editor plugin
  <-> Godot Editor API
```

## Features

- Scene, node, script, resource, project, editor, file, signal, runtime, debug, animation, shader, physics, UI, audio, lighting, particles, import/export, and ClassDB tools.
- Godot development skill modules for GDScript, scene architecture, signals, physics, networking, export, and more.
- Searchable references to open-source Godot project examples.
- MCP resources for project info, settings, current scene, editor state, console output, runtime status, and ClassDB queries.
- A `godot_connection_status` health tool for checking bridge state before running editor commands.

## Requirements

- Node.js 18 or newer.
- npm.
- Godot 4.4 or newer.
- An MCP client that supports stdio servers.

## Install

```bash
git clone <repository-url>
cd godot-mcp
npm run setup
```

Then install the Godot plugin into the project you want to control:

```bash
cp -R addons/godot_mcp /path/to/your-godot-project/addons/
```

Open the project in Godot and enable `Godot MCP` from:

```text
Project -> Project Settings -> Plugins
```

The plugin listens on `127.0.0.1:6505` by default.

## MCP Client Configuration

Point your MCP client at the built server:

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["/absolute/path/to/godot-mcp/server/dist/index.js"]
    }
  }
}
```

Restart your MCP client after changing its configuration.

## Verify The Connection

1. Open the Godot project and make sure the plugin is enabled.
2. Start or restart your MCP client.
3. Run the `godot_connection_status` MCP tool. It should report `"connected": true`.
4. Run `project_get_info`. It should return metadata for the open Godot project.

If `godot_connection_status` reports `false`, check that:

- Godot is open with the plugin enabled.
- No other process is using port `6505`.
- The MCP server is using the same host and port as the plugin.
- Your MCP client points to `server/dist/index.js` after `npm run setup`.

## Configuration

The Node bridge can be configured with environment variables:

| Variable | Default | Description |
| --- | --- | --- |
| `GODOT_WS_HOST` | `127.0.0.1` | Host where the Godot plugin listens. |
| `GODOT_WS_PORT` | `6505` | WebSocket port used by the Godot plugin. |
| `GODOT_RECONNECT_ATTEMPTS` | `5` | Reconnect attempts after a dropped bridge connection. |
| `GODOT_RECONNECT_DELAY_MS` | `2000` | Delay between reconnect attempts. |
| `GODOT_PING_INTERVAL_MS` | `30000` | WebSocket ping interval. |
| `GODOT_COMMAND_TIMEOUT_MS` | `30000` | Timeout for a single Godot command. |
| `LOG_LEVEL` | `info` | One of `debug`, `info`, `warn`, or `error`. |

Example:

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["/absolute/path/to/godot-mcp/server/dist/index.js"],
      "env": {
        "LOG_LEVEL": "debug",
        "GODOT_COMMAND_TIMEOUT_MS": "60000"
      }
    }
  }
}
```

## Development

```bash
npm run setup
npm run verify
npm run start
```

Useful commands:

| Command | Description |
| --- | --- |
| `npm run setup` | Install server dependencies and build TypeScript. |
| `npm run build` | Build the MCP server. |
| `npm run verify` | Run the current verification suite. |
| `npm run start` | Start the built MCP server over stdio. |
| `npm run clean` | Remove generated server build output and dependencies. |

Do not commit `server/node_modules` or `server/dist`; they are generated locally.

## Repository Layout

```text
addons/godot_mcp/   Godot editor plugin
server/src/         TypeScript MCP server
skills/             Godot development reference modules
examples/           Open-source example registry
```

## Safety Notes

The plugin can read and write files in the connected Godot project and can invoke editor APIs. Only enable it in projects and MCP clients you trust.

## License

MIT
