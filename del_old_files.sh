#!/bin/bash

# Show usage instructions
usage() {
  echo "📘 Usage: $0 <directory> <days> [log_directory]"
  echo "🔸 Example: $0 /home/user/logs 30 /home/user/log_output"
  echo "   → Deletes files in /home/user/logs not modified in the last 30 days"
  echo "   → Logs deletion list to /home/user/log_output/deleted_files_YYYYMMDD_HHMMSS.log"
  exit 1
}

# Parameter check
if [ "$#" -lt 2 ]; then
  usage
fi

TARGET_DIR="$1"
DAYS="$2"
LOG_DIR="$3"

# Set default log directory if not specified
if [ -z "$LOG_DIR" ]; then
  LOG_DIR="./logs"
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Generate log file name with timestamp
LOG_FILE="$LOG_DIR/deleted_files_$(date +%Y%m%d_%H%M%S).log"

# Validation
if [ ! -d "$TARGET_DIR" ]; then
  echo "❌ Error: Directory '$TARGET_DIR' does not exist." | tee -a "$LOG_FILE"
  exit 2
fi

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "❌ Error: The number of days must be a numeric value." | tee -a "$LOG_FILE"
  exit 3
fi

echo "🧹 Cleaning up files in '$TARGET_DIR' not modified in the last $DAYS days..." | tee -a "$LOG_FILE"
echo "📝 Logging deletions to: $LOG_FILE" | tee -a "$LOG_FILE"

{
  echo "🗑️ Deletion log - $(date)"
  echo "📂 Target directory: $TARGET_DIR"
  echo "📆 Older than: $DAYS days"
  echo "--------------------------------------------------------"
} | tee -a "$LOG_FILE"

# Delete files and log each deleted filename
find "$TARGET_DIR" -type f -mtime +"$DAYS" -print0 | while IFS= read -r -d '' file; do
  if rm -v "$file"; then
    echo "✅ [DELETED] $file" | tee -a "$LOG_FILE"
  else
    echo "❌ [Error] $file" | tee -a "$LOG_FILE"
  fi
done

echo "🎉 Done! Log saved to: $LOG_FILE"
