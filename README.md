# AegisOS - Build & Configuration System

AegisOS is a highly secured, privacy-focused, custom Linux-based operating system designed to run Linux, Android, and Windows applications natively and sandboxed. It uses Arch Linux as its base and compiles into a bootable ISO.

## Core Features

- **Maximum Isolation & Hardening**: Utilizes the `linux-hardened` kernel, kernel-level sysctl restrictions (disabled ptrace, core dumps, restricted dmesg), and AppArmor profiles.
- **Keylogger Mitigation**: Uses the modern **Sway** tiling window manager running natively on **Wayland** (X11 is vulnerable to root-level keyloggers; Wayland blocks cross-window input snooping).
- **Leak-Proof Network Containment**:
  - **Tor Transparent Proxy**: Automatically reroutes all TCP and DNS traffic through onion nodes while dropping UDP/ICMP to prevent DNS and location leaks.
  - **Dynamic MAC Spoofing**: Randomizes MAC addresses on all network cards before interfaces connect.
  - **Drop-by-Default Firewall**: Hardened stateful `nftables` blocking incoming probes.
- **Multilingual App Compatibility**:
  - **Linux Apps**: Run sandboxed via native Flatpak.
  - **Android Apps**: Run natively via **Waydroid** inside a secure LXC container on the shared host kernel (retaining GPU acceleration).
  - **Windows Apps**: Containerized via **Wine/Bottles** inside a Flatpak container, completely isolated from user home directories (drive mapping linkages broken to protect native files from potential Windows malware).

---

## Directory Structure

```
d:\Temp\OS\
├── build.sh                 # Native Arch compile orchestrator
├── Dockerfile               # Dockerized builder environment
├── README.md                # This manual
├── dashboard.html           # Interactive Customizer UI Dashboard
└── profile/                 # Archiso compile profile
    ├── packages.x86_64      # Package list to install in ISO
    ├── pacman.conf          # System pacman dependencies manager
    └── airootfs/            # Custom files injected into the root filesystem
        ├── etc/
        │   ├── sysctl.d/
        │   │   └── 99-security-hardening.conf  # Kernel hardening configuration
        │   ├── systemd/
        │   │   └── system/
        │   │       └── mac-spoof@.service      # Dynamic MAC spoofing service
        │   ├── security/
        │   │   └── limits.d/
        │   │       └── 99-disable-coredumps.conf # Global core dump blocker
        │   ├── nftables.conf                   # Stateful containment firewall
        │   └── skel/                           # User desktop configurations
        │       └── .config/
        │           ├── sway/
        │           │   └── config              # Sway window manager keys & theme
        │           └── waybar/
        │               ├── config              # Waybar module layouts
        │               └── style.css           # Glassmorphic top-bar styling
        └── usr/local/bin/
            ├── aegis-install                   # Full Disk Encrypted LUKS2 installer
            ├── aegis-waydroid-setup            # Android container builder
            ├── aegis-wine-setup                # Secure Wine Prefix configuration
            └── aegis-tor-toggle                # Tor transparent router toggler
```

---

## How to Customize

Double-click `dashboard.html` to launch the **AegisOS Builder Dashboard** in your web browser. 
This premium interactive interface allows you to:
1. Toggle components (Android Waydroid, Windows Wine, Tor Proxy, MAC Spoofing).
2. Choose your base kernel.
3. Automatically preview the generated configuration files.
4. Download your customized configuration.

---

## How to Build the ISO

### Method A: Docker Container (Recommended for Windows / Non-Arch systems)

Docker handles all system hooks and dependencies. Note that since `mkarchiso` mounts loops and creates file nodes, the build command requires the `--privileged` flag:

1. **Build the compiler container**:
   ```bash
   docker build -t aegis-builder .
   ```

2. **Execute compilation**:
   On Windows PowerShell:
   ```powershell
   docker run --privileged --rm -v ${PWD}:/build aegis-builder ./build.sh
   ```
   On Linux/macOS Terminal:
   ```bash
   docker run --privileged --rm -v $(pwd):/build aegis-builder ./build.sh
   ```

The compiled bootable ISO will be saved in the `./out/` folder.

### Method B: Native Arch Linux Host

If you are running Arch Linux or an Arch-based system natively:

1. **Install requirements**:
   ```bash
   sudo pacman -S archiso
   ```

2. **Run compilation**:
   ```bash
   sudo ./build.sh
   ```

---

## Post-Installation Runtimes

Once you boot into the AegisOS live session, run the installer:
- **Install AegisOS**: Launch `sudo aegis-install` to set up partitioning and LUKS2 Full Disk Encryption.

Once installed and booted:
- **Set up Android Apps**: Run `sudo aegis-waydroid-setup` to initialize Waydroid.
- **Set up Windows Apps**: Run `aegis-wine-setup` to configure sandboxed WinePrefixes or install Bottles.
- **Toggle Tor transparent routing**: Run `sudo aegis-tor-toggle on` (or `off` to deactivate).
