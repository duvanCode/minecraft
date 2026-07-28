#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# Entrypoint - Servidor Minecraft Java Edition 26.2 con soporte para mods
# ─────────────────────────────────────────────────────────────────────────────

DATA_DIR="/minecraft/data"
RUNTIME_DIR="/minecraft/runtime"
SERVER_JAR="$RUNTIME_DIR/server.jar"
FABRIC_SERVER_JAR="$RUNTIME_DIR/fabric-server-launch.jar"
MODS_DIR="$DATA_DIR/mods"
MC_PORT="${MC_PORT:-25566}"
BEDROCK_PORT="${BEDROCK_PORT:-19132}"
SERVER_FLAVOR="${SERVER_FLAVOR:-fabric}"
SERVER_FLAVOR_LOWER="${SERVER_FLAVOR,,}"
ENABLE_BEDROCK="${ENABLE_BEDROCK:-true}"
ENABLE_BEDROCK_LOWER="${ENABLE_BEDROCK,,}"
ENABLE_FLOODGATE="${ENABLE_FLOODGATE:-true}"
ENABLE_FLOODGATE_LOWER="${ENABLE_FLOODGATE,,}"
MINECRAFT_UID="$(id -u minecraft)"
MINECRAFT_GID="$(id -g minecraft)"
MODRINTH_API_URL="https://api.modrinth.com/v2"
FABRIC_API_PROJECT_ID="P7dR8mSH"
GEYSER_PROJECT_ID="wKkoqHrH"
FLOODGATE_PROJECT_ID="bWrNNfkb"
FABRIC_API_MANAGED_JAR="$MODS_DIR/zz-fabric-api-auto.jar"
GEYSER_MANAGED_JAR="$MODS_DIR/zz-geyser-auto.jar"
FLOODGATE_MANAGED_JAR="$MODS_DIR/zz-floodgate-auto.jar"
BEDROCK_STATE_FILE="$DATA_DIR/.bedrock-managed-state"
GEYSER_CONFIG_FILE="$DATA_DIR/config/Geyser-Fabric/config.yml"

download_file() {
    local target="$1"
    local url="$2"

    wget -q --show-progress -O "$target" "$url" || \
    curl -fL -o "$target" "$url"
}

fix_data_permissions() {
    mkdir -p "$DATA_DIR" "$MODS_DIR" "$RUNTIME_DIR"

    if [ "$(id -u)" -eq 0 ]; then
        chown -R "$MINECRAFT_UID:$MINECRAFT_GID" /minecraft 2>/dev/null || true
        chmod u+rwX "$DATA_DIR" "$MODS_DIR" "$RUNTIME_DIR" 2>/dev/null || true
    fi
}

ensure_data_dir_writable() {
    local probe_file="$DATA_DIR/.write-test"

    if ! touch "$probe_file" 2>/dev/null; then
        echo "══════════════════════════════════════════════════════════════════════"
        echo "  ERROR: El volumen $DATA_DIR no tiene permisos de escritura."
        echo "  Revisa el volumen montado en tu plataforma (Dokploy/Coolify)."
        echo "══════════════════════════════════════════════════════════════════════"
        ls -ld "$DATA_DIR" || true
        id || true
        exit 1
    fi

    rm -f "$probe_file"
}

ensure_mods_dir_writable() {
    local probe_file="$MODS_DIR/.write-test"

    if ! touch "$probe_file" 2>/dev/null; then
        echo "══════════════════════════════════════════════════════════════════════"
        echo "  ERROR: La carpeta $MODS_DIR no tiene permisos de escritura."
        echo "  No se pueden instalar los mods necesarios para Bedrock."
        echo "══════════════════════════════════════════════════════════════════════"
        ls -ld "$MODS_DIR" || true
        exit 1
    fi

    rm -f "$probe_file"
}

fetch_modrinth_primary_file() {
    local project_id="$1"
    local response
    local url
    local filename

    response="$(curl -fsSL "${MODRINTH_API_URL}/project/${project_id}/version?loaders=%5B%22fabric%22%5D&game_versions=%5B%22${MC_VERSION}%22%5D")"

    url="$(printf '%s' "$response" | jq -r '.[0].files[]? | select(.primary == true) | .url' | head -n 1)"
    filename="$(printf '%s' "$response" | jq -r '.[0].files[]? | select(.primary == true) | .filename' | head -n 1)"

    if [ -z "$url" ] || [ "$url" = "null" ] || [ -z "$filename" ] || [ "$filename" = "null" ]; then
        echo "ERROR: No se encontro una descarga compatible en Modrinth para el proyecto ${project_id} y MC_VERSION=${MC_VERSION}."
        exit 1
    fi

    printf '%s|%s\n' "$filename" "$url"
}

download_managed_mod() {
    local target="$1"
    local descriptor="$2"
    local filename="${descriptor%%|*}"
    local url="${descriptor#*|}"
    local temp_file="${target}.tmp"

    echo "► Descargando ${filename}..."
    download_file "$temp_file" "$url"
    mv "$temp_file" "$target"
}

ensure_bedrock_mods() {
    local fabric_api_descriptor
    local geyser_descriptor
    local floodgate_descriptor
    local desired_state
    local current_state=""

    if [ "$ENABLE_BEDROCK_LOWER" != "true" ]; then
        rm -f "$GEYSER_MANAGED_JAR" "$FLOODGATE_MANAGED_JAR" "$BEDROCK_STATE_FILE"
        return
    fi

    if [ "$SERVER_FLAVOR_LOWER" != "fabric" ]; then
        echo "ERROR: ENABLE_BEDROCK=true requiere SERVER_FLAVOR=fabric."
        exit 1
    fi

    ensure_mods_dir_writable

    fabric_api_descriptor="$(fetch_modrinth_primary_file "$FABRIC_API_PROJECT_ID")"
    geyser_descriptor="$(fetch_modrinth_primary_file "$GEYSER_PROJECT_ID")"
    desired_state="MC_VERSION=${MC_VERSION}
ENABLE_FLOODGATE=${ENABLE_FLOODGATE_LOWER}
FABRIC_API=${fabric_api_descriptor}
GEYSER=${geyser_descriptor}"

    if [ "$ENABLE_FLOODGATE_LOWER" = "true" ]; then
        floodgate_descriptor="$(fetch_modrinth_primary_file "$FLOODGATE_PROJECT_ID")"
        desired_state="${desired_state}
FLOODGATE=${floodgate_descriptor}"
    fi

    if [ -f "$BEDROCK_STATE_FILE" ]; then
        current_state="$(cat "$BEDROCK_STATE_FILE")"
    fi

    if [ "$current_state" != "$desired_state" ]; then
        echo "═══════════════════════════════════════════════════════"
        echo "  Instalando compatibilidad Bedrock..."
        echo "  MC_VERSION: ${MC_VERSION}"
        echo "  BEDROCK_PORT: ${BEDROCK_PORT}"
        echo "═══════════════════════════════════════════════════════"
        download_managed_mod "$FABRIC_API_MANAGED_JAR" "$fabric_api_descriptor"
        download_managed_mod "$GEYSER_MANAGED_JAR" "$geyser_descriptor"

        if [ "$ENABLE_FLOODGATE_LOWER" = "true" ]; then
            download_managed_mod "$FLOODGATE_MANAGED_JAR" "$floodgate_descriptor"
        else
            rm -f "$FLOODGATE_MANAGED_JAR"
        fi

        printf '%s\n' "$desired_state" > "$BEDROCK_STATE_FILE"
        echo "✔ Mods Bedrock actualizados."
    else
        echo "✔ Mods Bedrock ya estan sincronizados, omitiendo descarga."
    fi
}

configure_geyser() {
    local temp_config

    if [ "$ENABLE_BEDROCK_LOWER" != "true" ] || [ ! -f "$GEYSER_CONFIG_FILE" ]; then
        return
    fi

    temp_config="$(mktemp)"

    awk -v bedrock_port="$BEDROCK_PORT" -v auth_type="$(
        if [ "$ENABLE_FLOODGATE_LOWER" = "true" ]; then
            printf '%s' "floodgate"
        else
            printf '%s' "offline"
        fi
    )" '
        /^bedrock:/ { section="bedrock"; print; next }
        /^remote:/ { section="remote"; print; next }
        /^[^[:space:]]/ { section="" }
        section == "bedrock" && /^[[:space:]]+port:/ {
            sub(/:.*/, ": " bedrock_port)
            print
            next
        }
        section == "bedrock" && /^[[:space:]]+clone-remote-port:/ {
            sub(/:.*/, ": false")
            print
            next
        }
        section == "remote" && /^[[:space:]]+auth-type:/ {
            sub(/:.*/, ": " auth_type)
            print
            next
        }
        { print }
    ' "$GEYSER_CONFIG_FILE" > "$temp_config"

    mv "$temp_config" "$GEYSER_CONFIG_FILE"
}

# Crear directorios persistentes y corregir permisos del volumen montado
fix_data_permissions
ensure_data_dir_writable
ensure_bedrock_mods
configure_geyser
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
echo "  Bedrock: ${ENABLE_BEDROCK_LOWER}"
echo "  Puerto Bedrock: ${BEDROCK_PORT}"
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
