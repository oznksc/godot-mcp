import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerScriptTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'script_create',
    'Create a new GDScript file',
    {
      path: z.string().describe('Script path (res://scripts/my_script.gd)'),
      content: z.string().optional().describe('Initial script content'),
      extends_class: z.string().default('Node').describe('Base class to extend'),
    },
    async ({ path, content, extends_class }) => {
      const result = await bridge.sendCommand('script_create', { path, content, extends_class });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'script_read',
    'Read the content of a script file',
    {
      path: z.string().describe('Script path (res://...)'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('script_read', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'script_write',
    'Write content to a script file',
    {
      path: z.string().describe('Script path (res://...)'),
      content: z.string().describe('Full script content'),
    },
    async ({ path, content }) => {
      const result = await bridge.sendCommand('script_write', { path, content });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'script_attach',
    'Attach a script to a node',
    {
      node_path: z.string().describe('Node path in the scene'),
      script_path: z.string().describe('Script path (res://...)'),
    },
    async ({ node_path, script_path }) => {
      const result = await bridge.sendCommand('script_attach', { node_path, script_path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'script_detach',
    'Detach the script from a node',
    {
      node_path: z.string().describe('Node path in the scene'),
    },
    async ({ node_path }) => {
      const result = await bridge.sendCommand('script_detach', { node_path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'script_validate',
    'Validate GDScript syntax without saving',
    {
      content: z.string().describe('GDScript code to validate'),
    },
    async ({ content }) => {
      const result = await bridge.sendCommand('script_validate', { content });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'script_list',
    'List all GDScript files in the project',
    {},
    async () => {
      const result = await bridge.sendCommand('script_list');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
