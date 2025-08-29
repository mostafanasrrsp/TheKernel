# RadiateOS PC Build - HP Pavilion Intel Core i7 + NVIDIA GPU
FROM ubuntu:22.04 AS builder

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV KERNEL_VERSION=6.5.0
ENV NVIDIA_DRIVER_VERSION=545.29.06

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    git \
    wget \
    curl \
    libncurses-dev \
    flex \
    bison \
    libssl-dev \
    libelf-dev \
    libudev-dev \
    libpci-dev \
    libiberty-dev \
    autoconf \
    bc \
    rsync \
    kmod \
    cpio \
    xz-utils \
    fakeroot \
    libfdt-dev \
    libglib2.0-dev \
    libpixman-1-dev \
    zlib1g-dev \
    ninja-build \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python3-mako \
    glslang-tools \
    libglvnd-dev \
    libx11-dev \
    libxext-dev \
    libwayland-dev \
    wayland-protocols \
    libxcb1-dev \
    libxcb-keysyms1-dev \
    libxcb-image0-dev \
    libxcb-shm0-dev \
    libxcb-icccm4-dev \
    libxcb-sync-dev \
    libxcb-xfixes0-dev \
    libxcb-shape0-dev \
    libxcb-randr0-dev \
    libxcb-render-util0-dev \
    libxcb-util-dev \
    libxcb-xinerama0-dev \
    libxcb-xkb-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    mesa-utils \
    vulkan-tools \
    libvulkan-dev \
    isolinux \
    syslinux \
    syslinux-utils \
    dosfstools \
    squashfs-tools \
    genisoimage \
    memtest86+ \
    casper \
    lupin-casper \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub2-common \
    mtools \
    binutils \
    debhelper \
    dh-make \
    devscripts \
    xorriso \
    && rm -rf /var/lib/apt/lists/*

# Install Swift for Linux
RUN wget -q -O - https://download.swift.org/swift-5.9.2-release/ubuntu2204/swift-5.9.2-RELEASE/swift-5.9.2-RELEASE-ubuntu22.04.tar.gz | tar -xz -C / --strip-components=1

# Download and prepare Linux kernel source
WORKDIR /usr/src
RUN wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz && \
    tar -xf linux-${KERNEL_VERSION}.tar.xz && \
    rm linux-${KERNEL_VERSION}.tar.xz

# Copy kernel configuration
COPY kernel/kernel_config /usr/src/linux-${KERNEL_VERSION}/.config

# Copy RadiateOS source code
COPY RadiateOS /opt/radiateos
COPY Sources /opt/radiateos-sources
COPY scripts /opt/scripts

# Build directory
WORKDIR /build

# Entry point for building
CMD ["/bin/bash"]