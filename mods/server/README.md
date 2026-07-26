# Mods del servidor

Coloca aqui los `.jar` de los mods que deben cargarse en el servidor.

Esta carpeta se monta automaticamente en `/minecraft/data/mods` dentro del contenedor por medio de `docker-compose.yml`.

## Mods basicos recomendados

- `fabric-api`
- `lithium`
- `ferrite-core`
- `servercore`
- `spark`

## Importante

- Descarga siempre la version compatible con `MC_VERSION` y `Fabric Loader`.
- Los mods de esta carpeta afectan al servidor.
- Si un mod requiere tambien instalacion en cliente, agregalo tambien en `mods/client`.
