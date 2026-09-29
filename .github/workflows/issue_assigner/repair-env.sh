#!/data/data/com.termux/files/usr/bin/bash

ROOT="$HOME/kali-arm64"
set $ANDROID_HOME
echo "[*] Kali rootfs: $ROOT"

if [ ! -d "$ROOT/usr/bin" ]; then
    echo "[!] No existe $ROOT/usr/bin"
    exit 1
fi
termux-wifi-enable true
termux-wifi-connectioninfo
echo "[*] Estado actual:"
ls -ld "$ROOT/usr/bin/env" 2>/dev/null || true
file "$ROOT/usr/bin/env" 2>/dev/null || true

echo "[*] Eliminando solamente el objeto incorrecto..."
rm -rf "$ROOT/usr/bin/env"

echo "[*] Restaurando /usr/bin/env desde coreutils..."
if [ -x "$ROOT/bin/busybox" ]; then
    ln -s ../bin/busybox "$ROOT/usr/bin/env"
    echo "[+] env restaurado mediante BusyBox"
elif [ -x "$ROOT/usr/bin/coreutils" ]; then
    ln -s coreutils "$ROOT/usr/bin/env"
    echo "[+] env enlazado a coreutils"
else
    echo "[!] No encuentro BusyBox ni coreutils."
    echo "[!] No continúo para evitar dañar el rootfs."
    exit 2
fi

echo
echo "[+] Resultado:"
ls -l "$ROOT/usr/bin/env"
file "$ROOT/usr/bin/env"