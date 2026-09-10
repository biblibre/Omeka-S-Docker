# !/command/with-contenv bash
# Shared helpers for the /entrypoint.d hooks. Sourced first (00-), defines
# functions only: no `set -e`, no `exit`.

# chown -R the writable Omeka data directories to the application user.
# Always covers logs/files/config; extra directories can be passed as args.
# No-op when the container is not running as root.
otd_chown_data_dirs() {
    [ "$(id -u)" = "0" ] || return 0
    local d
    for d in /volume/logs /volume/files /volume/config "$@"; do
        [ -d "$d" ] && chown -R application:application "$d" 2>/dev/null || true
    done
}
