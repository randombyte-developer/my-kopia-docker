#!/bin/bash

# Replaces ; with a single space which makes it parse into an array.
# The elements must not contain spaces.
container_names=(${CONTAINER_NAMES//;/ })

while true; do
    # What until 00:10 each day and then sequentially execute the command with the specified delay inbetween each container
    sleep $((($(date -f - +%s- <<<$START_TIME$' tomorrow\nnow')0)%86400))
    for container_name in "${container_names[@]}"; do
        # Check if the container exists (might be down due to maintenance)
        container_id=$(docker ps --filter "name=$container_name" --format "{{.ID}}")
        echo "============================================================================="
        echo "`date "+%Y-%m-%d %H:%M:%S"` $container_name $container_id: Executing $COMMAND"
        docker exec "$container_id" sh -c "$COMMAND"
        echo "`date "+%Y-%m-%d %H:%M:%S"`: Command finished"
        echo "============================================================================="
        sleep "$SLEEP_INTERVAL"
    done
done
