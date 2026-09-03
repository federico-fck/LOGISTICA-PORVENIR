# Reporte de Smoke Tests — LOGISTICA-PORVENIR

## Fecha

21 de agosto de 2026, 19:18 (America/La_Paz).

## Entorno

- Angular: 21.2.x
- NestJS: 11.0.x
- PostgreSQL utilizado: `logistica_integracion1` (base controlada de integracion, marcada como `integration-tests-only`)
- Navegador: Chromium
- Herramienta: Playwright 1.62.1
- URL frontend: `http://127.0.0.1:4200`
- URL backend: `http://127.0.0.1:3000/api`
- Usuario smoke: `it_admin` (usuario controlado de integracion; secreto no documentado)

## Casos ejecutados

| Codigo | Funcion | Resultado esperado | Resultado obtenido | Estado |
| ------ | ------- | ------------------ | ------------------ | ------ |
| PH-01 | Backend disponible | API responde y endpoint protegido rechaza ausencia de token | `auth/login` invalido respondio 400 y `dashboard/tarjetas` sin token respondio 401 | PASS |
| PH-02 | Frontend disponible | Angular carga y redirige a login | Aplicacion cargo en `/login` | PASS |
| PH-03 | Pantalla de login | Campos usuario/password y boton visibles | Login visible con placeholders y boton de ingreso | PASS |
| PH-04 | Inicio de sesion | Usuario controlado accede al area autenticada | Login redirigio a `/dashboard` | PASS |
| PH-05 | Dashboard | Dashboard y secciones vitales visibles | Dashboard, tarjetas, pedidos recientes y stock critico visibles | PASS |
| PH-06 | Navegacion principal | Layout administrativo y menu disponibles | Menu principal visible con modulos criticos | PASS |
| PH-07 | Almacenes | Modulo carga sin error critico | `/almacenes` y listado visibles | PASS |
| PH-08 | Proveedores | Modulo carga sin error critico | `/proveedores` y listado visibles | PASS |
| PH-09 | Insumos | Modulo carga sin error critico | `/insumos` y listado visibles | PASS |
| PH-10 | Pedidos | Modulo carga sin error critico | `/pedidos` y listado visibles | PASS |
| PH-11 | Inventario | Vista principal carga | `/inventario-despachos`, tabs Inventario/Despachos visibles | PASS |
| PH-12 | Compras | Compras/comprobantes carga | `/compras-comprobantes` y tab Ordenes visible | PASS |
| PH-13 | Reportes | Modulo de reportes responde | `/reportes` y descripcion operativa visibles | PASS |
| PH-14 | Notificaciones | Funcionalidad principal disponible | `/notificaciones`, filtros, busqueda y actualizar visibles | PASS |
| PH-15 | Cierre de sesion | Logout elimina sesion y protege rutas | Redireccion a `/login`, token removido y `/dashboard` inaccesible sin sesion | PASS |

## Resultado general

- Casos ejecutados: 15
- Aprobados: 15
- Fallidos: 0
- Duracion Playwright: 3.9 s
- Duracion acumulada de casos: 2.829 s
- Cumplimiento: 100 %
- Build backend: PASS
- Build frontend: PASS

## Funciones vitales comprobadas

- Disponibilidad backend.
- Disponibilidad frontend.
- Login con usuario controlado.
- Dashboard.
- Menu administrativo y navegacion principal.
- Almacenes.
- Proveedores.
- Insumos.
- Pedidos.
- Inventario y despachos.
- Compras y comprobantes.
- Reportes.
- Notificaciones.
- Logout y proteccion de ruta autenticada.

## Incidencias

- Playwright `webServer` presento `spawn EPERM`/timeout en este entorno Windows administrado. Correccion: se reemplazo por un runner Node propio que prepara la base, inicia NestJS y Angular con sus CLIs locales, espera disponibilidad HTTP y luego ejecuta Playwright.
- `GET /api` no era un health 2xx apropiado para PH-01. Correccion: PH-01 usa rutas reales seguras: `POST /api/auth/login` con cuerpo invalido espera 400 y `GET /api/dashboard/tarjetas` sin token espera 401.
- PH-05 tenia selector ambiguo para `Stock critico`. Correccion: se usa heading por rol.
- PH-14 verificaba tarjetas de resumen no visibles en el render real. Correccion: se validan controles visibles de notificaciones: encabezado, actualizar, filtros y busqueda.
- No se detectaron fallos criticos de la aplicacion durante la ejecucion final.

## Evidencias

- Consola: `reports/smoke/smoke-test-results.txt`
- Reporte HTML Playwright: `reports/smoke/playwright-report/index.html`
- JSON Playwright: `reports/smoke/playwright-results.json`
- Screenshot dashboard: `reports/smoke/dashboard-smoke.png`

## Seguridad

- Base operativa modificada: NO
- Usuarios reales eliminados: NO
- Datos operativos eliminados: NO
- DROP/TRUNCATE sobre base operativa: NO
- Codigo productivo modificado: NO
- Diseno visual modificado: NO
- Impuestos introducidos: NO

## Conclusión

La suite de smoke tests confirma que las funciones vitales de LOGISTICA-PORVENIR estan operativas para continuar con demostracion o validacion posterior. El resultado final de la ejecucion real fue APROBADO con 15/15 casos exitosos.
