import * as net from 'net';
import { EventEmitter } from 'events';
import { logger } from './logger.js';

export interface LSPDiagnostic {
  range: {
    start: { line: number; character: number };
    end: { line: number; character: number };
  };
  severity: number;
  message: string;
}

export class GodotLSPClient extends EventEmitter {
  private socket: net.Socket | null = null;
  private host: string;
  private port: number;
  private buffer = '';
  private bufferChunks: Buffer[] = [];
  private bufferLength = 0;
  private nextId = 1;
  private pendingRequests = new Map<number | string, { resolve: (val: unknown) => void; reject: (err: Error) => void }>();
  private connected = false;

  constructor(host = '127.0.0.1', port = 6005) {
    super();
    this.host = host;
    this.port = port;
  }

  get isConnected(): boolean {
    return this.connected;
  }

  async connect(): Promise<boolean> {
    return new Promise((resolve) => {
      this.socket = net.createConnection({ host: this.host, port: this.port }, () => {
        this.connected = true;
        logger.info('lsp', `Connected to Godot LSP at ${this.host}:${this.port}`);
        this.initializeLSP();
        resolve(true);
      });

      this.socket.on('data', (data: Buffer) => {
        this.handleData(data);
      });

      this.socket.on('error', (err) => {
        logger.debug('lsp', `LSP socket not available: ${err.message}`);
        this.connected = false;
        resolve(false);
      });

      this.socket.on('close', () => {
        this.connected = false;
        logger.debug('lsp', 'LSP connection closed');
      });
    });
  }

  disconnect(): void {
    if (this.socket) {
      this.socket.destroy();
      this.socket = null;
      this.connected = false;
    }
  }

  private initializeLSP(): void {
    this.sendNotification('initialize', {
      processId: process.pid,
      rootUri: null,
      capabilities: {
        textDocument: {
          publishDiagnostics: { relatedInformation: true },
        },
      },
    });
  }

  sendNotification(method: string, params: Record<string, unknown>): void {
    if (!this.socket || !this.connected) return;
    const body = JSON.stringify({ jsonrpc: '2.0', method, params });
    const message = `Content-Length: ${Buffer.byteLength(body, 'utf8')}\r\n\r\n${body}`;
    this.socket.write(message);
  }

  async sendRequest(method: string, params: Record<string, unknown>): Promise<unknown> {
    if (!this.socket || !this.connected) {
      throw new Error('Godot LSP not connected');
    }
    const id = this.nextId++;
    const body = JSON.stringify({ jsonrpc: '2.0', id, method, params });
    const message = `Content-Length: ${Buffer.byteLength(body, 'utf8')}\r\n\r\n${body}`;

    return new Promise((resolve, reject) => {
      this.pendingRequests.set(id, { resolve, reject });
      this.socket!.write(message);
    });
  }

  private handleData(chunk: Buffer): void {
    this.bufferChunks.push(chunk);
    this.bufferLength += chunk.length;

    while (true) {
      // Only convert to string when we need to scan for headers—avoids
      // repeated full-buffer string allocations on every incoming chunk.
      const current = Buffer.concat(this.bufferChunks).toString('utf8');

      const headerEnd = current.indexOf('\r\n\r\n');
      if (headerEnd === -1) break;

      const header = current.substring(0, headerEnd);
      const match = header.match(/Content-Length:\s*(\d+)/i);
      if (!match) {
        const remaining = current.substring(headerEnd + 4);
        this.bufferChunks = [Buffer.from(remaining, 'utf8')];
        this.bufferLength = this.bufferChunks[0].length;
        continue;
      }

      const contentLength = parseInt(match[1], 10);
      const bodyStart = headerEnd + 4;
      if (current.length < bodyStart + contentLength) {
        break; // Wait for rest of message
      }

      const body = current.substring(bodyStart, bodyStart + contentLength);
      const remaining = current.substring(bodyStart + contentLength);
      this.bufferChunks = remaining.length > 0 ? [Buffer.from(remaining, 'utf8')] : [];
      this.bufferLength = remaining.length;

      try {
        const parsed = JSON.parse(body);
        if (parsed.id !== undefined && this.pendingRequests.has(parsed.id)) {
          const req = this.pendingRequests.get(parsed.id)!;
          this.pendingRequests.delete(parsed.id);
          if (parsed.error) {
            req.reject(new Error(parsed.error.message));
          } else {
            req.resolve(parsed.result);
          }
        } else if (parsed.method === 'textDocument/publishDiagnostics') {
          this.emit('diagnostics', parsed.params);
        }
      } catch (err) {
        logger.debug('lsp', `Failed to parse LSP payload: ${String(err)}`);
      }
    }
  }
}
