#!/bin/bash

# MX Linux Power Pack - Version 1.1
# Performance and Power Optimizer for MX Linux (CLI)

REPORT_DIR="$HOME/mxlpp-reports"
LOG_FILE="$REPORT_DIR/mxlpp.log"
mkdir -p "$REPORT_DIR"

# --- Dependency Check ---
if ! command -v bc >/dev/null || ! command -v iostat >/dev/null; then
  echo "⚠️  Required tools missing. Installing: bc sysstat"
  sudo apt install -y bc sysstat
fi

# --- Feature Functions ---

install_all() {
  echo -e "\n==== [ INSTALL ALL MXLPP FEATURES ] ====" | tee -a "$LOG_FILE"
  enable_zram
  install_tlp
  enable_preload
  optimize_swappiness
  apply_noatime
  echo "✅ All MXLPP features installed successfully." | tee -a "$LOG_FILE"
  read -p "📎 Press Enter to return to the menu..."
}

enable_zram() {
  echo -e "\n==== [ ENABLE ZRAM ] ====" | tee -a "$LOG_FILE"
  echo "▶ Enabling zram..." | tee -a "$LOG_FILE"
  sudo apt install -y zram-tools

  sudo bash -c 'cat > /etc/default/zramswap' <<EOF
ALGO=lz4
PERCENT=50
EOF

  sudo systemctl unmask zramswap.service 2>/dev/null
  sudo systemctl restart zramswap.service
  sudo systemctl enable zramswap.service

  echo "✅ zram enabled with LZ4 compression and 50% RAM size." | tee -a "$LOG_FILE"
  echo -e "\nCurrent zram status:"
  free -h
  lsblk | grep zram
  read -p "📎 Press Enter to return to the menu..."
}

install_tlp() {
  echo -e "\n==== [ INSTALL & CONFIGURE TLP ] ====" | tee -a "$LOG_FILE"
  echo "▶ Installing and configuring TLP..." | tee -a "$LOG_FILE"
  sudo apt install -y tlp tlp-rdw
  sudo systemctl enable tlp.service
  sudo systemctl start tlp.service
  echo "✅ TLP installed and active." | tee -a "$LOG_FILE"
  echo -e "\n🔍 TLP Status:"
  sudo tlp-stat -s | tee -a "$LOG_FILE"
  read -p "📎 Press Enter to return to the menu..."
}

enable_preload() {
  echo -e "\n==== [ INSTALL PRELOAD ] ====" | tee -a "$LOG_FILE"
  echo "▶ Installing preload..." | tee -a "$LOG_FILE"
  sudo apt install -y preload
  if systemctl list-units --all | grep -q preload; then
    sudo systemctl enable preload
    sudo systemctl start preload
    echo "✅ Preload service enabled and started." | tee -a "$LOG_FILE"
  else
    echo "ℹ️ Preload installed, but no systemd service found (may start automatically)." | tee -a "$LOG_FILE"
  fi
  echo "🧠 Tip: Preload benefits HDD systems most. On SSD, improvement may be minimal." | tee -a "$LOG_FILE"
  read -p "📎 Press Enter to return to the menu..."
}

optimize_swappiness() {
  echo -e "\n==== [ OPTIMIZE SWAPPINESS ] ====" | tee -a "$LOG_FILE"
  echo "▶ Optimizing swappiness and cache pressure..." | tee -a "$LOG_FILE"
  SWAPPINESS_BEFORE=$(cat /proc/sys/vm/swappiness)
  CACHE_PRESSURE_BEFORE=$(cat /proc/sys/vm/vfs_cache_pressure)

  sudo sysctl -w vm.swappiness=10
  sudo sysctl -w vm.vfs_cache_pressure=50

  echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
  echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf

  echo "✅ Swappiness set to 10 (was $SWAPPINESS_BEFORE)" | tee -a "$LOG_FILE"
  echo "✅ vfs_cache_pressure set to 50 (was $CACHE_PRESSURE_BEFORE)" | tee -a "$LOG_FILE"
  echo "🧠 Tip: These values reduce swapping and keep metadata cached in RAM." | tee -a "$LOG_FILE"
  read -p "📎 Press Enter to return to the menu..."
}

apply_noatime() {
  echo -e "\n==== [ APPLY NOATIME ] ====" | tee -a "$LOG_FILE"
  echo "▶ Applying noatime to ext4 partitions..." | tee -a "$LOG_FILE"
  sudo cp /etc/fstab /etc/fstab.backup-mxlpp
  sudo sed -i.bak -E 's/(ext4\s+defaults)(?!.*noatime)/\1,noatime/' /etc/fstab
  echo "✅ Updated /etc/fstab with noatime for ext4." | tee -a "$LOG_FILE"
  echo "🔁 Takes effect after reboot." | tee -a "$LOG_FILE"
  echo "🗂 Backup saved as /etc/fstab.backup-mxlpp" | tee -a "$LOG_FILE"
  read -p "📎 Press Enter to return to the menu..."
}

generate_pre_report() {
  echo "▶ Generating Pre-Install Performance Report..." | tee "$REPORT_DIR/pre-install.txt"
  {
    echo "========= MX Linux Pre-Install Performance Report ========="
    echo "Timestamp: $(date)"
    echo
    echo "🧠 RAM Usage (free -h):"
    free -h
    echo
    echo "🖥 CPU Info:"
    lscpu | grep -E 'Model name|CPU MHz|Socket|Core|Thread'
    echo
    echo "⏱ Boot Time (systemd-analyze):"
    systemd-analyze time
    echo
    echo "💾 Disk I/O Stats (iostat -dx):"
    iostat -dx 1 3
    echo
    echo "📊 Load Average (uptime):"
    uptime
    echo
    echo "⚙ Swappiness:"
    cat /proc/sys/vm/swappiness
    echo
    echo "⚙ vfs_cache_pressure:"
    cat /proc/sys/vm/vfs_cache_pressure
    echo "==========================================================="
  } | tee "$REPORT_DIR/pre-install.txt"
  echo "✅ Pre-install report saved at $REPORT_DIR/pre-install.txt"
  read -p "📎 Press Enter to return to the menu..."
}

generate_post_report() {
  echo "▶ Generating Post-Install Performance Report..." | tee "$REPORT_DIR/post-install.txt"
  {
    echo "========= MX Linux Post-Install Performance Report ========="
    echo "Timestamp: $(date)"
    echo
    echo "🧠 RAM Usage (free -h):"
    free -h
    echo
    echo "🖥 CPU Info:"
    lscpu | grep -E 'Model name|CPU MHz|Socket|Core|Thread'
    echo
    echo "⏱ Boot Time (systemd-analyze):"
    systemd-analyze time
    echo
    echo "💾 Disk I/O Stats (iostat -dx):"
    iostat -dx 1 3
    echo
    echo "📊 Load Average (uptime):"
    uptime
    echo
    echo "⚙ Swappiness:"
    cat /proc/sys/vm/swappiness
    echo
    echo "⚙ vfs_cache_pressure:"
    cat /proc/sys/vm/vfs_cache_pressure
    echo "============================================================"
  } | tee "$REPORT_DIR/post-install.txt"
  echo "✅ Post-install report saved at $REPORT_DIR/post-install.txt"
  read -p "📎 Press Enter to return to the menu..."
}

compare_reports() {
  echo "▶ Comparing Reports & Showing Optimization Advice..." | tee "$REPORT_DIR/comparison.txt"

  PRE="$REPORT_DIR/pre-install.txt"
  POST="$REPORT_DIR/post-install.txt"
  OUT="$REPORT_DIR/comparison.txt"

  PRE_RAM=$(grep -A1 "RAM Usage" "$PRE" | awk '/Mem:/ {print $3}')
  POST_RAM=$(grep -A1 "RAM Usage" "$POST" | awk '/Mem:/ {print $3}')
  PRE_BOOT=$(grep "Boot Time" "$PRE" -A1 | tail -n1 | grep -oP '\d+(\.\d+)?(?=s)' | head -1)
  POST_BOOT=$(grep "Boot Time" "$POST" -A1 | tail -n1 | grep -oP '\d+(\.\d+)?(?=s)' | head -1)
  PRE_SWAP=$(grep -A1 "Swappiness" "$PRE" | tail -n1)
  POST_SWAP=$(grep -A1 "Swappiness" "$POST" | tail -n1)
  PRE_CACHE=$(grep -A1 "vfs_cache_pressure" "$PRE" | tail -n1)
  POST_CACHE=$(grep -A1 "vfs_cache_pressure" "$POST" | tail -n1)

  echo "========= Performance Comparison Report =========" | tee -a "$OUT"
  echo "📅 Timestamp: $(date)" | tee -a "$OUT"
  echo "" | tee -a "$OUT"
  echo "🧠 RAM Usage (lower is better):" | tee -a "$OUT"
  echo "  Before: $PRE_RAM | After: $POST_RAM" | tee -a "$OUT"
  echo "⏱ Boot Time (lower is better):" | tee -a "$OUT"
  echo "  Before: $PRE_BOOT sec | After: $POST_BOOT sec" | tee -a "$OUT"
  echo "⚙ Swappiness:" | tee -a "$OUT"
  echo "  Before: $PRE_SWAP | After: $POST_SWAP" | tee -a "$OUT"
  echo "⚙ vfs_cache_pressure:" | tee -a "$OUT"
  echo "  Before: $PRE_CACHE | After: $POST_CACHE" | tee -a "$OUT"

  echo "" | tee -a "$OUT"
  echo "========= Optimization Advice =========" | tee -a "$OUT"

  if [[ -n "$PRE_RAM" && -n "$POST_RAM" ]] && (( $(echo "$POST_RAM < $PRE_RAM" | bc -l) )); then
    echo "✅ RAM usage improved — good memory handling." | tee -a "$OUT"
  else
    echo "❌ No improvement in RAM usage." | tee -a "$OUT"
  fi

  if [[ -n "$PRE_BOOT" && -n "$POST_BOOT" ]] && (( $(echo "$POST_BOOT < $PRE_BOOT" | bc -l) )); then
    echo "✅ Boot time improved — services optimized." | tee -a "$OUT"
  else
    echo "❌ Boot time unchanged — consider disabling preload." | tee -a "$OUT"
  fi

  if [ "$POST_SWAP" -lt "$PRE_SWAP" ] 2>/dev/null; then
    echo "✅ Swappiness tuned for better performance." | tee -a "$OUT"
  fi

  if [ "$POST_CACHE" -lt "$PRE_CACHE" ] 2>/dev/null; then
    echo "✅ Cache pressure reduced — faster file access." | tee -a "$OUT"
  fi

  echo -e "\n📄 Full comparison saved to: $OUT"
  echo -e "\n📜 Opening comparison report in less...\n"
  read -p "📎 Press Enter to view the report..." 
  less "$OUT"
}

uninstall_all() {
  echo -e "\n==== [ UNINSTALL ALL MXLPP FEATURES ] ====" | tee -a "$LOG_FILE"
  echo "🧹 Removing zram-tools..." | tee -a "$LOG_FILE"
  sudo systemctl stop zramswap.service 2>/dev/null
  sudo systemctl disable zramswap.service 2>/dev/null
  sudo systemctl mask zramswap.service 2>/dev/null
  sudo apt purge -y zram-tools 2>/dev/null

  echo "🧹 Removing TLP..." | tee -a "$LOG_FILE"
  sudo systemctl stop tlp.service 2>/dev/null
  sudo systemctl disable tlp.service 2>/dev/null
  sudo apt purge -y tlp tlp-rdw 2>/dev/null

  echo "🧹 Removing preload..." | tee -a "$LOG_FILE"
  sudo systemctl stop preload.service 2>/dev/null
  sudo systemctl disable preload.service 2>/dev/null
  sudo apt purge -y preload 2>/dev/null

  echo "🔧 Reverting sysctl.conf changes..." | tee -a "$LOG_FILE"
  sudo sed -i '/vm\.swappiness/d' /etc/sysctl.conf
  sudo sed -i '/vm\.vfs_cache_pressure/d' /etc/sysctl.conf

  echo "📁 Checking and restoring fstab backup..." | tee -a "$LOG_FILE"
  if [ -f /etc/fstab.backup-mxlpp ]; then
    sudo cp /etc/fstab.backup-mxlpp /etc/fstab
    echo "✅ fstab restored from backup." | tee -a "$LOG_FILE"
  else
    echo "❗ Backup not found. Manual restore may be needed." | tee -a "$LOG_FILE"
  fi

  echo "✅ All MXLPP features uninstalled and reverted." | tee -a "$LOG_FILE"
  read -p "📎 Press Enter to return to the menu..."
}

# --- Auto Pre-Install Report on First Run ---
if [ ! -f "$REPORT_DIR/pre-install.txt" ]; then
  echo "📊 First run detected. Generating Pre-Install Performance Report..."
  generate_pre_report
  echo "✅ Report created before applying any optimizations."
  read -p "📎 Press Enter to continue to the menu..."
fi

# --- Main Menu ---
while true; do
  clear
  echo "==============================="
  echo " MX Linux Power Pack v1.1"
  echo "==============================="
  echo " 0. Install ALL MXLPP features"
  echo " 1. Enable zram (compressed RAM swap)"
  echo " 2. Install and configure TLP (power manager)"
  echo " 3. Enable preload (faster app load)"
  echo " 4. Optimize swappiness & cache pressure"
  echo " 5. Use noatime on ext4 partitions"
  echo " 6. Generate Pre-Install Performance Report"
  echo " 7. Generate Post-Install Performance Report"
  echo " 8. Compare Pre & Post-Install Performance and Show Optimization Advice"
  echo " 9. Uninstall all mxlpp features"
  echo "10. Exit"
  echo "==============================="
  read -p "Select an option [0-10]: " choice

  case $choice in
    0) install_all ;;
    1) enable_zram ;;
    2) install_tlp ;;
    3) enable_preload ;;
    4) optimize_swappiness ;;
    5) apply_noatime ;;
    6) generate_pre_report ;;
    7) generate_post_report ;;
    8) compare_reports ;;
    9) uninstall_all ;;
    10) echo "👋 Exiting..."; exit 0 ;;
    *) echo "❌ Invalid option. Press Enter to continue..."; read ;;
  esac
done
