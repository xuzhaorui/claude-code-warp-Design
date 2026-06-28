# Physical Gate Runtime

## What

Machine-executable gate scripts that replace CLAUDE.md's manually described
physical gate protocol.  Each script produces a `physical-gate.report.json` for
machine consumption.

## Scripts

| Script | Command | Purpose |
|--------|---------|---------|
| `scripts/physical-gate.ps1` | `npm run physical:gate` | Run all 4 gates + git scoped status, produce report |
| `scripts/physical-gate.ps1 -DryRun` | `npm run physical:gate:dry` | Print commands without executing |
| `scripts/report-git-state.ps1` | `npm run physical:gate:report` | Print current git state (branch, commits, dirty files) |

## Checks Executed

1. `npm run design:lint` — Design.md lint
2. `flutter analyze` — Flutter static analysis
3. `flutter test` — Flutter test suite
4. `flutter build apk --debug` — Debug APK build
5. `git status --short` scoped to configured paths

## Configuration

`physical-gate.config.json`:

```json
{
  "allowedDirty": ["CLAUDE.md"],
  "scopedStatusPaths": ["CLAUDE.md", "package.json", ...],
  "checks": ["design:lint", "flutter analyze", "flutter test", "flutter build apk --debug"],
  "testCount": 284
}
```

## Report Output

`physical-gate.report.json` is generated **at runtime** after each `physical:gate` run.
It is **not tracked** by Git (ignored via `.gitignore`).
An example schema is at `physical-gate.report.example.json`.

```json
{
  "ok": true,
  "timestamp": "2026-06-28T...",
  "durationSeconds": 120.5,
  "branch": "feature/warehouse-app",
  "head": "abc123...",
  "checks": { ... },
  "allowedDirty": ["CLAUDE.md"],
  "unexpectedDirty": []
}
```

## Adding New Checks

1. Add the check command to `checks` in `physical-gate.config.json`
2. Add a `RunCheck` call in `scripts/physical-gate.ps1`
