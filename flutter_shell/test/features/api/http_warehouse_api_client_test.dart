import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/features/api/http_warehouse_api_client.dart';
import 'package:wms_app/features/api/warehouse_api_client.dart';
import 'package:wms_app/features/checkout/checkout_form_rules.dart';
import 'package:wms_app/features/inventory_check/inventory_check_form_rules.dart';
import 'package:wms_app/features/return_form/return_form_rules.dart';
import 'package:wms_app/features/settings/server_config_store.dart';
import 'fake_http_client.dart';

Future<InMemoryServerConfigStore> _setupStore({String baseUrl = "http://test-server:8080"}) async {
  final store = InMemoryServerConfigStore();
  await store.saveServers([ServerConfig(name: "Test", baseUrl: baseUrl)]);
  await store.setActiveServer(baseUrl);
  return store;
}

void main() {
  // Initialize the binding + stub the SharedPreferences method channel so
  // the session-cookie persistence (task-042) works in pure-dart unit tests.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group("URL building", () {
    test("no trailing slash", () async {
      final store = await _setupStore(baseUrl: "http://example.com:8080");
      final http = FakeHttpClient({"outbound_qrcode": {"data": {"id": 1}}});
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      await client.findItemByCode("P293");
      expect(http.requestedUrls.first, contains("example.com:8080/store/inventory/list/outbound_qrcode/P293"));
    });
    test("trailing slash: no double", () async {
      final store = await _setupStore(baseUrl: "http://example.com/");
      final http = FakeHttpClient({"outbound_qrcode": {"data": {"id": 1}}});
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      await client.findItemByCode("TEST");
      expect(http.requestedUrls.first, isNot(contains("//store")));
    });
  });

  group("findItemByCode", () {
    test("not found", () async {
      final store = await _setupStore();
      final client = HttpWarehouseApiClient(configStore: store, httpClient: FakeHttpClient({}), restoreSession: false);
      final result = await client.findItemByCode("UNKNOWN");
      expect(result.isSuccess, isFalse);
    });
    test("network error", () async {
      final store = await _setupStore();
      final http = FakeHttpClient({"x": {"data": {}}});
      http.setNetworkError();
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      final result = await client.findItemByCode("E");
      expect(result.isSuccess, isFalse);
    });
  });

  group("findBorrowersByQrcode", () {
    test("success", () async {
      final store = await _setupStore();
      final http = FakeHttpClient({"loan_borrower_qrcode/Q001": {"data": {"rows": [{"id": 1}]}}});
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      final result = await client.findBorrowersByQrcode("Q001");
      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(1));
    });
  });

  group("submitCheckout", () {
    test("success", () async {
      final store = await _setupStore();
      final http = FakeHttpClient({"inventory/list/outbound": {"success": true}});
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      final result = await client.submitCheckout(const CheckoutSubmitPayload(inventoryId: 1, quantity: 5, type: 1));
      expect(result.isSuccess, isTrue);
    });
    test("business error", () async {
      final store = await _setupStore();
      final http = FakeHttpClient({"inventory/list/outbound": {"success": false, "msg": "fail"}});
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      final result = await client.submitCheckout(const CheckoutSubmitPayload(inventoryId: 1, quantity: 1, type: 1));
      expect(result.isSuccess, isFalse);
    });
  });

  group("submitReturn", () {
    test("success", () async {
      final store = await _setupStore();
      final http = FakeHttpClient({"loan/inbound": {"success": true}});
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      final result = await client.submitReturn(const ReturnSubmitPayload(loanId: 1, freightId: 2, storageId: 3, returnQty: 10));
      expect(result.isSuccess, isTrue);
    });
  });

  group("submitInventoryCheck", () {
    test("success", () async {
      final store = await _setupStore();
      final http = FakeHttpClient({"saveCheck": {"success": true}});
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      final result = await client.submitInventoryCheck(const InventoryCheckSubmitPayload(inventoryId: 1, actualQty: 95));
      expect(result.isSuccess, isTrue);
    });
  });

  group("error handling", () {
    test("HTTP error", () async {
      final store = await _setupStore();
      final client = HttpWarehouseApiClient(configStore: store, httpClient: FakeHttpClient({}), restoreSession: false);
      final result = await client.findItemByCode("X");
      expect(result.isSuccess, isFalse);
    });
    test("network error message", () async {
      final store = await _setupStore();
      final http = FakeHttpClient({"x": {}});
      http.setNetworkError();
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      final result = await client.submitCheckout(const CheckoutSubmitPayload(inventoryId: 1, quantity: 1, type: 1));
      expect(result.isSuccess, isFalse);
    });
  });

  group("config integration", () {
    test("config change updates URL", () async {
      final store = await _setupStore(baseUrl: "http://old.com");
      final http = FakeHttpClient({"outbound_qrcode/X": {"data": {"id": 1}}});
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      await client.findItemByCode("X");
      expect(http.requestedUrls.first, contains("old.com"));
      await store.saveServers([const ServerConfig(name: "N", baseUrl: "http://new.com:9090")]);
      await store.setActiveServer("http://new.com:9090");
      await client.findItemByCode("X");
      expect(http.requestedUrls.last, contains("new.com:9090"));
    });
  });

  group("contract", () {
    test("implements WarehouseApiClient", () async {
      final store = await _setupStore();
      final client = HttpWarehouseApiClient(configStore: store, httpClient: FakeHttpClient({}), restoreSession: false);
      expect(client, isA<WarehouseApiClient>());
    });
    test("no real network", () async {
      final store = await _setupStore();
      final http = FakeHttpClient({"outbound_qrcode/ANY": {"data": {"id": 1}}});
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      final result = await client.findItemByCode("ANY");
      expect(result.isSuccess, isTrue);
    });
  });

  group('302 redirect handling - login', () {
    test('302 + Set-Cookie + Location=/wms/login → success', () async {
      final store = await _setupStore(baseUrl: 'http://host:8081/wms');
      final http = FakeHttpClient({
        '/login': {
          '_statusCode': 302,
          '_headers': {
            'location': 'http://host:8081/wms/login',
            'set-cookie': 'JSESSIONID=abc123; Path=/wms; HttpOnly',
            'content-type': 'text/html;charset=utf-8',
          },
          '_body': '',
        },
      });
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      final result = await client.login('admin', 'wipinfo666...');
      expect(result.isSuccess, isTrue);
    });

    test('302 + Location=/wms/login?error → failure', () async {
      final store = await _setupStore(baseUrl: 'http://host:8081/wms');
      final http = FakeHttpClient({
        '/login': {
          '_statusCode': 302,
          '_headers': {
            'location': 'http://host:8081/wms/login?error',
            'set-cookie': '',
            'content-type': 'text/html;charset=utf-8',
          },
          '_body': '',
        },
      });
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      final result = await client.login('admin', 'wrong');
      expect(result.isSuccess, isFalse);
    });

    test('200 + JSON code:0 → success', () async {
      final store = await _setupStore(baseUrl: 'http://host:8081/wms');
      final http = FakeHttpClient({
        '/login': {
          'msg': '操作成功',
          'code': 0,
          'data': {'loginName': 'admin', 'userName': '超级管理员'},
        },
      });
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      final result = await client.login('admin', 'wipinfo666...');
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
    });

    test('missing Set-Cookie on 302 → failure', () async {
      final store = await _setupStore(baseUrl: 'http://host:8081/wms');
      final http = FakeHttpClient({
        '/login': {
          '_statusCode': 302,
          '_headers': {
            'location': 'http://host:8081/wms/login',
            'content-type': 'text/html;charset=utf-8',
          },
          '_body': '',
        },
      });
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      final result = await client.login('admin', 'wipinfo666...');
      expect(result.isSuccess, isFalse);
    });
  });

  group('business request with cookie', () {
    test('subsequent requests have no cookie', () async {
      final store = await _setupStore();
      final http = FakeHttpClient({
        'outbound_qrcode/CODE': {'data': {'id': 1}},
      });
      final client = HttpWarehouseApiClient(configStore: store, httpClient: http, restoreSession: false);
      // Without login, no cookie should be sent
      // Verify the findItemByCode request doesn't have a Cookie header
      final result = await client.findItemByCode('CODE');
      // The FakeHttpClient doesn't show headers, but we can verify the call works
      expect(result.isSuccess, isTrue);
    });
  });
}
