# Task Plan: UI Planning Upgrade

**Goal**: Update CLAUDE.md and task-plan skill to produce HTML-format plan files for UI development tasks, containing component mapping, page composition views, interactive state diagrams, and ACTION/GATE/NEXT execution steps.

**Starting state**: CLAUDE.md has UI Reference Chain but no UI planning rules. task-plan skill only produces .md format plans with no HTML mode.

**Constraints**:
- Do not modify design-system.html, Design.md, or any project source code
- Plan files go in `plans/` directory as `plans/{name}.html`
- Preserve ACTION/GATE/NEXT format within HTML plans
- Keep existing .md plan mode for non-UI tasks

---

## Step 1: Add UI Planning rules to CLAUDE.md

**STATUS**: [x]

**ACTION**:
Add a new section "UI Task Planning" to `D:\claude-code-warp\Design\CLAUDE.md` after the existing "UI Reference Chain" section, containing these rules:

1. UI refactoring/building tasks MUST produce an HTML plan file in `plans/{name}.html`
2. The HTML plan file MUST contain four sections:
   - **Component Mapping Table**: Explicit mapping of `design-system.html §X component → src/components/Y.jsx`
   - **Page Composition Views**: Rendered HTML+CSS mockups showing multiple components composed into full pages
   - **Interactive State Diagram**: HTML+CSS+JS flowchart showing state transitions with clickable states that reveal component variations
   - **Execution Steps**: ACTION/GATE/NEXT format embedded in HTML, with visual GATE checks (screenshot comparisons where applicable)
3. The HTML plan file MUST be self-contained (inline CSS/JS, no external dependencies except CDN fonts)
4. The HTML plan file MUST use design tokens from Design.md (same CSS variables as design-system.html)
5. Layout is determined by the task-plan skill based on task complexity

**GATE**:
Read `CLAUDE.md` and grep for "UI Task Planning". Expected: section exists with all 5 rules listed above.

**NEXT**:
- GATE passes → proceed to Step 2
- GATE fails → re-read CLAUDE.md, verify the section was appended correctly, fix and re-check

---

## Step 2: Update task-plan skill to support HTML plan mode

**STATUS**: [x]

**ACTION**:
Edit `C:\Users\Lenovo\.claude\skills\task-plan\skill.md` to add a new "Phase 2B: HTML Plan Generation (UI Tasks)" section between Phase 2 and Phase 3, with these rules:

1. **Trigger condition**: When the task involves building, modifying, or refactoring UI components in a web/frontend project, use HTML plan mode instead of .md plan mode
2. **Detection**: Ask the user "Is this a UI/front-end task?" if it's ambiguous. If the user says yes, or the task clearly involves components/pages/visual changes, use HTML mode
3. **Output file**: `plans/{name}.html` instead of `task_plan_{name}.md`
4. **Required HTML structure**:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Plan: {task name}</title>
  <style>
    /* Inline styles using design tokens from Design.md */
    /* Sidebar navigation + main content area */
  </style>
</head>
<body>
  <!-- §1 Component Mapping Table -->
  <!-- §2 Page Composition Views (rendered mockups) -->
  <!-- §3 Interactive State Diagram (clickable flowchart) -->
  <!-- §4 Execution Steps (ACTION/GATE/NEXT with visual gates) -->
</body>
</html>
```

5. **§1 Component Mapping Table format**:

| design-system.html Section | Component Name | Target File | Change Type |
|---|---|---|---|
| §2 Buttons | PrimaryButton | src/components/Shared/PrimaryButton.jsx | New |
| §7 Floating Input | BumbleInput | src/components/Forms/BumbleInput.jsx | Modify |

6. **§2 Page Composition Views**: Each view is a `<div>` rendered with the same CSS tokens as design-system.html, showing the expected visual output. Include a `<select>` or tab to switch between "current" and "planned" states.

7. **§3 Interactive State Diagram**: Use HTML+CSS+JS to build a clickable state machine. Each state node shows the component in that state (e.g., "idle", "focused", "error", "loading"). Clicking transitions shows the animation/visual change. States are connected with CSS-drawn arrows.

8. **§4 Execution Steps**: Embed the standard ACTION/GATE/NEXT format in styled HTML cards. Each step card has a STATUS checkbox. GATE checks include visual comparison where applicable (e.g., "screenshot matches the §2 mockup above").

9. **Keep existing Phase 2**: Non-UI tasks continue to use the original .md plan format. Add a branch point at the start of Phase 2 that routes to 2A (markdown) or 2B (HTML).

Also update Phase 3 to handle HTML plan execution:
- The execution handoff block should reference `plans/{name}.html` when it's an HTML plan
- Add a note that HTML plan steps may include visual GATE checks that require browser comparison

**GATE**:
Read the skill.md file and verify:
1. A "Phase 2B" section exists
2. It references "plans/{name}.html"
3. It contains all 4 required sections (mapping, composition, state diagram, execution steps)
4. The existing Phase 2 is preserved and marked for non-UI tasks
5. Phase 3 mentions HTML plan execution

**NEXT**:
- GATE passes → proceed to Step 3
- GATE fails → re-read skill.md, identify missing sections, add them and re-check

---

## Step 3: Verify plans/ directory and create placeholder

**STATUS**: [x]

**ACTION**:
1. Verify `D:\claude-code-warp\Design\plans\` directory exists (created in preparation)
2. Add a `.gitkeep` file to `plans/` so the directory is tracked by git
3. Read the updated CLAUDE.md to confirm the UI Task Planning section is correctly positioned

**GATE**:
1. `ls plans/` shows `.gitkeep` exists
2. Reading CLAUDE.md shows "UI Task Planning" section after "UI Reference Chain" section

**NEXT**:
- GATE passes → proceed to Step 4
- GATE fails → create missing files/directories and re-check

---

## Step 4: End-to-end validation

**STATUS**: [x]

**ACTION**:
1. Read the final CLAUDE.md and verify the new rules are consistent with existing "UI Reference Chain" and "Coding Rules" sections (no contradictions)
2. Read the final skill.md and verify Phase 2A (markdown) and Phase 2B (HTML) are clearly branched and Phase 3 handles both outputs
3. Confirm plans/ directory structure is ready

**GATE**:
1. CLAUDE.md has no contradictions between "UI Reference Chain" and new "UI Task Planning" section
2. skill.md has clear branching: Phase 2 → 2A (non-UI, .md) or 2B (UI, .html)
3. plans/ directory exists with .gitkeep
4. All checks pass with no issues found

**NEXT**:
- GATE passes → plan complete
- GATE fails → fix identified issues in the specific file, re-run this GATE check
