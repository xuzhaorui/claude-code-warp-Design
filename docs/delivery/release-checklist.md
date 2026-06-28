# Release Checklist — Warehouse App Flutter Shell v0.1.0

## 1. Git 状态检查

- [ ] `git status --short` 为空（或仅 allowed dirty: CLAUDE.md）
- [ ] `git status --branch --short` 确认分支正确

```bash
git status --short
git status --branch --short
```

## 2. Baseline Verify

- [ ] baseline 存在且无 drift

```bash
npm run physical:gate:verify
```

Expected: `PASS — no drift detected`

## 3. Physical Gate

- [ ] 全量门禁通过

```bash
npm run physical:gate
```

Expected: `Result: ALL PASS`
Expected checks: design:lint ✅, flutter analyze ✅, flutter test ✅, flutter build ✅, baseline ✅, git scoped ✅

## 4. Android APK Build

- [ ] Debug APK 构建成功

```bash
cd flutter_shell && flutter build apk --debug
```

Expected: `Built build\app\outputs\flutter-apk\app-debug.apk`

## 5. 真机 Smoke（小米 8 或等效设备）

- [ ] APK 安装到设备

```bash
cd flutter_shell && flutter install
```

- [ ] App 启动不崩溃
- [ ] 底部导航 3 个 tab 可切换
- [ ] 扫码按钮响应

## 6. Scanner Smoke

- [ ] ScannerPage 打开正常
- [ ] Camera 权限已授权
- [ ] 扫描二维码成功
- [ ] `onScanResult` 回调触发

## 7. Forms Smoke

- [ ] 出库表单打开
- [ ] 出库方法切换（外销/外借）
- [ ] 数量 Stepper 交互
- [ ] 归还表单打开
- [ ] 盘点表单打开
- [ ] 表单关闭

## 8. 回滚策略

- [ ] 当前 release commit hash 已记录：

```
当前 HEAD: da8874c
Branch: feature/warehouse-app
```

- [ ] 如果 APK 在真机崩溃，回滚到 `da8874c` 重新构建

```bash
git checkout da8874c
cd flutter_shell && flutter clean && flutter pub get && flutter build apk --debug
```

## 9. Tag 建议

```text
warehouse-app-flutter-shell-v0.1.0
```

本 checklist **不自动创建 tag**。创建前请确认：

- [ ] APK 已通过真机 smoke
- [ ] 关键 reviewer 已知晓
- [ ] CI 已配置（如适用）

```bash
git tag -a warehouse-app-flutter-shell-v0.1.0 -m "Flutter shell v0.1.0 — warehouse migration baseline"
```

## 10. Push 确认

- [ ] 当前领先 origin 40 commits
- [ ] 可以推送到 remote

```bash
git push origin feature/warehouse-app
```
