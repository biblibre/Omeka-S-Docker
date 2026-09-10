#!/bin/bash
# set -e
# trap 'echo "An# error occurred. Exiting..."; exit 1;' ERR

OSC="omeka-s-cli"

# Wait for database to be available
wait_for_db() {
    echo "Waiting for database to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if mysql -h"${MYSQL_HOST:-db}" -P"${MYSQL_PORT:-3306}" -u"${MYSQL_USER:-omeka}" -p"${MYSQL_PASSWORD:-omeka}" -e "SELECT 1;" >/dev/null 2>&1; then
            echo "Database is ready!"
            return 0
        fi
        echo "Database not ready, attempt $attempt/$max_attempts. Waiting 5 seconds..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: Database failed to become ready after $max_attempts attempts"
    exit 1
}
wait_for_db

# install omeka core?
INSTALL_ARGS=""
if [ "${OMEKA_S_INSTALL_CORE:-0}" -eq "1" ]; then

    # check if core is installed
    if $OSC core:status --base-path /var/www/omeka-s | grep -q "^installed"; then
        echo "Omeka S core is already installed. Skipping installation."
    else
        # install core
        echo "Installing Omeka S core ..."
        $OSC core:install \
            --admin-name "${OMEKA_S_ADMIN_NAME:-admin}" \
            --admin-email "${OMEKA_S_ADMIN_EMAIL:-admin@example.com}" \
            --admin-password "${OMEKA_S_ADMIN_PASSWORD:-admin}" \
            --title "${OMEKA_S_TITLE:-Omeka S}" \
            --time-zone "${OMEKA_S_TIME_ZONE:-UTC}" \
            --locale "${OMEKA_S_LOCALE:-en_US}" \
            --base-path /var/www/omeka-s
    fi
fi

# Install/enable modules. Delegates to the shared `modules-install` helper.
#  - OMEKA_S_MODULES     : registry ids or ZIP URLs, installed when
#                          OMEKA_S_INSTALL_MODULES=1
#  - OMEKA_S_DEV_MODULES : host-mounted modules (otd --module), always installed
if [ "${OMEKA_S_INSTALL_MODULES:-0}" -eq "1" ] && [ -n "${OMEKA_S_MODULES:-}" ]; then
    modules-install ${OMEKA_S_MODULES}
fi
if [ -n "$(echo "${OMEKA_S_DEV_MODULES:-}" | tr -d ' ')" ]; then
    modules-install ${OMEKA_S_DEV_MODULES}
fi

# apply any pending core/database migrations (no-op right after a fresh install)
$OSC core:migrate --base-path /var/www/omeka-s || true

# todo: import resource templates
# todo: import vocabularies
