import 'package:flutter/material.dart';

import 'design/app_theme.dart';
import 'features/api/http_warehouse_api_client.dart';
import 'features/api/warehouse_api_client.dart';
import 'features/api/warehouse_api_models.dart';
import 'features/auth/login_page.dart';
import 'features/settings/server_config_page.dart';
import 'features/settings/server_config_store.dart';
import 'features/warehouse_shell/warehouse_shell_scanner_entry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(WarehouseApp());
}

/// Warehouse management app — entry point with login + API wiring.
class WarehouseApp extends StatefulWidget {
  const WarehouseApp({super.key});

  @override
  State<WarehouseApp> createState() => _WarehouseAppState();
}

class _WarehouseAppState extends State<WarehouseApp> {
  final ServerConfigStore _configStore = PersistentServerConfigStore();
  WarehouseApiClient? _apiClient;
  AuthSession? _session;
  bool _initialized = false;
  bool _needsServerConfig = true;
  String? _activeServerName;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final active = await _configStore.loadActiveServer();
    if (active != null) {
      _apiClient = HttpWarehouseApiClient(configStore: _configStore);
    }
    if (mounted) {
      setState(() {
        _needsServerConfig = active == null;
        _activeServerName = active?.name;
        _initialized = true;
      });
    }
  }

  void _onServerConfigured() async {
    final active = await _configStore.loadActiveServer();
    if (!mounted) return;
    setState(() {
      _apiClient = HttpWarehouseApiClient(configStore: _configStore);
      _needsServerConfig = false;
      _activeServerName = active?.name;
    });
  }

  void _onLoggedIn(AuthSession session) {
    setState(() => _session = session);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '仓库管理',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsServerConfig) {
      return Scaffold(
        backgroundColor: AppTheme.light.scaffoldBackgroundColor,
        body: ServerConfigPage(
          store: _configStore,
          onConfigured: _onServerConfigured,
        ),
      );
    }

    if (_session == null) {
      return LoginPage(
        apiClient: _apiClient!,
        onLoggedIn: _onLoggedIn,
      );
    }

    return WarehouseShellScannerEntry(
      apiClient: _apiClient,
      activeServerName: _activeServerName,
    );
  }
}
