#!/bin/bash

#
# GitLab CI Latest Tag Manager
# Handles smart updating of 'latest' tag based on registry state comparison
# Compares against the actual version behind the current 'latest' tag in the registry
# rather than git tags, ensuring registry consistency
#

set -e

function log_info() {
    echo "ℹ️  $1" >&2
}

function log_warning() {
    echo "⚠️  $1" >&2
}

function log_error() {
    echo "❌ $1" >&2
}

function get_current_registry_latest_version() {
    # Get the current version behind the 'latest' tag in the release registry
    local registry_latest_version

    if [ -z "$RELEASE_REGISTRY_IMAGE" ]; then
        log_error "RELEASE_REGISTRY_IMAGE is not set"
        echo "0.0.0"
        return 1
    fi

    # Try to get version from the latest tag in registry
    # We'll use the first service (django) as a reference since all services should have the same version
    local latest_image="$RELEASE_REGISTRY_IMAGE/{{cookiecutter.project_slug}}-django:latest"

    # Check if latest tag exists in registry
    if ./regctl image inspect "$latest_image" >/dev/null 2>&1; then
        # Try to get version from image labels first
        registry_latest_version=$(./regctl image inspect "$latest_image" --format '{{.Config.Labels.version}}' 2>/dev/null || echo "")

        # Handle case where regctl returns "<no value>" as a string
        if [ "$registry_latest_version" = "<no value>" ]; then
            registry_latest_version=""
        fi

        # If no version label, use digest comparison to find the actual version
        if [ -z "$registry_latest_version" ]; then
            log_info "No version label found, using digest comparison to determine version behind 'latest'"

            # Get the digest of the 'latest' tag
            local latest_digest=$(./regctl image digest "$latest_image" 2>/dev/null || echo "")

            if [ -n "$latest_digest" ]; then
                log_info "Latest tag digest: $latest_digest"

                # List all version tags and find which one matches latest's digest
                local version_tags=$(./regctl tag ls "$RELEASE_REGISTRY_IMAGE/{{cookiecutter.project_slug}}-django" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' | sort -V)

                for tag in $version_tags; do
                    local tag_image="$RELEASE_REGISTRY_IMAGE/{{cookiecutter.project_slug}}-django:$tag"
                    local tag_digest=$(./regctl image digest "$tag_image" 2>/dev/null || echo "")

                    if [ "$tag_digest" = "$latest_digest" ]; then
                        registry_latest_version="$tag"
                        log_info "Found matching version for 'latest': $tag (digest: $tag_digest)"
                        break
                    fi
                done

                # If no matching version tag found (shouldn't happen unless 'latest' points to non-version tag)
                if [ -z "$registry_latest_version" ]; then
                    log_warning "Could not find a version tag matching 'latest' digest. This may happen if 'latest' was manually set to a non-version tag."
                    # Fallback: exclude current tag from consideration if it exists
                    if [ -n "$CI_COMMIT_TAG" ]; then
                        registry_latest_version=$(echo "$version_tags" | grep -v "^${CI_COMMIT_TAG}$" | tail -n1 || echo "")
                        if [ -n "$registry_latest_version" ]; then
                            log_warning "Falling back to highest version excluding current tag: $registry_latest_version"
                        fi
                    fi
                fi
            else
                log_warning "Could not get digest for 'latest' tag"
                # Last resort fallback - get the highest version tag excluding current
                if [ -n "$CI_COMMIT_TAG" ]; then
                    registry_latest_version=$(./regctl tag ls "$RELEASE_REGISTRY_IMAGE/{{cookiecutter.project_slug}}-django" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' | grep -v "^${CI_COMMIT_TAG}$" | sort -V | tail -n1 || echo "")
                else
                    registry_latest_version=$(./regctl tag ls "$RELEASE_REGISTRY_IMAGE/{{cookiecutter.project_slug}}-django" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n1 || echo "")
                fi
                if [ -n "$registry_latest_version" ]; then
                    log_warning "Using highest version tag as fallback: $registry_latest_version"
                fi
            fi
        fi
    else
        log_warning "No 'latest' tag found in registry"
    fi

    if [ -z "$registry_latest_version" ]; then
        log_warning "No existing 'latest' tag found in registry or no version info available"
        echo "0.0.0"
    else
        log_info "Current latest version in registry: $registry_latest_version"
        echo "$registry_latest_version"
    fi
}

function normalize_version() {
    local version="$1"
    # Remove 'v' prefix if present and handle empty/invalid versions
    if [ -z "$version" ]; then
        echo "0.0.0"
        return
    fi

    local normalized=$(echo "$version" | sed 's/^v//')
    echo "$normalized"
}

function is_annotated_tag() {
    local tag="${1:-$CI_COMMIT_TAG}"

    if [ -z "$tag" ]; then
        log_error "No tag provided for annotation check"
        return 1
    fi

    # Check for TAG_TYPE_OVERRIDE environment variable
    local tag_type_override="${TAG_TYPE_OVERRIDE:-auto}"
    if [ "$tag_type_override" = "annotated" ]; then
        log_info "🔧 TAG_TYPE_OVERRIDE=annotated - treating as annotated tag"
        return 0
    elif [ "$tag_type_override" = "lightweight" ]; then
        log_info "🔧 TAG_TYPE_OVERRIDE=lightweight - treating as lightweight tag"
        return 1
    fi

    # Method 1: Check if tag object exists using git (annotated tags have tag objects)
    if command -v git >/dev/null 2>&1; then
        if git cat-file -t "refs/tags/$tag" 2>/dev/null | grep -q "^tag$"; then
            log_info "✅ Tag '$tag' is annotated (has comments/message)"
            return 0
        elif git rev-parse "refs/tags/$tag" >/dev/null 2>&1; then
            log_info "📝 Tag '$tag' is lightweight (no comments/message)"
            return 1
        fi
    fi

    # Method 2: Fallback to GitLab API if git is not available or tag not found locally
    if [ -n "$CI_JOB_TOKEN" ] && [ -n "$CI_API_V4_URL" ] && [ -n "$CI_PROJECT_ID" ]; then
        log_info "Checking tag type via GitLab API..."
        local api_response=$(curl -s --header "JOB-TOKEN: $CI_JOB_TOKEN" \
            "$CI_API_V4_URL/projects/$CI_PROJECT_ID/repository/tags/$tag" 2>/dev/null)

        # Check if response contains a message field (annotated tags have messages)
        if echo "$api_response" | grep -q '"message":\s*"[^"]\+'; then
            log_info "✅ Tag '$tag' is annotated (has message via API)"
            return 0
        elif echo "$api_response" | grep -q '"name":\s*"'"$tag"'"'; then
            log_info "📝 Tag '$tag' is lightweight (no message via API)"
            return 1
        fi
    fi

    # Method 3: Check for pre-release identifiers as a heuristic
    if echo "$tag" | grep -qiE "(alpha|beta|rc|pre|dev|test)"; then
        log_info "📝 Tag '$tag' appears to be a pre-release (contains alpha/beta/rc/pre/dev/test) - treating as lightweight"
        return 1
    fi

    # Default: if we can't determine, assume it's lightweight (safer default)
    log_warning "Could not determine tag type for '$tag' - defaulting to lightweight"
    return 1
}

function is_version_newer() {
    local new_tag="$1"
    local current_tag="$2"

    if [ -z "$new_tag" ]; then
        log_error "New tag is empty"
        return 1
    fi

    if [ -z "$current_tag" ] || [ "$current_tag" = "0.0.0" ]; then
        log_info "No current tag or current tag is 0.0.0, new tag will be considered newer"
        return 0
    fi

    # Normalize both versions (remove v prefix)
    local new_clean=$(normalize_version "$new_tag")
    local current_clean=$(normalize_version "$current_tag")

    log_info "Comparing versions: '$new_clean' vs '$current_clean'"

    # Use sort -V for semantic version comparison
    # If the new version comes last when sorted, it's newer
    local sorted_result=$(printf '%s\n' "$current_clean" "$new_clean" | sort -V | tail -n1)

    if [ "$sorted_result" = "$new_clean" ] && [ "$new_clean" != "$current_clean" ]; then
        log_info "✅ Version '$new_tag' is newer than '$current_tag'"
        return 0  # true - new version is newer
    else
        log_info "❌ Version '$new_tag' is not newer than '$current_tag'"
        return 1  # false - new version is older or same
    fi
}

function should_update_latest() {
    local current_tag="${CI_COMMIT_TAG}"

    if [ -z "$current_tag" ]; then
        log_error "CI_COMMIT_TAG is not set"
        echo "false"
        return 1
    fi

    log_info "Evaluating whether to update 'latest' tag for: $current_tag"

    # Handle backward compatibility and determine strategy
    local strategy="${UPDATE_LATEST_STRATEGY:-}"

    # Backward compatibility with old boolean variables
    if [ -z "$strategy" ]; then
        if [ "${FORCE_UPDATE_LATEST}" = "true" ]; then
            strategy="force"
            log_warning "⚠️ FORCE_UPDATE_LATEST is deprecated. Use UPDATE_LATEST_STRATEGY=force instead"
        elif [ "${SKIP_LATEST_UPDATE}" = "true" ]; then
            strategy="skip"
            log_warning "⚠️ SKIP_LATEST_UPDATE is deprecated. Use UPDATE_LATEST_STRATEGY=skip instead"
        else
            strategy="auto"
        fi
    else
        # Check for conflicting old variables when new variable is set
        if [ "${FORCE_UPDATE_LATEST}" = "true" ] || [ "${SKIP_LATEST_UPDATE}" = "true" ]; then
            log_warning "⚠️ Both old (FORCE_UPDATE_LATEST/SKIP_LATEST_UPDATE) and new (UPDATE_LATEST_STRATEGY) variables are set. Using UPDATE_LATEST_STRATEGY=$strategy"
        fi
    fi

    log_info "🎯 Using UPDATE_LATEST_STRATEGY: $strategy"

    case "$strategy" in
        "force")
            log_info "🔧 Strategy=force - forcing latest update regardless of version or tag type"
            echo "true"
            return 0
            ;;
        "skip")
            log_info "🔧 Strategy=skip - skipping latest update regardless of version or tag type"
            echo "false"
            return 0
            ;;
        "auto")
            log_info "🤖 Strategy=auto - using automatic version comparison against registry state"
            ;;
        *)
            log_warning "⚠️ Unknown strategy '$strategy', falling back to 'auto'"
            ;;
    esac

    # Check if tag is annotated (unless force mode)
    if [ "$strategy" != "force" ]; then
        if ! is_annotated_tag "$current_tag"; then
            log_info "⏭️ Lightweight tag detected - skipping 'latest' update"
            log_info "💡 Use annotated tags (git tag -a) for official releases that should update 'latest'"
            log_info "💡 Or use UPDATE_LATEST_STRATEGY=force to override this behavior"
            echo "false"
            return 0
        fi
    fi

    # Automatic comparison (default behavior for "auto" and unknown strategies)
    local registry_latest_version=$(get_current_registry_latest_version)

    if is_version_newer "$current_tag" "$registry_latest_version"; then
        log_info "✅ Will update 'latest' tag from '$registry_latest_version' to '$current_tag'"
        echo "true"
    else
        log_info "⏭️  Will keep 'latest' tag at '$registry_latest_version' (not updating to '$current_tag')"
        echo "false"
    fi
}

function show_help() {
    cat << EOF
GitLab CI Latest Tag Manager

USAGE:
    $0 <command>

COMMANDS:
    should_update_latest    Check if 'latest' tag should be updated (returns true/false)
                           Compares against current registry state, not git tags
                           Only annotated tags can update 'latest' (unless forced)
    get_registry_latest     Get the current version behind the 'latest' tag in registry
    compare <tag1> <tag2>   Compare two version tags (returns newer version)
    help                    Show this help message

ENVIRONMENT VARIABLES:
    CI_COMMIT_TAG           Current tag being processed (automatically set by GitLab CI)
    RELEASE_REGISTRY_IMAGE  Release registry image base path (required for registry checks)
    UPDATE_LATEST_STRATEGY  Strategy for updating 'latest' tag (auto, force, skip)
                           - auto: Compare versions and update if newer (default)
                                  Only annotated tags can update 'latest' in auto mode
                           - force: Always update 'latest' tag regardless of version or tag type
                           - skip: Never update 'latest' tag
    TAG_TYPE_OVERRIDE       Override tag type detection (annotated, lightweight, auto)
                           - annotated: Treat tag as annotated regardless of actual type
                           - lightweight: Treat tag as lightweight regardless of actual type
                           - auto: Use automatic detection (default)

TAG TYPE BEHAVIOR:
    - ANNOTATED TAGS (git tag -a): Can update 'latest' tag (official releases)
    - LIGHTWEIGHT TAGS (git tag): Cannot update 'latest' tag (internal/alpha releases)
    - Tags containing 'alpha', 'beta', 'rc', 'pre', 'dev', 'test' are treated as lightweight

RELEASE WORKFLOW:
    Internal/Alpha Release:
        git tag 1.8.7alpha
        git push origin 1.8.7alpha
        → Images built and pushed with version tag
        → 'latest' tag NOT updated

    Official Release:
        git tag -a 1.8.7 -m "Release v1.8.7 - Features and fixes"
        git push origin 1.8.7
        → Images built and pushed with version tag
        → 'latest' tag UPDATED (if version is newer)

EXAMPLES:
    # Check if current tag should update latest (in CI pipeline)
    ./ci_latest_manager.sh should_update_latest

    # Compare two versions manually
    ./ci_latest_manager.sh compare v1.2.3 1.2.4

    # Force update latest (set in GitLab CI variables)
    export UPDATE_LATEST_STRATEGY=force
    ./ci_latest_manager.sh should_update_latest

    # Override tag type detection
    export TAG_TYPE_OVERRIDE=annotated
    ./ci_latest_manager.sh should_update_latest

EOF
}

function compare_versions() {
    local tag1="$1"
    local tag2="$2"

    if [ -z "$tag1" ] || [ -z "$tag2" ]; then
        log_error "Both tags must be provided for comparison"
        return 1
    fi

    if is_version_newer "$tag1" "$tag2"; then
        echo "$tag1"
    else
        echo "$tag2"
    fi
}

# Main command handling
case "${1:-}" in
    should_update_latest)
        should_update_latest
        ;;
    get_registry_latest)
        get_current_registry_latest_version
        ;;
    compare)
        if [ -z "$2" ] || [ -z "$3" ]; then
            log_error "Usage: $0 compare <tag1> <tag2>"
            exit 1
        fi
        compare_versions "$2" "$3"
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        log_error "No command provided"
        show_help
        exit 1
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
