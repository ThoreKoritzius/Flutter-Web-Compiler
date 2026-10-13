# Hosting an authenticated native slice

The experimental Dart runtime emits `index.html` and `app.js`. The script path
is relative, so the bundle can be hosted under a path such as `/native-preview/`.
Native builds use dart2js `--csp`, which disables dynamic code generation. The
current host uses inline styles; its styling requires an appropriate style policy.

For an existing cookie-authenticated application, serve the native slice on the
same HTTPS origin as its API and sign in through the application's normal flow.
SameSite=Lax session cookies do not accompany cross-site fetches from localhost;
adding a CORS allowlist entry alone does not change cookie eligibility. See
[MDN cookie rules](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Set-Cookie).
Do not treat successful compilation as proof of authenticated access.

For Caddy, a dedicated static directory can be mounted read-only:

```caddyfile
handle /native-preview {
    redir * /native-preview/ 308
}
handle_path /native-preview/* {
    root * /srv/native-preview
    header Cache-Control "no-store"
    file_server
}
```

Place the preview handler alongside existing API handlers and before the
application's catch-all handler. `handle_path` strips the prefix before serving
files; see [Caddy's documentation](https://caddyserver.com/docs/caddyfile/directives/handle_path).
Publish only the intended static assets, not source/configuration/snapshots or
inspection reports. Preserve the existing API authentication, cookie and CSRF
policies. A static page does not grant access to authenticated API data.

Validate the routing configuration, trailing-slash redirect, asset URLs, CSP and
missing-file behavior before applying it through the normal deployment workflow.
After deployment, verify original requests and model decoding with the signed-in
browser. A page that only starts successfully has not passed that live check.
