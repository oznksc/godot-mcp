import { z } from 'zod';
export function registerRuntimeTools(server, bridge) {
    server.tool('runtime_run_project', 'Run the project in debug mode', {
        scene: z.string().optional().describe('Specific scene to run (res://...)'),
    }, async ({ scene }) => {
        const result = await bridge.sendCommand('runtime_run_project', { scene });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('runtime_stop', 'Stop the running project', {}, async () => {
        const result = await bridge.sendCommand('runtime_stop');
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('runtime_pause', 'Pause the running project', {}, async () => {
        const result = await bridge.sendCommand('runtime_pause');
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('runtime_resume', 'Resume the paused project', {}, async () => {
        const result = await bridge.sendCommand('runtime_resume');
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('runtime_step', 'Step one frame forward (debug mode)', {}, async () => {
        const result = await bridge.sendCommand('runtime_step');
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('runtime_is_playing', 'Check if the project is currently running', {}, async () => {
        const result = await bridge.sendCommand('runtime_is_playing');
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('runtime_get_status', 'Get detailed runtime status', {}, async () => {
        const result = await bridge.sendCommand('runtime_get_status');
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
}
//# sourceMappingURL=runtime-tools.js.map