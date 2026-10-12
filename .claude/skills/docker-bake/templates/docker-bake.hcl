variable "APP_VERSION" {
    default = "latest"
}

# Registry host + project. Not stored in the repository: set it in
# docker-bake.override.hcl (see docker-bake.override.hcl.example) or pass
# REGISTRY from the environment.
variable "REGISTRY" {
    default = "registry.example.com/project"
}

# `docker buildx bake --push` builds every service for amd64 + arm64 and pushes
# one manifest per service, tagged $APP_VERSION and latest.
group "default" {
    targets = [
        "__SERVICE__"
    ]
}

# The "<service>-amd64" / "<service>-arm64" targets are for the CI pipeline,
# which builds each architecture on its own runner
# (`docker buildx bake $SERVICE-<arch>`) and joins them into a manifest itself.

# Repeat these three targets for every service.

# ---- __SERVICE__ ----
target "__SERVICE__" {
    context = "__CONTEXT__"
    dockerfile = "__DOCKERFILE__"
    platforms = ["linux/amd64", "linux/arm64"]
    tags = [
        "${REGISTRY}/__SERVICE__:${APP_VERSION}",
        "${REGISTRY}/__SERVICE__:latest"
    ]
    attest = ["type=provenance,disabled=true"]
}

target "__SERVICE__-amd64" {
    context = "__CONTEXT__"
    dockerfile = "__DOCKERFILE__"
    platforms = ["linux/amd64"]
    tags = [
        "${REGISTRY}/__SERVICE__:latest-amd64"
    ]
    push = true
}

target "__SERVICE__-arm64" {
    context = "__CONTEXT__"
    dockerfile = "__DOCKERFILE__"
    platforms = ["linux/arm64"]
    tags = [
        "${REGISTRY}/__SERVICE__:latest-arm64"
    ]
    push = true
}
