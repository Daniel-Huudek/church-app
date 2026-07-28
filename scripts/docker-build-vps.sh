#!/bin/sh
echo "Do NOT build on the 4GB VPS."
echo "Use Dokploy pull-only deploy — see docs/deploy-dokploy.md"
echo "Build images via GitHub Actions (Docker Publish) or ./scripts/docker-build-push-pc.sh on your PC."
exit 1
