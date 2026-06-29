# Flutter API Contract — WarehouseApiClient

## 概要

基于 Web 版真实 API 设计的 Flutter API 客户端契约。
当前不实现，仅定义接口。

## 1. 配置存储接口

```dart
/// Persisted server configuration.
class ServerConfig {
  final String url;   // e.g. "http://192.168.1.100:8080"
  final String name;  // display name, e.g. "主服务器"
}

abstract class ServerConfigStore {
  Future<List<ServerConfig>> loadServers();
  Future<void> saveServers(List<ServerConfig> servers);
  Future<ServerConfig?> loadActiveServer();
  Future<void> setActiveServer(String url);
}

/// In-memory implementation for testing.
class InMemoryServerConfigStore implements ServerConfigStore { ... }

/// SharedPreferences-backed implementation for production.
class PersistentServerConfigStore implements ServerConfigStore { ... }
```

## 2. API 客户端接口

```dart
/// Generic API error.
class ApiError {
  final String message;
  final int? httpStatus;
  final String? code;
}

/// Result wrapper matching Web's {success, code, msg, data} shape.
class ApiResult<T> {
  final bool success;
  final String? message;
  final T? data;
}

/// DTO for inventory item queried by scan code.
class InventoryItemDto {
  final int id;
  final String warehouse;
  final String itemName;
  final String code;
  final String spec;
  final int stockQty;
  final double costPrice;
}

/// DTO for borrow record queried by scan code (return flow).
class BorrowRecordDto {
  final int id;
  final int loanId;
  final int inventoryId;
  final String itemName;
  final String warehouse;
  final String code;
  final String spec;
  final int borrowQty;
  final double costPrice;
  final String borrower;
  final String borrowTime;
}

/// Web API client contract — mirrors src/api/*.js.
abstract class WarehouseApiClient {
  // — Inventory / Scan —
  Future<InventoryItemDto?> findInventoryByCode(String code);

  // — Borrow records (return) —
  Future<List<BorrowRecordDto>> findBorrowersByQrcode(String qrcode);
  Future<BorrowRecordDto?> getBorrowerDetail(int inventoryId, int borrowerUserId);

  // — Checkout —
  Future<void> submitCheckout({
    required int inventoryId,
    required int quantity,
    required int type,       // 1=外销, 2=外借
    double? totalPrice,
    double? costUnitPrice,
    String? remark,
  });
  Future<List<CheckoutRecordDto>> fetchCheckoutRecords();

  // — Return —
  Future<void> submitReturn({
    required int loanId,
    required int freightId,
    required int storageId,
    required int quantity,
    String? remark,
  });
  Future<List<ReturnRecordDto>> fetchReturnRecords();

  // — Inventory Check —
  Future<void> submitInventoryCheck({
    required int inventoryId,
    required int actualQty,
    String? remark,
  });
  Future<List<InventoryCheckRecordDto>> fetchInventoryCheckRecords();
}
```

## 3. Auth / Session

```dart
class AuthSession {
  final String username;
  final Map<String, dynamic> profile;
  final DateTime loggedAt;
}

abstract class AuthApiClient {
  Future<AuthSession> login(String username, String password);
  Future<void> logout();
  bool isAuthenticated();
  void clearSession();
}
```

## 4. URL 构建

```dart
class ApiUrlBuilder {
  final String? baseUrl;  // from ServerConfigStore.activeServer

  String build(String path) => '/store$path';  // always /store context
}
```

Web 版使用 `buildApiUrl(path)` 始终添加 `/store` 前缀和用户配置的 baseURL。
Flutter 版可直接拼接 `$baseUrl/store$path`。

## 5. 错误处理

```dart
/// Parses Web's JSON error response and throws typed exceptions.
T handleApiResponse<T>(Map<String, dynamic> payload) {
  if (payload['success'] == false || payload['code'] == '1') {
    throw ApiError(message: payload['msg'] ?? '操作失败');
  }
  return payload['data'] as T;
}
```

## 6. 实现策略

| 类型 | 文件 | 说明 |
|------|------|------|
| 接口 | `lib/services/warehouse_api_client.dart` | abstract interface class |
| Mock | `lib/services/mock_warehouse_api_client.dart` | 返回 fixture 数据，用于测试 |
| HTTP | `lib/services/http_warehouse_api_client.dart` | 真实 HTTP 调用 |
| DI | 构造器注入 | 各 FormMin/ScannerEntry 通过构造参数接收 client |

## 7. 测试策略

- `MockWarehouseApiClient` 提供 fixture 响应
- `WarehouseApiClient` 接口保证可 mock
- 不依赖网络 / 真实服务器
