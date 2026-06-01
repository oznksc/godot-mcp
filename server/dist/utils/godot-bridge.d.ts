import { EventEmitter } from 'events';
import type { WebSocketConfig } from '../types.js';
export declare class GodotBridge extends EventEmitter {
    private ws;
    private config;
    private pendingRequests;
    private reconnectCount;
    private pingTimer;
    private _connected;
    constructor(config?: Partial<WebSocketConfig>);
    get connected(): boolean;
    connect(): Promise<void>;
    disconnect(): Promise<void>;
    sendCommand(method: string, params?: Record<string, unknown>): Promise<unknown>;
    private handleResponse;
    private rejectAllPending;
    private startPing;
    private stopPing;
    private tryReconnect;
}
//# sourceMappingURL=godot-bridge.d.ts.map