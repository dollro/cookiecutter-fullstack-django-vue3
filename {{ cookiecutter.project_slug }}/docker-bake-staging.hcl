# docker-bake-staging.hcl
# Buildx Bake configuration for {{cookiecutter.project_slug}} staging builds (AMD64)
# Optimized for parallel builds in GitLab CI

# Include the production configuration and override specific values
include = ["docker-bake-production.hcl"]

# Override the default BUILD_TARGET for staging
variable "BUILD_TARGET" {
  default = "staging"
}
