# Docker Buildx Bake — prefer SERIAL on VPS (see scripts/docker-build-vps.sh).
# Parallel bake can OOM a 4GB machine. Use compose --parallel 1 on Dokploy.
# Usage (CI / strong machines only): docker buildx bake -f docker-bake.hcl

variable "TAG" {
  default = "latest"
}

group "default" {
  targets = [
    "api-gateway",
    "auth-service",
    "member-service",
    "schedule-service",
    "event-service",
    "notification-service",
    "prayer-service",
    "financial-service",
    "worship-service",
    "chat-service",
  ]
}

target "service-base" {
  context    = "."
  dockerfile = "docker/Dockerfile.service"
  platforms  = ["linux/amd64"]
}

target "api-gateway" {
  inherits = ["service-base"]
  args = {
    SERVICE      = "api-gateway"
    PORT         = "3030"
    PACKAGE_NAME = "@church-app/api-gateway"
    HAS_PRISMA   = "false"
  }
  tags = ["church-app-api-gateway:${TAG}"]
}

target "auth-service" {
  inherits = ["service-base"]
  args = {
    SERVICE      = "auth-service"
    PORT         = "3001"
    PACKAGE_NAME = "@church-app/auth-service"
    HAS_PRISMA   = "true"
  }
  tags = ["church-app-auth-service:${TAG}"]
}

target "member-service" {
  inherits = ["service-base"]
  args = {
    SERVICE      = "member-service"
    PORT         = "3006"
    PACKAGE_NAME = "@church-app/member-service"
    HAS_PRISMA   = "true"
  }
  tags = ["church-app-member-service:${TAG}"]
}

target "schedule-service" {
  inherits = ["service-base"]
  args = {
    SERVICE      = "schedule-service"
    PORT         = "3003"
    PACKAGE_NAME = "@church-app/schedule-service"
    HAS_PRISMA   = "true"
  }
  tags = ["church-app-schedule-service:${TAG}"]
}

target "event-service" {
  inherits = ["service-base"]
  args = {
    SERVICE      = "event-service"
    PORT         = "3004"
    PACKAGE_NAME = "@church-app/event-service"
    HAS_PRISMA   = "true"
  }
  tags = ["church-app-event-service:${TAG}"]
}

target "notification-service" {
  inherits = ["service-base"]
  args = {
    SERVICE      = "notification-service"
    PORT         = "3005"
    PACKAGE_NAME = "@church-app/notification-service"
    HAS_PRISMA   = "true"
  }
  tags = ["church-app-notification-service:${TAG}"]
}

target "prayer-service" {
  inherits = ["service-base"]
  args = {
    SERVICE      = "prayer-service"
    PORT         = "3007"
    PACKAGE_NAME = "@church-app/prayer-service"
    HAS_PRISMA   = "true"
  }
  tags = ["church-app-prayer-service:${TAG}"]
}

target "financial-service" {
  inherits = ["service-base"]
  args = {
    SERVICE      = "financial-service"
    PORT         = "3008"
    PACKAGE_NAME = "@church-app/financial-service"
    HAS_PRISMA   = "true"
  }
  tags = ["church-app-financial-service:${TAG}"]
}

target "worship-service" {
  inherits = ["service-base"]
  args = {
    SERVICE      = "worship-service"
    PORT         = "3010"
    PACKAGE_NAME = "@church-app/worship-service"
    HAS_PRISMA   = "true"
  }
  tags = ["church-app-worship-service:${TAG}"]
}

target "chat-service" {
  inherits = ["service-base"]
  args = {
    SERVICE      = "chat-service"
    PORT         = "3002"
    PACKAGE_NAME = "@church-app/chat-service"
    HAS_PRISMA   = "true"
  }
  tags = ["church-app-chat-service:${TAG}"]
}
