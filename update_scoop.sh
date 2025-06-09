#!/bin/zsh

# ==========================
# Scoop Auto Update Script
# For WSL Ubuntu (or Linux where Scoop is available)
# ==========================

# Usage:
#   ./scoop_auto_update.sh [log_directory]
# Default log dir: ./logs

# ────────────────────────────────
cd /home/ubuntu/util
# 1. Parse arguments
LOG_DIR="${1:-./logs}"

# 2. Prepare log directory & file
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/update_scoop_$TIMESTAMP.log"

# 3. Write log header
{
    echo "🛠️  Scoop Auto Update Log - $(date)"
    echo "📂 Log Directory: $LOG_DIR"
    echo "--------------------------------------------------------"
} | tee -a "$LOG_FILE"

# 4. Update Scoop itself
echo "🔄 Updating Scoop itself..." | tee -a "$LOG_FILE"
scoop update 2>&1 | tee -a "$LOG_FILE"

# 5. Update installed apps
echo "" | tee -a "$LOG_FILE"
echo "📦 Updating all installed apps..." | tee -a "$LOG_FILE"
scoop list | awk '$1~/^[a-z0-9]/ { print $1 }' | xargs scoop update | tee -a "$LOG_FILE"
# 6. Cleanup old versions
echo "" | tee -a "$LOG_FILE"
echo "🧹 Cleaning up outdated versions..." | tee -a "$LOG_FILE"
scoop cleanup "*" 2>&1 | tee -a "$LOG_FILE"

# 7. Print Still Running Error
if [ `grep -c "still running." "$LOG_FILE"` -gt 0 ]; then
  echo "" | tee -a "$LOG_FILE"
  echo "⛔ Error: Still Running"| tee -a "$LOG_FILE"
  echo "❌ Quit this apps, if you want update"| tee -a "$LOG_FILE"
  echo "`grep 'still running.' $LOG_FILE` | awk -F'\"' '{print $2}'" | tee -a "$LOG_FILE"
fi

# 8. Remove ^M(\r) EOF character and no data row
sed -i "s|\s*\r|\n|g" $LOG_FILE
sed -i '/^[[:space:]]*$/d' $LOG_FILE

# 9. Done
echo "" | tee -a "$LOG_FILE"
echo "✅ Done! Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"

