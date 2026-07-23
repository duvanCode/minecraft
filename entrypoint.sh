#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# Entrypoint – Servidor Minecraft Java Edition 26.2
# ─────────────────────────────────────────────────────────────────────────────

DATA_DIR="/minecraft/data"
SERVER_JAR="$DATA_DIR/server.jar"

# Crear directorio de datos si no existe
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

# ── 1. Descargar server.jar si no existe ──────────────────────────────────────
if [ ! -f "$SERVER_JAR" ]; then
    echo "═══════════════════════════════════════════════════════"
    echo "  Descargando Minecraft Server 26.2 desde Mojang..."
    echo "  URL: $SERVER_JAR_URL"
    echo "═══════════════════════════════════════════════════════"
    wget -q --show-progress -O "$SERVER_JAR" "$SERVER_JAR_URL" || \
    curl -fL -o "$SERVER_JAR" "$SERVER_JAR_URL"
    echo "✔ server.jar descargado correctamente."
else
    echo "✔ server.jar ya existe, omitiendo descarga."
fi

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
server-port=25565
online-mode=true
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

# ── 4. Iniciar el servidor ────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════"
echo "  Iniciando Minecraft Java Edition 26.2 – Chaos Cubed"
echo "  RAM: ${JAVA_OPTS}"
echo "═══════════════════════════════════════════════════════"

exec java $JAVA_OPTS \
    -jar "$SERVER_JAR" \
    --nogui \
    --universe "$DATA_DIR"
