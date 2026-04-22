#!/bin/bash
# ============================================================
# Secure Web Server Setup Script
# OS Course Project — Nginx + SSL + Logging + Zenity GUI
# ============================================================

# ---------- Root Check ----------
if [[ $(id -u) != 0 ]]; then
    zenity --error --title="Permission Denied" --text="❌ This script must be run as root!\n\nUse: sudo bash webserver_setup.sh"
    exit 1
fi

# ---------- Install Dependencies ----------
zenity --info --title="Installing..." --text="⏳ Installing required packages (nginx, openssl, zenity, curl)...\nThis may take a moment." &
ZENITY_PID=$!

apt-get update -y > /dev/null 2>&1
apt-get install -y zenity nginx openssl curl > /dev/null 2>&1

kill $ZENITY_PID 2>/dev/null

# ---------- Start Confirmation ----------
zenity --question \
    --title="Web Server Setup" \
    --text="🚀 Welcome to Secure Web Server Setup!\n\nThis script will:\n• Install and configure Nginx\n• Generate a self-signed SSL certificate\n• Set proper file permissions\n• Enable access/error logging\n\nContinue?" \
    --ok-label="Yes, Start" \
    --cancel-label="Cancel" || exit 0

# ---------- Login ----------
USER_INPUT=$(zenity --entry \
    --title="Admin Login" \
    --text="🔐 Enter Username:" \
    --entry-text="")
[[ $? -ne 0 ]] && exit 1

PASS_INPUT=$(zenity --password \
    --title="Admin Login" \
    --text="🔐 Enter Password:")
[[ $? -ne 0 ]] && exit 1

if [[ "$USER_INPUT" != "admin" || "$PASS_INPUT" != "1234" ]]; then
    zenity --error --title="Login Failed" --text="❌ Incorrect username or password!\n\nPlease try again."
    exit 1
fi

zenity --info --title="Login Successful" --text="✅ Welcome, $USER_INPUT!\nProceeding with setup..."

# ---------- Domain Input ----------
DOMAIN=$(zenity --entry \
    --title="Domain Configuration" \
    --text="🌐 Enter your domain name:\n(e.g. mysite.local, test.dev)" \
    --entry-text="mysite.local")

[[ $? -ne 0 ]] && exit 1
[[ -z "$DOMAIN" ]] && zenity --error --text="❌ Domain name cannot be empty!" && exit 1

# Validate domain (basic check — no spaces, no slashes)
if [[ "$DOMAIN" =~ [[:space:]/\\] ]]; then
    zenity --error --title="Invalid Domain" --text="❌ Domain name is invalid.\nNo spaces or slashes allowed."
    exit 1
fi


=================================================================================
=================================================================================


# ---------- FIX: Clean up any broken nginx includes before starting ----------
# This prevents the "sites-enabled/https:" error shown in screenshot
if [[ -f /etc/nginx/nginx.conf ]]; then
    # Remove any broken include lines pointing to non-directory paths
    sed -i '/include.*sites-enabled\/https/d' /etc/nginx/nginx.conf 2>/dev/null
    # Ensure correct sites-enabled include exists
    if ! grep -q "sites-enabled" /etc/nginx/nginx.conf; then
        sed -i '/http {/a\\tinclude /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
    fi
fi

# ---------- Main Setup Progress ----------
(
echo 5
echo "# Preparing directories..."
mkdir -p /var/www/$DOMAIN/public
mkdir -p /etc/nginx/ssl
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

echo 15
echo "# Enabling and starting Nginx..."
systemctl enable nginx > /dev/null 2>&1
systemctl start nginx > /dev/null 2>&1

echo 25
echo "# Creating website files..."
cat <<HTMLEOF > /var/www/$DOMAIN/public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>$DOMAIN — Running</title>
    <style>
        body { font-family: sans-serif; background: #0f172a; color: #e2e8f0; 
               display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .card { background: #1e293b; padding: 40px 60px; border-radius: 12px;
                text-align: center; border: 1px solid #334155; }
        h1 { color: #38bdf8; font-size: 2.5rem; margin-bottom: 10px; }
        p  { color: #94a3b8; }
        .badge { background: #16a34a; color: white; padding: 4px 12px; 
                 border-radius: 20px; font-size: 0.85rem; }
    </style>
</head>
<body>
    <div class="card">
        <h1>🌐 $DOMAIN</h1>
        <p><span class="badge">✅ HTTPS Active</span></p>
        <p>Nginx Web Server is running successfully.<br>
           SSL secured with self-signed certificate.</p>
        <p style="color:#64748b; font-size:0.8rem;">Setup by OS Course Project Script</p>
    </div>
</body>
</html>
HTMLEOF

echo 40
echo "# Setting file permissions..."
chown -R www-data:www-data /var/www/$DOMAIN
chmod -R 755 /var/www/$DOMAIN

echo 55
echo "# Generating SSL certificate..."
openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/$DOMAIN.key \
    -out  /etc/nginx/ssl/$DOMAIN.crt \
    -subj "/C=BD/ST=Dhaka/L=Dhaka/O=OSCourse/CN=$DOMAIN" > /dev/null 2>&1

echo 70
echo "# Writing Nginx configuration..."
cat <<NGINXEOF > /etc/nginx/sites-available/$DOMAIN
# HTTP → HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $DOMAIN;

    # SSL
    ssl_certificate     /etc/nginx/ssl/$DOMAIN.crt;
    ssl_certificate_key /etc/nginx/ssl/$DOMAIN.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    # Document root
    root  /var/www/$DOMAIN/public;
    index index.html;

    # Logging
    access_log /var/log/nginx/${DOMAIN}.access.log;
    error_log  /var/log/nginx/${DOMAIN}.error.log warn;

    # Serve files
    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINXEOF

echo 80
echo "# Enabling site and testing config..."

# Enable site (symlink)
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

# Disable default site to prevent conflicts
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration — if it fails, abort and report
NGINX_TEST=$(nginx -t 2>&1)
if [[ $? -ne 0 ]]; then
    echo "100"
    echo "# ❌ Nginx config test failed!"
    # Write error to a temp file so we can show it later
    echo "$NGINX_TEST" > /tmp/nginx_error.txt
    exit 1
fi

echo 88
echo "# Restarting Nginx..."
systemctl restart nginx > /dev/null 2>&1

echo 93
echo "# Mapping domain in /etc/hosts..."
grep -q "$DOMAIN" /etc/hosts || echo "127.0.0.1   $DOMAIN" >> /etc/hosts

echo 97
echo "# Generating initial log entry..."
curl -sk https://$DOMAIN -o /dev/null 2>&1
sleep 1

echo 100
echo "# ✅ Setup Complete!"

) | zenity --progress \
    --title="Setting Up Web Server" \
    --text="Starting..." \
    --percentage=0 \
    --auto-close \
    --width=450

# Check if progress was cancelled or nginx failed
if [[ $? -ne 0 ]]; then
    if [[ -f /tmp/nginx_error.txt ]]; then
        zenity --error \
            --title="Nginx Config Error" \
            --text="❌ Nginx configuration test failed:\n\n$(cat /tmp/nginx_error.txt)" \
            --width=500
        rm -f /tmp/nginx_error.txt
    else
        zenity --warning --text="⚠️ Setup was cancelled or encountered an error."
    fi
    exit 1
fi

# ---------- Show Nginx Status ----------
NGINX_STATUS=$(systemctl is-active nginx)
if [[ "$NGINX_STATUS" != "active" ]]; then
    zenity --error --title="Nginx Not Running" \
        --text="⚠️ Nginx failed to start after setup.\n\nCheck: journalctl -xe"
    exit 1
fi

# ---------- Log Viewer ----------
LOG="/var/log/nginx/${DOMAIN}.access.log"
sleep 1  # Give curl a moment to write logs

if [[ -f "$LOG" && -s "$LOG" ]]; then
    zenity --text-info \
        --title="📋 Last 20 Access Log Entries — $DOMAIN" \
        --width=750 --height=400 \
        --filename=<(tail -n 20 "$LOG")
else
    zenity --warning \
        --title="No Logs Yet" \
        --text="⚠️ No access logs yet for $DOMAIN.\n\nOpen a browser and visit:\nhttps://$DOMAIN\n\nLog file will be at:\n$LOG"
fi

# ---------- Final Summary ----------
IP=$(hostname -I | awk '{print $1}')
zenity --info \
    --title="✅ Setup Complete!" \
    --width=420 \
    --text="
🎉 Web Server Setup Complete!

━━━━━━━━━━━━━━━━━━━━━━━━━
🌐 Domain    : $DOMAIN
🔒 Protocol  : HTTPS (SSL)
📁 Web Root  : /var/www/$DOMAIN/public
🔑 SSL Cert  : /etc/nginx/ssl/$DOMAIN.crt
📋 Access Log: /var/log/nginx/${DOMAIN}.access.log
❗ Error Log : /var/log/nginx/${DOMAIN}.error.log
━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Visit: https://$DOMAIN
   (Add to /etc/hosts if not already done)

OS Course Project — Secure Web Server
"
