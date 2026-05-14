function normalizeServerUrl(raw) {
  let url = (raw || '').trim().replace(/\/$/, '');
  if (url && !url.startsWith('http')) url = `http://${url}`;
  return url;
}

export function setApiBaseUrl(rawUrl) {
  const url = normalizeServerUrl(rawUrl);
  localStorage.setItem('api-base-url', url);
  // /__proxy-target is a Vite dev-only endpoint — skip in production to avoid 405
  if (import.meta.env.DEV) {
    fetch('/__proxy-target', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ target: url }),
    }).catch(() => {});
  }
}

export function buildApiUrl(path) {
  const normalizedPath = path.startsWith('/') ? path : '/' + path;

  // Dev: Vite proxy handles cross-server routing via /__proxy-target
  if (import.meta.env.DEV) return `/store${normalizedPath}`;

  const storedBase = localStorage.getItem('api-base-url');
  if (storedBase) {
    try {
      const parsed = new URL(storedBase);
      const hasContextPath = parsed.pathname && parsed.pathname !== '/';
      const contextPath = hasContextPath ? parsed.pathname.replace(/\/$/, '') : '/store';

      if (parsed.origin === window.location.origin) {
        // Same origin: use relative path so nginx routes it (no Mixed Content)
        return `${contextPath}${normalizedPath}`;
      }

      // Different origin: use absolute URL — target server must be HTTPS to avoid Mixed Content
      return `${parsed.origin}${contextPath}${normalizedPath}`;
    } catch { /* malformed URL — fall through */ }
  }
  return `/store${normalizedPath}`;
}

export function buildFormBody(fields) {
  const params = new URLSearchParams();
  Object.entries(fields).forEach(([key, value]) => {
    if (value !== null && value !== undefined && value !== '') {
      params.append(key, String(value));
    }
  });
  return params;
}

export async function parseJsonResponse(response) {
  if (response.status === 401) {
    handleAuthExpired();
    throw new Error('未登录或会话已过期');
  }
  if (response.redirected) {
    throw new Error('未登录或会话已过期');
  }

  const contentType = response.headers.get('content-type');
  if (contentType && contentType.includes('text/html')) {
    const html = await response.text();
    if (html.includes('登录') || html.includes('login')) {
      handleAuthExpired();
      throw new Error('未登录或会话已过期');
    }
    if (response.status === 403 || html.includes('403') || html.includes('权限') || html.includes('denied')) {
      throw new Error('账号权限不足，无法访问此系统');
    }
    throw new Error(`服务器返回了HTML而不是JSON（HTTP ${response.status}）`);
  }

  let text;
  try {
    text = await response.text();
  } catch {
    throw new Error('读取响应失败');
  }

  let data;
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    throw new Error('JSON解析失败');
  }

  if (data.code === 401 || (data.msg && /未登录|登录超时|重新登录|会话已失效|登录状态已过期/.test(data.msg))) {
    handleAuthExpired();
    throw new Error('未登录或会话已过期');
  }

  return data;
}

export function ensureAjaxSuccess(payload, fallbackMessage) {
  if (!payload) {
    throw new Error(fallbackMessage || '服务器响应为空');
  }
  if (payload.success === false || payload.code === '1') {
    throw new Error(payload.msg || payload.message || fallbackMessage || '操作失败');
  }
  if (payload.code && payload.code !== '0' && payload.code !== '200' && payload.code !== 200) {
    throw new Error(payload.msg || payload.message || fallbackMessage || '操作失败');
  }
  return payload;
}

export function normalizeTableRows(payload) {
  const data = payload?.data ?? payload;
  if (Array.isArray(data?.rows)) return data.rows;
  if (Array.isArray(payload?.rows)) return payload.rows;
  if (Array.isArray(data)) return data;
  if (Array.isArray(payload)) return payload;
  return [];
}

let authExpiredHandler = null;

export function setAuthExpiredHandler(handler) {
  authExpiredHandler = handler;
}

export function handleAuthExpired() {
  if (authExpiredHandler) {
    authExpiredHandler();
  }
}
