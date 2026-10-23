# Source inside the image, including docker exec interactive shells.
# Docker bridge mode supplies a container-specific IPv4 address.
if [[ -z ${CYBER_IP:-} ]]; then
    CYBER_IP=$(ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}')
fi
if [[ -z $CYBER_IP || $CYBER_IP == 127.* ]]; then
    echo 'Cannot determine container IPv4 address; set CYBER_IP explicitly.' >&2
    exit 1
fi
export CYBER_IP CYBER_DOMAIN_ID="${CYBER_DOMAIN_ID:-80}"
source /opt/bridge/build/setup.bash
printf 'Bridge CYBER_IP=%s CYBER_DOMAIN_ID=%s\n' "$CYBER_IP" "$CYBER_DOMAIN_ID" >&2
