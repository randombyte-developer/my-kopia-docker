#!/bin/bash

# Replaces ; with a single space which makes it parse into an array.
# The elements must not contain spaces.
container_names=(${CONTAINER_NAMES//;/ })

while true; do
    # What until the specified time each day and then sequentially execute the command with the given delay inbetween each container
    sleep $((($(date -f - +%s- <<<$START_TIME$' tomorrow\nnow')0)%86400))
    for container_name in "${container_names[@]}"; do
        container_id=$(docker ps --filter "name=$container_name" --format "{{.ID}}")
        echo "============================================================================="
        echo "`date "+%Y-%m-%d %H:%M:%S"` $container_name $container_id: Executing $COMMAND"

        # Report start of backup
        curl -X PUT -F "container_name=$container_name" -F "state=0" $HASS_WEBHOOK_URL

        docker exec "$container_id" sh -c "$COMMAND"
        if [ $? -eq 0 ]; then
            state=1 # Success
        else
            state=2 # Error
        fi

        # Report end of backup with state
        curl -X PUT -F "container_name=$container_name" -F "state=$state" $HASS_WEBHOOK_URL

        echo "`date "+%Y-%m-%d %H:%M:%S"`: Command finished"
        echo "============================================================================="
        sleep "$SLEEP_INTERVAL"
    done
done
