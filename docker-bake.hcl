# Docker Buildx Bake — prefer SERIAL on VPS (see scripts/docker-build-vps.sh).
# Parallel bake can OOM a 4GB machine. Use compose --parallel 1 on Dokploy.
# Usage (CI / strong machines only): docker buildx bake -f docker-bake.hcl

variable "TAG" {
  default = "latest"
}

variable "WEB_API_URL" {
  default = "https://api.ipiavare.com.br"
}

group "default" {
  targets = ["api", "web"]
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

target "web" {
  context    = "."
  dockerfile = "docker/Dockerfile.web"
  platforms  = ["linux/amd64"]
  args = {
    VITE_API_URL = "${WEB_API_URL}"
  }
  tags = ["church-app-web:${TAG}"]
}
