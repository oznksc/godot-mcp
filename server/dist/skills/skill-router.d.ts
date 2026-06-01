export interface SkillDefinition {
    id: string;
    name: string;
    file: string;
    keywords: string[];
    patterns: RegExp[];
    contextClues: string[];
    description: string;
}
export interface SkillMatch {
    skill: SkillDefinition;
    score: number;
    matchedKeywords: string[];
}
export declare function findRelevantSkills(query: string, maxSkills?: number, minScore?: number): SkillMatch[];
export declare function getSkillContent(skillId: string): string;
export declare function getMatchedSkillsContext(query: string): string;
export declare function listAvailableSkills(): SkillDefinition[];
//# sourceMappingURL=skill-router.d.ts.map