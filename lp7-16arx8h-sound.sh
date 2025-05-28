#!/bin/bash

# Check for root
[ "$(id -u)" -ne 0 ] && { echo "Requires root privileges."; exit 1; }

# Create tas2781 fix script
mkdir -p /usr/local/bin
cat > /usr/local/bin/tas2781-fix << 'EOF'
#!/bin/sh
[ "$(id -u)" -ne 0 ] && { printf "Requires root privileges.\n"; exit 1; }

POWER_SAVE_PATH="/sys/module/snd_hda_intel/parameters/power_save"
POWER_CONTROL_PATH="/sys/bus/i2c/drivers/tas2781-hda/i2c-TIAS2781:00/power/control"

check_paths() {
  [ -e "$POWER_SAVE_PATH" ] && [ -e "$POWER_CONTROL_PATH" ]
}

while ! check_paths; do
  sleep 1
done

# Disable snd_hda_intel power saving
printf "0" > "$POWER_SAVE_PATH"

# Disable runtime suspend/resume for tas2781
printf "on" > "$POWER_CONTROL_PATH"
EOF

chmod +x /usr/local/bin/tas2781-fix
echo "Created tas2781 fix script /usr/local/bin/tas2781-fix"

# Create systemd service
cat > /etc/systemd/system/tas2781-fix.service << 'EOF'
[Unit]
Description=Run the tas2781-fix script after the relevant sysfs paths become available

[Service]
Type=oneshot
ExecStart=/usr/local/bin/tas2781-fix
RemainAfterExit=true
TimeoutSec=60

[Install]
WantedBy=multi-user.target
EOF

systemctl enable tas2781-fix.service
echo "Enabled systemd service /etc/systemd/system/tas2781-fix.service"

# Create modprobe configuration
mkdir -p /etc/modprobe.d
cat > /etc/modprobe.d/60-hda.conf << 'EOF'
options snd-hda-intel model=,17aa:38a8
EOF
echo "Applied modprobe configuration /etc/modprobe.d/60-hda.conf"

# Reboot when ready
echo "Setup complete. Reboot required."
