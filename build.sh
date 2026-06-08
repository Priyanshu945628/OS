#!/bin/bash
# AegisOS Custom ISO Builder
# Must be executed as root (or via sudo) on an Arch Linux system or inside the Docker container.

set -euo pipefail

# Visual headers
echo -e "\033[1;36m====================================================\033[0m"
echo -e "\033[1;36m                 AEGIS OS - BUILDER                 \033[0m"
echo -e "\033[1;36m====================================================\033[0m"

# 1. Self root-check
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[1;31m[-] Error: This script must be run as root or using sudo.\033[0m"
    exit 1
fi

# 2. Dependency checks
echo -e "\033[1;34m[*] Verifying build tools...\033[0m"
command -v mkarchiso >/dev/null 2>&1 || {
    echo -e "\033[1;31m[-] Error: 'mkarchiso' is missing. Install it with: pacman -S archiso\033[0m"
    exit 1
}

# 3. Directories setup
PROFILE_DIR="./profile"
WORK_DIR="/tmp/archiso-aegis"
OUT_DIR="./out"

if [ ! -d "$PROFILE_DIR" ]; then
    echo -e "\033[1;31m[-] Error: Profile directory '$PROFILE_DIR' not found. Make sure you are in the workspace root.\033[0m"
    exit 1
fi

# 4. Clean previous builds
echo -e "\033[1;34m[*] Cleaning up previous temporary build files...\033[0m"
rm -rf "$WORK_DIR"
mkdir -p "$OUT_DIR"

# 5. Execute compilation
echo -e "\033[1;32m[*] Commencing compilation of AegisOS ISO...\033[0m"
echo -e "\033[1;32m[*] Working Directory: $WORK_DIR\033[0m"
echo -e "\033[1;32m[*] Output ISO Path:   $OUT_DIR/\033[0m"
echo -e ""

# Execute the compiler. We enforce the linux-hardened profile logic.
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"

echo -e ""
echo -e "\033[1;32m[+] Success! AegisOS ISO compilation finished.\033[0m"
echo -e "\033[1;36m[+] ISO location: $OUT_DIR/$(ls -t $OUT_DIR | head -n 1)\033[0m"
echo -e "\033[1;36m====================================================\033[0m"
