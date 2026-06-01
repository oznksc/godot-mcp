import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerSignalTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'signal_connect',
    'Connect a signal to a method on a target node',
    {
      source_path: z.string().describe('Source node path'),
      signal_name: z.string().describe('Signal name'),
      target_path: z.string().describe('Target node path'),
      method_name: z.string().describe('Method name on target node'),
      binds: z.array(z.any()).optional().describe('Additional bind arguments'),
    },
    async ({ source_path, signal_name, target_path, method_name, binds }) => {
      const result = await bridge.sendCommand('signal_connect', { source_path, signal_name, target_path, method_name, binds });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'signal_disconnect',
    'Disconnect a signal from a method',
    {
      source_path: z.string().describe('Source node path'),
      signal_name: z.string().describe('Signal name'),
      target_path: z.string().describe('Target node path'),
      method_name: z.string().describe('Method name'),
    },
    async ({ source_path, signal_name, target_path, method_name }) => {
      const result = await bridge.sendCommand('signal_disconnect', { source_path, signal_name, target_path, method_name });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'signal_list_connections',
    'List all signal connections for a node',
    {
      path: z.string().describe('Node path'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('signal_list_connections', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'signal_list_available',
    'List all available signals on a node',
    {
      path: z.string().describe('Node path'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('signal_list_available', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'signal_emit',
    'Emit a signal on a node',
    {
      path: z.string().describe('Node path'),
      signal_name: z.string().describe('Signal name'),
      args: z.array(z.any()).optional().describe('Signal arguments'),
    },
    async ({ path, signal_name, args }) => {
      const result = await bridge.sendCommand('signal_emit', { path, signal_name, args });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
