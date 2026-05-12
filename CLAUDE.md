# Warehouse Management App (仓库管理)

## Project Overview
B2B 仓库管理移动端 Web APP，面向仓库操作员的出库/归还/盘点流程。
React 19 (JSX) + Vite 8 + Tailwind CSS 4 + Framer Motion 12 + Lucide React + html5-qrcode
优化优先级：操作流畅度 > 交互反馈 > 视觉细节
验证标准：操作员单手完成出库/归还全流程，无卡顿，无歧义

## Do NOT Introduce Unless Explicitly Requested
- TypeScript — project is plain JSX
- CSS-in-JS (styled-components, emotion, CSS modules) — use Tailwind only
- State management (Redux, MobX, Zustand) — use React useState/useContext
- UI libraries (MUI, Ant Design, Chakra) — all components are custom
- Other CSS frameworks (Bootstrap, Bulma)
- SSR frameworks (Next.js, Remix) — this is a SPA
- Routing libraries besides react-router-dom

## UI Reference Chain (UI 构建必读)
When building or modifying any UI component, follow this decision tree:

1. **Read Design.md** — design specification: colors, typography, corner radius, motion physics, component rules
2. **Read design-system.html** — runnable HTML/CSS reference implementations of Design.md components
3. If Design.md + design-system.html cover the needed component → build directly in React, following both sources
4. If neither covers it → read `Using Claude Code_ The Unreasonable Effectiveness of HTML.md`
5. **Propose** modifications to design-system.html (include: what to add, why, design rationale)
6. **Wait** for user to review and approve the proposal
7. After approval: update design-system.html first, then build in React

All animation/motion parameters must follow Design.md exactly — never invent values.

## UI Task Planning (UI 任务规划)
When planning UI building, refactoring, or visual modification tasks, the task-plan skill MUST produce an HTML plan file instead of a markdown plan:

1. **Output**: `plans/{name}.html` — a single self-contained HTML file (inline CSS/JS, no external deps except CDN fonts)
2. **Component Mapping Table**: Explicit mapping of `design-system.html §X component → src/components/Y.jsx` with change type (New/Modify/Delete)
3. **Page Composition Views**: Rendered HTML+CSS mockups showing multiple components composed into full pages, with toggle between "current" and "planned" states
4. **Interactive State Diagram**: HTML+CSS+JS flowchart showing state transitions (idle → focused → error → loading), clickable to reveal component variations, connected with CSS arrows
5. **Execution Steps**: ACTION/GATE/NEXT format embedded in styled HTML cards, with visual GATE checks (screenshot/mocking comparisons where applicable)
6. **Design tokens**: Use same CSS variables as design-system.html (--bumble-yellow, --action-black, etc.)

7. **Mapping Completeness (映射完整性)**: Before writing §1, read `design-system.html` to identify the exact `§X` section number for each component. Every component that will be Modified or Created MUST appear in the table with a verified section reference. Section numbers must not be inferred from memory — they must be read from the file.
8. **Composition Coverage (组合覆盖)**: §2 must include one composition view per app tab/page that contains a modified component. Composition must render at 375px mobile width with phone frame border, using design-system.html CSS tokens.
9. **Interaction Diagram Type (交互图类型)**: §3 uses one of two diagram types — choose based on task nature: (a) **State Machine**: for component state transitions (idle → focused → error → loading → disabled); (b) **Execution Flowchart**: for sequential workflows with branch points (Step → Gate? → continue or rollback). Label the chosen type at the top of the diagram.

Layout structure is determined by the task-plan skill based on task complexity. Non-UI tasks continue to use standard `.md` plan format.

## Architecture
- `src/App.jsx` — Splash → Auth → AppShell entry point
- `src/pages/` — Tab pages (CheckoutTab, ReturnTab, InventoryTab, AppShell)
- `src/components/` — Scanner, Records, BottomSheet, Forms, Details, Settings, Login, Splash
- `src/data/mockData.js` — Mock data layer + CRUD functions (swap target for real API)
- `src/index.css` — Tailwind `@theme` tokens (brand-yellow, action-black, etc.)

## Context Tiers
- **Tier 1 (always load):** CLAUDE.md, Design.md, design-system.html, src/index.css
- **Tier 2 (on-demand):** src/data/mockData.js, src/App.jsx, task_plan_*.md
- **Tier 3 (ignore unless asked):** dist/, node_modules/

## Coding Discipline (编码纪律)
- **Git 是后悔药**：每次变更需当前分支本地提交
- **踩坑记录**：`踩坑记录.txt` 记录每次遇到的问题和反脆弱措施，遇到问题时先阅读

## Coding Rules
- Named exports only (default export for route-level components)
- Chinese UI text, English identifiers and comments
- Component file ≤ 200 lines (split if exceeded)
- async/await, no Promise chains
- Full variable names, no abbreviations (except id/url/ctx)
- No console.log, no commented-out code blocks
- Tailwind utility classes exclusively — no inline styles except dynamic values
- Framer Motion for all animations — no CSS transitions except keyframes in index.css
- Mobile-first: 375px–428px width
- All motion/gesture/animation params: follow Design.md, not this file

## Branches
- `main` — stable
- `feature/*` — feature development

## Key Invariants
- Auth state in localStorage (`currentUser`, `servers`, `activeServer`)
- Data layer is mockData.js — no real API yet, structure for easy swap
- Scanner camera stays active during bottom sheet interaction
- API 只走相对路径（Vite proxy 转发）
