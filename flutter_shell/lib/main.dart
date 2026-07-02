import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  runApp(const WarehouseApp());
}

/// Warehouse management app — entry point with login + API wiring.
///
/// Persists the active server, the session cookie (via
/// [HttpWarehouseApiClient]) and a login flag so a logged-in user returns
/// straight to the shell after an app restart (task-042).
class WarehouseApp extends StatefulWidget {
  const WarehouseApp({super.key});

  @override
  State<WarehouseApp> createState() => _WarehouseAppState();
}

class _WarehouseAppState extends State<WarehouseApp> {
  static const _kLoggedIn = 'wms.loggedIn';
  static const _kSessionUsername = 'wms.sessionUsername';

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final ServerConfigStore _configStore = PersistentServerConfigStore();
  WarehouseApiClient? _apiClient;
  AuthSession? _session;
  String? _activeServerName;
  String? _activeServerUrl;
  bool _initialized = false;
  bool _needsServerConfig = true;

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
        _activeServerUrl = active?.normalizedBaseUrl;
        _initialized = true;
      });
    }

    // Restore a previously persisted login so the user skips the login page
    // after an app restart.  The session cookie itself is restored inside
    // HttpWarehouseApiClient; here we only restore the UI-level flag.
    if (_apiClient != null && !await _wasLoggedIn()) {
      return; // no prior login — stay on login page (handled in build)
    }
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_kSessionUsername);
    if (username != null && mounted) {
      setState(() {
        _session = AuthSession(username: username, loggedAt: DateTime.now());
      });
    }
  }

  Future<bool> _wasLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedIn) ?? false;
  }

  void _onServerConfigured() async {
    final active = await _configStore.loadActiveServer();
    if (!mounted) return;
    setState(() {
      _apiClient = HttpWarehouseApiClient(configStore: _configStore);
      _needsServerConfig = false;
      _activeServerName = active?.name;
      _activeServerUrl = active?.normalizedBaseUrl;
    });
  }

  void _onLoggedIn(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kSessionUsername, session.displayName);
    if (!mounted) return;
    setState(() => _session = session);
  }

  Future<void> _clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, false);
    await prefs.remove(_kSessionUsername);
    final client = _apiClient;
    if (client is HttpWarehouseApiClient) {
      await client.clearPersistedSession();
    }
    if (!mounted) return;
    setState(() => _session = null);
  }

  Future<void> _recreateClientForActiveServer() async {
    final active = await _configStore.loadActiveServer();
    if (!mounted) return;
    setState(() {
      _apiClient = active == null
          ? null
          : HttpWarehouseApiClient(configStore: _configStore);
      _needsServerConfig = active == null;
      _activeServerName = active?.name;
      _activeServerUrl = active?.normalizedBaseUrl;
    });
  }

  Future<void> _onLogout() async {
    // Best-effort server logout; clear local state regardless of result.
    try {
      await _apiClient?.logout();
    } catch (_) {
      // ignore — local clear is authoritative for the UI
    }
    await _clearLocalSession();
    if (!mounted) return;
    setState(() => _apiClient = null);
    // Recreate the API client (without a restored session) so the next login
    // starts clean.  Active server stays configured.
    await _recreateClientForActiveServer();
  }

  Future<void> _onSessionExpired() async {
    await _clearLocalSession();
    await _recreateClientForActiveServer();
  }

  Future<void> _onServerChanged() async {
    await _clearLocalSession();
    await _recreateClientForActiveServer();
  }

  void _openServerConfigFromLogin() async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppTheme.light.scaffoldBackgroundColor,
          body: SafeArea(
            child: ServerConfigPage(
              store: _configStore,
              onServerChanged: _onServerChanged,
            ),
          ),
        ),
      ),
    );
    await _onServerChanged();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: '仓库管理',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        activeServerName: _activeServerName,
        activeServerUrl: _activeServerUrl,
        onChangeServer: _openServerConfigFromLogin,
      );
    }

    return WarehouseShellScannerEntry(
      apiClient: _apiClient,
      activeUsername: _activeServerName ?? '未知',
      onLogout: _onLogout,
      onSessionExpired: _onSessionExpired,
      onServerChanged: _onServerChanged,
    );
  }
}
