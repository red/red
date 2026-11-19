# 32-bit (i386) test environment for Red/View (GTK3 + Xvfb).
#
# Design notes:
#  * Rebol2 is downloaded in a separate stage built on a tiny *native* Alpine
#    image, so the 32-bit stage no longer needs the `curl` package at all.
#  * Ubuntu 18.04 is EOL and its mirrors are slow/flaky from hosted runners.
#    `APT::Update::Error-Mode=any` makes `apt-get update` fail on a partial
#    index download (it normally only warns), and the whole update+install is
#    retried so a single bad mirror does not fail the build.
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

ENV DISPLAY=:0 \
    DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    ok=0; \
    for attempt in 1 2 3 4 5; do \
        if apt-get -o Acquire::Retries=5 -o Acquire::http::Timeout=30 \
                   -o APT::Update::Error-Mode=any update \
        && apt-get -o Acquire::Retries=5 -o Acquire::http::Timeout=30 -y install \
                   ca-certificates libcurl4 libgtk-3-0 xvfb; then \
            ok=1; break; \
        fi; \
        echo "apt failed (attempt $attempt), retrying..."; \
        sleep 5; \
    done; \
    test "$ok" = 1; \
    rm -rf /var/lib/apt/lists/*

COPY --from=rebol-fetch /rebol /bin/rebol
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
