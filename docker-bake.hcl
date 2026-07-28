# Docker Buildx Bake — prefer SERIAL on VPS (see scripts/docker-build-vps.sh).
# Parallel bake can OOM a 4GB machine. Use compose --parallel 1 on Dokploy.
# Usage (CI / strong machines only): docker buildx bake -f docker-bake.hcl

variable "TAG" {
  default = "latest"
}

group "default" {
  targets = ["api"]
}

target "service-base" {
  context    = "."
  dockerfile = "docker/Dockerfile.service"
  platforms  = ["linux/amd64"]
}

target "api" {
  inherits = ["service-base"]
  args = {
    SERVICE      = "api"
    PORT         = "3030"
    PACKAGE_NAME = "@church-app/api"
    HAS_PRISMA   = "true"
  }
  tags = ["church-app-api:${TAG}"]
}
