import { z } from 'zod';
export function registerClassdbTools(server, bridge) {
    server.tool('classdb_query', 'Query information about a Godot class', {
        class_name: z.string().describe('Godot class name (e.g., Node2D, CharacterBody3D, Resource)'),
    }, async ({ class_name }) => {
        const result = await bridge.sendCommand('classdb_query', { class_name });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('classdb_list_methods', 'List methods of a Godot class', {
        class_name: z.string().describe('Godot class name'),
        include_inherited: z.boolean().default(false).describe('Include inherited methods'),
    }, async ({ class_name, include_inherited }) => {
        const result = await bridge.sendCommand('classdb_list_methods', { class_name, include_inherited });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('classdb_list_classes', 'List all available Godot classes', {
        filter: z.string().optional().describe('Optional filter string'),
    }, async ({ filter }) => {
        const result = await bridge.sendCommand('classdb_list_classes', { filter });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
}
//# sourceMappingURL=classdb-tools.js.map