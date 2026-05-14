# Task Plan: Refactor CLAUDE.md

**Goal**: Rewrite CLAUDE.md under 200 lines, eliminating all redundancies, adding the 3-tier UI reference chain, and promoting design-system.html to Tier 1.
**Starting state**: CLAUDE.md exists (~95 lines) with 3 categories of redundancy; design-system.html is not referenced; no UI reference workflow defined.
**Constraints**: Follow 8 principles from the article; ≤200 lines; 3-tier UI reference chain must be explicit.

---

## Step 1: Identify redundancies to cut

**STATUS**: [x]

**ACTION**:
Read current `CLAUDE.md` and list every line/section that falls into these redundancy categories:

1. **Architecture file tree is too detailed** — the full `src/` file listing (lines 27-40 approximately) violates principle #4 (pointer not library). Replace with 3-line directory summary.
2. **Coding Rules duplicate Design.md** — rules like `whileTap={{ scale: 0.96 }}`, animation parameters, and UI specifications already exist in `Design.md`. Remove duplicates; keep only rules NOT covered by Design.md.
3. **Working Style overlaps with Memory system** — items like "使用 /task-plan 技能规划非平凡任务", "回复用中文，代码注释用英文", "新功能在 feature 分支开发" are already stored in `feedback-workflow.md` memory. Remove duplicates from CLAUDE.md; keep only items NOT in memory.

Produce a written diff plan listing: what to delete, what to merge, what to keep as-is.

**GATE**:
The diff plan must explicitly list at least 5 specific items to cut or merge, with reason for each.

**NEXT**:
- GATE passes → proceed to Step 2
- GATE fails → re-read CLAUDE.md and memory files more carefully, expand analysis scope

---

## Step 2: Write refactored CLAUDE.md

**STATUS**: [x]

**ACTION**:
Rewrite `D:\claude-code-warp\Design\CLAUDE.md` with these sections (in this order):

### Section 1: Project Overview (≤10 lines)
- What: B2B 仓库管理移动端 Web APP
- Tech stack: React 19 + Vite 8 + Tailwind CSS 4 + Framer Motion 12 + Lucide React + html5-qrcode
- Optimization priority: 操作流畅度 > 交互反馈 > 视觉细节

### Section 2: Do NOT Introduce (≤10 lines)
- Keep the existing list of 7 forbidden technologies as-is.

### Section 3: Architecture (≤8 lines)
- Replace full file tree with concise directory summary:
  - `src/App.jsx` — 入口 (Splash → Auth → Shell)
  - `src/pages/` — Tab 页面
  - `src/components/` — Scanner, Records, BottomSheet, Forms, Details, Settings, Login, Splash
  - `src/data/mockData.js` — Mock 数据层
  - `src/index.css` — Tailwind @theme tokens
- No individual file listings.

### Section 4: UI Reference Chain (NEW, ≤15 lines)
This is the critical addition. Write as a decision tree:

```
When building or modifying any UI component:
1. Read Design.md for design specification (colors, typography, motion params, component rules)
2. Read design-system.html for runnable HTML/CSS reference implementations
3. If Design.md + design-system.html cover the needed component → build directly in React, following both sources
4. If neither covers it → read "Using Claude Code_ The Unreasonable Effectiveness of HTML.md"
5. Propose modifications to design-system.html (include: what to add, why, your design rationale)
6. Wait for user to review and approve the proposal
7. After approval: update design-system.html first, then build in React
```

### Section 5: Context Tiers (≤6 lines)
- Tier 1 (always load): CLAUDE.md, Design.md, design-system.html, src/index.css
- Tier 2 (on-demand): src/data/mockData.js, src/App.jsx, task_plan_*.md
- Tier 3 (ignore): dist/, node_modules/

### Section 6: Coding Rules (deduplicated, ≤12 lines)
Keep only rules NOT already in Design.md or memory:
- Named exports only (default for route components)
- Chinese UI text, English identifiers/comments
- Component ≤ 200 lines
- async/await, no Promise chains
- Full variable names, no abbreviations (except id/url/ctx)
- No console.log, no commented-out code
- Tailwind only for styling, no inline styles except dynamic values
- Mobile-first: 375px–428px width
- For all animation parameters, motion physics, gesture thresholds: follow Design.md exactly

Remove: `whileTap={{ scale: 0.96 }}` (in Design.md), drag thresholds (in Design.md), any motion param (in Design.md).

### Section 7: Branches (≤3 lines)
- `main` — stable
- `feature/*` — development

### Section 8: Key Invariants (≤8 lines)
- Auth in localStorage
- Data layer is mockData.js — no real API yet, structure for easy swap
- Scanner camera stays active during bottom sheet interaction

### What to REMOVE entirely:
- Working Style section — all items exist in memory system (feedback-workflow.md)
- Any animation parameter that appears in Design.md
- Any preference that appears in memory files

**GATE**:
1. Run `wc -l D:\claude-code-warp\Design\CLAUDE.md` (or count lines). Must be ≤ 200 lines.
2. Grep for `design-system.html` in CLAUDE.md. Must find at least 2 matches (Context Tiers + UI Reference Chain).
3. Grep for `whileTap` or `y > 150px` or `vy > 500px` in CLAUDE.md. Must find 0 matches (these belong in Design.md only).
4. Grep for `Working Style` or `Great question` in CLAUDE.md. Must find 0 matches.

**NEXT**:
- GATE passes → proceed to Step 3
- GATE fails (line count) → identify which section is too verbose and cut it
- GATE fails (missing design-system.html) → add missing reference
- GATE fails (duplicate motion params) → remove the duplicated lines
- GATE fails (Working Style remains) → delete that section entirely

---

## Step 3: Validate refactored CLAUDE.md against 8 principles

**STATUS**: [x] against the 8 principles from the article. For each principle, write a one-line pass/fail assessment:

1. Under 200 lines? → check line count
2. Do NOT introduce list exists? → verify section exists with ≥3 items
3. Every rule is actionable/verifiable in 5 seconds? → spot-check 3 random rules
4. Pointer not library? → verify no full file listings, no inlined specs
5. Local CLAUDE.md for sensitive modules? → note: not applicable yet, state this explicitly
6. Hook-driven? → note: not configured yet, state this explicitly
7. Memory system referenced? → verify MEMORY.md pointer exists or is not duplicated
8. Working style encoded? → verify NOT duplicated from memory (should be absent from CLAUDE.md)

**GATE**:
All 8 principles assessed, each with a clear pass/fail/defer status. Any "fail" must have a fix applied before this step passes.

**NEXT**:
- GATE passes → plan complete
- GATE fails → apply the fix to CLAUDE.md, then re-run this step's GATE
- If fix requires judgment call → escalate to user
