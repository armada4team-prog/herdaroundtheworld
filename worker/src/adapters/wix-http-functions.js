// Stands in for Velo's `wix-http-functions`: ok / badRequest / serverError become Responses.
function respond(status) {
  return ({ headers = {}, body } = {}) =>
    new Response(typeof body === 'string' ? body : JSON.stringify(body === undefined ? {} : body), { status, headers });
}

export const ok = respond(200);
export const badRequest = respond(400);
export const serverError = respond(500);
