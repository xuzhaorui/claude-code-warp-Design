import { buildApiUrl, buildFormBody, parseJsonResponse, ensureAjaxSuccess } from './config';

export async function login(username, password, rememberMe) {
  const response = await fetch(buildApiUrl('/login'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    },
    credentials: 'include',
    body: buildFormBody({ username, password, rememberMe }),
  });

  const payload = await parseJsonResponse(response);
  return ensureAjaxSuccess(payload, '登录失败');
}

export async function logout() {
  const response = await fetch(buildApiUrl('/logout'), {
    method: 'POST',
    credentials: 'include',
  });

  await parseJsonResponse(response);
  clearAuthSession();
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
  return getAuthSession() !== null;
}
