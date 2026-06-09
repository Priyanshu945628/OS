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
TEMP_PROFILE="/tmp/aegis-profile-build"

if [ ! -d "$PROFILE_DIR" ]; then
    echo -e "\033[1;31m[-] Error: Profile directory '$PROFILE_DIR' not found. Make sure you are in the workspace root.\033[0m"
    exit 1
fi

# 4. Clean previous builds
echo -e "\033[1;34m[*] Cleaning up previous temporary build files...\033[0m"
rm -rf "$WORK_DIR"
rm -rf "$TEMP_PROFILE"
mkdir -p "$OUT_DIR"

# 5. Merge profile configurations with the official Archiso 'releng' template
echo -e "\033[1;34m[*] Merging custom profile with official Archiso 'releng' template...\033[0m"
RELENG_TEMPLATE="/usr/share/archiso/configs/releng"
if [ ! -d "$RELENG_TEMPLATE" ]; then
    echo -e "\033[1;31m[-] Error: Archiso releng template not found at $RELENG_TEMPLATE.\033[0m"
    exit 1
fi

# Copy the complete template to our temp build folder
cp -r "$RELENG_TEMPLATE" "$TEMP_PROFILE"

# Backup the original template packages list
mv "$TEMP_PROFILE/packages.x86_64" "$TEMP_PROFILE/packages.x86_64.orig"

# Copy our custom configurations on top of the template
cp -r "$PROFILE_DIR"/* "$TEMP_PROFILE"/

# Append the original packages to the end of our custom packages list (prevents missing live system modules)
cat "$TEMP_PROFILE/packages.x86_64.orig" >> "$TEMP_PROFILE/packages.x86_64"
rm -f "$TEMP_PROFILE/packages.x86_64.orig"

# Rewrite standard kernel references to linux-hardened in boot configurations
echo -e "\033[1;34m[*] Adjusting bootloader configurations for linux-hardened...\033[0m"
find "$TEMP_PROFILE" -type f -exec sed -i 's/vmlinuz-linux/vmlinuz-linux-hardened/g' {} + || true
find "$TEMP_PROFILE" -type f -exec sed -i 's/initramfs-linux.img/initramfs-linux-hardened.img/g' {} + || true

# Append execution permissions for our custom scripts in profiledef.sh
echo -e "\033[1;34m[*] Registering secure file permissions in profiledef.sh...\033[0m"
cat << 'EOF' >> "$TEMP_PROFILE/profiledef.sh"

# AegisOS Custom File Permissions
file_permissions+=(
  ["/usr/local/bin/aegis-install"]="0:0:755"
  ["/usr/local/bin/aegis-tor-toggle"]="0:0:755"
  ["/usr/local/bin/aegis-waydroid-setup"]="0:0:755"
  ["/usr/local/bin/aegis-wine-setup"]="0:0:755"
)
EOF

# 6. Execute compilation
echo -e "\033[1;32m[*] Commencing compilation of AegisOS ISO...\033[0m"
echo -e "\033[1;32m[*] Working Directory: $WORK_DIR\033[0m"
echo -e "\033[1;32m[*] Output ISO Path:   $OUT_DIR/\033[0m"
echo -e ""

# Execute the compiler. We enforce the merged profile logic.
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$TEMP_PROFILE"

# Rename the compiled ISO file inside the root container and grant host-level write access
echo -e "\033[1;34m[*] Renaming ISO and setting file permissions...\033[0m"
ISO_FILE=$(ls -t "$OUT_DIR"/*.iso | head -n 1)
mv "$ISO_FILE" "$OUT_DIR/aegis-os-latest.iso"
chmod -R a+rw "$OUT_DIR"

echo -e ""
echo -e "\033[1;32m[+] Success! AegisOS ISO compilation finished.\033[0m"
echo -e "\033[1;36m[+] ISO location: $OUT_DIR/aegis-os-latest.iso\033[0m"
echo -e "\033[1;36m====================================================\033[0m"
