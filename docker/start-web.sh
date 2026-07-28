#!/bin/sh
set -e

API_URL="${WEB_API_URL:-${VITE_API_URL:-https://api.ipiavare.com.br}}"
# strip trailing slash
API_URL=$(printf '%s' "$API_URL" | sed 's:/*$::')

# Escape for JS string
ESCAPED=$(printf '%s' "$API_URL" | sed 's/\\/\\\\/g; s/"/\\"/g')

cat > /usr/share/nginx/html/config.js <<EOF
window.__ENV__ = Object.freeze({ API_URL: "${ESCAPED}" });
EOF

echo "web config: API_URL=${API_URL}"
exec nginx -g 'daemon off;'
