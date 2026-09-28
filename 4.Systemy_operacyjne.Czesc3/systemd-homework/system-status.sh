#!/usr/bin/env bash
set -euo pipefail

printf '=== START ===\n'
printf 'Server: %s\n' "$(hostname)"
printf 'Date: %s\n' "$(date)"
printf 'Kernel: %s\n' "$(uname -r)"
printf 'Uptime: %s\n' "$(uptime -p)"

printf '\n=== FILESYSTEM ===\n'
df -hT

printf '\n=== MEMORY ===\n'
free -h

printf '\n=== TOP 10 CPU usage===\n'
ps -e -o pid,user,%cpu,%mem,cmd --sort=-%cpu | head

printf '=== END ===\n'
