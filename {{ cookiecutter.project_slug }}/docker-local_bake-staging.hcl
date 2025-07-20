# docker-local_bake-staging.hcl
# Buildx Bake configuration for webapp_test production builds (Local Development)
# Optimized for local builds without external registry dependencies

# Define variables that will be passed from environment or use defaults
# Include the production configuration and override specific values
include = ["docker-local_bake-production.hcl"]

# Override the default BUILD_TARGET for staging
variable "BUILD_TARGET" {
  default = "staging"
}
# Override the default IMAGE_BASENAME for staging
variable "IMAGE_BASENAME" {
  default = "{{cookiecutter.project_slug}}_staging"
}