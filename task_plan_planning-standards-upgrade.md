# Task Plan: Planning Standards Upgrade

**Goal**: CLAUDE.md 的 UI Task Planning section 增加 3 条约束规则；skill.md Phase 2B 的 §1 和 §3 加强为可验证的强制要求，使未来生成的 HTML 计划文件在执行前必须读 design-system.html 填写真实映射、必须覆盖所有涉及 tab 的组合视图、§3 允许状态机或流程图两种形式。

**Starting state**:
- `CLAUDE.md` UI Task Planning 有 6 条规则，无映射完整性要求，无组合视图覆盖要求，无交互图类型说明
- `C:\Users\Lenovo\.claude\skills\task-plan\skill.md` Phase 2B 有 §1–§4，但 §1 未要求读取 design-system.html，§3 只提 state machine 不提 flowchart

**Constraints**:
- 不修改 design-system.html、Design.md、src/ 任何文件
- 非 UI 任务继续用 .md 格式，Phase 2A 不变
- 新规则必须与现有规则无冲突

---

## Step 1: 在 CLAUDE.md UI Task Planning 新增规则 7、8、9

**STATUS**: [x]

**ACTION**:
Edit `D:\claude-code-warp\Design\CLAUDE.md`.

定位到此行：
```
Layout structure is determined by the task-plan skill based on task complexity. Non-UI tasks continue to use standard `.md` plan format.
```

在这一行**之前**插入以下三条新规则（编号紧接现有第 6 条）：

```
7. **Mapping Completeness (映射完整性)**: Before writing §1, read `design-system.html` to identify the exact `§X` section number for each component. Every component that will be Modified or Created MUST appear in the table with a verified section reference. Section numbers must not be inferred from memory — they must be read from the file.
8. **Composition Coverage (组合覆盖)**: §2 must include one composition view per app tab/page that contains a modified component. Composition must render at 375px mobile width with phone frame border, using design-system.html CSS tokens.
9. **Interaction Diagram Type (交互图类型)**: §3 uses one of two diagram types — choose based on task nature: (a) **State Machine**: for component state transitions (idle → focused → error → loading → disabled); (b) **Execution Flowchart**: for sequential workflows with branch points (Step → Gate? → continue or rollback). Label the chosen type at the top of the diagram.
```

**GATE**:
Run: `Select-String -Path "D:\claude-code-warp\Design\CLAUDE.md" -Pattern "Mapping Completeness|Composition Coverage|Interaction Diagram Type"`
Expected: 3 matches, each containing the respective rule name.

**NEXT**:
- GATE passes → proceed to Step 2
- GATE fails → re-read CLAUDE.md lines 31–42, verify insertion was placed correctly before the "Layout structure" line, fix and re-run GATE

---

## Step 2: 加强 skill.md Phase 2B §1（读文件后填表）

**STATUS**: [x]

**ACTION**:
Edit `C:\Users\Lenovo\.claude\skills\task-plan\skill.md`.

定位 §1 Component Mapping Table 的现有内容（从 `### §1 Component Mapping Table` 到表格结束）：

```
### §1 Component Mapping Table

A table with columns:

| design-system.html Section | Component Name | Target File | Change Type |
|---|---|---|---|
| §2 Buttons | PrimaryButton | src/components/Shared/PrimaryButton.jsx | New |
| §7 Floating Input | BumbleInput | src/components/Forms/BumbleInput.jsx | Modify |

Change Type is one of: **New** (create from scratch), **Modify** (edit existing), **Delete** (remove file).
```

替换为：

```
### §1 Component Mapping Table

**Before populating this table**: read `design-system.html` to identify the exact `§X` section number for each component. Read each `src/components/*.jsx` target file to confirm the path exists. A row may NOT contain a section number that was not verified by reading the file — do not infer from memory.

A table with columns:

| design-system.html Section | Component Name | Target File | Change Type |
|---|---|---|---|
| §2 Buttons | PrimaryButton | src/components/Shared/PrimaryButton.jsx | New |
| §7 Floating Input | BumbleInput | src/components/Forms/BumbleInput.jsx | Modify |

Change Type is one of: **New** (create from scratch), **Modify** (edit existing), **Delete** (remove file).

**Completeness rule**: Every component that will be Modified or Created by any step in §4 MUST appear in this table. If a component cannot be mapped to a design-system.html section, stop and read design-system.html before continuing.
```

**GATE**:
Run: `Select-String -Path "C:\Users\Lenovo\.claude\skills\task-plan\skill.md" -Pattern "Before populating this table|Completeness rule"`
Expected: 2 matches.

**NEXT**:
- GATE passes → proceed to Step 3
- GATE fails → re-read skill.md lines 153–163, verify the §1 block was replaced correctly, fix and re-run GATE

---

## Step 3: 更新 skill.md Phase 2B §3（允许状态机或流程图）

**STATUS**: [x]

**ACTION**:
Edit `C:\Users\Lenovo\.claude\skills\task-plan\skill.md`.

定位 §3 Interactive State Diagram 的现有内容（从 `### §3 Interactive State Diagram` 到该 section 结尾）：

```
### §3 Interactive State Diagram

An HTML+CSS+JS interactive flowchart showing component state transitions. Requirements:
- Each state is a node showing the component rendered in that state (e.g., idle, focused, error, loading, disabled)
- Nodes are connected with CSS-drawn arrows showing transitions
- Clicking a state node reveals the component in that state (visual preview)
- Label transitions with trigger events (e.g., "onFocus", "onError", "onSubmit")
- Use CSS transitions/animations to show state changes, not static images
```

替换为：

```
### §3 Interactive State Diagram

An HTML+CSS+JS interactive diagram showing component/process behavior. Choose ONE type based on task nature — label the chosen type at the top of the diagram:

**Type A — State Machine** (use when the task modifies how a component behaves across states):
- Each node shows the component rendered in a specific state (idle, focused, error, loading, disabled)
- Nodes connected with CSS-drawn arrows labeled with trigger events (onFocus, onError, onSubmit)
- Clicking a node reveals the component visual in that state
- Use CSS transitions/animations to show state changes, not static images

**Type B — Execution Flowchart** (use when the task involves multi-step workflows or conditional logic):
- Each node represents a step or decision point (Step 1, Gate: passes?, Step 2 or Rollback)
- Diamond nodes for decisions, rectangle nodes for actions
- Arrows labeled with conditions (pass / fail / retry)
- Clicking a node reveals the ACTION or GATE check for that step
```

**GATE**:
Run: `Select-String -Path "C:\Users\Lenovo\.claude\skills\task-plan\skill.md" -Pattern "Type A — State Machine|Type B — Execution Flowchart"`
Expected: 2 matches.

**NEXT**:
- GATE passes → proceed to Step 4
- GATE fails → re-read skill.md lines 174–180, verify the §3 block was replaced correctly, fix and re-run GATE

---

## Step 4: End-to-end verification

**STATUS**: [x]

**ACTION**:
1. Read `D:\claude-code-warp\Design\CLAUDE.md` lines 31–55 (UI Task Planning section)
2. Read `C:\Users\Lenovo\.claude\skills\task-plan\skill.md` lines 119–200 (Phase 2B)

Verify:
- CLAUDE.md rules 7, 8, 9 are present and correctly positioned before the "Layout structure" line
- skill.md §1 includes "Before populating this table" instruction and "Completeness rule"
- skill.md §3 includes both "Type A — State Machine" and "Type B — Execution Flowchart"
- No contradictions between CLAUDE.md rules and skill Phase 2B requirements

**GATE**:
Run all three in sequence:
1. `Select-String -Path "D:\claude-code-warp\Design\CLAUDE.md" -Pattern "Mapping Completeness|Composition Coverage|Interaction Diagram Type"` — Expected: 3 matches
2. `Select-String -Path "C:\Users\Lenovo\.claude\skills\task-plan\skill.md" -Pattern "Before populating this table|Completeness rule"` — Expected: 2 matches
3. `Select-String -Path "C:\Users\Lenovo\.claude\skills\task-plan\skill.md" -Pattern "Type A — State Machine|Type B — Execution Flowchart"` — Expected: 2 matches

All 3 commands must return expected match counts.

**NEXT**:
- All 3 GATE commands pass → plan complete
- Any GATE fails → identify which file and which rule is missing, return to the corresponding step and fix
