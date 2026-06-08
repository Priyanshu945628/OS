# Automatically start Sway graphical environment on tty1 login for arch user
if [ -z "$DISPLAY" ] && [ "${XDG_VTNR:-0}" -eq 1 ] && [ "$USER" = "arch" ]; then
    exec sway
fi
