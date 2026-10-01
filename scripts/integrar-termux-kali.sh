```bash
#!/data/data/com.termux/files/usr/bin/bash

set -u

KALI_DIR="${KALI_DIR:-$HOME/kali-arm64}"
LOG="$HOME/integracion-termux-kali.log"

exec > >(tee -a "$LOG") 2>&1

echo
echo "======================================================"
echo " TERMUX ↔ KALI ROOTLESS"
echo "======================================================"
echo "Fecha     : $(date)"
echo "Termux    : ${PREFIX:-desconocido}"
echo "Kali      : $KALI_DIR"
echo "Arquitect : $(uname -m)"
echo

fail() {
    echo "[FAIL] $*"
    exit 1
}

ok() {
    echo "[ OK ] $*"
}

warn() {
    echo "[WARN] $*"
}

# ------------------------------------------------------
# 1. Termux
# ------------------------------------------------------

echo "[1] Comprobando Termux"

if [ -z "${PREFIX:-}" ]; then
    fail "Este script debe ejecutarse desde Termux"
fi

case "$PREFIX" in
    /data/data/com.termux/files/usr)
        ok "PREFIX de Termux correcto"
        ;;
    *)
        warn "PREFIX inesperado: $PREFIX"
        ;;
esac

echo
echo "Termux:"
pkg --version 2>/dev/null || true

echo
echo "Arquitectura:"
dpkg --print-architecture 2>/dev/null || true

# ------------------------------------------------------
# 2. Kali
# ------------------------------------------------------

echo
echo "[2] Buscando Kali rootless"

if [ ! -d "$KALI_DIR" ]; then
    fail "No existe $KALI_DIR

Puedes indicar otro directorio:

KALI_DIR=\$HOME/kali-arm64 ./integrar-termux-kali.sh"
fi

ok "Directorio Kali encontrado"

if [ ! -x "$KALI_DIR/bin/bash" ]; then
    warn "$KALI_DIR/bin/bash no existe o no es ejecutable"

    if [ -x "$KALI_DIR/usr/bin/bash" ]; then
        ok "Encontrado /usr/bin/bash"
    else
        fail "No se encontró bash dentro del rootfs Kali"
    fi
fi

# ------------------------------------------------------
# 3. Detectar proot
# ------------------------------------------------------

echo
echo "[3] Comprobando proot"

if command -v proot >/dev/null 2>&1; then
    ok "proot encontrado"
    proot --version 2>/dev/null || true
else
    fail "proot no está instalado

Instala desde Termux:

pkg install proot proot-distro"
fi

# ------------------------------------------------------
# 4. Wrapper Kali
# ------------------------------------------------------

echo
echo "[4] Creando wrapper Kali"

KALI_WRAPPER="$PREFIX/bin/kali-apt"

cat > "$KALI_WRAPPER" <<EOF
#!/data/data/com.termux/files/usr/bin/bash

KALI_DIR="$KALI_DIR"

exec proot \\
    -0 \\
    -r "\$KALI_DIR" \\
    -b /dev \\
    -b /proc \\
    -b /sys \\
    -b "\$HOME:/root/termux-home" \\
    -w /root \\
    /usr/bin/env -i \\
        HOME=/root \\
        USER=root \\
        TERM="\${TERM:-xterm-256color}" \\
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \\
        LANG=C.UTF-8 \\
        LC_ALL=C.UTF-8 \\
        /bin/bash -lc 'apt "\$@"' bash
EOF

chmod +x "$KALI_WRAPPER"

ok "Creado: $KALI_WRAPPER"

# ------------------------------------------------------
# 5. Repositorio Kali
# ------------------------------------------------------

echo
echo "[5] Configurando repositorio Kali"

KALI_SOURCES="$KALI_DIR/etc/apt/sources.list"

if [ ! -f "$KALI_SOURCES" ]; then
    warn "No existe $KALI_SOURCES"
else

    cp "$KALI_SOURCES" \
       "$KALI_SOURCES.backup.$(date +%Y%m%d-%H%M%S)"

    cat > "$KALI_SOURCES" <<'EOF'
deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
EOF

    ok "Repositorio Kali configurado"
fi

# ------------------------------------------------------
# 6. Política: NO mezclar Termux + Kali
# ------------------------------------------------------