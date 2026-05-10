let currentApiBaseUrl = 'http://localhost:8080';

const DEFAULT_BASE_URL = 'http://175.178.165.153:8082/store';

export function setApiBaseUrl(url) {
  currentApiBaseUrl = url;
  localStorage.setItem('api-base-url', url);
}

export function buildApiUrl(path) {
  const baseUrl = localStorage.getItem('api-base-url') || DEFAULT_BASE_URL;
  const normalizedPath = path.startsWith('/') ? path : '/' + path;
  return `${baseUrl}${normalizedPath}`;
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
  if (response.status === 401 || response.redirected) {
    throw new Error('未登录或会话已过期');
  }

  const contentType = response.headers.get('content-type');
  if (contentType && contentType.includes('text/html')) {
    const html = await response.text();
    if (html.includes('登录') || html.includes('login')) {
      throw new Error('未登录或会话已过期');
    }
    throw new Error('服务器返回了HTML而不是JSON');
  }

  try {
    const text = await response.text();
    const data = text ? JSON.parse(text) : {};
    if (data.code === 401 || (data.msg && /未登录|登录超时|重新登录|会话已失效|登录状态已过期/.test(data.msg))) {
      throw new Error('未登录或会话已过期');
    }
    return data;
  } catch (error) {
    throw new Error('JSON解析失败');
  }
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
