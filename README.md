# hello-micro-nezha

Tiny Hello World (Express) + Nezha v1 agent bundled, for Abasthan Free (512MB / 0.1 vCPU).

This repo contains NO secret. The Nezha secret lives only in Abasthan environment variables.

## Deploy on Abasthan
1. Create App → Web Service, Public Git Repository = this repo URL, Branch = main, Language Node.js Runtime 22
2. Instance Type = **Free**
3. Set env vars in the app settings (do NOT commit them):
   - `NZ_SERVER=39.98.89.122:50001`
   - `NZ_TLS=false`
   - `NZ_CLIENT_SECRET=<from Nezha panel install command>`
   - `NZ_UUID=<server UUID from panel install command>`
4. Deploy. `start.sh` downloads nezha-agent v1.15.0 (linux amd64/arm64) on first start, writes `config.yml`, runs the agent in background, then runs the Node app in foreground.

## Notes / limits
- Free instance sleeps after inactivity, so the probe will show offline in the Nezha panel when asleep. First visit wakes it; agent reconnects on wake.
- Container restarts re-run start.sh; the agent binary is re-downloaded only if missing.
- Panel: https://nezha.lyooonapp.com (fallback http://39.98.89.122:50001), Nezha v1 Dashboard 2.6.1.
