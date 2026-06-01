import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerUiTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'ui_create_control',
    'Create a Control node for UI',
    {
      type: z.enum(['Button', 'Label', 'LineEdit', 'TextEdit', 'ProgressBar', 'TextureRect', 'HScrollBar', 'VScrollBar', 'HSlider', 'VSlider', 'CheckBox', 'OptionButton', 'RichTextLabel', 'Panel', 'PanelContainer', 'MarginContainer', 'TabContainer', 'Popup', 'WindowDialog']).describe('Control node type'),
      name: z.string().describe('Node name'),
      parent: z.string().optional().describe('Parent node path'),
    },
    async ({ type, name, parent }) => {
      const result = await bridge.sendCommand('ui_create_control', { type, name, parent });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'ui_create_container',
    'Create a container node for UI layout',
    {
      type: z.enum(['HBoxContainer', 'VBoxContainer', 'GridContainer', 'FlowContainer', 'CenterContainer', 'ScrollContainer']).describe('Container type'),
      name: z.string().describe('Node name'),
      parent: z.string().optional().describe('Parent node path'),
      columns: z.number().optional().describe('Columns (GridContainer only)'),
    },
    async ({ type, name, parent, columns }) => {
      const result = await bridge.sendCommand('ui_create_container', { type, name, parent, columns });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'ui_set_anchors',
    'Set anchor and margin preset for a Control node',
    {
      path: z.string().describe('Control node path'),
      preset: z.enum(['FullRect', 'TopLeft', 'TopRight', 'BottomLeft', 'BottomRight', 'CenterLeft', 'CenterRight', 'TopCenter', 'BottomCenter', 'Center', 'LeftWide', 'RightWide', 'TopWide', 'BottomWide', 'VCenterWide', 'HCenterWide']).describe('Anchor preset'),
      offset_left: z.number().optional().describe('Left offset'),
      offset_top: z.number().optional().describe('Top offset'),
      offset_right: z.number().optional().describe('Right offset'),
      offset_bottom: z.number().optional().describe('Bottom offset'),
    },
    async ({ path, preset, offset_left, offset_top, offset_right, offset_bottom }) => {
      const result = await bridge.sendCommand('ui_set_anchors', { path, preset, offset_left, offset_top, offset_right, offset_bottom });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'ui_set_theme',
    'Set a theme resource on a Control node',
    {
      path: z.string().describe('Control node path'),
      theme_path: z.string().describe('Theme resource path (res://...)'),
    },
    async ({ path, theme_path }) => {
      const result = await bridge.sendCommand('ui_set_theme', { path, theme_path });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
