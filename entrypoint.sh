#! /bin/bash

DHPARAM_SIZE_DEFAULT=2048

die() { echo "$@" 1>&2 ; exit 1; }

log() {
  if [[ "$@" ]]; then echo "[`date +'%Y-%m-%d %T'`] $@";
  else echo; fi
}

# Generate nginx DH for use with SSL
generateDHParam() {
  if [ ! -n "${DHPARAM_SIZE}" ]; then
    log "No \$KEYSIZE provided, using default with size ${DHPARAM_SIZE_DEFAULT}"
    DHPARAM_SIZE=${DHPARAM_SIZE_DEFAULT}
  fi
  log "dhparam file /etc/nginx/dhparam/dhparam.pem does not exist. Generating one with ${DHPARAM_SIZE} bits. This will take a while..."
  openssl dhparam -out /etc/nginx/dhparam/dhparam.pem "${DHPARAM_SIZE}"  || die "Could not generate dhparam file"
  log "Finished dhparam generation."
}

# Generate nginx sub configuration file based on server names
generateConfiguration() {
  # Set server names
  if [ ! -n "${NGINX_SERVERNAMES}" ]; then
    die "No Server name provided in variable \$NGINX_SERVERNAMES , exiting."
  fi
  IFS=':' read -r -a servers <<< "${NGINX_SERVERNAMES}"

  # Erase previous configuration
  rm -rf /etc/nginx/servers
  mkdir /etc/nginx/servers

  # function variables
  LETSENCRYPT_WATCH_PATH=/etc/letsencrypt
  LETSENCRYPT_ROOT_CERTIFICATE_PATH=/etc/letsencrypt/live

  # Configure nginx without SSL if letsencrypt is not plugged and if there is no certificates
  if [ ! -d /var/acme-webroot ] && [ ! -d "${LETSENCRYPT_ROOT_CERTIFICATE_PATH}" ]; then
    sed "s/NGINX_SERVERNAMES/${servers[*]}/g" /etc/nginx/server.conf.model > "/etc/nginx/servers/server-${servers[0]}.conf"
    LETSENCRYPT_WATCH_PATH=
    return
  fi

  # Configure nginx with SSL if certificates are existing
  CERTIFICATE_PATH="${LETSENCRYPT_ROOT_CERTIFICATE_PATH}/${servers[0]}"
  if [ -f "${CERTIFICATE_PATH}/fullchain.pem" ]; then
    sed -e "s~NGINX_SERVERNAMES~${servers[*]}~g; s~LETSENCRYPT_CERTIFICATE_PATH~$CERTIFICATE_PATH~g" /etc/nginx/server-ssl.conf.model > "/etc/nginx/servers/server-${servers[0]}-ssl.conf"
  fi

  # Configure nginx with Lets encrypt if acme webroot is available
  if [ -d /var/acme-webroot ]; then
    sed "s/NGINX_SERVERNAMES/${servers[*]}/g" /etc/nginx/server-certbot.conf.model > "/etc/nginx/servers/server${servers[0]}-certbot.conf"
  fi

  # Generate dhparam if not existing
  if [ ! -f /etc/nginx/dhparam/dhparam.pem ]; then
    generateDHParam
  fi
}

# Generate nginx configuration
generateConfiguration

# Start nginx
log "Starting nginx."
nginx

# Check if config or certificates were changed
while inotifywait -q -r --exclude '\.git/' -e modify -e create -e delete /etc/nginx "${LETSENCRYPT_WATCH_PATH}"; do
  log "Configuration changes detected. Updating nginx configuration."
  sleep 1s
  generateConfiguration
  nginx -s reload && log "Reload signal sent"
done
