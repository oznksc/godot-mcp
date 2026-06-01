import { z } from 'zod';
export function registerPrompts(server) {
    server.prompt('godot_scene_setup', 'Guide for setting up a Godot scene with proper hierarchy', {
        scene_type: z.string().describe('Type of scene: 2d, 3d, or ui'),
    }, ({ scene_type }) => ({
        messages: [{
                role: 'user',
                content: {
                    type: 'text',
                    text: `I need help setting up a ${scene_type} scene in Godot. Please guide me through creating the proper node hierarchy, including:
1. The root node type
2. Essential child nodes
3. Required scripts
4. Signal connections
5. Physics/collision setup (if applicable)
6. Camera setup

Scene type: ${scene_type}`,
                },
            }],
    }));
    server.prompt('godot_node_guide', 'Guide about Godot node types and their usage', {
        node_type: z.string().describe('Node type to learn about (e.g., CharacterBody3D, Area2D, Control)'),
    }, ({ node_type }) => ({
        messages: [{
                role: 'user',
                content: {
                    type: 'text',
                    text: `Explain the Godot node type "${node_type}":
1. What is it used for?
2. What are its key properties?
3. What signals does it emit?
4. Common usage patterns
5. Related nodes and when to use each
6. Best practices and common pitfalls

Please provide practical examples with GDScript code.`,
                },
            }],
    }));
    server.prompt('godot_script_review', 'Template for reviewing GDScript code', {
        script_content: z.string().describe('The GDScript code to review'),
    }, ({ script_content }) => ({
        messages: [{
                role: 'user',
                content: {
                    type: 'text',
                    text: `Please review the following GDScript code for:
1. Syntax errors and potential bugs
2. Performance issues
3. Godot best practices and conventions
4. Signal connection patterns
5. Memory management (resource handling)
6. Code organization and readability
7. Type safety improvements

Code to review:
\`\`\`gdscript
${script_content}
\`\`\``,
                },
            }],
    }));
    server.prompt('godot_debug_guide', 'Debugging guide for Godot issues', {
        error_message: z.string().describe('The error message or issue description'),
    }, ({ error_message }) => ({
        messages: [{
                role: 'user',
                content: {
                    type: 'text',
                    text: `I'm encountering this error/issue in Godot:
"${error_message}"

Please help me:
1. Understand what this error means
2. Find the likely cause
3. Provide a step-by-step fix
4. Suggest how to prevent similar issues
5. Recommend relevant Godot documentation`,
                },
            }],
    }));
    server.prompt('godot_export_guide', 'Guide for configuring Godot exports', {
        platform: z.string().describe('Target platform (windows, linux, macos, android, ios, web)'),
    }, ({ platform }) => ({
        messages: [{
                role: 'user',
                content: {
                    type: 'text',
                    text: `Help me configure Godot export for the ${platform} platform:
1. Required export presets
2. Platform-specific settings
3. Optimization options
4. Common export issues and fixes
5. Testing the export
6. Size optimization tips

Target platform: ${platform}`,
                },
            }],
    }));
    server.prompt('godot_skill', 'Load a specific Godot skill module for in-depth guidance', {
        topic: z.string().describe('Godot topic (gdscript, scene, signal, performance, 2d, 3d, ui, physics, animation, audio, networking, export)'),
    }, ({ topic }) => ({
        messages: [{
                role: 'user',
                content: {
                    type: 'text',
                    text: `Please provide expert-level guidance on the Godot topic: "${topic}"

Use your knowledge of this skill module to:
1. Explain the core concepts
2. Provide best practices
3. Show common patterns with GDScript code
4. Highlight pitfalls and how to avoid them
5. Suggest related topics to explore

Topic: ${topic}`,
                },
            }],
    }));
}
//# sourceMappingURL=index.js.map