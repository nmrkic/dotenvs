variable "APP_VERSION" {
    default = "latest"
}

# Set in docker-bake.override.hcl or passed by the pipeline (see the
# docker-bake skill).
variable "REGISTRY" {
    default = "registry.example.com/project"
}

group "default" {
    targets = [
        "__SERVICE__-amd64",
        "__SERVICE__-arm64"
    ]
}

# Repeat this pair for every frontend app in the CI build matrix. The target
# name must be exactly "<service>-amd64" / "<service>-arm64" and the tag
# "<registry>/<service>:latest-<arch>", because the pipeline calls
# `docker buildx bake $SERVICE-<arch>` and retags that image.
# `args` are the build args of the repo's Dockerfile; drop the block when the
# Dockerfile takes none.

target "__SERVICE__-amd64" {
    context = "./"
    dockerfile = "Dockerfile"
    platforms = ["linux/amd64"]
    args = {
        APP_NAME = "__APP_NAME__"
        PORT     = "__PORT__"
    }
    tags = [
        "${REGISTRY}/__SERVICE__:latest-amd64"
    ]
    push = true
}

target "__SERVICE__-arm64" {
    context = "./"
    dockerfile = "Dockerfile"
    platforms = ["linux/arm64"]
    args = {
        APP_NAME = "__APP_NAME__"
        PORT     = "__PORT__"
    }
    tags = [
        "${REGISTRY}/__SERVICE__:latest-arm64"
    ]
    push = true
}
