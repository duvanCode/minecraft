# 🎮 Servidor Minecraft Java Edition 26.2 – Chaos Cubed

Servidor vanilla sin mods, dockerizado y listo para desplegar en una VPS con **Dokploy**.

---

## 📦 Contenido del proyecto

```
minecraft-server/
├── Dockerfile          ← Imagen basada en Eclipse Temurin 25 (Java SE 25)
├── docker-compose.yml  ← Configuración de servicios para Dokploy
├── entrypoint.sh       ← Script de inicio (descarga el JAR, acepta EULA, arranca)
└── README.md           ← Esta guía
```

---

## 🚀 Despliegue en Dokploy

### Opción A – Desde repositorio Git (recomendado)

1. Sube esta carpeta a GitHub/GitLab (puede ser privado).
2. En Dokploy → **Create Service → Docker Compose**.
3. Conecta el repositorio.
4. Dokploy detectará el `docker-compose.yml` automáticamente.
5. Haz clic en **Deploy**.

### Opción B – Subir archivos directamente

1. En Dokploy → **Create Service → Docker Compose**.
2. Pega el contenido del `docker-compose.yml` en el editor.
3. Sube `Dockerfile` y `entrypoint.sh` al servidor (misma carpeta).
4. Despliega.

---

## ⚙️ Configuración importante

### RAM (JAVA_OPTS en docker-compose.yml)

| Jugadores | `-Xms` | `-Xmx` | RAM del contenedor |
|-----------|--------|--------|-------------------|
| 1–5       | 1G     | 2G     | 3G                |
| 5–15      | 2G     | 4G     | 5G                |
| 15–30     | 3G     | 6G     | 7G                |
| 30+       | 4G     | 8G     | 10G               |

Cambia los valores `-Xms` / `-Xmx` en `JAVA_OPTS` y el `memory` en `deploy.resources`.

### Puertos

El servidor expone el puerto **25565 TCP**. Asegúrate de que tu firewall/VPS lo tenga abierto:

```bash
# UFW
sudo ufw allow 25565/tcp

# iptables
sudo iptables -A INPUT -p tcp --dport 25565 -j ACCEPT
```

---

## 🛠️ Personalización del servidor

Una vez corriendo, edita el archivo de configuración dentro del volumen:

```bash
# Encontrar el contenedor
docker ps

# Editar server.properties
docker exec -it minecraft-26-2 nano /minecraft/data/server.properties

# Ver logs en tiempo real
docker logs -f minecraft-26-2
```

### Variables de entorno disponibles

| Variable | Default | Descripción |
|----------|---------|-------------|
| `EULA` | `false` | Pon `true` para aceptar el EULA |
| `TZ` | `America/Bogota` | Zona horaria del contenedor |
| `JAVA_OPTS` | *(G1GC optimizado)* | Flags de JVM |

---

## 💾 Backups del mundo

Los datos se guardan en el volumen Docker `minecraft_data`. Para hacer backup:

```bash
# Crear backup
docker run --rm \
  -v minecraft_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/mundo-backup-$(date +%Y%m%d).tar.gz /data

# Restaurar backup
docker run --rm \
  -v minecraft_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/mundo-backup-YYYYMMDD.tar.gz -C /
```

---

## 🔧 Comandos útiles

```bash
# Ver estado del servidor
docker compose ps

# Reiniciar el servidor
docker compose restart minecraft

# Parar el servidor (guarda el mundo)
docker compose stop minecraft

# Ver logs
docker compose logs -f minecraft

# Entrar a la consola del servidor
docker attach minecraft-26-2
# (usa Ctrl+P, Ctrl+Q para salir sin matar el proceso)

# Reconstruir la imagen
docker compose build --no-cache
docker compose up -d
```

---

## 📋 Requisitos mínimos de VPS

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| CPU | 2 vCPU | 4 vCPU |
| RAM | 3 GB | 6 GB |
| Disco | 20 GB | 40 GB SSD |
| OS | Ubuntu 22.04+ | Ubuntu 24.04 |

---

## 📜 Novedades de Minecraft 26.2 – Chaos Cubed

- **Sulfur Caves**: nuevo bioma subterráneo con bloques de azufre y cinabrio.
- **Sulfur Cube**: nueva mob pasiva que absorbe bloques y cambia de comportamiento.
- **Potent Sulfur**: genera géiseres y nubes de gas tóxico.
- **Vulkan** (experimental): nuevo backend de renderizado.
- **Friends List**: lista de amigos integrada.
- Requiere **Java SE 25**.

---

## 🔗 Links útiles

- [Wiki oficial 26.2](https://minecraft.wiki/w/Java_Edition_26.2)
- [Dokploy Docs](https://docs.dokploy.com)
- [EULA de Minecraft](https://aka.ms/MinecraftEULA)
