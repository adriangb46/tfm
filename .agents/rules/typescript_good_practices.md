# TypeScript Good Practices

These rules apply to all TypeScript code in the project — primarily the Angular frontend and any shared type packages.

## Compiler Configuration

- Always enable **strict mode** in `tsconfig.json`:
  ```json
  {
    "compilerOptions": {
      "strict": true,
      "noUncheckedIndexedAccess": true,
      "exactOptionalPropertyTypes": true,
      "noImplicitOverride": true
    }
  }
  ```
- Target **ES2022** or higher. Do not target legacy ES versions.
- Enable `strictNullChecks`. Every nullable value must be handled explicitly.

## Types vs Interfaces

- Use **`interface`** for object shapes that describe entities, DTOs, or service contracts.
  ```typescript
  interface Troop {
    id: string;
    type: TroopType;
    actionPoints: number;
    currentPoints: number;
    deployed: boolean;
  }
  ```
- Use **`type`** for unions, intersections, mapped types, and aliases.
  ```typescript
  type GamePhase = 'preparation' | 'war' | 'end';
  type ClanAdvantage = Record<ClanType, ClanType[]>; // qué clanes tiene ventaja sobre cuáles
  ```
- Never use `interface` and `type` interchangeably for the same construct within the same layer.

## Enums

- Prefer **`const` object + `typeof` union** over TypeScript `enum` for better tree-shaking and serialisation:
  ```typescript
  // ✅ Correcto
  export const ClanType = {
    BERSERKER: 'BERSERKER',
    SHIELDMAIDEN: 'SHIELDMAIDEN',
    SKALD: 'SKALD',
    JARL: 'JARL',
  } as const;
  export type ClanType = typeof ClanType[keyof typeof ClanType];

  // ❌ Evitar
  enum ClanType { BERSERKER, SHIELDMAIDEN }
  ```

## `any` and `unknown`

- **Never use `any`**. If a type is genuinely unknown, use `unknown` and narrow it with a type guard.
- Write **type guard functions** for external data (Socket.IO payloads, HTTP responses):
  ```typescript
  function isAttackPayload(value: unknown): value is AttackPayload {
    return (
      typeof value === 'object' &&
      value !== null &&
      'targetCapitalId' in value &&
      'troopIds' in value
    );
  }
  ```
- The only acceptable use of `as` casts is when TypeScript cannot infer a type that you can prove correct. Always leave a comment explaining why.

## Generics

- Write generic functions and types when logic is reusable across different entity types.
- Constrain generics with `extends` to keep them meaningful:
  ```typescript
  function findById<T extends { id: string }>(items: T[], id: string): T | undefined {
    return items.find((item) => item.id === id);
  }
  ```
- Do not overuse generics. If a function only ever works with one type, it should not be generic.

## Utility Types

- Prefer built-in utility types over manual repetition: `Partial<T>`, `Required<T>`, `Readonly<T>`, `Pick<T, K>`, `Omit<T, K>`, `Record<K, V>`, `ReturnType<F>`, `Parameters<F>`.
- Use `Readonly<T>` and `ReadonlyArray<T>` on data that must not be mutated.

## Null Safety

- Never use the non-null assertion operator (`!`) without a comment explaining why nullability is impossible at that point.
- Use **optional chaining** (`?.`) and **nullish coalescing** (`??`) instead of manual null checks where readable.
- Model optional fields explicitly: `field?: string` means the field may be absent. `field: string | null` means the field is present but may be null. Do not mix these semantics.

## Functions

- Always declare **explicit return types** on exported and public functions. Inferred return types are acceptable only for private/local helpers.
- Prefer `function` declarations for named top-level functions. Use arrow functions for callbacks and inline expressions.
- Keep functions pure where possible. A function that receives the same inputs should return the same output.

## Modules & Imports

- Use **path aliases** (configured in `tsconfig.json`) instead of relative `../../..` imports.
  ```typescript
  // ✅ Correcto
  import { Troop } from '@game/domain/troop';

  // ❌ Incorrecto
  import { Troop } from '../../../domain/troop';
  ```
- Never use default exports except where a framework requires it (e.g. Angular `@NgModule` — though NgModules are not used in this project).
- Group imports: (1) external libraries, (2) internal modules, separated by a blank line.

## Naming Conventions

- Types and interfaces: `PascalCase`
- Variables, functions, parameters: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Generic type parameters: single uppercase letter (`T`, `K`, `V`) or descriptive `PascalCase` (`TEntity`, `TKey`)
- Files: `kebab-case.ts`
- Code in **English**. Comments in **Spanish**.

## General Rules

- Enable and run **ESLint** with `@typescript-eslint` rules. All lint errors must be resolved before committing.
- Do not disable ESLint rules inline (`// eslint-disable`) without a comment justifying the exception.
- Do not export types that are only used internally within a module.
- Review types when they become complex. If a type is hard to read, it likely signals a design problem in the data model.
