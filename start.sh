#!/bin/bash
set -e
echo "[start] hello-micro-nezha starting, PORT=${PORT:-5000}"

# --- Nezha v1 agent (optional, only if env vars are set) ---
# Expected env vars (set in Abasthan dashboard, NOT in this repo):
#   NZ_SERVER=39.98.89.122:50001
#   NZ_TLS=false
#   NZ_CLIENT_SECRET=<from panel install command>
#   NZ_UUID=<server UUID from panel install command, optional — if empty a UUID is generated once and saved to ./nezha-uuid for reuse>
# UUID: prefer env var, else reuse saved file, else generate once
if [ -z "$NZ_UUID" ] && [ -f ./nezha-uuid ]; then
  NZ_UUID=$(cat ./nezha-uuid)
  echo "[nezha] reusing saved UUID from ./nezha-uuid"
fi
if [ -z "$NZ_UUID" ]; then
  if [ -f /proc/sys/kernel/random/uuid ]; then
    NZ_UUID=$(cat /proc/sys/kernel/random/uuid)
  else
    NZ_UUID=$(python3 -c "import uuid; print(uuid.uuid4())")
  fi
  echo "$NZ_UUID" > ./nezha-uuid
  echo "[nezha] generated new UUID and saved to ./nezha-uuid (panel will show it as a new server)"
fi
if [ -n "$NZ_SERVER" ] && [ -n "$NZ_CLIENT_SECRET" ] && [ -n "$NZ_UUID" ]; then
  echo "[nezha] env vars present, preparing agent..."
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) NZ_ARCH="amd64" ;;
    aarch64|arm64) NZ_ARCH="arm64" ;;
    *) echo "[nezha] unsupported arch $ARCH, skipping agent"; NZ_ARCH="" ;;
  esac
  if [ -n "$NZ_ARCH" ]; then
    if [ ! -f ./nezha-agent ]; then
      echo "[nezha] downloading agent v1.15.0 linux_${NZ_ARCH}..."
      # prefer curl, fall back to wget
      if command -v curl >/dev/null 2>&1; then
        curl -L -o /tmp/nezha-agent.zip "https://github.com/nezhahq/agent/releases/download/v1.15.0/nezha-agent_linux_${NZ_ARCH}.zip"
      else
        wget -O /tmp/nezha-agent.zip "https://github.com/nezhahq/agent/releases/download/v1.15.0/nezha-agent_linux_${NZ_ARCH}.zip"
      fi
      # unzip (python fallback if unzip missing)
      if command -v unzip >/dev/null 2>&1; then
        unzip -o /tmp/nezha-agent.zip -d /tmp/nezha-extract
      else
        python3 -c "import zipfile; zipfile.ZipFile('/tmp/nezha-agent.zip').extractall('/tmp/nezha-extract')"
      fi
      cp /tmp/nezha-extract/nezha-agent ./nezha-agent
      chmod +x ./nezha-agent
      rm -rf /tmp/nezha-agent.zip /tmp/nezha-extract
      echo "[nezha] agent downloaded"
    else
      echo "[nezha] agent binary already present, reusing"
    fi

    TLS_VAL="${NZ_TLS:-false}"
    cat > config.yml <<EOF
client_secret: ${NZ_CLIENT_SECRET}
debug: false
disable_auto_update: true
disable_command_execute: false
disable_force_update: true
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: false
ip_report_period: 1800
report_delay: 1
server: ${NZ_SERVER}
skip_connection_count: false
skip_procs_count: false
temperature: false
tls: ${TLS_VAL}
use_gitee_to_upgrade: false
use_ipv6_country_code: false
uuid: ${NZ_UUID}
EOF
    echo "[nezha] config.yml written, server=${NZ_SERVER} tls=${TLS_VAL} uuid=${NZ_UUID}"
    # run in background, log to nezha-agent.log
    nohup ./nezha-agent -c config.yml > nezha-agent.log 2>&1 &
    echo "[nezha] agent started pid $!"
    sleep 2
    cat nezha-agent.log || true
  fi
else
  echo "[nezha] NZ_SERVER / NZ_CLIENT_SECRET / NZ_UUID not all set, skipping agent (web app still runs)"
fi

# --- Web app (foreground, keeps container alive) ---
echo "[start] starting node app..."
exec node index.js
