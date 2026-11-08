#!/bin/bash

# Replaces ; with a single space which makes it parse into an array.
# The elements must not contain spaces.
container_names=(${CONTAINER_NAMES//;/ })

# Reports the state of a container to Home Assistant (0 = running, 1 = success, 2 = error).
# Skipped if no webhook URL is configured. Times out so a hanging Home Assistant can't block the backups.
report_state() {
    [ -z "$HASS_WEBHOOK_URL" ] && return
    curl -fsS --max-time 10 -X PUT -F "container_name=$1" -F "state=$2" "$HASS_WEBHOOK_URL" \
        || echo "Failed to report state $2 for $1 to Home Assistant"
}

while true; do
    # What until the specified time each day and then sequentially execute the command with the given delay inbetween each container
    sleep $((($(date -f - +%s- <<<$START_TIME$' tomorrow\nnow')0)%86400))
    for container_name in "${container_names[@]}"; do
        echo "============================================================================="
        echo "`date "+%Y-%m-%d %H:%M:%S"` $container_name: Executing $COMMAND"

        # Report start of command
        report_state "$container_name" 0

        docker exec "$container_name" sh -c "$COMMAND"
        if [ $? -eq 0 ]; then
            state=1 # Success
        else
            state=2 # Error
        fi

        # Report end of command with state
        report_state "$container_name" "$state"

        echo "`date "+%Y-%m-%d %H:%M:%S"`: Command finished"
        echo "============================================================================="
        sleep "$SLEEP_INTERVAL"
    done
done
