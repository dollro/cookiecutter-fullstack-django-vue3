# docker-local_bake-production.hcl
# Buildx Bake configuration for webapp_test production builds (Local Development)
# Optimized for local builds without external registry dependencies

# Define variables that will be passed from environment or use defaults
variable "IMAGE_BASENAME" {
  default = "{{cookiecutter.project_slug}}"
}

variable "IMAGETAG" {
  default = "latest"
}

variable "BUILD_TARGET" {
  default = "production"
}

variable "PLATFORM" {
  default = "linux/amd64"
}

variable "PLATFORM_SLUG" {
  default = "amd64"
}

# PostgreSQL service (always uses production Dockerfile)
target "postgres" {
  context    = "."
  dockerfile = "compose/production/postgres/Dockerfile"
  platforms  = ["${PLATFORM}"]
  pull       = true
  args = {
    BUILDKIT_INLINE_CACHE = "1"
  }
  tags = ["${IMAGE_BASENAME}-postgres:${IMAGETAG}"]
  cache-from = [
    "type=local,src=./.buildx-cache/postgres"
  ]
  cache-to = [
    "type=local,dest=./.buildx-cache/postgres,mode=max"
  ]
  output     = ["type=docker"]
  provenance = false
}

# Traefik service
target "traefik" {
  context    = "."
  dockerfile = "compose/${BUILD_TARGET}/traefik/Dockerfile"
  platforms  = ["${PLATFORM}"]
  pull       = true
  args = {
    BUILDKIT_INLINE_CACHE = "1"
  }
  tags = ["${IMAGE_BASENAME}-traefik:${IMAGETAG}"]
  cache-from = [
    "type=local,src=./.buildx-cache/traefik"
  ]
  cache-to = [
    "type=local,dest=./.buildx-cache/traefik,mode=max"
  ]
  output     = ["type=docker"]
  provenance = false
}

# Django service - Pre-stage build (first stage of multi-stage build)
target "django-pre-stage" {
  context    = "."
  dockerfile = "compose/production/django/Dockerfile"
  target     = "pre-stage"
  platforms  = ["${PLATFORM}"]
  pull       = true
  args = {
    BUILDKIT_INLINE_CACHE = "0"
  }
  tags = ["${IMAGE_BASENAME}-django:${IMAGETAG}-pre-stage"]
  cache-from = [
    "type=local,src=./.buildx-cache/django-pre-stage"
  ]
  cache-to = [
    "type=local,dest=./.buildx-cache/django-pre-stage,mode=max"
  ]
  output     = ["type=docker"]
  provenance = false
}

# Django service - Main stage build (final stage of multi-stage build)
target "django" {
  context    = "."
  dockerfile = "compose/production/django/Dockerfile"
  target     = "main-stage"
  platforms  = ["${PLATFORM}"]
  pull       = true
  args = {
    BUILDKIT_INLINE_CACHE = "1"
  }
  tags = ["${IMAGE_BASENAME}-django:${IMAGETAG}"]
  cache-from = [
    "type=local,src=./.buildx-cache/django-pre-stage",
    "type=local,src=./.buildx-cache/django"
  ]
  cache-to = [
    "type=local,dest=./.buildx-cache/django,mode=max"
  ]
  output     = ["type=docker"]
  provenance = false
  # Ensure pre-stage is built first
  depends-on = ["django-pre-stage"]
}

# Group target to build all single-stage services in parallel
group "single-stage" {
  targets = ["postgres", "traefik"]
}

# Group target to build multi-stage services (Django with dependencies)
group "multi-stage" {
  targets = ["django-pre-stage", "django"]
}

# Group target to build everything
group "all" {
  targets = ["postgres", "traefik", "django-pre-stage", "django"]
}
