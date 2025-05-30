FROM i386/ubuntu:18.04
COPY entrypoint.sh /entrypoint.sh
RUN apt-get update && apt-get -y install curl && curl -o /bin/rebol https://static.red-lang.org/tmp/rebol && chmod +x /bin/rebol
ENTRYPOINT ["/entrypoint.sh"]
