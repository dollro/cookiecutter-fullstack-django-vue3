#!/bin/bash
# ci_e2c_build_script.sh - Remote build execution script for E2C
# This script is copied to and executed on the E2C instance

set -euo pipefail

# Script version
BUILD_SCRIPT_VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_progress() {
    echo -e "${YELLOW}⏳ $1${NC}"
}

# Function to validate required environment variables
validate_build_environment() {
    local missing_vars=()

    local required_vars=(
        "_BUILD_REGISTRY"
        "_BUILD_REGISTRY_IMAGE"
        "_BUILD_REGISTRY_USER"
        "_BUILD_REGISTRY_PASSWORD"
        "IMAGE_BASENAME"
        "IMAGETAG"
        "BUILD_TARGET"
        "PLATFORM"
        "PLATFORM_SLUG"
    )

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        return 1
    fi

    return 0
}

# Function to display script usage
show_usage() {
    cat << EOF
E2C Build Script v${BUILD_SCRIPT_VERSION}

USAGE:
    $0 <bake_file> <target>

ARGUMENTS:
    bake_file    Docker bake file to use (e.g., docker-bake-production.hcl)
    target       Build target (e.g., single-stage, multi-stage, all)

ENVIRONMENT VARIABLES:
    The following variables must be set before running this script:
    - _BUILD_REGISTRY, _BUILD_REGISTRY_IMAGE, _BUILD_REGISTRY_USER, _BUILD_REGISTRY_PASSWORD
    - IMAGE_BASENAME, IMAGETAG, BUILD_TARGET, PLATFORM, PLATFORM_SLUG

EXAMPLES:
    $0 docker-bake-production.hcl single-stage
    $0 docker-bake-staging.hcl multi-stage
    $0 docker-bake-production.hcl all

EOF
}

# Main build function
main() {
    echo "=========================================="
    echo "🚀 E2C Build Script v${BUILD_SCRIPT_VERSION}"
    echo "=========================================="

    # Check arguments
    if [[ $# -ne 2 ]]; then
        log_error "Invalid number of arguments"
        show_usage
        exit 1
    fi

    local bake_file="$1"
    local target="$2"

    # Validate build environment
    log_info "Validating build environment..."
    if ! validate_build_environment; then
        log_error "Environment validation failed"
        exit 1
    fi

    # Display build configuration
    log_info "Build Configuration:"
    echo "  📋 Platform: $PLATFORM ($PLATFORM_SLUG)"
    echo "  🎯 Build Target: $BUILD_TARGET"
    echo "  🏷️  Image Tag: $IMAGETAG"
    echo "  📄 Bake File: $bake_file"
    echo "  🎯 Target: $target"
    echo "  🖼️  Image Basename: $IMAGE_BASENAME"
    echo ""

    # Check if bake file exists
    if [[ ! -f "$bake_file" ]]; then
        log_error "Bake file not found: $bake_file"
        exit 1
    fi

    # Login to Docker registry
    log_info "Logging into Docker registry $_BUILD_REGISTRY..."
    if ! echo "$_BUILD_REGISTRY_PASSWORD" | docker login -u "$_BUILD_REGISTRY_USER" --password-stdin "$_BUILD_REGISTRY"; then
        log_error "Failed to login to Docker registry"
        exit 1
    fi
    log_success "Successfully logged into Docker registry"

    # Setup buildx environment
    log_info "Setting up buildx environment..."

    # Create tls-environment context if it doesn't exist (using proven pattern from GitLab CI)
    docker context ls 2>/dev/null | grep tls-environment >/dev/null || docker context create tls-environment

    # Create ci-project-builder if it doesn't exist (using proven pattern from GitLab CI)
    docker buildx ls 2>/dev/null | grep ci-project-builder >/dev/null || docker buildx create --name ci-project-builder --driver docker-container --bootstrap --use tls-environment

    # Use the builder
    docker buildx use ci-project-builder

    log_success "Buildx environment ready"

    # Execute the build
    echo ""
    echo "=========================================="
    log_info "🚀 Executing docker buildx bake..."
    echo "Command: docker buildx bake --file $bake_file --progress=plain $target"
    echo "=========================================="
    echo ""

    # Run the actual build command
    if ! docker buildx bake --file "$bake_file" --progress=plain "$target"; then
        log_error "Build failed!"
        exit 1
    fi
    # Remove the builder
    docker buildx ls 2>/dev/null | grep ci-project-builder >/dev/null || docker buildx rm ci-project-builder

    echo ""
    echo "=========================================="
    log_success "✅ Build completed successfully!"
    echo "Platform: $PLATFORM ($PLATFORM_SLUG)"
    echo "Target: $target"
    echo "Images tagged with: $IMAGETAG"
    echo "=========================================="
}

# Execute main function with all arguments
main "$@"
