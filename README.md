# Servidor Minecraft Java Edition 26.2 - Chaos Cubed

Servidor Docker listo para desplegar en una VPS con Dokploy o Coolify, ahora preparado para usar `Fabric` y una base de mods sencilla.

## Contenido del proyecto

```text
minecraft-server/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── mods/
│   ├── client/
│   │   └── README.md
│   └── server/
│       └── README.md
└── README.md
```

## Que cambio

- El contenedor arranca en modo `Fabric` por defecto.
- Los mods del servidor se montan desde `./mods/server`.
- Se agrega `./mods/client` para guardar el pack recomendado para los jugadores.
- La instancia Docker usa el nombre `chaos-cubed-server`.
- El servidor Java usa el puerto `25566`.
- Si quieres volver a vanilla, cambia `SERVER_FLAVOR` a `vanilla`.

## Despliegue

### Opcion A - Desde repositorio Git

1. Sube esta carpeta a GitHub o GitLab.
2. En Dokploy crea un servicio tipo `Docker Compose`.
3. Conecta el repositorio.
4. Despliega normalmente.

### Opcion B - Subiendo archivos

1. Crea un servicio `Docker Compose`.
2. Pega el contenido de `docker-compose.yml`.
3. Sube `Dockerfile`, `entrypoint.sh` y la carpeta `mods`.
4. Despliega.

## Configuracion principal

### Variables de entorno

| Variable | Default | Descripcion |
|----------|---------|-------------|
| `SERVER_FLAVOR` | `fabric` | `fabric` para mods o `vanilla` para servidor sin mods |
| `FABRIC_LOADER_VERSION` | `stable` | Version del loader de Fabric |
| `FABRIC_INSTALLER_VERSION` | `stable` | Version del instalador de Fabric |
| `EULA` | `false` | Debe ser `true` para aceptar el EULA |
| `TZ` | `America/Bogota` | Zona horaria del contenedor |
| `JAVA_OPTS` | ver compose | Flags de JVM |

### RAM sugerida

| Jugadores | `-Xms` | `-Xmx` | RAM del contenedor |
|-----------|--------|--------|-------------------|
| 1-5       | 1G     | 2G     | 3G                |
| 5-15      | 2G     | 4G     | 5G                |
| 15-30     | 3G     | 6G     | 7G                |
| 30+       | 4G     | 8G     | 10G               |

## Mods del servidor

Coloca los `.jar` compatibles en:

```text
mods/server
```

Esa carpeta se monta automaticamente como:

```text
/minecraft/data/mods
```

### Base recomendada para el server

- `fabric-api`
- `lithium`
- `ferrite-core`
- `servercore`
- `spark`

## Mods del cliente

Guarda el pack recomendado para los jugadores en:

```text
mods/client
```

Cada jugador debe copiar esos `.jar` a su carpeta local de Minecraft:

```text
Windows: %APPDATA%\.minecraft\mods
Linux:   ~/.minecraft/mods
macOS:   ~/Library/Application Support/minecraft/mods
```

### Base recomendada para el PC

- `fabric-api`
- `modmenu`
- `sodium`
- `lithium`
- `ferrite-core`

## Nota importante

Con esta seleccion basica, el servidor queda listo para usar mods de Fabric, pero los `.jar` deben descargarse en versiones compatibles con `MC_VERSION` y con el loader configurado. El repo deja la estructura preparada y separa claramente lo que va en el servidor y lo que va en el cliente.

## Comandos utiles

```bash
docker compose build --no-cache
docker compose up -d
docker compose logs -f minecraft
docker compose restart minecraft
docker compose stop minecraft
```

## Backups

Los datos del mundo y configuracion siguen persistiendo en el volumen Docker `minecraft_data`.

```bash
docker run --rm \
  -v minecraft_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/mundo-backup-$(date +%Y%m%d).tar.gz /data
```

## Links utiles

- [Fabric](https://fabricmc.net/)
- [Dokploy Docs](https://docs.dokploy.com)
- [EULA de Minecraft](https://aka.ms/MinecraftEULA)
