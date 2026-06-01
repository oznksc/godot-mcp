import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerNodeTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'node_add',
    'Add a new node to the scene tree',
    {
      type: z.string().describe('Node type (Node2D, Sprite2D, RigidBody3D, etc.)'),
      name: z.string().describe('Node name'),
      parent: z.string().optional().describe('Parent node path (default: scene root)'),
    },
    async ({ type, name, parent }) => {
      const result = await bridge.sendCommand('node_add', { type, name, parent });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_remove',
    'Remove a node from the scene tree',
    {
      path: z.string().describe('Node path to remove'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('node_remove', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_rename',
    'Rename a node',
    {
      path: z.string().describe('Current node path'),
      new_name: z.string().describe('New name for the node'),
    },
    async ({ path, new_name }) => {
      const result = await bridge.sendCommand('node_rename', { path, new_name });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_move',
    'Move a node to a new parent',
    {
      path: z.string().describe('Node path to move'),
      new_parent: z.string().describe('New parent node path'),
      index: z.number().optional().describe('Position index in new parent'),
    },
    async ({ path, new_parent, index }) => {
      const result = await bridge.sendCommand('node_move', { path, new_parent, index });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_duplicate',
    'Duplicate a node',
    {
      path: z.string().describe('Node path to duplicate'),
      new_name: z.string().optional().describe('Name for the duplicate'),
    },
    async ({ path, new_name }) => {
      const result = await bridge.sendCommand('node_duplicate', { path, new_name });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_get_properties',
    'Get all properties of a node',
    {
      path: z.string().describe('Node path'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('node_get_properties', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_set_property',
    'Set a property on a node',
    {
      path: z.string().describe('Node path'),
      property: z.string().describe('Property name'),
      value: z.any().describe('Property value'),
    },
    async ({ path, property, value }) => {
      const result = await bridge.sendCommand('node_set_property', { path, property, value });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_set_properties',
    'Set multiple properties on a node at once',
    {
      path: z.string().describe('Node path'),
      properties: z.record(z.any()).describe('Key-value pairs of properties'),
    },
    async ({ path, properties }) => {
      const result = await bridge.sendCommand('node_set_properties', { path, properties });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_find',
    'Find a node by name in the scene tree',
    {
      name: z.string().describe('Node name to search for'),
      recursive: z.boolean().default(true).describe('Search recursively'),
    },
    async ({ name, recursive }) => {
      const result = await bridge.sendCommand('node_find', { name, recursive });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_find_by_type',
    'Find all nodes of a given type',
    {
      type: z.string().describe('Node type to search for'),
    },
    async ({ type }) => {
      const result = await bridge.sendCommand('node_find_by_type', { type });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_get_children',
    'Get children of a node',
    {
      path: z.string().describe('Node path'),
      recursive: z.boolean().default(false).describe('Get all descendants'),
    },
    async ({ path, recursive }) => {
      const result = await bridge.sendCommand('node_get_children', { path, recursive });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_get_parent',
    'Get the parent of a node',
    {
      path: z.string().describe('Node path'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('node_get_parent', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_set_groups',
    'Set groups for a node',
    {
      path: z.string().describe('Node path'),
      groups: z.array(z.string()).describe('Group names'),
    },
    async ({ path, groups }) => {
      const result = await bridge.sendCommand('node_set_groups', { path, groups });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_get_groups',
    'Get groups of a node',
    {
      path: z.string().describe('Node path'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('node_get_groups', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_set_meta',
    'Set metadata on a node',
    {
      path: z.string().describe('Node path'),
      key: z.string().describe('Metadata key'),
      value: z.any().describe('Metadata value'),
    },
    async ({ path, key, value }) => {
      const result = await bridge.sendCommand('node_set_meta', { path, key, value });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'node_get_meta',
    'Get metadata from a node',
    {
      path: z.string().describe('Node path'),
      key: z.string().optional().describe('Specific metadata key (omit for all)'),
    },
    async ({ path, key }) => {
      const result = await bridge.sendCommand('node_get_meta', { path, key });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
