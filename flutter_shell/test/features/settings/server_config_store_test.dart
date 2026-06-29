import 'package:flutter_test/flutter_test.dart';

import 'package:wms_app/features/settings/server_config_store.dart';

void main() {
  group('ServerConfig model', () {
    test('normalizedBaseUrl removes trailing slash', () {
      final config = ServerConfig(name: 'Test', baseUrl: 'http://example.com/');
      expect(config.normalizedBaseUrl, 'http://example.com');
    });

    test('normalizedBaseUrl keeps URL without trailing slash', () {
      final config = ServerConfig(name: 'Test', baseUrl: 'http://example.com');
      expect(config.normalizedBaseUrl, 'http://example.com');
    });

    test('json roundtrip preserves all fields', () {
      final config = ServerConfig(name: '主服务器', baseUrl: 'http://192.168.1.100:8080');
      final json = config.toJson();
      final restored = ServerConfig.fromJson(json);
      expect(restored.name, '主服务器');
      expect(restored.baseUrl, 'http://192.168.1.100:8080');
      expect(restored.normalizedBaseUrl, 'http://192.168.1.100:8080');
    });

    test('equality based on name and normalizedBaseUrl', () {
      final a = ServerConfig(name: 'Srv', baseUrl: 'http://a.com/');
      final b = ServerConfig(name: 'Srv', baseUrl: 'http://a.com');
      expect(a, equals(b));
    });
  });

  group('InMemoryServerConfigStore', () {
    late InMemoryServerConfigStore store;

    setUp(() {
      store = InMemoryServerConfigStore();
    });

    test('starts empty', () async {
      final servers = await store.loadServers();
      expect(servers, isEmpty);
    });

    test('saveServers then loadServers returns saved configs', () async {
      await store.saveServers([
        ServerConfig(name: 'A', baseUrl: 'http://a.com'),
        ServerConfig(name: 'B', baseUrl: 'http://b.com'),
      ]);
      final servers = await store.loadServers();
      expect(servers.length, 2);
      expect(servers[0].name, 'A');
      expect(servers[1].name, 'B');
    });

    test('setActiveServer then loadActiveServer returns server', () async {
      await store.saveServers([
        ServerConfig(name: 'A', baseUrl: 'http://a.com'),
      ]);
      await store.setActiveServer('http://a.com');
      final active = await store.loadActiveServer();
      expect(active, isNotNull);
      expect(active!.name, 'A');
    });

    test('deleting active server clears active', () async {
      await store.saveServers([
        ServerConfig(name: 'A', baseUrl: 'http://a.com'),
      ]);
      await store.setActiveServer('http://a.com');
      await store.saveServers([]); // clear servers
      final active = await store.loadActiveServer();
      expect(active, isNull);
    });

    test('setting active with trailing slash normalizes', () async {
      await store.saveServers([
        ServerConfig(name: 'A', baseUrl: 'http://a.com'),
      ]);
      await store.setActiveServer('http://a.com/');
      final active = await store.loadActiveServer();
      expect(active, isNotNull);
      expect(active!.normalizedBaseUrl, 'http://a.com');
    });

    test('loadServers returns unmodifiable list', () async {
      await store.saveServers([
        ServerConfig(name: 'A', baseUrl: 'http://a.com'),
      ]);
      final servers = await store.loadServers();
      expect(() => servers.add(ServerConfig(name: 'B', baseUrl: 'http://b.com')), throwsA(anything));
    });
  });
}
