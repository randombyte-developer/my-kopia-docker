FROM alpine:3.19.1

RUN apk --no-cache add docker

COPY run.sh /run.sh

ENTRYPOINT [ "/run.sh" ]
