#!/data/data/com.termux/files/usr/bin/bash

KALI="$HOME/kali-arm64"
RESOLV="$KALI/etc/resolv.conf"

echo "=== Reparación DNS Kali ==="

if [ ! -d "$KALI" ]; then
    echo "ERROR: no existe $KALI"
    exit 10
fi

mkdir -p "$KALI/etc"

if [ -e "$RESOLV" ] || [ -L "$RESOLV" ]; then
    cp -a "$RESOLV" "$RESOLV.backup.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
fi

cat > "$RESOLV" <<'DNS'
nameserver 1.1.1.1
nameserver 8.8.8.8
DNS

cat "$RESOLV"

echo
echo "=== PRUEBA ==="
kali-shell -c 'getent hosts http.kali.org'

exit $?