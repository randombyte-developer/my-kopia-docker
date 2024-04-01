FROM kopia/kopia:0.15.0

ENV DEBIAN_FRONTEND="noninteractive" \
    TERM="xterm-256color" \
    LC_ALL="C.UTF-8" \
    KOPIA_CONFIG_PATH=/app/config/repository.config \
    KOPIA_LOG_DIR=/app/logs \
    KOPIA_CACHE_DIRECTORY=/app/cache \
    KOPIA_PERSIST_CREDENTIALS_ON_CONNECT=true \
    KOPIA_CHECK_FOR_UPDATES=false \
    TZ=CET

# According to the Docker image best practices docs an apt clean is automatically run for Ubuntu images (which kopia uses)
# https://docs.docker.com/develop/develop-images/instructions/#apt-get
RUN apt-get update && apt-get install -y cifs-utils && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh

ENTRYPOINT [ "/run.sh" ]
