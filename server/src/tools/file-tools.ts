import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerFileTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'file_list_dir',
    'List files in a project directory',
    {
      path: z.string().default('res://').describe('Directory path (res://...)'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('file_list_dir', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'file_read',
    'Read a file from the project',
    {
      path: z.string().describe('File path (res://...)'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('file_read', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'file_write',
    'Write content to a file in the project',
    {
      path: z.string().describe('File path (res://...)'),
      content: z.string().describe('File content'),
    },
    async ({ path, content }) => {
      const result = await bridge.sendCommand('file_write', { path, content });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'file_delete',
    'Delete a file from the project',
    {
      path: z.string().describe('File path (res://...)'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('file_delete', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'file_rename',
    'Rename a file in the project',
    {
      old_path: z.string().describe('Current file path (res://...)'),
      new_path: z.string().describe('New file path (res://...)'),
    },
    async ({ old_path, new_path }) => {
      const result = await bridge.sendCommand('file_rename', { old_path, new_path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'file_search',
    'Search for files in the project by name or content',
    {
      query: z.string().describe('Search query'),
      path: z.string().optional().describe('Directory to search in (res://)'),
      type: z.string().optional().describe('File type filter (e.g., .gd, .tscn, .tres)'),
      content_search: z.boolean().default(false).describe('Search file contents instead of names'),
    },
    async ({ query, path, type, content_search }) => {
      const result = await bridge.sendCommand('file_search', { query, path, type, content_search });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
