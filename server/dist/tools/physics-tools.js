import { z } from 'zod';
export function registerPhysicsTools(server, bridge) {
    server.tool('physics_set_collision_shape', 'Set the collision shape for a physics node', {
        node_path: z.string().describe('Physics node path (CharacterBody, RigidBody, StaticBody, etc.)'),
        shape_type: z.enum(['Rectangle', 'Circle', 'Capsule', 'ConvexPolygon', 'ConcavePolygon', 'Sphere', 'Box', 'Cylinder', 'Capsule3D']).describe('Collision shape type'),
        shape_properties: z.record(z.any()).optional().describe('Shape-specific properties (extents, radius, height, etc.)'),
    }, async ({ node_path, shape_type, shape_properties }) => {
        const result = await bridge.sendCommand('physics_set_collision_shape', { node_path, shape_type, shape_properties });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('physics_set_collision_layer', 'Set collision layer and mask for a node', {
        path: z.string().describe('Node path'),
        layer: z.number().min(1).max(32).describe('Collision layer (1-32)'),
        mask: z.number().min(1).max(32).describe('Collision mask (1-32)'),
    }, async ({ path, layer, mask }) => {
        const result = await bridge.sendCommand('physics_set_collision_layer', { path, layer, mask });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('physics_configure_material', 'Configure PhysicsMaterial for a physics node', {
        path: z.string().describe('Node path'),
        bounce: z.number().optional().describe('Bounce factor (0-1)'),
        friction: z.number().optional().describe('Friction coefficient'),
        absorbent: z.boolean().optional().describe('Is absorbent'),
    }, async ({ path, bounce, friction, absorbent }) => {
        const result = await bridge.sendCommand('physics_configure_material', { path, bounce, friction, absorbent });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
    server.tool('physics_get_body_state', 'Get physics body state at runtime', {
        path: z.string().describe('Physics body node path'),
    }, async ({ path }) => {
        const result = await bridge.sendCommand('physics_get_body_state', { path });
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    });
}
//# sourceMappingURL=physics-tools.js.map