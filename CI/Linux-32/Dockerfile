# 32-bit (i386) test environment for Red/System.
#
# Base is Debian 12 (bookworm) i386 rather than Ubuntu 18.04: Debian still
# ships a *full* i386 architecture (security support until 2026, LTS until
# 2028), while Ubuntu keeps only a whitelist of i386 packages and bionic has
# been EOL since 2023.
#
# Rebol2 is downloaded in a separate stage built on a tiny *native* Alpine
# image, so this build never runs apt-get and never touches a distro mirror.
# That network dependency used to be the main source of CI failures.
FROM alpine:3.20 AS rebol-fetch

RUN set -eux; \
    for attempt in 1 2 3; do \
        if wget -q -O /rebol https://static.red-lang.org/tmp/rebol; then break; fi; \
        echo "rebol download failed (attempt $attempt), retrying..."; \
        sleep 3; \
    done; \
    test -s /rebol; \
    chmod +x /rebol

FROM i386/debian:12-slim

COPY --from=rebol-fetch /rebol /bin/rebol
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
