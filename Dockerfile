# ─────────────────────────────────────────────────────────────────────────────
# Servidor de Minecraft Java Edition 26.2 ("Chaos Cubed")
# Imagen base: Eclipse Temurin 25 (Java SE 25 LTS – requerido por MC 26.x)
# ─────────────────────────────────────────────────────────────────────────────
FROM eclipse-temurin:25-jre-noble

# Metadatos
LABEL maintainer="tu-nombre"
LABEL description="Minecraft Java Edition 26.2 - Vanilla - Sin mods"
LABEL mc.version="26.2"

# Variables de entorno configurables vía docker-compose
ENV MC_VERSION="26.2" \
    SERVER_JAR_URL="https://piston-data.mojang.com/v1/objects/823e2250d24b3ddac457a60c92a6a941943fcd6a/server.jar" \
    JAVA_OPTS="-Xms2G -Xmx4G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=8 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1" \
    EULA="false" \
    TZ="America/Bogota"

# Usuario no-root para seguridad
RUN groupadd -r minecraft && useradd -r -g minecraft -m -d /minecraft minecraft

WORKDIR /minecraft

# Instalar curl y wget (para descargar el JAR en el entrypoint)
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl wget && \
    rm -rf /var/lib/apt/lists/*

# Copiar el script de entrada
COPY --chown=minecraft:minecraft entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Dar permisos al directorio de trabajo
RUN chown -R minecraft:minecraft /minecraft

# Puerto de Minecraft Java
EXPOSE 25565/tcp

# El mundo y la configuración se persisten en un volumen
VOLUME ["/minecraft/data"]

USER minecraft

ENTRYPOINT ["/entrypoint.sh"]
