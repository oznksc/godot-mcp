import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerSceneTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'scene_create',
    'Create a new Godot scene with a root node',
    {
      name: z.string().describe('Scene name'),
      root_type: z.string().default('Node2D').describe('Root node type (Node2D, Node3D, Control, etc.)'),
      root_name: z.string().optional().describe('Root node name (defaults to scene name)'),
    },
    async ({ name, root_type, root_name }) => {
      const result = await bridge.sendCommand('scene_create', { name, root_type, root_name: root_name || name });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'scene_read',
    'Read the current scene structure as JSON',
    {},
    async () => {
      const result = await bridge.sendCommand('scene_read');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'scene_save',
    'Save the current scene',
    {
      path: z.string().optional().describe('Save path (res://...). If omitted, saves to current path'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('scene_save', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'scene_list',
    'List all scenes in the project',
    {},
    async () => {
      const result = await bridge.sendCommand('scene_list');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'scene_open',
    'Open a scene in the Godot editor',
    {
      path: z.string().describe('Scene path (res://...)'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('scene_open', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'scene_close',
    'Close the current scene in the editor',
    {},
    async () => {
      const result = await bridge.sendCommand('scene_close');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'scene_get_current',
    'Get the currently open scene',
    {},
    async () => {
      const result = await bridge.sendCommand('scene_get_current');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'scene_instance',
    'Instance a scene as a child in the current scene',
    {
      path: z.string().describe('Scene path to instance (res://...)'),
      parent: z.string().optional().describe('Parent node path'),
    },
    async ({ path, parent }) => {
      const result = await bridge.sendCommand('scene_instance', { path, parent });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'scene_get_hierarchy',
    'Get the full scene hierarchy as a tree structure',
    {},
    async () => {
      const result = await bridge.sendCommand('scene_get_hierarchy');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'scene_get_open_scenes',
    'List all open scene tabs in the editor',
    {},
    async () => {
      const result = await bridge.sendCommand('scene_get_open_scenes');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'scene_export_mesh_library',
    'Export the current scene as a MeshLibrary for GridMap',
    {
      path: z.string().describe('Output path (res://...)'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('scene_export_mesh_library', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
