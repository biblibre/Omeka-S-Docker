# !/command/with-contenv bash
# Align the image's "application" user with the host UID/GID so that files
# written to the mounted volumes stay editable from the host.
# Driven by LOCAL_UID / LOCAL_GID (injected by the `otd` wrapper).
#
# NB: this file is *sourced* by the webdevops entrypoint -> no `set -e`,
# no `exit`, everything wrapped in a function.

__otd_fix_uid() {
    if [ "$(id -u)" != "0" ]; then
        echo "[fix_uid] container is not root, nothing to do"
        return 0
    fi

    local target_uid="${LOCAL_UID:-1000}"
    local target_gid="${LOCAL_GID:-1000}"
    local app_user="application"

    case "$target_uid" in ''|*[!0-9]*) echo "[fix_uid] invalid LOCAL_UID, skipping"; return 0 ;; esac
    case "$target_gid" in ''|*[!0-9]*) echo "[fix_uid] invalid LOCAL_GID, skipping"; return 0 ;; esac

    local cur_uid cur_gid
    cur_uid="$(id -u "$app_user" 2>/dev/null)" || { echo "[fix_uid] user '$app_user' not found"; return 0; }
    cur_gid="$(id -g "$app_user" 2>/dev/null)"

    if [ "$cur_gid" != "$target_gid" ]; then
        echo "[fix_uid] group $app_user: $cur_gid -> $target_gid"
        groupmod -o -g "$target_gid" "$app_user" 2>/dev/null || true
    fi
    if [ "$cur_uid" != "$target_uid" ]; then
        echo "[fix_uid] user $app_user: $cur_uid -> $target_uid"
        usermod -o -u "$target_uid" "$app_user" 2>/dev/null || true
    fi

    # Make the mount points traversable now; 70- and 90- do the recursive pass.
    local d
    for d in /volume /var/www/omeka-s; do
        [ -e "$d" ] && chown "$target_uid:$target_gid" "$d" 2>/dev/null || true
    done
}

__otd_fix_uid
unset -f __otd_fix_uid
