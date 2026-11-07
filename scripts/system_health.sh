#!/usr/bin/env bash
# =============================================================
#  system_health.sh – Collects CPU, Memory & Disk metrics and
#  appends a timestamped entry to health_log.txt.
#
#  Usage:
#    chmod +x scripts/system_health.sh
#    ./scripts/system_health.sh
#
#  Schedule with cron (every 5 min):
#    */5 * * * * /path/to/scripts/system_health.sh
# =============================================================

set -euo pipefail

LOG_FILE="health_log.txt"
DISK_THRESHOLD=80
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ── CPU Usage (percentage, 1-second sample) ──────────────────
# Uses /proc/stat to compute a one-second delta (avoids dependency on mpstat/top)
read_cpu() {
  awk '/^cpu /{print $2+$3+$4, $2+$3+$4+$5}' /proc/stat
}

CPU1=$(read_cpu)
sleep 1
CPU2=$(read_cpu)

CPU_USAGE=$(echo "$CPU1 $CPU2" | awk '{
  active = $3 - $1;
  total  = $4 - $2;
  printf "%.1f", (active / total) * 100
}')

# ── Memory Usage ─────────────────────────────────────────────
MEM_INFO=$(free -m | awk '/^Mem:/{printf "%.1f%% (%dMB / %dMB)", ($3/$2)*100, $3, $2}')

# ── Disk Usage (root partition) ──────────────────────────────
DISK_LINE=$(df -h / | awk 'NR==2{print $0}')
DISK_USAGE_PCT=$(echo "$DISK_LINE" | awk '{gsub(/%/,""); print $5}')
DISK_DISPLAY=$(df -h / | awk 'NR==2{printf "%s used of %s (%s)", $3, $2, $5}')

# ── Build log entry ─────────────────────────────────────────
ENTRY="[${TIMESTAMP}]  CPU: ${CPU_USAGE}%  |  Memory: ${MEM_INFO}  |  Disk: ${DISK_DISPLAY}"

# Append warning if disk exceeds threshold
if [ "${DISK_USAGE_PCT}" -ge "${DISK_THRESHOLD}" ]; then
  ENTRY="${ENTRY}  [WARNING] Disk space high!"
  echo "[WARNING] Disk space high! (${DISK_USAGE_PCT}%)"
fi

# Write to log and echo to stdout
echo "$ENTRY" | tee -a "$LOG_FILE"
