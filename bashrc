if [ -n "$WSL_INTEROP" ] && [ -z "$XDG_RUNTIME_DIR" ]; then
    exec /usr/bin/enter-systemd-namespace bash $*
fi