// Talking to The Herd's Wix site over the Wix REST API with an API key.
// Every call sends the key in `Authorization` and the site in `wix-site-id`
// (https://dev.wix.com/docs/api-reference/articles/rest-authentication/rest-api-authentication).

export const WIX_API = 'https://www.wixapis.com';

let current = null;

/** Called once per request with the Worker's environment (vars and secrets). */
export function configure(env) {
  current = {
    apiKey: env.WIX_API_KEY || '',
    siteId: env.WIX_SITE_ID || '',
    env,
  };
}

export function config() {
  if (!current) throw new Error('The checker was not configured.');
  return current;
}

/** True when the Worker has what it needs to reach Wix (the key is a secret, the site ID a var). */
export function isConfigured(env) {
  return !!(env && env.WIX_API_KEY && env.WIX_SITE_ID);
}

/** One JSON call to www.wixapis.com. Throws (so the checker answers 500) when Wix says no. */
export async function wixFetch(path, { method = 'POST', body } = {}) {
  const { apiKey, siteId } = config();
  const headers = { Authorization: apiKey, 'wix-site-id': siteId };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const res = await fetch(WIX_API + path, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`Wix ${method} ${path} answered ${res.status}: ${text.slice(0, 500)}`);
  return text ? JSON.parse(text) : {};
}
