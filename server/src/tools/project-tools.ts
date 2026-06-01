import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerProjectTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'project_get_info',
    'Get project information (name, version, structure)',
    {},
    async () => {
      const result = await bridge.sendCommand('project_get_info');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'project_get_settings',
    'Get all project settings',
    {},
    async () => {
      const result = await bridge.sendCommand('project_get_settings');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'project_update_setting',
    'Update a project setting',
    {
      setting: z.string().describe('Setting path (e.g., display/window/size/width)'),
      value: z.any().describe('New value'),
    },
    async ({ setting, value }) => {
      const result = await bridge.sendCommand('project_update_setting', { setting, value });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'project_get_input_map',
    'Get the project input map',
    {},
    async () => {
      const result = await bridge.sendCommand('project_get_input_map');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'project_configure_input_map',
    'Add or update an input action',
    {
      action: z.string().describe('Input action name'),
      events: z.array(z.object({
        type: z.string().describe('Event type (Key, MouseButton, JoyButton, JoyAxis, etc.)'),
        keycode: z.number().optional().describe('Key code'),
        button_index: z.number().optional().describe('Mouse/Joy button index'),
        axis: z.number().optional().describe('Joy axis'),
        axis_value: z.number().optional().describe('Axis value'),
        physical_keycode: z.number().optional().describe('Physical key code'),
      })).describe('Input events for this action'),
    },
    async ({ action, events }) => {
      const result = await bridge.sendCommand('project_configure_input_map', { action, events });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'project_get_collision_layers',
    'Get collision layer and mask names',
    {},
    async () => {
      const result = await bridge.sendCommand('project_get_collision_layers');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'project_setup_autoload',
    'Add an autoload singleton',
    {
      name: z.string().describe('Autoload name'),
      path: z.string().describe('Script path (res://...)'),
      enabled: z.boolean().default(true).describe('Whether autoload is enabled'),
    },
    async ({ name, path, enabled }) => {
      const result = await bridge.sendCommand('project_setup_autoload', { name, path, enabled });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'project_remove_autoload',
    'Remove an autoload singleton',
    {
      name: z.string().describe('Autoload name to remove'),
    },
    async ({ name }) => {
      const result = await bridge.sendCommand('project_remove_autoload', { name });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'project_get_class_list',
    'Get the list of registered global classes',
    {},
    async () => {
      const result = await bridge.sendCommand('project_get_class_list');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'project_get_export_presets',
    'Get export presets',
    {},
    async () => {
      const result = await bridge.sendCommand('project_get_export_presets');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
