#!/bin/bash

# Smart deployment script for {{cookiecutter.project_slug}} that make use of reverse SSH tunnel and remote docker context
# Usage: ./docker-compose-remote.sh <target> [docker-compose-args]
# Examples:
#   ./docker-compose-remote.sh asparuha up -d
#   ./docker-compose-remote.sh wolpertinger down
#   ./docker-compose-remote.sh asparuha logs django

set -e  # Exit on any error
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

ENV_FILE_BASE=".envs/.production/.django"


# Check if at least one argument was provided
if [ $# -eq 0 ]; then
    echo "❌ Invalid target. Usage: $0 <asparuha|wolpertinger> [docker-compose-args]"
    echo ""
    echo "Examples:"
    echo "  $0 asparuha up -d          # Deploy asparuha environment"
    echo "  $0 wolpertinger up -d      # Deploy wolpertinger environment"
    echo "  $0 asparuha down           # Stop asparuha services"
    echo "  $0 wolpertinger logs django # View django logs for wolpertinger"
    exit 1
fi

TARGET=$1
shift  # Remove target from arguments, pass rest to docker compose

if [[ "$TARGET" != "asparuha" && "$TARGET" != "wolpertinger" ]]; then
    echo "❌ Invalid target. Usage: $0 <asparuha|wolpertinger> [docker-compose-args]"
    echo ""
    echo "Examples:"
    echo "  $0 asparuha up -d          # Deploy asparuha environment"
    echo "  $0 wolpertinger up -d      # Deploy wolpertinger environment"
    echo "  $0 asparuha down           # Stop asparuha services"
    echo "  $0 wolpertinger logs django # View django logs for wolpertinger"
    exit 1
fi



# Check if base environment file exists
if [[ ! -f "$ENV_FILE_BASE" ]]; then
    echo "❌ Environment file not found: $ENV_FILE_BASE"
    exit 1
fi

# Check if environment file exists
ENV_FILE_TARGET="$ENV_FILE_BASE.$TARGET"
if [[ ! -f "$ENV_FILE_TARGET" ]]; then
    echo "❌ Environment file not found: $ENV_FILE_TARGET"
    exit 1
fi

# Set deployment target variable for deploy.yml
export DEPLOYMENT_TARGET=$TARGET


# Source the environment file - just to get the variables needed for the deploy.yml itself
#
echo "📋 Loading environments from $ENV_FILE_BASE and $ENV_FILE_TARGET"
set -a  # Automatically export all variables
source "$ENV_FILE_BASE"
source "$ENV_FILE_TARGET"
set +a  # Stop auto-exporting


# Verify required variables are set
if [[ -z "$DOCKER_REGISTRY" || -z "$DOCKER_REGISTRY_USER" || -z "$DOCKER_REGISTRY_PASS" ]]; then
    echo "❌ Docker registry variables not set !"
    exit 1
fi

# Run docker compose with remaining arguments
echo "🚀 Deploying to $TARGET..."
echo "📁 Using compose file: deploy.yml"
echo "🔧 Environment file: $ENV_FILE_BASE and $ENV_FILE_TARGET"
echo "⚙️  Command: docker compose -f deploy.yml $*"
echo ""

docker context ls | grep "asparuha-remote" || docker context create asparuha-remote --docker "host=ssh://sshadmin@localhost:42001"
docker context ls | grep "wolpertinger-remote" || docker context create wolpertinger-remote --docker "host=ssh://sshadmin@localhost:42000"
docker context use "$TARGET-remote"
docker compose -f deploy.yml "$@"
docker context use default

echo ""
echo "✅ Deployment command completed for $TARGET"
