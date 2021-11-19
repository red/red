FROM i386/ubuntu:18.04
COPY entrypoint.sh /entrypoint.sh
ENV DISPLAY :0
RUN apt-get update && apt-get -y install curl libcurl4 libgtk-3-0 xvfb && curl -o /bin/rebol https://static.red-lang.org/tmp/rebol && chmod +x /bin/rebol
ENTRYPOINT ["/entrypoint.sh"]
