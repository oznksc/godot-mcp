import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { GodotBridge } from '../utils/godot-bridge.js';
import { GodotLSPClient } from '../utils/godot-lsp.js';

export function registerLspTools(
  server: McpServer,
  bridge: GodotBridge,
  lspClient?: GodotLSPClient
): void {
  server.tool(
    'script_get_diagnostics',
    'Get precise compilation diagnostics, syntax errors, and type warnings for a GDScript file via Godot Language Server or AST validation',
    {
      path: z.string().describe('Script file path (res://...)'),
      content: z.string().optional().describe('Optional source content to validate before saving'),
    },
    async ({ path, content }) => {
      // 1. Try internal compiler validation via bridge first
      const validationResult = (await bridge.sendCommand('script_validate', {
        path,
        content,
      })) as Record<string, unknown>;

      let lspConnected = false;
      if (lspClient && lspClient.isConnected) {
        lspConnected = true;
      }

      return {
        content: [
          {
            type: 'text' as const,
            text: JSON.stringify(
              {
                path,
                valid: validationResult.valid ?? true,
                error: validationResult.error ?? null,
                warnings: validationResult.warnings ?? [],
                lsp_connected: lspConnected,
                details: validationResult,
              },
              null,
              2
            ),
          },
        ],
      };
    }
  );

  server.tool(
    'script_get_symbols',
    'List document symbols (classes, functions, signals, variables) in a GDScript file via Language Server',
    {
      path: z.string().describe('Script file path (res://...)'),
    },
    async ({ path }) => {
      if (lspClient && lspClient.isConnected) {
        try {
          const symbols = await lspClient.sendRequest('textDocument/documentSymbol', {
            textDocument: { uri: path },
          });
          return { content: [{ type: 'text' as const, text: JSON.stringify(symbols, null, 2) }] };
        } catch (err) {
          // fallback
        }
      }

      // Fallback: Read file and parse basic symbols
      const readRes = (await bridge.sendCommand('script_read', { path })) as { content?: string };
      const content = readRes?.content || '';
      const symbols: Array<{ type: string; name: string; line: number }> = [];

      const lines = content.split('\n');
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (line.startsWith('func ')) {
          symbols.push({
            type: 'function',
            name: line.replace('func ', '').split('(')[0].trim(),
            line: i + 1,
          });
        } else if (line.startsWith('signal ')) {
          symbols.push({
            type: 'signal',
            name: line.replace('signal ', '').split('(')[0].trim(),
            line: i + 1,
          });
        } else if (line.startsWith('var ') || line.startsWith('@export var ') || line.startsWith('@onready var ')) {
          const varPart = line.replace('@export ', '').replace('@onready ', '').replace('var ', '');
          symbols.push({
            type: 'variable',
            name: varPart.split(':')[0].split('=')[0].trim(),
            line: i + 1,
          });
        }
      }

      return {
        content: [
          {
            type: 'text' as const,
            text: JSON.stringify({ path, symbols, count: symbols.length, source: 'parser_fallback' }, null, 2),
          },
        ],
      };
    }
  );
}
