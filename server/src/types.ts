export interface GodotCommand {
  id: string;
  method: string;
  params: Record<string, unknown>;
  token?: string;
}

export interface GodotResponse {
  id: string;
  result?: unknown;
  error?: {
    code: number;
    message: string;
    data?: unknown;
  };
}

export interface GodotError {
  code: number;
  message: string;
  data?: unknown;
}

export interface SceneNode {
  name: string;
  type: string;
  properties: Record<string, unknown>;
  children: SceneNode[];
  script?: string;
  groups?: string[];
  metadata?: Record<string, unknown>;
}

export interface ProjectInfo {
  name: string;
  version: string;
  config_version: number;
  path: string;
}

export interface EditorState {
  is_playing: boolean;
  playing_scene: string | null;
  current_scene: string | null;
  open_scenes: string[];
  active_screen: string;
}

export interface NodeProperty {
  name: string;
  type: string;
  value: unknown;
  hint?: string;
  hint_string?: string;
}

export type GodotConnectionState = 'disconnected' | 'connecting' | 'handshaking' | 'connected';

export interface WebSocketConfig {
  host: string;
  port: number;
  reconnectAttempts: number;
  reconnectDelay: number;
  pingInterval: number;
  commandTimeout: number;
  sessionToken?: string;
  sessionKeyPath?: string;
}

export interface HandshakeInfo {
  protocol_version: string;
  engine: {
    major: number;
    minor: number;
    patch: number;
    status: string;
    build: string;
    string: string;
    mono?: boolean;
  };
  capabilities: string[];
  project_name: string;
  session_token?: string;
  os?: string;
  editor_pid?: number;
  client_compatible?: boolean;
}

export interface ViewportCaptureResult {
  view: string;
  format: string;
  width: number;
  height: number;
  original_width?: number;
  original_height?: number;
  base64: string;
}

export interface PlaytestStep {
  type: 'wait' | 'key' | 'action' | 'mouse' | 'screenshot' | 'assert_node';
  seconds?: number;
  duration?: number;
  key?: string;
  action?: string;
  position?: [number, number];
  tag?: string;
  node_path?: string;
  property?: string;
  expected?: unknown;
  min?: number;
  max?: number;
}
