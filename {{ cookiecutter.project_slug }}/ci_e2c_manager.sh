#!/bin/bash

# ci_e2c_manager.sh - E2C Instance Management for GitLab CI
# Handles setup, build execution, and teardown of AWS E2C instances

set -euo pipefail

# Script version
SCRIPT_VERSION="1.2.0"

# Default values
DEFAULT_MAX_IP_RETRIES=10
DEFAULT_SSH_RETRIES=5
DEFAULT_IP_RETRY_DELAY=10
DEFAULT_SSH_RETRY_DELAY=15

# State file for persistence across GitLab CI script phases
# Using CI_JOB_ID to make state files job-specific for parallel builds
E2C_STATE_FILE=".e2c_instance_state_${CI_JOB_ID}"

# Colors and emojis for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output (all logging goes to stderr to avoid contaminating stdout)
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" >&2
}

log_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

log_progress() {
    echo -e "${YELLOW}⏳ $1${NC}" >&2
}

# Function to write state to persistent file
write_state_file() {
    local state_file="${E2C_STATE_FILE}"

    log_info "Writing state to file: $state_file"

    # Validate required variables before writing
    if [[ -z "${TARGET_INSTANCE_ID:-}" ]] || [[ -z "${E2C_PUBLIC_IP:-}" ]] || [[ -z "${E2C_INSTANCE_STRATEGY:-}" ]]; then
        log_error "Cannot write state file: missing required variables"
        log_error "TARGET_INSTANCE_ID='${TARGET_INSTANCE_ID:-}'"
        log_error "E2C_PUBLIC_IP='${E2C_PUBLIC_IP:-}'"
        log_error "E2C_INSTANCE_STRATEGY='${E2C_INSTANCE_STRATEGY:-}'"
        return 1
    fi

    # Write state to file
    cat > "$state_file" << EOF
TARGET_INSTANCE_ID=${TARGET_INSTANCE_ID}
E2C_PUBLIC_IP=${E2C_PUBLIC_IP}
E2C_INSTANCE_STRATEGY=${E2C_INSTANCE_STRATEGY}
EOF

    if [[ $? -eq 0 ]]; then
        log_success "State file written successfully"
        log_info "State: Instance=${TARGET_INSTANCE_ID}, IP=${E2C_PUBLIC_IP}, Strategy=${E2C_INSTANCE_STRATEGY}"
        return 0
    else
        log_error "Failed to write state file"
        return 1
    fi
}

# Function to read state from persistent file
read_state_file() {
    local state_file="${E2C_STATE_FILE}"

    if [[ ! -f "$state_file" ]]; then
        log_error "State file not found: $state_file"
        log_error "The setup command must complete successfully before cleanup/teardown can run"
        return 1
    fi

    log_info "Reading state from file: $state_file"

    # Source the state file to load variables
    if ! source "$state_file"; then
        log_error "Failed to read state file: $state_file"
        return 1
    fi

    # Validate that required variables were loaded
    if [[ -z "${TARGET_INSTANCE_ID:-}" ]] || [[ -z "${E2C_PUBLIC_IP:-}" ]] || [[ -z "${E2C_INSTANCE_STRATEGY:-}" ]]; then
        log_error "State file is missing required variables"
        log_error "TARGET_INSTANCE_ID='${TARGET_INSTANCE_ID:-}'"
        log_error "E2C_PUBLIC_IP='${E2C_PUBLIC_IP:-}'"
        log_error "E2C_INSTANCE_STRATEGY='${E2C_INSTANCE_STRATEGY:-}'"
        return 1
    fi

    # Export variables for use in current session
    export TARGET_INSTANCE_ID
    export E2C_PUBLIC_IP
    export E2C_INSTANCE_STRATEGY

    log_success "State loaded successfully"
    log_info "State: Instance=${TARGET_INSTANCE_ID}, IP=${E2C_PUBLIC_IP}, Strategy=${E2C_INSTANCE_STRATEGY}"
    return 0
}

# Function to remove state file
remove_state_file() {
    local state_file="${E2C_STATE_FILE}"

    if [[ -f "$state_file" ]]; then
        log_info "Removing state file: $state_file"
        if rm "$state_file"; then
            log_success "State file removed"
        else
            log_warning "Failed to remove state file: $state_file"
        fi
    else
        log_info "State file not found (already removed): $state_file"
    fi
}

# Function to determine instance strategy (existing vs template)
determine_instance_strategy() {
    # E2C_INSTANCE_STRATEGY is now REQUIRED when E2C_USAGE is enabled
    if [[ -z "${E2C_INSTANCE_STRATEGY:-}" ]]; then
        log_error "E2C_INSTANCE_STRATEGY must be explicitly set when E2C_USAGE=true"
        log_error "Valid values: 'existing' or 'template'"
        log_error ""
        log_error "Examples:"
        log_error "  E2C_INSTANCE_STRATEGY=\"existing\"   # Use existing instance approach"
        log_error "  E2C_INSTANCE_STRATEGY=\"template\"   # Use template-based instance approach"
        return 1
    fi

    case "$E2C_INSTANCE_STRATEGY" in
        "existing")
            # Validate required variables for existing instance strategy
            if [[ -z "${E2C_INSTANCE_ID:-}" ]]; then
                log_error "E2C_INSTANCE_ID required when E2C_INSTANCE_STRATEGY=existing"
                log_error "Set E2C_INSTANCE_ID to your existing EC2 instance ID (e.g., i-0123456789abcdef0)"
                return 1
            fi
            export TARGET_INSTANCE_ID="$E2C_INSTANCE_ID"
            log_info "Using existing E2C instance: $E2C_INSTANCE_ID"
            ;;
        "template")
            # Validate required variables for template strategy
            if [[ -z "${E2C_LAUNCH_TEMPLATE_ID:-}" ]]; then
                log_error "E2C_LAUNCH_TEMPLATE_ID required when E2C_INSTANCE_STRATEGY=template"
                log_error "Set E2C_LAUNCH_TEMPLATE_ID to your launch template ID (e.g., lt-08c7ea1a2658e52f7)"
                return 1
            fi
            export TARGET_INSTANCE_ID=""  # Will be set after creation
            log_info "Using E2C launch template: $E2C_LAUNCH_TEMPLATE_ID"
            ;;
        *)
            log_error "Invalid E2C_INSTANCE_STRATEGY: '$E2C_INSTANCE_STRATEGY'"
            log_error "Valid values: 'existing' or 'template'"
            log_error ""
            log_error "Examples:"
            log_error "  E2C_INSTANCE_STRATEGY=\"existing\"   # Use existing instance approach"
            log_error "  E2C_INSTANCE_STRATEGY=\"template\"   # Use template-based instance approach"
            return 1
            ;;
    esac
}

# Function to validate launch template
validate_launch_template() {
    local template_id="$1"

    log_info "Validating launch template: $template_id"

    # Check if template exists and get basic info
    local template_info
    local aws_error

    if ! template_info=$(aws ec2 describe-launch-templates \
        --launch-template-ids "$template_id" \
        --query 'LaunchTemplates[0].[LaunchTemplateId,LaunchTemplateName,DefaultVersionNumber]' \
        --output text 2>&1); then
        log_error "Launch template validation failed for $template_id"
        log_error "AWS Error: $template_info"
        return 1
    fi

    if [[ -z "$template_info" ]] || [[ "$template_info" == *"None"* ]]; then
        log_error "Launch template $template_id not found or returned empty data"
        return 1
    fi

    local template_name=$(echo "$template_info" | awk '{print $2}')
    local default_version=$(echo "$template_info" | awk '{print $3}')

    log_success "Template validated: $template_name (default version: $default_version)"
    return 0
}

# Function to get instance IP (works for both existing and template instances)
get_instance_ip() {
    local instance_id="$1"
    local ip_result

    if ! ip_result=$(aws ec2 describe-instances \
        --instance-ids "${instance_id}" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text 2>&1); then
        log_error "Failed to query IP for instance ${instance_id}: $ip_result"
        echo "None"
        return 1
    fi

    echo "$ip_result"
}

# Function to wait for instance to reach running state
wait_for_instance_running() {
    log_info "Waiting for instance ${TARGET_INSTANCE_ID} to reach running state..."

    local wait_result
    if ! wait_result=$(aws ec2 wait instance-running --instance-ids "${TARGET_INSTANCE_ID}" 2>&1); then
        log_error "Instance ${TARGET_INSTANCE_ID} failed to reach running state"
        if [[ -n "$wait_result" ]]; then
            log_error "Wait command output: $wait_result"
        fi

        # Get current instance state for debugging
        local state_info
        if state_info=$(aws ec2 describe-instances --instance-ids "${TARGET_INSTANCE_ID}" \
            --query 'Reservations[0].Instances[0].[State.Name,StateReason.Message]' \
            --output text 2>/dev/null); then
            log_error "Current instance state: $state_info"
        fi
        return 1
    fi

    log_success "Instance ${TARGET_INSTANCE_ID} is now running"
    return 0
}

# Function to create instance from launch template
create_instance_from_template() {
    log_info "Creating instance from launch template ${E2C_LAUNCH_TEMPLATE_ID}..."

    # Validate the template first
    if ! validate_launch_template "$E2C_LAUNCH_TEMPLATE_ID"; then
        return 1
    fi

    # Build launch template specification
    local template_spec="LaunchTemplateId=${E2C_LAUNCH_TEMPLATE_ID}"
    if [[ -n "${E2C_LAUNCH_TEMPLATE_VERSION:-}" ]]; then
        template_spec+=",Version=${E2C_LAUNCH_TEMPLATE_VERSION}"
    else
        template_spec+=",Version=\$Latest"
    fi

    # Build run-instances command using array for proper parameter handling
    local aws_cmd=(
        "aws" "ec2" "run-instances"
        "--launch-template" "${template_spec}"
        "--count" "1"
    )

    # Add optional instance type override
    if [[ -n "${E2C_INSTANCE_TYPE:-}" ]]; then
        aws_cmd+=("--instance-type" "${E2C_INSTANCE_TYPE}")
        log_info "Overriding instance type: ${E2C_INSTANCE_TYPE}"
    fi

    # Add optional subnet
    if [[ -n "${E2C_SUBNET_ID:-}" ]]; then
        aws_cmd+=("--subnet-id" "${E2C_SUBNET_ID}")
        log_info "Using subnet: ${E2C_SUBNET_ID}"
    fi

    # Add optional security groups
    if [[ -n "${E2C_SECURITY_GROUP_IDS:-}" ]]; then
        aws_cmd+=("--security-group-ids" "${E2C_SECURITY_GROUP_IDS}")
        log_info "Using security groups: ${E2C_SECURITY_GROUP_IDS}"
    fi

    # Add optional key pair
    if [[ -n "${E2C_KEY_PAIR_NAME:-}" ]]; then
        aws_cmd+=("--key-name" "${E2C_KEY_PAIR_NAME}")
        log_info "Using key pair: ${E2C_KEY_PAIR_NAME}"
    fi

    # Handle spot instances (only if explicitly enabled)
    if [[ "${E2C_USE_SPOT:-false}" == "true" ]]; then
        if [[ -n "${E2C_SPOT_MAX_PRICE:-}" ]]; then
            local spot_spec="SpotPrice=${E2C_SPOT_MAX_PRICE},Type=one-time"
            aws_cmd+=("--instance-market-options" "MarketType=spot,SpotOptions={${spot_spec}}")
            log_info "Using spot instance with max price: ${E2C_SPOT_MAX_PRICE}"
        else
            log_warning "E2C_USE_SPOT=true but E2C_SPOT_MAX_PRICE not set - using on-demand"
        fi
    fi

    # Create unique tags for tracking
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local instance_tags="{Key=Name,Value=ci-build-${CI_JOB_ID}-${timestamp}},{Key=JobId,Value=${CI_JOB_ID}},{Key=CreatedBy,Value=GitLabCI},{Key=Project,Value={{ cookiecutter.project_slug }}},{Key=AutoTerminate,Value=true}"

    aws_cmd+=("--tag-specifications" "ResourceType=instance,Tags=[${instance_tags}]")
    aws_cmd+=("--query" "Instances[0].InstanceId")
    aws_cmd+=("--output" "text")

    # Execute instance creation with detailed error reporting
    log_info "Creating instance with launch template..."
    log_info "Command: ${aws_cmd[*]}"

    local instance_output
    if ! instance_output=$("${aws_cmd[@]}" 2>&1); then
        log_error "Failed to create instance from template ${E2C_LAUNCH_TEMPLATE_ID}"
        log_error "AWS CLI Error Output: $instance_output"
        return 1
    fi

    TARGET_INSTANCE_ID="$instance_output"

    if [[ -z "$TARGET_INSTANCE_ID" ]] || [[ "$TARGET_INSTANCE_ID" == "None" ]] || [[ "$TARGET_INSTANCE_ID" == "null" ]]; then
        log_error "Instance creation returned empty or invalid instance ID: '$TARGET_INSTANCE_ID'"
        log_error "Full AWS output: $instance_output"
        return 1
    fi

    export TARGET_INSTANCE_ID
    log_success "Created instance ${TARGET_INSTANCE_ID} from template ${E2C_LAUNCH_TEMPLATE_ID}"
    return 0
}

# Function to validate required environment variables
validate_environment() {
    local missing_vars=()

    # AWS credentials and configuration
    local aws_vars=(
        "AWS_ACCESS_KEY_ID"
        "AWS_SECRET_ACCESS_KEY"
        "AWS_DEFAULT_REGION"
    )

    # Common E2C variables
    local common_e2c_vars=(
        "E2C_SSH_USER"
        "E2C_SSH_PRIVATE_KEY"
        "E2C_BUILD_DIR"
        "CI_JOB_ID"
    )

    # Check AWS variables
    for var in "${aws_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done

    # Check common E2C variables
    for var in "${common_e2c_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done

    # Check that either E2C_INSTANCE_ID or E2C_LAUNCH_TEMPLATE_ID is set
    if [[ -z "${E2C_INSTANCE_ID:-}" ]] && [[ -z "${E2C_LAUNCH_TEMPLATE_ID:-}" ]]; then
        missing_vars+=("E2C_INSTANCE_ID or E2C_LAUNCH_TEMPLATE_ID")
    fi

    # Report missing variables
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        log_error "Please set these variables in your GitLab CI/CD settings."
        return 1
    fi

    log_success "All required environment variables are set"
    return 0
}

# Function to validate build environment variables (only when needed for build operation)
validate_build_environment() {
    local missing_vars=()

    local build_vars=(
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

    for var in "${build_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required build environment variables:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        return 1
    fi

    log_success "All required build environment variables are set"
    return 0
}

# Function to setup SSH key
setup_ssh_key() {
    log_info "Setting up SSH key..."
    mkdir -p ~/.ssh
    echo "$E2C_SSH_PRIVATE_KEY" | base64 -d > ~/.ssh/id_rsa_e2c
    chmod 600 ~/.ssh/id_rsa_e2c
    log_success "SSH key configured"
}

# Function to start E2C instance
start_instance() {
    log_info "Starting E2C instance ${E2C_INSTANCE_ID}..."

    local start_result
    if ! start_result=$(aws ec2 start-instances --instance-ids "${E2C_INSTANCE_ID}" 2>&1); then
        log_error "Failed to start E2C instance ${E2C_INSTANCE_ID}"
        log_error "AWS Error: $start_result"
        return 1
    fi

    log_info "Waiting for E2C instance to be running..."
    local wait_result
    if ! wait_result=$(aws ec2 wait instance-running --instance-ids "${E2C_INSTANCE_ID}" 2>&1); then
        log_error "E2C instance failed to reach running state"
        log_error "Wait command output: $wait_result"
        return 1
    fi

    log_success "E2C instance ${E2C_INSTANCE_ID} is running"
    return 0
}

# Function to fetch public IP with retry logic
fetch_public_ip() {
    local max_retries=${1:-$DEFAULT_MAX_IP_RETRIES}
    local retry_delay=${2:-$DEFAULT_IP_RETRY_DELAY}
    local retry_count=0

    log_info "Fetching dynamic public IP for instance ${TARGET_INSTANCE_ID}..."

    while [[ $retry_count -lt $max_retries ]]; do
        local ip
        ip=$(get_instance_ip "${TARGET_INSTANCE_ID}")

        if [[ "$ip" != "None" ]] && [[ -n "$ip" ]] && [[ "$ip" != "null" ]]; then
            export E2C_PUBLIC_IP="$ip"
            log_success "Got public IP: $E2C_PUBLIC_IP"
            return 0
        fi

        retry_count=$((retry_count + 1))
        log_progress "Waiting for public IP assignment... (attempt $retry_count/$max_retries)"
        sleep "$retry_delay"
    done

    log_error "Failed to get public IP for instance ${TARGET_INSTANCE_ID} after $max_retries attempts"
    return 1
}

# Function to test SSH connectivity
test_ssh_connectivity() {
    local max_retries=${1:-$DEFAULT_SSH_RETRIES}
    local retry_delay=${2:-$DEFAULT_SSH_RETRY_DELAY}
    local retry_count=0

    log_info "Testing SSH connectivity to $E2C_PUBLIC_IP..."

    while [[ $retry_count -lt $max_retries ]]; do
        if ssh -o StrictHostKeyChecking=no \
               -o UserKnownHostsFile=/dev/null \
               -o ConnectTimeout=10 \
               -o LogLevel=ERROR \
               -i ~/.ssh/id_rsa_e2c \
               "${E2C_SSH_USER}@${E2C_PUBLIC_IP}" \
               "echo 'SSH connection successful'" >/dev/null 2>&1; then
            log_success "SSH connectivity confirmed"
            return 0
        fi

        retry_count=$((retry_count + 1))
        log_progress "SSH not ready yet, waiting... (attempt $retry_count/$max_retries)"
        sleep "$retry_delay"
    done

    log_error "SSH connectivity failed after $max_retries attempts"
    return 1
}

# Function to copy build files to E2C
copy_build_files() {
    log_info "Copying build files to E2C instance..."

    # Create job-specific target directory
    local job_build_dir="${E2C_BUILD_DIR}/${CI_JOB_ID}"
    log_info "Using job-specific build directory: $job_build_dir"

    if ! ssh -o StrictHostKeyChecking=no \
             -o UserKnownHostsFile=/dev/null \
             -o LogLevel=ERROR \
             -i ~/.ssh/id_rsa_e2c \
             "${E2C_SSH_USER}@${E2C_PUBLIC_IP}" \
             "mkdir -p ${job_build_dir}" 2>/dev/null; then
        log_error "Failed to create job-specific target directory on E2C"
        return 1
    fi

    # Archive and copy project context (includes docker-bake files)
    log_info "Archiving and copying project context to E2C..."
    if ! tar -czf project_context.tar.gz \
             --exclude='.git' \
             --exclude='.cache' \
             --exclude='project_context.tar.gz' \
             . 2>/dev/null; then
        log_error "Failed to create project archive"
        return 1
    fi

    if ! scp -o StrictHostKeyChecking=no \
             -o UserKnownHostsFile=/dev/null \
             -o LogLevel=ERROR \
             -i ~/.ssh/id_rsa_e2c \
             project_context.tar.gz \
             "${E2C_SSH_USER}@${E2C_PUBLIC_IP}:${job_build_dir}/project_context.tar.gz" 2>/dev/null; then
        log_error "Failed to copy project context to E2C"
        return 1
    fi

    # Extract project context and cleanup
    if ! ssh -o StrictHostKeyChecking=no \
             -o UserKnownHostsFile=/dev/null \
             -o LogLevel=ERROR \
             -i ~/.ssh/id_rsa_e2c \
             "${E2C_SSH_USER}@${E2C_PUBLIC_IP}" \
             "cd ${job_build_dir} && tar -xzf ${job_build_dir}/project_context.tar.gz && rm ${job_build_dir}/project_context.tar.gz" 2>/dev/null; then
        log_error "Failed to extract project context on E2C"
        return 1
    fi

    log_success "Project context copied and extracted on E2C in job-specific directory"
    return 0
}

# Function to execute setup
e2c_setup() {
    # Redirect all stdout to stderr except for the final export statement
    {
        log_info "🚀 Starting E2C setup..."

        # Determine which E2C strategy to use
        if ! determine_instance_strategy; then
            return 1
        fi

        # Validate environment
        if ! validate_environment; then
            return 1
        fi

        # Install required tools (if not already available)
        if ! command -v aws >/dev/null 2>&1 || ! command -v ssh >/dev/null 2>&1; then
            log_info "Installing required tools..."
            apk add --no-cache openssh-client aws-cli >/dev/null 2>&1 || {
                log_error "Failed to install required tools"
                return 1
            }
        fi

        # Setup SSH key
        if ! setup_ssh_key; then
            return 1
        fi

        # Handle the E2C strategy
        case "$E2C_INSTANCE_STRATEGY" in
            "existing")
                log_info "📋 Using existing instance strategy"
                if ! start_instance; then
                    return 1
                fi
                ;;
            "template")
                log_info "🏗️ Using template instance strategy"
                if ! create_instance_from_template; then
                    return 1
                fi
                if ! wait_for_instance_running; then
                    return 1
                fi
                ;;
        esac

        # Common E2C setup steps
        if ! fetch_public_ip; then
            return 1
        fi

        if ! test_ssh_connectivity; then
            return 1
        fi

        if ! copy_build_files; then
            return 1
        fi

        log_success "🎉 E2C setup completed successfully!"
        log_info "Instance: $TARGET_INSTANCE_ID (${E2C_INSTANCE_STRATEGY})"
        log_info "Public IP: $E2C_PUBLIC_IP"

        # Validate IP format before export
        if [[ ! "$E2C_PUBLIC_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            log_error "Invalid IP format: $E2C_PUBLIC_IP"
            return 1
        fi

        # Write state to file for persistence across GitLab CI script phases
        if ! write_state_file; then
            log_error "Failed to write state file - cleanup/teardown may fail"
            return 1
        fi

    } >&2

    # Export the IP and instance info for use by calling scripts
    printf "export E2C_PUBLIC_IP='%s'\n" "$E2C_PUBLIC_IP"
    printf "export TARGET_INSTANCE_ID='%s'\n" "$TARGET_INSTANCE_ID"
    printf "export E2C_INSTANCE_STRATEGY='%s'\n" "$E2C_INSTANCE_STRATEGY"

    return 0
}

# Function to execute remote build
e2c_build() {
    local platform=""
    local target=""
    local bake_file=""

    # Parse build arguments (expects --option="value" format)
    while [[ $# -gt 0 ]]; do
        case $1 in
            --platform=*)
                platform="${1#*=}"
                shift
                ;;
            --target=*)
                target="${1#*=}"
                shift
                ;;
            --bake-file=*)
                bake_file="${1#*=}"
                shift
                ;;
            *)
                log_error "Unknown build argument: $1. Use format: --platform=\"value\" --target=\"value\" --bake-file=\"value\""
                return 1
                ;;
        esac
    done

    # Validate build arguments
    if [[ -z "$platform" ]] || [[ -z "$target" ]] || [[ -z "$bake_file" ]]; then
        log_error "Missing required build arguments. Usage: build --platform PLATFORM --target TARGET --bake-file BAKE_FILE"
        return 1
    fi

    # Validate build environment
    if ! validate_build_environment; then
        return 1
    fi

    # Ensure we have the public IP
    if [[ -z "${E2C_PUBLIC_IP:-}" ]]; then
        log_error "E2C_PUBLIC_IP not set. Run setup first."
        return 1
    fi

    log_info "🔨 Executing remote build on E2C..."
    log_info "Platform: $platform, Target: $target, Bake file: $bake_file"

    # Define job-specific directory
    local job_build_dir="${E2C_BUILD_DIR}/${CI_JOB_ID}"
    local build_script="ci_e2c_build_script.sh"

    # Copy build script to E2C instance
    log_info "Copying build script to E2C instance..."
    if ! scp -o StrictHostKeyChecking=no \
             -o UserKnownHostsFile=/dev/null \
             -o LogLevel=ERROR \
             -i ~/.ssh/id_rsa_e2c \
             "$build_script" \
             "${E2C_SSH_USER}@${E2C_PUBLIC_IP}:${job_build_dir}/${build_script}"; then
        log_error "Failed to copy build script to E2C"
        return 1
    fi

    # Make build script executable on E2C
    if ! ssh -o StrictHostKeyChecking=no \
             -o UserKnownHostsFile=/dev/null \
             -o LogLevel=ERROR \
             -i ~/.ssh/id_rsa_e2c \
             "${E2C_SSH_USER}@${E2C_PUBLIC_IP}" \
             "chmod +x ${job_build_dir}/${build_script}"; then
        log_error "Failed to make build script executable"
        return 1
    fi

    log_success "Build script prepared on E2C instance"

    # Execute remote build using the dedicated script
    log_info "🚀 Executing build script on E2C instance..."
    if ! ssh -o StrictHostKeyChecking=no \
             -o UserKnownHostsFile=/dev/null \
             -o LogLevel=QUIET \
             -i ~/.ssh/id_rsa_e2c \
             "${E2C_SSH_USER}@${E2C_PUBLIC_IP}" \
             "cd ${job_build_dir} && \
              export _BUILD_REGISTRY='${_BUILD_REGISTRY}' && \
              export _BUILD_REGISTRY_IMAGE='${_BUILD_REGISTRY_IMAGE}' && \
              export _BUILD_REGISTRY_USER='${_BUILD_REGISTRY_USER}' && \
              export _BUILD_REGISTRY_PASSWORD='${_BUILD_REGISTRY_PASSWORD}' && \
              export IMAGE_BASENAME='${IMAGE_BASENAME}' && \
              export IMAGETAG='${IMAGETAG}' && \
              export BUILD_TARGET='${BUILD_TARGET}' && \
              export PLATFORM='${platform}' && \
              export PLATFORM_SLUG='${PLATFORM_SLUG}' && \
              ./${build_script} ${bake_file} ${target}"; then
        log_error "Remote build failed"
        return 1
    fi

    log_success "✅ Remote build completed successfully!"
    return 0
}

# Function to cleanup job-specific build directory
e2c_cleanup() {
    log_info "🧹 Cleaning up job-specific build directory..."

    # Read instance info from state file
    if ! read_state_file; then
        log_error "Cannot perform cleanup: state file not available"
        return 1
    fi

    # Validate minimal environment for cleanup
    if [[ -z "${CI_JOB_ID:-}" ]]; then
        log_error "CI_JOB_ID not set"
        return 1
    fi

    if [[ -z "${E2C_BUILD_DIR:-}" ]]; then
        log_error "E2C_BUILD_DIR not set"
        return 1
    fi

    if [[ -z "${E2C_SSH_USER:-}" ]]; then
        log_error "E2C_SSH_USER not set"
        return 1
    fi

    # Ensure SSH key is available for cleanup
    if [[ ! -f ~/.ssh/id_rsa_e2c ]]; then
        if [[ -n "${E2C_SSH_PRIVATE_KEY:-}" ]]; then
            log_info "Setting up SSH key for cleanup..."
            mkdir -p ~/.ssh
            echo "$E2C_SSH_PRIVATE_KEY" | base64 -d > ~/.ssh/id_rsa_e2c
            chmod 600 ~/.ssh/id_rsa_e2c
        else
            log_error "SSH key not available and E2C_SSH_PRIVATE_KEY not set"
            return 1
        fi
    fi

    local job_build_dir="${E2C_BUILD_DIR}/${CI_JOB_ID}"
    log_info "Removing job-specific directory: $job_build_dir"
    log_info "Using instance: ${TARGET_INSTANCE_ID}, IP: ${E2C_PUBLIC_IP}"

    if ! ssh -o StrictHostKeyChecking=no \
             -o UserKnownHostsFile=/dev/null \
             -o LogLevel=ERROR \
             -o ConnectTimeout=10 \
             -i ~/.ssh/id_rsa_e2c \
             "${E2C_SSH_USER}@${E2C_PUBLIC_IP}" \
             "rm -rf ${job_build_dir}" 2>/dev/null; then
        log_warning "Failed to remove job-specific directory (may not exist or instance not accessible)"
        return 0  # Don't fail the overall process for cleanup issues
    fi

    log_success "Job-specific build directory cleaned up successfully"
    return 0
}

# Function to execute teardown
e2c_teardown() {
    log_info "🛑 Managing E2C instance..."

    # Read instance info from state file
    if ! read_state_file; then
        log_error "Cannot perform teardown: state file not available"
        return 1
    fi

    # Ensure AWS CLI is available for teardown
    if ! command -v aws >/dev/null 2>&1; then
        log_info "Installing AWS CLI for teardown..."
        apk add --no-cache aws-cli >/dev/null 2>&1 || {
            log_error "Failed to install AWS CLI"
            return 1
        }
    fi

    log_info "Using instance: ${TARGET_INSTANCE_ID}, Strategy: ${E2C_INSTANCE_STRATEGY}"

    case "${E2C_INSTANCE_STRATEGY}" in
        "existing")
            log_info "Stopping existing instance: $TARGET_INSTANCE_ID"
            local stop_result
            if ! stop_result=$(aws ec2 stop-instances --instance-ids "$TARGET_INSTANCE_ID" 2>&1); then
                log_warning "Failed to stop instance $TARGET_INSTANCE_ID (may already be stopped)"
                if [[ -n "$stop_result" ]]; then
                    log_warning "AWS Error: $stop_result"
                fi
            else
                log_success "Stop command issued for existing instance $TARGET_INSTANCE_ID"
            fi
            ;;
        "template")
            log_info "Terminating template-created instance: $TARGET_INSTANCE_ID"
            local terminate_result
            if ! terminate_result=$(aws ec2 terminate-instances --instance-ids "$TARGET_INSTANCE_ID" 2>&1); then
                log_warning "Failed to terminate instance $TARGET_INSTANCE_ID"
                if [[ -n "$terminate_result" ]]; then
                    log_warning "AWS Error: $terminate_result"
                fi
            else
                log_success "Terminate command issued for template instance $TARGET_INSTANCE_ID"
                log_info "Instance will be destroyed and billing will stop"
            fi
            ;;
        *)
            log_warning "Unknown instance strategy: ${E2C_INSTANCE_STRATEGY}"
            ;;
    esac

    # Clean up state file after teardown
    remove_state_file

    return 0
}

# Function to display help
show_help() {
    cat << EOF
E2C Instance Manager v${SCRIPT_VERSION}

USAGE:
    $0 <command> [options]

COMMANDS:
    setup                 Start instance, fetch IP, test SSH, copy files
    build                 Execute remote build on E2C
    cleanup               Remove job-specific build directory
    teardown              Stop the E2C instance
    help                  Show this help message

BUILD OPTIONS:
    --platform PLATFORM   Build platform (e.g., linux/arm64)
    --target TARGET        Build target (e.g., single-stage, multi-stage)
    --bake-file FILE       Docker bake file to use

ENVIRONMENT VARIABLES:
    Required for all operations:
        AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION
        E2C_SSH_USER, E2C_SSH_PRIVATE_KEY, E2C_BUILD_DIR, CI_JOB_ID

    E2C Instance Strategy (choose ONE):
        Option 1 - Existing Instance:
            E2C_INSTANCE_ID (e.g., i-0123456789abcdef0)

        Option 2 - Template-based Instance:
            E2C_LAUNCH_TEMPLATE_ID (e.g., lt-08c7ea1a2658e52f7)
            E2C_LAUNCH_TEMPLATE_VERSION (optional, default: $Latest)
            E2C_INSTANCE_TYPE (optional, overrides template)
            E2C_SUBNET_ID (optional, overrides template)
            E2C_SECURITY_GROUP_IDS (optional, overrides template)
            E2C_KEY_PAIR_NAME (optional, overrides template)
            E2C_USE_SPOT (optional, default: false)
            E2C_SPOT_MAX_PRICE (optional, required when USE_SPOT=true)

    Required for build operations:
        _BUILD_REGISTRY, _BUILD_REGISTRY_IMAGE, _BUILD_REGISTRY_USER, _BUILD_REGISTRY_PASSWORD
        IMAGE_BASENAME, IMAGETAG, BUILD_TARGET, PLATFORM, PLATFORM_SLUG

EXAMPLES:
    # Setup E2C instance
    $0 setup

    # Build single-stage services for ARM64
    $0 build --platform linux/arm64 --target single-stage --bake-file docker-bake-production.hcl

    # Cleanup job-specific directory
    $0 cleanup

    # Stop instance
    $0 teardown

EOF
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        log_error "No command provided"
        show_help
        exit 1
    fi

    local command="$1"
    shift

    case "$command" in
        setup)
            e2c_setup
            ;;
        build)
            e2c_build "$@"
            ;;
        cleanup)
            e2c_cleanup
            ;;
        teardown)
            e2c_teardown
            ;;
        help|--help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
