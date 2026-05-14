import { buildApiUrl, buildFormBody, parseJsonResponse, ensureAjaxSuccess, setAuthExpiredHandler, handleAuthExpired } from './config';

export { setAuthExpiredHandler, handleAuthExpired };

export async function login(username, password) {
  const response = await fetch(buildApiUrl('/login'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
      'X-Requested-With': 'XMLHttpRequest',
    },
    credentials: 'include',
    body: buildFormBody({ username, password, rememberMe: 'true' }),
  });

  const payload = await parseJsonResponse(response);
  ensureAjaxSuccess(payload, '登录失败');

  return {
    success: true,
    message: payload?.msg || payload?.message || '登录成功',
    data: payload?.data ?? payload,
    code: payload?.code,
  };
}

export function clearAuthSession() {
  localStorage.removeItem('currentUser');
  localStorage.removeItem('api-base-url');
  sessionStorage.removeItem('wms-auth-session');
  sessionStorage.removeItem('wms-remembered-username');
}

export function setAuthSession(user) {
  const sessionData = {
    username: user.username,
    profile: user.profile || {},
    loggedAt: new Date().toISOString(),
  };
  sessionStorage.setItem('wms-auth-session', JSON.stringify(sessionData));
  localStorage.setItem('currentUser', JSON.stringify({
    id: user.id,
    username: user.username,
    profile: user.profile || {},
  }));
}

export function getAuthSession() {
  try {
    const session = sessionStorage.getItem('wms-auth-session');
    return session ? JSON.parse(session) : null;
  } catch {
    return null;
  }
}

export function isAuthenticated() {
  if (getAuthSession()) return true;
  try {
    const user = JSON.parse(localStorage.getItem('currentUser'));
    return !!user?.username;
  } catch { return false; }
}
