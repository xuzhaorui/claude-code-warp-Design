// Permission utilities — mirrors Web `src/utils/permissions.js` exactly.
//
// The login API returns a profile object containing:
//   - `permissions`: List<String> of permission keys (e.g. 'inventory:outBound:view')
//   - `roles`: List<Map> with a `roleKey` field (e.g. {'roleKey': 'costUnitPrice'})
//
// `*:*:*` is the superadmin wildcard — grants everything.

/// Extracts the permission-key list from a login profile.
///
/// Mirrors Web `extractPermissions(profile)`.
List<String> extractPermissions(Map<String, dynamic>? profile) {
  if (profile == null) return const [];
  final perms = profile['permissions'];
  if (perms is List) {
    return perms.map((p) => p.toString()).toList();
  }
  return const [];
}

/// Extracts the role-key list from a login profile.
///
/// Mirrors Web `extractRoles(profile)` but flattens to a list of roleKey
/// strings for easier Dart consumption.
List<String> extractRoles(Map<String, dynamic>? profile) {
  if (profile == null) return const [];
  final roles = profile['roles'];
  if (roles is List) {
    return roles
        .map((r) {
          if (r is Map) return r['roleKey']?.toString() ?? '';
          return r.toString();
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return const [];
}

/// Returns true if the profile grants the given permission.
///
/// Mirrors Web `hasPermission(profile, permission)`. The `*:*:*` wildcard
/// grants all permissions.
bool hasPermission(Map<String, dynamic>? profile, String permission) {
  final perms = extractPermissions(profile);
  if (perms.contains('*:*:*')) return true;
  return perms.contains(permission);
}

/// Returns true if the profile has the given role key.
///
/// Mirrors Web `hasRole(profile, roleKey)`.
bool hasRole(Map<String, dynamic>? profile, String roleKey) {
  final roles = extractRoles(profile);
  return roles.contains(roleKey);
}

/// Returns true if the user is allowed to see cost-price fields.
///
/// Mirrors Web `canViewCostPrice(profile)`:
/// - If the profile has NO permissions and NO roles (open mode), returns true.
/// - Otherwise requires the `inventory:viewUnitPrice` permission or the
///   `costUnitPrice` role.
bool canViewCostPrice(Map<String, dynamic>? profile) {
  final perms = extractPermissions(profile);
  final roles = extractRoles(profile);
  if (perms.isEmpty && roles.isEmpty) return true;
  return hasPermission(profile, 'inventory:viewUnitPrice') ||
      hasRole(profile, 'costUnitPrice');
}

/// The set of warehouse tabs the user is allowed to see.
///
/// Mirrors Web `getAllowedTabs(profile)`:
/// - Open mode (no perms + no roles): all tabs.
/// - Otherwise: settings is always present; outbound/return/inventory are
///   gated by their respective permissions.
///
/// Returns the tabs in display order (business tabs first, settings last),
/// matching the Web `allTabs` array in AppShell.jsx.
List<String> getAllowedTabs(Map<String, dynamic>? profile) {
  final perms = extractPermissions(profile);
  final roles = extractRoles(profile);
  if (perms.isEmpty && roles.isEmpty) {
    return const ['outbound', 'return', 'inventory', 'settings'];
  }

  // Build in reverse order so we can insert before settings.
  // Web does: tabs = ['settings']; unshift/insert business tabs before it.
  final tabs = <String>['settings'];

  if (hasPermission(profile, 'inventory:loan:loanReturnInbound')) {
    tabs.insert(tabs.indexOf('settings'), 'return');
  }
  if (hasPermission(profile, 'calculate:calculate:mobilePhoneInventory')) {
    tabs.insert(tabs.indexOf('settings'), 'inventory');
  }
  if (hasPermission(profile, 'inventory:outBound:view') ||
      hasPermission(profile, 'inventory:outBound:add') ||
      hasPermission(profile, 'inventory:outBound:list')) {
    tabs.insert(0, 'outbound');
  }

  return tabs;
}
