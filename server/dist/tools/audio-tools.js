import { z } from 'zod';
export function registerAudioTools(server, bridge) {
    server.tool('audio_create_player', 'Create an AudioStreamPlayer node', {
        type: z.enum(['AudioStreamPlayer', 'AudioStreamPlayer2D', 'AudioStreamPlayer3D']).describe('Player type'),
        name: z.string().describe('Node name'),
        parent: z.string().optional().describe('Parent node path'),
        stream_path: z.string().optional().describe('Audio stream path (res://...)'),
    }, async ({ type, name, parent, stream_path }) => {
        const result = await bridge.sendCommand('audio_create_player', { type, name, parent, stream_path });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('audio_set_stream', 'Set the audio stream on a player node', {
        path: z.string().describe('AudioStreamPlayer node path'),
        stream_path: z.string().describe('Audio file path (res://...)'),
    }, async ({ path, stream_path }) => {
        const result = await bridge.sendCommand('audio_set_stream', { path, stream_path });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('audio_set_bus', 'Set the audio bus for a player node', {
        path: z.string().describe('AudioStreamPlayer node path'),
        bus_name: z.string().describe('Audio bus name (e.g., Master, Music, SFX)'),
    }, async ({ path, bus_name }) => {
        const result = await bridge.sendCommand('audio_set_bus', { path, bus_name });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('audio_get_bus_layout', 'Get the audio bus layout', {}, async () => {
        const result = await bridge.sendCommand('audio_get_bus_layout');
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
}
//# sourceMappingURL=audio-tools.js.map