#!/bin/zsh

# ==========================
# Scoop Auto Update Script
# For WSL Ubuntu (or Linux where Scoop is available)
# ==========================

# Usage:
#   ./scoop_auto_update.sh [log_directory]
# Default log dir: ./logs

# ────────────────────────────────
cd $HOME/Util
# 1. Parse arguments
LOG_DIR="${1:-$HOME/Util/logs}"

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

# 7. Print Install Success Apps (version)
if [ $(grep -c "installed successfully!" "$LOG_FILE") -gt 0 ]; then
  echo "" | tee -a "$LOG_FILE"
  echo "⭐ Update Success"| tee -a "$LOG_FILE"
  echo "$(grep 'installed successfully!' $LOG_FILE | awk -F' was ' '{print $1}')" | tee -a "$LOG_FILE"
fi

# 7. Print Still Running Fail Apps
if [ $(grep -c "still running." "$LOG_FILE") -gt 0 ]; then
  echo "" | tee -a "$LOG_FILE"
  echo "⛔ Update Fail: Still Running"| tee -a "$LOG_FILE"
  echo "❌ Close this apps, if you want to update"| tee -a "$LOG_FILE"
  echo "$(grep 'still running.' $LOG_FILE | awk -F'\"' '{print $2}')" | tee -a "$LOG_FILE"
fi

# 8. Remove ^M(\r) EOF character and no data row
sed -i "s|\s*\r|\n|g" $LOG_FILE
sed -i '/^[[:space:]]*$/d' $LOG_FILE

# 9. Done
echo "" | tee -a "$LOG_FILE"
echo "✅ Done! Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"

