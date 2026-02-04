# CI/CD Pipeline

## Pipeline Stages

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌───────────────┐    ┌─────────┐
│  lint   │───▶│  test   │───▶│  build  │───▶│build_manifests│───▶│ release │
└─────────┘    └─────────┘    └─────────┘    └───────────────┘    └─────────┘
```

## Stage Details

| Stage | Description | Triggers |
|-------|-------------|----------|
| **lint** | Pre-commit hooks (Black, Pylint) | All feature branches |
| **test** | pytest in Docker | All feature branches |
| **build** | Build Docker images (per platform) | staging, tags |
| **build_manifests** | Merge multi-arch manifests | staging, tags |
| **release** | Push to release registry | tags only |

## Branch Rules

| Branch Pattern | Stages Run |
|----------------|------------|
| `fix/*`, `feat/*`, `test/*`, `chore/*` | lint, test |
| `staging` | lint, test, build, build_manifests |
| Tags (e.g., `1.2.3`) | All stages including release |

## Tag Types and Release Strategy

- **Annotated tags** (`git tag -a 1.0.0 -m "Release"`): Official releases, updates `latest` tag
- **Lightweight tags** (`git tag 1.0.0alpha`): Internal/alpha releases, no `latest` update

```bash
# Official release
git tag -a 1.2.3 -m "Release v1.2.3"
git push origin 1.2.3

# Alpha release
git tag 1.2.3alpha
git push origin 1.2.3alpha
```

## Multi-Platform Builds

### Supported Platforms

| Platform | Architecture | Build Enabled | Notes |
|----------|--------------|---------------|-------|
| `linux/amd64` | x86_64 | Default ON | Standard servers |
| `linux/arm64` | ARM 64-bit | Optional | Apple Silicon, ARM servers |
| `linux/arm/v7` | ARM 32-bit | Optional | Raspberry Pi |

### Build Process

**Docker Buildx Bake** is used for parallel multi-service builds:

```
docker-bake-production.hcl
├── postgres    (single-stage)
├── traefik     (single-stage)
├── watchtower  (single-stage)
└── django      (multi-stage)
    ├── pre-stage   (Node.js - Vue build)
    └── main-stage  (Python - Django)
```

### ARM Build Strategies

Two options for ARM builds:

1. **Local Cross-Compilation**: Uses QEMU emulation on amd64 runner
2. **E2C Remote Build**: Uses native ARM EC2 instances via AWS

```yaml
# .gitlab-ci.yml
E2C_USAGE: "false"  # true = use AWS ARM instances
E2C_INSTANCE_STRATEGY: "template"  # or "existing"
```

### Manifest Merging

After platform-specific builds, manifests are merged:

```bash
# Creates multi-arch manifest
docker buildx imagetools create \
  -t registry/image:1.0.0 \
  registry/image:1.0.0-amd64 \
  registry/image:1.0.0-arm64
```

## Latest Tag Management

### Automatic Latest Tag Updates (`ci_latest_manager.sh`)

The CI pipeline uses a sophisticated system to manage the `latest` Docker tag based on semantic versioning and tag types.

#### Decision Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                     SHOULD UPDATE LATEST?                               │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. Check UPDATE_LATEST_STRATEGY                                       │
│     ├── "force" → Always update latest                                 │
│     ├── "skip"  → Never update latest                                  │
│     └── "auto"  → Continue to step 2                                   │
│                                                                         │
│  2. Check tag type (annotated vs lightweight)                          │
│     ├── Annotated (git tag -a) → Continue to step 3                   │
│     └── Lightweight (git tag)  → Skip update (alpha/internal release) │
│                                                                         │
│  3. Compare versions against current registry latest                   │
│     ├── New version > Current latest → Update latest tag              │
│     └── New version <= Current latest → Keep existing latest          │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

#### Tag Type Detection Methods

The script uses multiple methods to detect tag type (in priority order):

1. **TAG_TYPE_OVERRIDE env var**: Manual override (`annotated` or `lightweight`)
2. **Git cat-file**: Check if tag object exists (`git cat-file -t refs/tags/$tag`)
3. **GitLab API**: Query tag metadata for message field
4. **Heuristic**: Tags containing `alpha/beta/rc/pre/dev/test` treated as lightweight

#### Version Comparison Against Registry

```bash
# Uses regctl to inspect current "latest" in the registry
./regctl image digest "$RELEASE_REGISTRY_IMAGE/<project>-django:latest"

# Compares against all version tags to find what "latest" points to
for tag in $version_tags; do
    tag_digest=$(./regctl image digest "$tag_image")
    if [ "$tag_digest" = "$latest_digest" ]; then
        # Found the version behind "latest"
    fi
done

# Semantic version comparison using sort -V
printf '%s\n' "$current" "$new" | sort -V | tail -n1
```

#### Release Workflow Examples

```bash
# Internal/Alpha Release (lightweight tag)
git tag 1.8.7alpha
git push origin 1.8.7alpha
# → Images built and pushed with 1.8.7alpha tag
# → 'latest' tag NOT updated

# Official Release (annotated tag)
git tag -a 1.8.7 -m "Release v1.8.7 - Features and fixes"
git push origin 1.8.7
# → Images built and pushed with 1.8.7 tag
# → 'latest' tag UPDATED (if 1.8.7 > current latest)
```

## E2C ARM Build Management

### E2C Instance Management (`ci_e2c_manager.sh`)

For native ARM builds (faster than QEMU emulation), the CI can spin up AWS EC2 ARM instances.

#### Two Instance Strategies

```
┌─────────────────────────────────────────────────────────────────────┐
│                    E2C INSTANCE STRATEGIES                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Strategy: "existing"                                                │
│  ├── Uses a pre-configured EC2 instance                             │
│  ├── Instance is stopped when idle, started for builds              │
│  ├── Requires: E2C_INSTANCE_ID                                      │
│  └── Lifecycle: Start → Build → Stop                                │
│                                                                      │
│  Strategy: "template"                                                │
│  ├── Creates fresh instance from launch template                    │
│  ├── Instance is terminated after build                             │
│  ├── Requires: E2C_LAUNCH_TEMPLATE_ID                               │
│  ├── Optional: Spot instances for cost savings                      │
│  └── Lifecycle: Create → Build → Terminate                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

#### E2C Lifecycle Commands

```bash
# Setup Phase (before_script in GitLab CI)
./ci_e2c_manager.sh setup
# → Determines strategy (existing/template)
# → Starts or creates instance
# → Waits for public IP assignment
# → Tests SSH connectivity
# → Copies project files to instance
# → Writes state file for later phases

# Build Phase (script in GitLab CI)
./ci_e2c_manager.sh build --platform="linux/arm64" --target="all" --bake-file="docker-bake-production.hcl"
# → Copies build script to remote instance
# → Executes docker buildx bake remotely
# → Pushes images to registry from ARM instance

# Cleanup Phase (after_script in GitLab CI)
./ci_e2c_manager.sh cleanup
# → Removes job-specific build directory

# Teardown Phase (after_script in GitLab CI)
./ci_e2c_manager.sh teardown
# → Stops (existing) or terminates (template) instance
# → Removes state file
```

#### State Persistence Across CI Phases

GitLab CI runs `before_script`, `script`, and `after_script` in separate shell sessions. State is persisted via file:

```bash
# State file format (.e2c_instance_state_${CI_JOB_ID})
TARGET_INSTANCE_ID=i-0123456789abcdef0
E2C_PUBLIC_IP=54.123.45.67
E2C_INSTANCE_STRATEGY=template
```

#### Required CI/CD Variables

```yaml
# AWS Credentials
AWS_ACCESS_KEY_ID: "..."
AWS_SECRET_ACCESS_KEY: "..."
AWS_DEFAULT_REGION: "eu-north-1"

# E2C Configuration
E2C_INSTANCE_STRATEGY: "template"
E2C_LAUNCH_TEMPLATE_ID: "lt-08c7ea1a2658e52f7"
E2C_SSH_USER: "admin"
E2C_SSH_PRIVATE_KEY: "base64-encoded-private-key"
E2C_BUILD_DIR: "~/builds"

# Optional for Spot Instances
E2C_USE_SPOT: "true"
E2C_SPOT_MAX_PRICE: "0.10"
```
