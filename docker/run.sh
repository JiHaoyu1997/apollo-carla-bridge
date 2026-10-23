#!/usr/bin/env bash
set -eo pipefail
bridge_name=${BRIDGE_CONTAINER:-apollo_carla_bridge}
bridge_image=${BRIDGE_IMAGE:-apollo-carla-bridge:dev}
# Do not replace an existing container or change the Apollo container.
if docker container inspect "$bridge_name" >/dev/null 2>&1; then
    echo "Container $bridge_name already exists. Use docker start -ai $bridge_name, or choose BRIDGE_CONTAINER." >&2
    exit 1
fi
docker run -d --init --name "$bridge_name" --network bridge \
    --shm-size=512m -e "CYBER_DOMAIN_ID=${CYBER_DOMAIN_ID:-80}" \
    "$bridge_image" "$@"
bridge_ip=$(docker inspect -f '{{(index .NetworkSettings.Networks "bridge").IPAddress}}' "$bridge_name")
apollo_ip=$(docker inspect -f '{{(index .NetworkSettings.Networks "bridge").Gateway}}' "$bridge_name")
printf 'Bridge IP: %s\nApollo host-network CYBER_IP: %s\nDomain: %s\n' \
    "$bridge_ip" "$apollo_ip" "${CYBER_DOMAIN_ID:-80}"
printf 'Apollo terminal (after sourcing cyber/setup.bash):\nexport CYBER_IP=%s\nexport CYBER_DOMAIN_ID=%s\ncyber_channel echo channel/chatter\n' \
    "$apollo_ip" "${CYBER_DOMAIN_ID:-80}"
printf 'Bridge logs: docker logs -f %s\n' "$bridge_name"
