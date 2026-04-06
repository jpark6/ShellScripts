#!/bin/zsh

# ==========================
# Save Scoop Apps List to Text File
# ==========================

# Usage:
#   ./scoop_list.sh
# scoop_list.txt dir : ./

# ────────────────────────────────

SCOOP_LIST_FILE="scoop_list.txt"

# 3. Write log header
echo "Save Scoop Apps List to Text File - $(date)"
echo "--------------------------------------------------------"
scoop list | awk '{ print $1 }' | grep -Ev 'Name|---|Installed|^[^M]$' | tee $SCOOP_LIST_FILE
echo "--------------------------------------------------------"
