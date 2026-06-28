import 'package:flutter/material.dart';

import 'design/app_theme.dart';
import 'features/warehouse_shell/warehouse_shell_scanner_entry.dart';

void main() {
  runApp(const WarehouseApp());
}

/// Warehouse management app — native Flutter shell.
///
/// Entry point is [WarehouseShellScannerEntry], which wires:
/// - [WarehouseShellFormWiring] (three business form tabs)
/// - [ScannerPage] with [RealMobileScannerAdapter] (production camera scanning)
///
/// Legacy [WebShellPage] is no longer the default home — the app no longer
/// loads http://localhost via WebView on startup.
class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '仓库管理',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WarehouseShellScannerEntry(),
    );
  }
}
