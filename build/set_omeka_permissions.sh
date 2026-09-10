# !/command/with-contenv bash
# Give the application user ownership + write permission on the data directories.
# Uses otd_chown_data_dirs() from 00-otd-lib.sh (root-only, no-op otherwise).

echo "Setting permissions for files and logs ..."
otd_chown_data_dirs
chmod -R 0775 /volume/files /volume/logs 2>/dev/null || true

if [ "${OMEKA_S_ALLOW_EASY_ADMIN:-0}" -eq "1" ]; then
    echo "Setting permissions for modules and themes ..."
    otd_chown_data_dirs /volume/modules /volume/themes
    chmod -R 0775 /volume/modules /volume/themes 2>/dev/null || true
fi
