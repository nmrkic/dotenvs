variable "APP_VERSION" {
    default = "latest"
}

group "default" {
    targets = [
        "__SERVICE__-amd64",
        "__SERVICE__-arm64"
    ]
}

# Repeat this pair for every service in the CI build matrix. The target name
# must be exactly "<service>-amd64" / "<service>-arm64" and the tag
# "<registry>/<service>:latest-<arch>", because the pipeline calls
# `docker buildx bake $SERVICE-<arch>` and retags that image.

target "__SERVICE__-amd64" {
    context = "./"
    dockerfile = "__SERVICE__/Dockerfile"
    platforms = ["linux/amd64"]
    tags = [
        "reg.bwl.rs/__PROJECT__/__SERVICE__:latest-amd64"
    ]
    push = true
}

target "__SERVICE__-arm64" {
    context = "./"
    dockerfile = "__SERVICE__/Dockerfile"
    platforms = ["linux/arm64"]
    tags = [
        "reg.bwl.rs/__PROJECT__/__SERVICE__:latest-arm64"
    ]
    push = true
}
