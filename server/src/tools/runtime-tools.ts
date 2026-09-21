import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerRuntimeTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'runtime_run_project',
    'Run the project in debug mode',
    {
      scene: z.string().optional().describe('Specific scene to run (res://...)'),
    },
    async ({ scene }) => {
      const result = await bridge.sendCommand('runtime_run_project', { scene });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'runtime_stop',
    'Stop the running project',
    {},
    async () => {
      const result = await bridge.sendCommand('runtime_stop');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'runtime_pause',
    'Pause the running project',
    {},
    async () => {
      const result = await bridge.sendCommand('runtime_pause');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'runtime_resume',
    'Resume the paused project',
    {},
    async () => {
      const result = await bridge.sendCommand('runtime_resume');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'runtime_step',
    'Step one frame forward (debug mode)',
    {},
    async () => {
      const result = await bridge.sendCommand('runtime_step');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'runtime_is_playing',
    'Check if the project is currently running',
    {},
    async () => {
      const result = await bridge.sendCommand('runtime_is_playing');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'runtime_get_status',
    'Get detailed runtime status',
    {},
    async () => {
      const result = await bridge.sendCommand('runtime_get_status');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'runtime_get_remote_scene_tree',
    'Get the live scene tree of the running game',
    {},
    async () => {
      const result = await bridge.sendCommand('runtime_get_remote_scene_tree');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'runtime_get_node_properties',
    'Read real-time properties of any active node in the running game',
    {
      path: z.string().describe('Node path in running scene tree (e.g. "/root/Main/Player")'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('runtime_get_node_properties', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'runtime_set_node_property',
    'Dynamically modify a property on an active node in the running game without restarting',
    {
      path: z.string().describe('Node path in running scene tree'),
      property: z.string().describe('Property name to change'),
      value: z.any().describe('New property value'),
    },
    async ({ path, property, value }) => {
      const result = await bridge.sendCommand('runtime_set_node_property', { path, property, value });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'runtime_get_performance_metrics',
    'Get real-time engine profiler and performance metrics (FPS, frame time, draw calls, memory, active physics objects)',
    {},
    async () => {
      const result = await bridge.sendCommand('runtime_get_performance_metrics');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
