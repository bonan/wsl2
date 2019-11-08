if test -n "$WSL_INTEROP"
    if test -z "$XDG_RUNTIME_DIR"
        set cmdline (string split0 < /proc/self/cmdline)
        exec enter-systemd-namespace fish $cmdline[2..-1]
    end
end
