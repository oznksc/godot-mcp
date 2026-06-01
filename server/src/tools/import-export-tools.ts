import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerImportExportTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'import_reimport',
    'Reimport files in the project',
    {
      files: z.array(z.string()).describe('File paths to reimport (res://...)'),
    },
    async ({ files }) => {
      const result = await bridge.sendCommand('import_reimport', { files });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'import_get_settings',
    'Get import settings for a file',
    {
      path: z.string().describe('File path (res://...)'),
    },
    async ({ path }) => {
      const result = await bridge.sendCommand('import_get_settings', { path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'import_set_settings',
    'Update import settings for a file',
    {
      path: z.string().describe('File path (res://...)'),
      settings: z.record(z.any()).describe('Import settings to update'),
    },
    async ({ path, settings }) => {
      const result = await bridge.sendCommand('import_set_settings', { path, settings });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'export_run',
    'Run export with a preset',
    {
      preset: z.string().describe('Export preset name'),
      output_path: z.string().describe('Output file path'),
      debug: z.boolean().default(false).describe('Export as debug build'),
    },
    async ({ preset, output_path, debug }) => {
      const result = await bridge.sendCommand('export_run', { preset, output_path, debug });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'export_get_presets',
    'List all export presets',
    {},
    async () => {
      const result = await bridge.sendCommand('export_get_presets');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
