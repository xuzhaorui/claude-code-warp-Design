function extractPermissions(profile) {
  if (!profile) return [];
  const perms = profile.permissions;
  if (Array.isArray(perms)) return perms;
  return [];
}

function extractRoles(profile) {
  if (!profile) return [];
  const roles = profile.roles;
  if (Array.isArray(roles)) return roles;
  return [];
}

function hasPermission(profile, permission) {
  const perms = extractPermissions(profile);
  if (perms.includes('*:*:*')) return true;
  return perms.includes(permission);
}

function hasRole(profile, roleKey) {
  const roles = extractRoles(profile);
  return roles.some(r => r.roleKey === roleKey);
}

export function canViewCostPrice(profile) {
  const perms = extractPermissions(profile);
  const roles = extractRoles(profile);
  if (perms.length === 0 && roles.length === 0) return true;
  return hasPermission(profile, 'inventory:viewUnitPrice') || hasRole(profile, 'costUnitPrice');
}

export function getAllowedTabs(profile) {
  const perms = extractPermissions(profile);
  const roles = extractRoles(profile);
  if (perms.length === 0 && roles.length === 0) {
    return ['outbound', 'return', 'inventory', 'settings'];
  }
  const tabs = ['settings'];
  if (hasPermission(profile, 'inventory:outBound:view') ||
      hasPermission(profile, 'inventory:outBound:add') ||
      hasPermission(profile, 'inventory:outBound:list')) {
    tabs.unshift('outbound');
  }
  if (hasPermission(profile, 'inventory:loan:loanReturnInbound')) {
    tabs.splice(tabs.indexOf('settings'), 0, 'return');
  }
  if (hasPermission(profile, 'calculate:calculate:mobilePhoneInventory')) {
    tabs.splice(tabs.indexOf('settings'), 0, 'inventory');
  }
  return tabs;
}
