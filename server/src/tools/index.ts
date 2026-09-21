import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { GodotBridge } from '../utils/godot-bridge.js';
import { registerSceneTools } from './scene-tools.js';
import { registerNodeTools } from './node-tools.js';
import { registerScriptTools } from './script-tools.js';
import { registerResourceTools } from './resource-tools.js';
import { registerProjectTools } from './project-tools.js';
import { registerEditorTools } from './editor-tools.js';
import { registerFileTools } from './file-tools.js';
import { registerSignalTools } from './signal-tools.js';
import { registerRuntimeTools } from './runtime-tools.js';
import { registerDebugTools } from './debug-tools.js';
import { registerAnimationTools } from './animation-tools.js';
import { registerShaderTools } from './shader-tools.js';
import { registerPhysicsTools } from './physics-tools.js';
import { registerUiTools } from './ui-tools.js';
import { registerAudioTools } from './audio-tools.js';
import { registerLightingTools } from './lighting-tools.js';
import { registerParticlesTools } from './particles-tools.js';
import { registerImportExportTools } from './import-export-tools.js';
import { registerClassdbTools } from './classdb-tools.js';
import { registerTransactionTools } from './transaction-tools.js';
import { registerViewportTools } from './viewport-tools.js';
import { registerInputTools } from './input-tools.js';
import { registerPlaytestTools } from './playtest-tools.js';
import { registerLspTools } from './lsp-tools.js';
import { registerSkillTools } from '../skills/skill-tools.js';
import { registerExampleTools } from '../skills/example-tools.js';
import { GodotLSPClient } from '../utils/godot-lsp.js';

export function registerAllTools(
  server: McpServer,
  bridge: GodotBridge,
  lspClient?: GodotLSPClient
): void {
  server.tool(
    'godot_connection_status',
    'Get MCP-to-Godot bridge connection health, version handshake, and capabilities',
    {},
    async () => ({
      content: [{ type: 'text' as const, text: JSON.stringify(bridge.getStatus(), null, 2) }],
    })
  );

  registerSceneTools(server, bridge);
  registerNodeTools(server, bridge);
  registerScriptTools(server, bridge);
  registerResourceTools(server, bridge);
  registerProjectTools(server, bridge);
  registerEditorTools(server, bridge);
  registerFileTools(server, bridge);
  registerSignalTools(server, bridge);
  registerRuntimeTools(server, bridge);
  registerDebugTools(server, bridge);
  registerAnimationTools(server, bridge);
  registerShaderTools(server, bridge);
  registerPhysicsTools(server, bridge);
  registerUiTools(server, bridge);
  registerAudioTools(server, bridge);
  registerLightingTools(server, bridge);
  registerParticlesTools(server, bridge);
  registerImportExportTools(server, bridge);
  registerClassdbTools(server, bridge);

  // Godot MCP v2 Tools
  registerTransactionTools(server, bridge);
  registerViewportTools(server, bridge);
  registerInputTools(server, bridge);
  registerPlaytestTools(server, bridge);
  registerLspTools(server, bridge, lspClient);

  registerSkillTools(server);
  registerExampleTools(server);
}
