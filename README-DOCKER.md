# Dockerizacion LOGISTICA-PORVENIR

Esta configuracion levanta PostgreSQL, el backend NestJS y el frontend Angular servido con Nginx.

## Requisitos

- Docker Desktop instalado
- Docker Compose

## Levantar sistema

Desde la raiz del proyecto:

```bash
cd /d/PROYECTO
docker compose up --build
```

## Accesos

Frontend:
http://localhost:8080

Backend:
http://localhost:3000/api

Swagger:
http://localhost:3000/api/docs

Swagger por proxy Nginx:
http://localhost:8080/api/docs

PostgreSQL:

- Host: localhost
- Puerto: 5432
- Database: insumos
- User: postgres
- Password: definido localmente en `.env.docker`

## Detener

```bash
docker compose down
```

## Detener y borrar volumen

Esto borra los datos guardados en el volumen Docker de PostgreSQL.

```bash
docker compose down -v
```

## Ver logs

```bash
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f db
```

## Base de datos existente

Docker crea una base nueva dentro del contenedor. La base actual de DBeaver llamada `insumos` no se importa automaticamente.

Opcion A: levantar base vacia.

El backend actualmente tiene `synchronize: false` en TypeORM. Si se mantiene asi, la base vacia no creara tablas automaticamente; debes importar un dump o ejecutar los SQL/migraciones del proyecto. Si en algun momento activas `synchronize`, TypeORM podria crear tablas al iniciar.

Opcion B: importar dump SQL.

Exportar desde Windows, DBeaver o `pg_dump`:

```bash
pg_dump -U postgres -h localhost -p 5432 -d insumos -f backup_insumos.sql
```

Copiar al contenedor:

```bash
docker cp backup_insumos.sql logistica_porvenir_db:/backup_insumos.sql
```

Importar:

```bash
docker exec -it logistica_porvenir_db psql -U postgres -d insumos -f /backup_insumos.sql
```

## Variables de entorno

La configuracion Docker usa `.env.docker` en la raiz.

Valores principales:

- `DB_HOST=db`
- `DB_PORT=5432`
- `DB_USERNAME=postgres`
- `DB_PASSWORD=<set-docker-password>`
- `DB_DATABASE=insumos`
- `DB_SCHEMA=public`
- `JWT_SECRET=<set-long-random-jwt-secret>`
- `JWT_EXPIRES_IN=8h`
- `PORT=3000`
- `NODE_ENV=production`
- `CORS_ORIGIN=http://localhost:8080`

## Frontend y API

En desarrollo local, Angular conserva `http://localhost:3000/api`.

En Docker, el build del frontend usa `src/environments/environment.docker.ts` con:

```ts
apiUrl: '/api'
```

Nginx sirve Angular en `http://localhost:8080` y hace proxy:

```text
http://localhost:8080/api -> http://backend:3000/api
```

## Problemas comunes

Puerto 5432 ocupado:

Si tienes PostgreSQL local usando el puerto 5432, cambia el puerto externo del servicio `db` en `docker-compose.yml`, por ejemplo `5433:5432`.

Puerto 3000 ocupado:

Deten el backend local o cambia el puerto externo del servicio `backend`.

Puerto 8080 ocupado:

Cambia el puerto externo del servicio `frontend`, por ejemplo `8081:80`.

Backend no conecta a DB:

Verifica que `DB_HOST=db` en `.env.docker` y revisa:

```bash
docker compose logs -f backend
docker compose logs -f db
```

Frontend no llama API:

Usa el frontend Docker desde `http://localhost:8080`. En Docker, la API se consume con `/api` y Nginx la proxya al backend.

CORS:

Para Docker, `CORS_ORIGIN` debe incluir `http://localhost:8080`. Para desarrollo con Angular en `http://localhost:4200`, puedes dejar el backend local sin `CORS_ORIGIN` o agregar ambos origenes separados por coma:

```bash
CORS_ORIGIN=http://localhost:8080,http://localhost:4200
```

## Comando final

Ejecuta manualmente:

```bash
cd /d/PROYECTO
docker compose up --build
```

Luego abre:

http://localhost:8080
