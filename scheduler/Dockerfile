FROM alpine:3.24.4

RUN apk --no-cache add bash coreutils curl docker-cli tzdata

ENV TZ=Europe/Berlin

COPY run.sh /run.sh

ENTRYPOINT [ "/run.sh" ]
