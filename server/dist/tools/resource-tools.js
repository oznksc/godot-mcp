import { z } from 'zod';
export function registerResourceTools(server, bridge) {
    server.tool('resource_get_info', 'Get information about a resource', {
        path: z.string().describe('Resource path (res://...)'),
    }, async ({ path }) => {
        const result = await bridge.sendCommand('resource_get_info', { path });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('resource_set_property', 'Set a property on a resource', {
        path: z.string().describe('Resource path (res://...)'),
        property: z.string().describe('Property name'),
        value: z.any().describe('Property value'),
    }, async ({ path, property, value }) => {
        const result = await bridge.sendCommand('resource_set_property', { path, property, value });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('resource_save', 'Save a resource to disk', {
        path: z.string().describe('Resource path to save (res://...)'),
    }, async ({ path }) => {
        const result = await bridge.sendCommand('resource_save', { path });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('resource_load', 'Load a resource from disk', {
        path: z.string().describe('Resource path (res://...)'),
    }, async ({ path }) => {
        const result = await bridge.sendCommand('resource_load', { path });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('resource_create', 'Create a new resource of a specified type', {
        type: z.string().describe('Resource type (StandardMaterial3D, Gradient, Curve, etc.)'),
        path: z.string().optional().describe('Save path (res://...)'),
        properties: z.record(z.any()).optional().describe('Initial properties'),
    }, async ({ type, path, properties }) => {
        const result = await bridge.sendCommand('resource_create', { type, path, properties });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('resource_list_by_type', 'List all resources of a given type in the project', {
        type: z.string().describe('Resource type to search for'),
    }, async ({ type }) => {
        const result = await bridge.sendCommand('resource_list_by_type', { type });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
}
//# sourceMappingURL=resource-tools.js.map