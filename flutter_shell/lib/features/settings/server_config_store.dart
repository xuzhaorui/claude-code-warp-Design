import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// ── ServerConfig model ──

/// A single server configuration entry.
class ServerConfig {
  const ServerConfig({
    required this.name,
    required this.baseUrl,
  });

  final String name;

  /// Server base URL without trailing slash.
  final String baseUrl;

  /// Returns [baseUrl] with trailing slash removed.
  String get normalizedBaseUrl => baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  Map<String, dynamic> toJson() => {'name': name, 'baseUrl': normalizedBaseUrl};

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
        name: json['name'] as String? ?? '',
        baseUrl: json['baseUrl'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerConfig && name == other.name && normalizedBaseUrl == other.normalizedBaseUrl;

  @override
  int get hashCode => Object.hash(name, normalizedBaseUrl);

  @override
  String toString() => 'ServerConfig(name: $name, baseUrl: $normalizedBaseUrl)';
}

// ── Store interface ──

/// Abstract storage for server configurations.
abstract interface class ServerConfigStore {
  Future<List<ServerConfig>> loadServers();
  Future<void> saveServers(List<ServerConfig> servers);
  Future<ServerConfig?> loadActiveServer();
  Future<void> setActiveServer(String baseUrl);
}

// ── In-memory store (testable, no platform dependency) ──

/// In-memory implementation of [ServerConfigStore].  No platform plugins needed.
class InMemoryServerConfigStore implements ServerConfigStore {
  List<ServerConfig> _servers = [];
  String? _activeBaseUrl;

  @override
  Future<List<ServerConfig>> loadServers() async => List.unmodifiable(_servers);

  @override
  Future<void> saveServers(List<ServerConfig> servers) async {
    _servers = List.from(servers);
    // If active server was removed, clear active.
    if (_activeBaseUrl != null && !_servers.any((s) => s.normalizedBaseUrl == _activeBaseUrl)) {
      _activeBaseUrl = null;
    }
  }

  @override
  Future<ServerConfig?> loadActiveServer() async {
    if (_activeBaseUrl == null) return null;
    return _servers.cast<ServerConfig?>().firstWhere(
          (s) => s!.normalizedBaseUrl == _activeBaseUrl,
          orElse: () => null,
        );
  }

  @override
  Future<void> setActiveServer(String baseUrl) async {
    _activeBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  }
}

// ── Persistent store (SharedPreferences) ──

/// SharedPreferences-backed implementation of [ServerConfigStore].
class PersistentServerConfigStore implements ServerConfigStore {
  static const _kConfigs = 'wms.serverConfigs';
  static const _kActive = 'wms.activeServerBaseUrl';

  // ignore: prefer_initializing_formals — _prefs is mutable, not final
  PersistentServerConfigStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async => _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<List<ServerConfig>> loadServers() async {
    final prefs = await _store;
    final raw = prefs.getString(_kConfigs);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => ServerConfig.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveServers(List<ServerConfig> servers) async {
    final prefs = await _store;
    final raw = jsonEncode(servers.map((s) => s.toJson()).toList());
    await prefs.setString(_kConfigs, raw);
  }

  @override
  Future<ServerConfig?> loadActiveServer() async {
    final prefs = await _store;
    final baseUrl = prefs.getString(_kActive);
    if (baseUrl == null || baseUrl.isEmpty) return null;
    final servers = await loadServers();
    return servers.cast<ServerConfig?>().firstWhere(
          (s) => s!.normalizedBaseUrl == baseUrl,
          orElse: () => null,
        );
  }

  @override
  Future<void> setActiveServer(String baseUrl) async {
    final prefs = await _store;
    final normalized = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    await prefs.setString(_kActive, normalized);
  }
}
