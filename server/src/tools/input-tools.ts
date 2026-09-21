import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';

export function registerInputTools(server: McpServer, bridge: GodotBridge): void {
  server.tool(
    'input_simulate_key',
    'Simulate a physical keyboard event (key press or release) inside Godot',
    {
      key: z.string().describe('Key name (e.g. "Space", "W", "A", "S", "D", "Escape", "Enter")'),
      pressed: z.boolean().default(true).describe('True for keydown, false for keyup'),
      echo: z.boolean().default(false).describe('True if this is a repeat/echo event'),
      shift: z.boolean().default(false).describe('Shift modifier state'),
      ctrl: z.boolean().default(false).describe('Ctrl modifier state'),
      alt: z.boolean().default(false).describe('Alt modifier state'),
    },
    async ({ key, pressed, echo, shift, ctrl, alt }) => {
      const result = await bridge.sendCommand('input_simulate_key', {
        key,
        pressed,
        echo,
        shift,
        ctrl,
        alt,
      });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'input_simulate_mouse',
    'Simulate a mouse event (click, move, mouse down, mouse up) at specific viewport coordinates',
    {
      action: z.enum(['click', 'down', 'up', 'move']).default('click').describe('Mouse action type'),
      position: z.tuple([z.number(), z.number()]).describe('Mouse [x, y] coordinates'),
      button: z.number().default(1).describe('Mouse button index (1: Left, 2: Right, 3: Middle)'),
      pressed: z.boolean().default(true).describe('Pressed state for down/up'),
    },
    async ({ action, position, button, pressed }) => {
      const result = await bridge.sendCommand('input_simulate_mouse', {
        action,
        position,
        button,
        pressed,
      });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );

  server.tool(
    'input_simulate_action',
    'Trigger a configured Godot InputMap action (e.g. "ui_accept", "move_right")',
    {
      action: z.string().describe('InputMap action name'),
      pressed: z.boolean().default(true).describe('True to press, false to release'),
      strength: z.number().default(1.0).describe('Action strength (0.0 to 1.0)'),
    },
    async ({ action, pressed, strength }) => {
      const result = await bridge.sendCommand('input_simulate_action', {
        action,
        pressed,
        strength,
      });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    }
  );
}
