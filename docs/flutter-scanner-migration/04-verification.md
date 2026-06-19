# 04. Flutter 工业扫码验收与回滚

## 1. 验收原则

本迁移是否成功，不以“能打开相机”为标准，而以“工业现场扫码效率”作为标准。

必须用真实 Android 手机、真实仓库标签、真实光线环境测试。

## 2. 功能验收

| 编号 | 场景 | 标准 |
|---|---|---|
| F-01 | APK 启动 | APP 能正常打开 React 仓库页面 |
| F-02 | 出库扫码 | 点击出库扫码后进入 Flutter ScannerPage |
| F-03 | 归还扫码 | 点击归还扫码后进入 Flutter ScannerPage |
| F-04 | 盘点扫码 | 点击盘点扫码后进入 Flutter ScannerPage |
| F-05 | 扫码成功 | 扫到后自动返回 Web 页面并打开原业务表单 |
| F-06 | 取消扫码 | 返回后不触发业务查询 |
| F-07 | 无权限 | 明确提示摄像头权限问题 |
| F-08 | 浏览器访问 | 仍可使用原 Web ScannerOverlay fallback |
| F-09 | 断网 | 明确提示业务查询失败，不误判为扫码失败 |
| F-10 | 重复扫码 | 同一次识别只触发一次业务处理 |

## 3. 工业扫码验收

准备真实标签：

```text
20 张 Code128 条码
10 张二维码
5 张轻微磨损标签
5 张塑封/反光标签
5 张小尺寸标签
```

测试环境：

```text
正常仓库光线
弱光
反光
手持轻微抖动
距离 10cm / 20cm / 40cm
```

通过标准：

| 指标 | 标准 |
|---|---:|
| 首次识别成功率 | >= 95% |
| 平均识别耗时 | <= 1 秒 |
| 单次最长可接受耗时 | <= 3 秒 |
| 连续扫码稳定性 | 连续 50 次无卡死 |
| 重复触发 | 0 次 |
| 错码 | 0 次 |

## 4. 对比验收

必须对比三种方案：

```text
旧 Web html5-qrcode
优化后的 Web html5-qrcode
Flutter mobile_scanner
```

记录格式：

| 标签编号 | 码制 | Web旧版耗时 | Web新版耗时 | Flutter耗时 | 是否成功 | 备注 |
|---|---|---:|---:|---:|---|---|

如果 Flutter 没有明显优于 Web，则不能进入发布。

## 5. 性能验收

| 项 | 标准 |
|---|---|
| APP 冷启动 | <= 3 秒 |
| WebView 首屏 | <= 3 秒 |
| 打开扫码页 | <= 1 秒 |
| 扫码页退出 | <= 500ms |
| 扫码 50 次 | 无明显发热、无崩溃 |

## 6. 构建验收

必须通过：

```bash
npm run build
cd flutter_shell
flutter pub get
flutter analyze
flutter build apk --debug
flutter build apk --release
```

允许警告：

```text
Flutter doctor 提示 Android Studio 未安装
```

不允许：

```text
Android toolchain 缺失
SDK license 未接受
真机无法识别
APK 构建失败
```

## 7. 失败判定

出现以下任一情况，判定本阶段失败：

1. APK 内仍调用 Web 摄像头扫码作为主路径。
2. Flutter ScannerPage 无法稳定打开相机。
3. 扫码成功后无法回传 Web 页面。
4. 三个业务入口只有一个可用。
5. 连续扫码出现重复提交。
6. 工业标签首次识别成功率低于 95%。
7. 无法通过命令行构建 APK。
8. 需要 Android Studio 才能完成构建或运行。

## 8. 回滚方案

### 8.1 代码回滚

```bash
git reset --hard <snapshot_commit>
```

### 8.2 功能回滚

保留 Flutter 壳，但临时关闭原生扫码：

```text
Web 页面强制走 ScannerOverlay fallback
```

### 8.3 发布回滚

如果 APK 已发给用户，回滚方式：

```text
发布上一版 APK
版本号递增
通知用户覆盖安装
```

## 9. 现场测试记录模板

```text
测试日期：
测试人员：
手机型号：
Android 版本：
APP 版本：
仓库环境：正常光 / 弱光 / 反光

扫码样本：
- Code128：__ 张
- QR：__ 张
- 磨损：__ 张
- 反光：__ 张

结果：
- 首次成功率：__%
- 平均耗时：__ 秒
- 最长耗时：__ 秒
- 错码次数：__
- 重复触发次数：__
- 崩溃次数：__

结论：通过 / 不通过
问题：
下一步：
```
