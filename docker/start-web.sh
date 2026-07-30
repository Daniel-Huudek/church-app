#!/bin/sh
set -e

# Dokploy / compose env: WEB_API_URL (public API the browser calls)
API_URL="${WEB_API_URL:-${API_URL:-${VITE_API_URL:-}}}"
API_URL=$(printf '%s' "$API_URL" | sed 's:/*$::')

if [ -z "$API_URL" ]; then
  echo "ERROR: WEB_API_URL is required (set it in Dokploy Environment)."
  echo "Example: WEB_API_URL=https://church.inspeare.com.br"
  exit 1
fi

ESCAPED=$(printf '%s' "$API_URL" | sed 's/\\/\\\\/g; s/"/\\"/g')

cat > /usr/share/nginx/html/config.js <<EOF
window.__ENV__ = Object.freeze({ API_URL: "${ESCAPED}" });
EOF

echo "web config: API_URL=${API_URL}"
exec nginx -g 'daemon off;'
