import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerDebugTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'debug_get_output',
    'Get the console/output log',
    {
      lines: z.number().default(100).describe('Number of recent lines to return'),
      type: z.enum(['all', 'stdout', 'stderr']).default('all').describe('Filter by output type'),
    },
    async ({ lines, type }) => {
      const result = await bridge.sendCommand('debug_get_output', { lines, type });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'debug_get_errors',
    'Get runtime errors',
    {
      limit: z.number().default(50).describe('Maximum number of errors to return'),
    },
    async ({ limit }) => {
      const result = await bridge.sendCommand('debug_get_errors', { limit });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'debug_get_warnings',
    'Get runtime warnings',
    {
      limit: z.number().default(50).describe('Maximum number of warnings to return'),
    },
    async ({ limit }) => {
      const result = await bridge.sendCommand('debug_get_warnings', { limit });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'debug_clear_console',
    'Clear the console output',
    {},
    async () => {
      const result = await bridge.sendCommand('debug_clear_console');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'debug_get_scene_tree',
    'Get the scene tree of the running project',
    {},
    async () => {
      const result = await bridge.sendCommand('debug_get_scene_tree');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
