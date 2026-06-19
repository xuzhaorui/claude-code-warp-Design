import 'package:flutter/material.dart';

import 'pages/web_shell_page.dart';

void main() {
  runApp(const WarehouseApp());
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '仓库管理',
      debugShowCheckedModeBanner: false,
      home: WebShellPage(),
    );
  }
}
