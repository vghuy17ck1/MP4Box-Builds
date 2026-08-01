FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends bash build-essential ca-certificates cmake curl file git jq make perl pkg-config python3 python3-pip unzip zip xz-utils zlib1g-dev libssl-dev ffmpeg clang lld llvm gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 binutils-mingw-w64-x86-64 musl-tools && rm -rf /var/lib/apt/lists/*
WORKDIR /src/MP4Box-Builds
