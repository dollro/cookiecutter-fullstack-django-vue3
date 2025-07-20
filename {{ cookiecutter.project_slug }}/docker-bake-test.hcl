# docker-bake-test.hcl
# Buildx Bake configuration for {{cookiecutter.project_slug}} test stage
# Optimized for GitLab CI Docker-in-Docker environment

# Define variables that will be passed from CI environment
variable "IMAGE_BASENAME" {
  default = ""
}

variable "IMAGETAG" {
  default = "test"
}

variable "BUILD_TARGET" {
  default = "local"
}

variable "PLATFORM" {
  default = "linux/amd64"
}

variable "PLATFORM_SLUG" {
  default = "amd64"
}

variable "CI_COMMIT_REF_SLUG" {
  default = "main" # Default to main, will be overridden by CI
}

# Django service target (local build for testing)
target "django-local" {
  context    = "."
  dockerfile = "compose/${BUILD_TARGET}/django/Dockerfile"
  platforms  = ["${PLATFORM}"]
  pull       = true
  args = {
    BUILDKIT_INLINE_CACHE = "1"
  }
  tags = ["${IMAGE_BASENAME}-django:${IMAGETAG}"]
  cache-from = [
    "type=registry,ref=${IMAGE_BASENAME}-django:cache-${IMAGETAG}",
    "type=registry,ref=${IMAGE_BASENAME}-django:cache-develop",
    "type=registry,ref=${IMAGE_BASENAME}-django:cache-master",
    "type=registry,ref=${IMAGE_BASENAME}-django:cache-staging"
  ]
  cache-to = [
    "type=registry,ref=${IMAGE_BASENAME}-django:cache-${IMAGETAG},mode=max"
  ]
  output     = ["type=registry,push=true,oci-mediatypes=false"]
  provenance = false
}

# PostgreSQL service target (production build used in tests)
target "postgres-production" {
  context    = "."
  dockerfile = "compose/production/postgres/Dockerfile"
  platforms  = ["${PLATFORM}"]
  pull       = true
  args = {
    BUILDKIT_INLINE_CACHE = "1"
  }
  tags = ["${IMAGE_BASENAME}-postgres:${IMAGETAG}"]
  cache-from = [
    "type=registry,ref=${IMAGE_BASENAME}-postgres:cache-${IMAGETAG}",
    "type=registry,ref=${IMAGE_BASENAME}-postgres:cache-develop",
    "type=registry,ref=${IMAGE_BASENAME}-postgres:cache-master",
    "type=registry,ref=${IMAGE_BASENAME}-postgres:cache-staging"
  ]
  cache-to = [
    "type=registry,ref=${IMAGE_BASENAME}-postgres:cache-${IMAGETAG},mode=max"
  ]
  output     = ["type=registry,push=true,oci-mediatypes=false"]
  provenance = false
}

# Node.js/Vue service target (local build for testing)
target "node-vue-local" {
  context    = "."
  dockerfile = "compose/${BUILD_TARGET}/node-vue/Dockerfile"
  platforms  = ["${PLATFORM}"]
  pull       = true
  args = {
    BUILDKIT_INLINE_CACHE = "1"
  }
  tags = ["${IMAGE_BASENAME}-node-vue:${IMAGETAG}"]
  cache-from = [
    "type=registry,ref=${IMAGE_BASENAME}-node-vue:cache-${IMAGETAG}",
    "type=registry,ref=${IMAGE_BASENAME}-node-vue:cache-develop",
    "type=registry,ref=${IMAGE_BASENAME}-node-vue:cache-master",
    "type=registry,ref=${IMAGE_BASENAME}-node-vue:cache-staging"
  ]
  cache-to = [
    "type=registry,ref=${IMAGE_BASENAME}-node-vue:cache-${IMAGETAG},mode=max"
  ]
  output     = ["type=registry,push=true,oci-mediatypes=false"]
  provenance = false
}

# Group target to build all test services in parallel
group "test" {
  targets = ["django-local", "postgres-production", "node-vue-local"]
}
