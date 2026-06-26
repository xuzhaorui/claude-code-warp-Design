import 'package:flutter/material.dart';

import 'design/app_theme.dart';
import 'pages/web_shell_page.dart';

void main() {
  runApp(const WarehouseApp());
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '仓库管理',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WebShellPage(),
    );
  }
}
