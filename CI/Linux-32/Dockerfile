# 32-bit (i386) test environment for Red/System.
#
# Design notes:
#  * Rebol2 is downloaded in a separate stage built on a tiny *native* Alpine
#    image. This removes `apt-get` (and therefore archive.ubuntu.com) from the
#    build completely - the flaky step that used to break CI.
#  * The final stage only adds COPY layers on top of i386/ubuntu:18.04, so it
#    builds in about a second and never needs network access.
FROM alpine:3.20 AS rebol-fetch

RUN set -eux; \
    for attempt in 1 2 3; do \
        if wget -q -O /rebol https://static.red-lang.org/tmp/rebol; then break; fi; \
        echo "rebol download failed (attempt $attempt), retrying..."; \
        sleep 3; \
    done; \
    test -s /rebol; \
    chmod +x /rebol

FROM i386/ubuntu:18.04

COPY --from=rebol-fetch /rebol /bin/rebol
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
