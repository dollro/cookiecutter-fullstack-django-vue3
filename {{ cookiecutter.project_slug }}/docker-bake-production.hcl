# docker-bake-production.hcl
# Buildx Bake configuration for {{cookiecutter.project_slug}} production builds (AMD64)
# Optimized for parallel builds in GitLab CI

# Define variables that will be passed from CI environment
variable "IMAGE_BASENAME" {
  default = ""
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
  tags = ["${IMAGE_BASENAME}-postgres:${IMAGETAG}-${PLATFORM_SLUG}"]
  cache-from = [
    "type=registry,ref=${IMAGE_BASENAME}-postgres:cache-latest-${PLATFORM_SLUG}"
  ]
  cache-to = [
    "type=registry,ref=${IMAGE_BASENAME}-postgres:cache-latest-${PLATFORM_SLUG},mode=max"
  ]
  output     = ["type=registry,push=true,oci-mediatypes=false"]
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
  tags = ["${IMAGE_BASENAME}-traefik:${IMAGETAG}-${PLATFORM_SLUG}"]
  cache-from = [
    "type=registry,ref=${IMAGE_BASENAME}-traefik:cache-latest-${PLATFORM_SLUG}"
  ]
  cache-to = [
    "type=registry,ref=${IMAGE_BASENAME}-traefik:cache-latest-${PLATFORM_SLUG},mode=max"
  ]
  output     = ["type=registry,push=true,oci-mediatypes=false"]
  provenance = false
}


# Watchtower service
target "watchtower" {
  context    = "."
  dockerfile = "compose/${BUILD_TARGET}/watchtower/Dockerfile"
  platforms  = ["${PLATFORM}"]
  pull       = true
  args = {
    BUILDKIT_INLINE_CACHE = "1"
  }
  tags = ["${IMAGE_BASENAME}-watchtower:${IMAGETAG}-${PLATFORM_SLUG}"]
  cache-from = [
    "type=registry,ref=${IMAGE_BASENAME}-watchtower:cache-latest-${PLATFORM_SLUG}"
  ]
  cache-to = [
    "type=registry,ref=${IMAGE_BASENAME}-watchtower:cache-latest-${PLATFORM_SLUG},mode=max"
  ]
  output     = ["type=registry,push=true,oci-mediatypes=false"]
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
    APP_VERSION = "${IMAGETAG}"
    VITE_APP_VERSION = "${IMAGETAG}"
  }
  tags = ["${IMAGE_BASENAME}-django:${IMAGETAG}-pre-stage-${PLATFORM_SLUG}"]
  cache-from = [
    "type=registry,ref=${IMAGE_BASENAME}-django:cache-latest-pre-stage-${PLATFORM_SLUG}"
  ]
  cache-to = [
    "type=registry,ref=${IMAGE_BASENAME}-django:cache-latest-pre-stage-${PLATFORM_SLUG},mode=max"
  ]
  output     = ["type=registry,push=true,oci-mediatypes=false"]
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
    APP_VERSION = "${IMAGETAG}"
  }
  tags = ["${IMAGE_BASENAME}-django:${IMAGETAG}-${PLATFORM_SLUG}"]
  cache-from = [
    "type=registry,ref=${IMAGE_BASENAME}-django:cache-latest-pre-stage-${PLATFORM_SLUG}",
    "type=registry,ref=${IMAGE_BASENAME}-django:cache-latest-${PLATFORM_SLUG}"
  ]
  cache-to = [
    "type=registry,ref=${IMAGE_BASENAME}-django:cache-latest-${PLATFORM_SLUG},mode=max"
  ]
  output     = ["type=registry,push=true,oci-mediatypes=false"]
  provenance = false
  # Ensure pre-stage is built first
  depends-on = ["django-pre-stage"]
}

# Group target to build all single-stage services in parallel
group "single-stage" {
  targets = ["postgres", "traefik", "watchtower"]
}

# Group target to build multi-stage services (Django with dependencies)
group "multi-stage" {
  targets = ["django-pre-stage", "django"]
}

# Group target to build everything
group "all" {
  targets = ["watchtower", "postgres", "traefik", "django-pre-stage", "django"]
}
