# AegisOS Docker Builder Image
# Allows building the Arch Linux based AegisOS ISO on non-Arch hosts (Windows, macOS, Ubuntu, etc.)

FROM archlinux:latest

# Update system keyring and install dependencies
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    archiso \
    base-devel \
    git \
    squashfs-tools \
    dosfstools \
    libisoburn \
    lynx \
    grub \
    parted

WORKDIR /build

# Mount point instructions:
# Since mkarchiso mounts loop devices (which requires raw host hardware privileges),
# the container must be run with the --privileged flag.
#
# Compilation command:
# docker build -t aegis-builder .
# docker run --privileged --rm -v ${PWD}:/build aegis-builder ./build.sh
