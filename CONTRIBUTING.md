# Contributing

Thanks for helping improve Godot MCP.

## Development Setup

```bash
npm run setup
npm run verify
```

To test against Godot:

1. Copy `addons/godot_mcp/` into a Godot 4.4+ project.
2. Enable the plugin in `Project Settings -> Plugins`.
3. Start an MCP client configured to run `server/dist/index.js`.
4. Call `godot_connection_status`, then `project_get_info`.

## Pull Requests

- Keep changes focused and include a short explanation of the user-visible behavior.
- Run `npm run verify` before opening a PR.
- Do not commit generated build output, dependency folders, local Godot projects, or secrets.
- If you add or change a Godot editor command, update the matching TypeScript tool and README notes when relevant.

## Coding Notes

- The MCP server communicates over stdio with the client.
- The Godot editor plugin listens on `127.0.0.1:6505` and the Node bridge connects to it.
- Logs must go to stderr so stdio MCP messages stay clean.
