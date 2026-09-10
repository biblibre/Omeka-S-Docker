# !/command/with-contenv bash
# Last startup script:
#   - authoritative ownership pass on the data directories (the core install and
#     module setup run as root and may have created root-owned files there);
#   - drops a "provisioning done" marker.
# The primary mechanism for `otd --wait-ready` remains the container healthcheck.
#
# NB: this file is *sourced* by the webdevops entrypoint -> no `exit`.

otd_chown_data_dirs

touch /tmp/omeka_ready 2>/dev/null || true
echo "Omeka-S-Docker: provisioning done."
