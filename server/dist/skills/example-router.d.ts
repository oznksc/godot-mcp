export interface ExampleEntry {
    path: string;
    type: string;
    description: string;
    difficulty: 'beginner' | 'intermediate' | 'advanced' | 'expert';
}
export interface Repository {
    id: string;
    name: string;
    url: string;
    stars: number;
    license: string;
    description: string;
    examples: ExampleEntry[];
}
export interface ExampleMatch {
    repo: Repository;
    example: ExampleEntry;
    score: number;
}
export declare function findRelevantExamples(query: string, maxResults?: number, minScore?: number): ExampleMatch[];
export declare function getExampleContent(repoUrl: string, examplePath: string): string;
export declare function listRepositories(): Repository[];
export declare function getExamplesByDifficulty(difficulty: string): ExampleMatch[];
export declare function getExamplesByType(type: string): ExampleMatch[];
//# sourceMappingURL=example-router.d.ts.map