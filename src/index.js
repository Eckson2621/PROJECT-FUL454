function withSecurityHeaders(response) {
  const headers = new Headers(response.headers);
  headers.set("X-Content-Type-Options", "nosniff");
  headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
  headers.set("X-Frame-Options", "DENY");
  headers.set("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
  headers.set("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
  headers.set("X-Permitted-Cross-Domain-Policies", "none");
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === "/health") {
      return withSecurityHeaders(Response.json({
        ok: true,
        app: "FUL454",
        service: "cloudflare-worker"
      }, {
        headers: { "Cache-Control": "no-store" }
      }));
    }

    const response = await env.ASSETS.fetch(request);
    return withSecurityHeaders(response);
  }
};
