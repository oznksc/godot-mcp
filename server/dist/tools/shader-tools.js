import { z } from 'zod';
export function registerShaderTools(server, bridge) {
    server.tool('shader_create', 'Create a new shader file', {
        path: z.string().describe('Shader path (res://shaders/my_shader.gdshader)'),
        type: z.enum(['spatial', 'canvas_item', 'particles', 'sky', 'fog']).describe('Shader type'),
        content: z.string().optional().describe('Initial shader code'),
    }, async ({ path, type, content }) => {
        const result = await bridge.sendCommand('shader_create', { path, type, content });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('shader_read', 'Read shader source code', {
        path: z.string().describe('Shader path (res://...)'),
    }, async ({ path }) => {
        const result = await bridge.sendCommand('shader_read', { path });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('shader_write', 'Write shader source code', {
        path: z.string().describe('Shader path (res://...)'),
        content: z.string().describe('Full shader code'),
    }, async ({ path, content }) => {
        const result = await bridge.sendCommand('shader_write', { path, content });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('shader_assign_material', 'Assign a ShaderMaterial to a node', {
        node_path: z.string().describe('Node path'),
        shader_path: z.string().describe('Shader path (res://...)'),
        properties: z.record(z.any()).optional().describe('Material shader parameter overrides'),
    }, async ({ node_path, shader_path, properties }) => {
        const result = await bridge.sendCommand('shader_assign_material', { node_path, shader_path, properties });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
}
//# sourceMappingURL=shader-tools.js.map