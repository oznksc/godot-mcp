import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerEditorTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'editor_get_state',
    'Get the current editor state (open scenes, active screen, playing status)',
    {},
    async () => {
      const result = await bridge.sendCommand('editor_get_state');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'editor_set_main_screen',
    'Switch the main editor screen',
    {
      screen: z.enum(['2D', '3D', 'Script', 'AssetLib']).describe('Screen to switch to'),
    },
    async ({ screen }) => {
      const result = await bridge.sendCommand('editor_set_main_screen', { screen });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'editor_inspect_node',
    'Show a node in the Inspector dock',
    {
      path: z.string().describe('Node path to inspect'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('editor_inspect_node', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'editor_inspect_resource',
    'Show a resource in the Inspector dock',
    {
      path: z.string().describe('Resource path (res://...)'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('editor_inspect_resource', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'editor_get_selection',
    'Get the currently selected nodes in the editor',
    {},
    async () => {
      const result = await bridge.sendCommand('editor_get_selection');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'editor_select_node',
    'Select a node in the editor',
    {
      path: z.string().describe('Node path to select'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('editor_select_node', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'editor_open_script',
    'Open a script in the script editor',
    {
      path: z.string().describe('Script path (res://...)'),
      line: z.number().optional().describe('Line number to jump to'),
      column: z.number().optional().describe('Column number'),
    },
    async ({ path, line, column }) => {
      const result = await bridge.sendCommand('editor_open_script', { path, line, column });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'editor_rescan_filesystem',
    'Rescan the project filesystem',
    {},
    async () => {
      const result = await bridge.sendCommand('editor_rescan_filesystem');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'editor_restart',
    'Restart the Godot editor',
    {
      save: z.boolean().default(true).describe('Save open scenes before restarting'),
    },
    async ({ save }) => {
      const result = await bridge.sendCommand('editor_restart', { save });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
