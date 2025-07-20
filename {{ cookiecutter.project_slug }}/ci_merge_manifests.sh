#!/bin/sh

# Helper function to add a tag to the list of source images
# $IMAGE_BASENAME-$SERVICE:$IMAGETAG-$PLATFORM_SLUG
add_source_tag() {
    local tag_to_add="$1"
    # Ensure the tag_to_add is not empty
    if [ -n "$tag_to_add" ]; then
        if [ -z "$SOURCE_IMAGE_TAGS" ]; then
            SOURCE_IMAGE_TAGS="$tag_to_add"
        else
            SOURCE_IMAGE_TAGS="$SOURCE_IMAGE_TAGS $tag_to_add"
        fi
    fi
}

# For each service: create a combined manifest from the multiple architectures
for SERVICE in django postgres traefik
    do
        # Construct a space-separated list of source image tags
        # Check the BUILD toggle variables to determine which platforms were actually built
        SOURCE_IMAGE_TAGS=""
        if [ "$BUILD_AMD64" = "true" ] && [ -n "$PLATFORM_SLUG_AMD64" ]; then add_source_tag "$IMAGE_BASENAME-$SERVICE:$IMAGETAG-$PLATFORM_SLUG_AMD64"; fi
        if [ "$BUILD_ARMHF" = "true" ] && [ -n "$PLATFORM_SLUG_ARMHF" ]; then add_source_tag "$IMAGE_BASENAME-$SERVICE:$IMAGETAG-$PLATFORM_SLUG_ARMHF"; fi
        if [ "$BUILD_ARM64" = "true" ] && [ -n "$PLATFORM_SLUG_ARM64" ]; then add_source_tag "$IMAGE_BASENAME-$SERVICE:$IMAGETAG-$PLATFORM_SLUG_ARM64"; fi
        if [ -z "$SOURCE_IMAGE_TAGS" ]; then
            echo "Error: No source image tags found. Check BUILD_AMD64/ARM64/ARMHF variables and ensure at least one platform is enabled." >&2
            exit 1
        fi


        # Use = for string comparison in sh
        if [ "$CI_COMMIT_REF_SLUG" = "master" ]; then
        docker buildx imagetools create \
          -t "$IMAGE_BASENAME-$SERVICE:$IMAGETAG" -t "$IMAGE_BASENAME-$SERVICE:latest" \
          $SOURCE_IMAGE_TAGS # Unquoted to allow word splitting for multiple source images
        else
        docker buildx imagetools create \
          -t "$IMAGE_BASENAME-$SERVICE:$IMAGETAG" \
          $SOURCE_IMAGE_TAGS # Unquoted to allow word splitting for multiple source images
       fi
    done
