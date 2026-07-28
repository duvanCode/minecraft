#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# Entrypoint - Servidor Minecraft Java Edition 26.2 con soporte para mods
# ─────────────────────────────────────────────────────────────────────────────

DATA_DIR="/minecraft/data"
SERVER_JAR="$DATA_DIR/server.jar"
FABRIC_SERVER_JAR="$DATA_DIR/fabric-server-launch.jar"
MODS_DIR="$DATA_DIR/mods"
MC_PORT="${MC_PORT:-25566}"
SERVER_FLAVOR="${SERVER_FLAVOR:-fabric}"
SERVER_FLAVOR_LOWER="${SERVER_FLAVOR,,}"
MINECRAFT_UID="$(id -u minecraft)"
MINECRAFT_GID="$(id -g minecraft)"

download_file() {
    local target="$1"
    local url="$2"

    wget -q --show-progress -O "$target" "$url" || \
    curl -fL -o "$target" "$url"
}

fix_data_permissions() {
    mkdir -p "$DATA_DIR" "$MODS_DIR"

    if [ "$(id -u)" -eq 0 ]; then
        chown -R "$MINECRAFT_UID:$MINECRAFT_GID" /minecraft
        chmod u+rwX "$DATA_DIR" "$MODS_DIR"
    fi
}

# Crear directorios persistentes y corregir permisos del volumen montado
fix_data_permissions
cd "$DATA_DIR"

case "$SERVER_FLAVOR_LOWER" in
    fabric)
        if [ ! -f "$FABRIC_SERVER_JAR" ]; then
            FABRIC_SERVER_URL="https://meta.fabricmc.net/v2/versions/loader/${MC_VERSION}/${FABRIC_LOADER_VERSION}/${FABRIC_INSTALLER_VERSION}/server/jar"
            echo "═══════════════════════════════════════════════════════"
            echo "  Descargando Fabric Server Launcher..."
            echo "  MC_VERSION: ${MC_VERSION}"
            echo "  URL: ${FABRIC_SERVER_URL}"
            echo "═══════════════════════════════════════════════════════"
            download_file "$FABRIC_SERVER_JAR" "$FABRIC_SERVER_URL"
            echo "✔ Fabric server launcher descargado correctamente."
        else
            echo "✔ Fabric server launcher ya existe, omitiendo descarga."
        fi
        STARTUP_JAR="$FABRIC_SERVER_JAR"
        ;;
    vanilla)
        if [ ! -f "$SERVER_JAR" ]; then
            echo "═══════════════════════════════════════════════════════"
            echo "  Descargando Minecraft Server desde Mojang..."
            echo "  URL: $SERVER_JAR_URL"
            echo "═══════════════════════════════════════════════════════"
            download_file "$SERVER_JAR" "$SERVER_JAR_URL"
            echo "✔ server.jar descargado correctamente."
        else
            echo "✔ server.jar ya existe, omitiendo descarga."
        fi
        STARTUP_JAR="$SERVER_JAR"
        ;;
    *)
        echo "ERROR: SERVER_FLAVOR debe ser 'fabric' o 'vanilla'. Valor actual: ${SERVER_FLAVOR}"
        exit 1
        ;;
esac

# ── 2. Aceptar EULA ───────────────────────────────────────────────────────────
if [ "${EULA,,}" = "true" ]; then
    echo "eula=true" > "$DATA_DIR/eula.txt"
    echo "✔ EULA aceptada."
else
    echo "══════════════════════════════════════════════════════════════════════"
    echo "  ERROR: Debes aceptar el EULA de Minecraft."
    echo "  Establece la variable de entorno EULA=true en docker-compose.yml"
    echo "══════════════════════════════════════════════════════════════════════"
    exit 1
fi

# ── 3. Generar server.properties si no existe ─────────────────────────────────
if [ ! -f "$DATA_DIR/server.properties" ]; then
    echo "► Generando server.properties con valores por defecto..."
    cat > "$DATA_DIR/server.properties" << 'EOF'
# Minecraft Server 26.2 – Configuración
# Edita estos valores y reinicia el contenedor

# ── Red ────────────────────────────────────────────────────────────
server-port=25566
online-mode=false
max-players=20
network-compression-threshold=256

# ── Mundo ──────────────────────────────────────────────────────────
level-name=world
level-type=minecraft\:default
difficulty=normal
gamemode=survival
allow-nether=true
allow-flight=false
pvp=true
generate-structures=true
max-world-size=29999984
view-distance=10
simulation-distance=10

# ── Chat / seguridad ───────────────────────────────────────────────
enable-command-block=false
white-list=false
enforce-whitelist=false
spawn-protection=16
max-build-height=320

# ── Rendimiento ────────────────────────────────────────────────────
max-tick-time=60000
sync-chunk-writes=true

# ── Mensajes y RCON (deshabilitado) ────────────────────────────────
motd=Servidor Minecraft 26.2 - Chaos Cubed
enable-rcon=false
enable-query=false
EOF
    echo "✔ server.properties creado."
fi

# Mantener el puerto del servidor alineado con la variable del contenedor
if grep -q '^server-port=' "$DATA_DIR/server.properties"; then
    sed -i "s/^server-port=.*/server-port=${MC_PORT}/" "$DATA_DIR/server.properties"
else
    printf '\nserver-port=%s\n' "$MC_PORT" >> "$DATA_DIR/server.properties"
fi

# ── 4. Iniciar el servidor ────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════"
echo "  Iniciando Minecraft Java Edition ${MC_VERSION} - Chaos Cubed"
echo "  Flavor: ${SERVER_FLAVOR_LOWER}"
echo "  RAM: ${JAVA_OPTS}"
echo "  Mods: ${MODS_DIR}"
echo "═══════════════════════════════════════════════════════"

if [ "$(id -u)" -eq 0 ]; then
    exec gosu minecraft java $JAVA_OPTS \
        -jar "$STARTUP_JAR" \
        --nogui \
        --universe "$DATA_DIR"
else
    exec java $JAVA_OPTS \
        -jar "$STARTUP_JAR" \
        --nogui \
        --universe "$DATA_DIR"
fi
