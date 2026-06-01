export interface GodotCommand {
  id: string;
  method: string;
  params: Record<string, unknown>;
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

export type GodotConnectionState = 'disconnected' | 'connecting' | 'connected';

export interface WebSocketConfig {
  host: string;
  port: number;
  reconnectAttempts: number;
  reconnectDelay: number;
  pingInterval: number;
}
