---
description: cleanup and refactor code by functionality
---

# Workflow: /clean-code

## Trigger

Invoked with `/clean-code [feature/file/directory]` from the Antigravity chat.

## Purpose

Review a specific functionality, file, or directory to remove junk code, legacy logic, unused exports, and ensure alignment with the current project standards.

---

## Step 1 — Context Acquisition

Identify the target and understand its intended purpose using:
- [proyect_arquitecture.md](file:///.agents/proyect_arquitecture.md)
- [AGENTS_CHANGELOG.md](file:///.agents/AGENTS_CHANGELOG.md)
- Code comments and JSDoc.

## Step 2 — Dependency & Dead Code Analysis

Scan for:
- [ ] **Unused Code**: Variables, imports, or private functions that are never used.
- [ ] **Commented Blocks**: Remove blocks of code that have been commented out (logic should be in Git history, not in the code).
- [ ] **Debug Artifacts**: `console.log`, `printStacktrace`, or temporary debug variables.
- [ ] **Legacy Mocks**: Code that was used as a placeholder (stub) but should now be replaced by real logic or removed if redundant.
- [ ] **Duplicated Logic**: Patterns that are implemented better elsewhere in the project.

## Step 3 — Architectural & Security Alignment

Verify that the code follows:
- [GEMINI.md](file:///GEMINI.md) (Project rules, high precedence)
- Technology-specific rules in `.agents/rules/` (`javascript_good_practices.md`, etc.)
- [security.md](file:///security.md) (Security protocols)

## Step 4 — Refactoring Proposal

Present a detailed plan to the user:
1. List specific items of "junk" or "legacy" code identified.
2. Explain why they are considered junk (e.g., "unused import", "deprecated logic replaced by Service X").
3. Show a "Before vs After" preview if possible.

## Step 5 — Execution and Verification

// turbo
1. **Execute Cleanup**: Use `replace_file_content` or `multi_replace_file_content` to apply changes.
2. **Verification**: 
   - Run linter (if applicable).
   - Run existing unit tests for the modified component.
3. **Log changes**: Update [AGENTS_CHANGELOG.md](file:///.agents/AGENTS_CHANGELOG.md) documenting the cleanup.

---

## Rules

- 🔴 **Stop and Ask**: Always describe the cleanup plan and wait for explicit user approval before modifying files.
- **Scope Control**: Only touch files within the scope of the requested feature/file.
- **No functional changes**: The primary goal is cleanup; if functionality needs to change, it should be a separate task or clearly marked.
