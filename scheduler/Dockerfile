FROM alpine:3.19.1

RUN apk --no-cache add bash coreutils alpine-conf docker \
    && setup-timezone -z CET

COPY run.sh /run.sh

ENTRYPOINT [ "/run.sh" ]
