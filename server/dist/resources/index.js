import { ResourceTemplate } from '@modelcontextprotocol/sdk/server/mcp.js';
export function registerResources(server, bridge) {
    server.resource('project-info', 'godot://project/info', { description: 'Project metadata (name, version, structure)', mimeType: 'application/json' }, async () => {
        const data = await bridge.sendCommand('project_get_info');
        return { contents: [{ uri: 'godot://project/info', text: JSON.stringify(data, null, 2), mimeType: 'application/json' }] };
    });
    server.resource('project-settings', 'godot://project/settings', { description: 'All project settings', mimeType: 'application/json' }, async () => {
        const data = await bridge.sendCommand('project_get_settings');
        return { contents: [{ uri: 'godot://project/settings', text: JSON.stringify(data, null, 2), mimeType: 'application/json' }] };
    });
    server.resource('current-scene', 'godot://scene/current', { description: 'Currently open scene structure', mimeType: 'application/json' }, async () => {
        const data = await bridge.sendCommand('scene_get_hierarchy');
        return { contents: [{ uri: 'godot://scene/current', text: JSON.stringify(data, null, 2), mimeType: 'application/json' }] };
    });
    server.resource('editor-state', 'godot://editor/state', { description: 'Current editor state (open scenes, active screen, playing status)', mimeType: 'application/json' }, async () => {
        const data = await bridge.sendCommand('editor_get_state');
        return { contents: [{ uri: 'godot://editor/state', text: JSON.stringify(data, null, 2), mimeType: 'application/json' }] };
    });
    server.resource('console-output', 'godot://console/output', { description: 'Console and debug output', mimeType: 'text/plain' }, async () => {
        const data = await bridge.sendCommand('debug_get_output', { lines: 200, type: 'all' });
        return { contents: [{ uri: 'godot://console/output', text: JSON.stringify(data, null, 2), mimeType: 'text/plain' }] };
    });
    server.resource('runtime-status', 'godot://runtime/status', { description: 'Runtime execution status', mimeType: 'application/json' }, async () => {
        const data = await bridge.sendCommand('runtime_get_status');
        return { contents: [{ uri: 'godot://runtime/status', text: JSON.stringify(data, null, 2), mimeType: 'application/json' }] };
    });
    server.resource('classdb', new ResourceTemplate('godot://classdb/{className}', {
        list: async () => ({
            resources: [{ uri: 'godot://classdb/Node2D', name: 'Node2D' }],
        }),
    }), { description: 'Query Godot ClassDB for class information', mimeType: 'application/json' }, async (uri, { className }) => {
        const data = await bridge.sendCommand('classdb_query', { class_name: className });
        return { contents: [{ uri: uri.href, text: JSON.stringify(data, null, 2), mimeType: 'application/json' }] };
    });
}
//# sourceMappingURL=index.js.map