import { expect, test, type APIRequestContext, type Page } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

const frontendUrl = process.env.SMOKE_FRONTEND_URL || 'http://127.0.0.1:4200';
const backendUrl = process.env.SMOKE_BACKEND_URL || 'http://127.0.0.1:3000/api';
const smokeUser = process.env.SMOKE_USER || 'it_admin';
const smokePassword =
  process.env.SMOKE_PASSWORD ||
  process.env.INTEGRATION_PASSWORD ||
  'IntegrationTest#2026';

const reportsDir = path.resolve(__dirname, '..', '..', '..', 'reports', 'smoke');
const dashboardScreenshot = path.join(reportsDir, 'dashboard-smoke.png');

test.describe.configure({ mode: 'serial' });

test.describe('Smoke Tests LOGISTICA-PORVENIR', () => {
  let page: Page;
  const pageErrors: string[] = [];
  const apiServerErrors: string[] = [];

  test.beforeAll(async ({ browser }) => {
    fs.mkdirSync(reportsDir, { recursive: true });

    page = await browser.newPage({ baseURL: frontendUrl });
    page.on('pageerror', (error) => {
      pageErrors.push(error.message);
    });
    page.on('response', (response) => {
      const url = response.url();
      if (url.includes('/api/') && response.status() >= 500) {
        apiServerErrors.push(`${response.status()} ${url}`);
      }
    });
  });

  test.afterAll(async () => {
    await page?.close();
  });

  async function expectNoCriticalIssues() {
    await page.waitForLoadState('networkidle', { timeout: 5_000 }).catch(() => {});

    expect(pageErrors, `Errores JS no controlados: ${pageErrors.join(' | ')}`).toEqual([]);
    expect(
      apiServerErrors,
      `Respuestas API con error servidor: ${apiServerErrors.join(' | ')}`,
    ).toEqual([]);

    await expect(
      page.getByText(
        /No tiene permisos|Error al cargar|Usuario o contrase(?:ñ|n)a incorrectos|Internal server error/i,
      ),
    ).toHaveCount(0);
  }

  async function expectBackendAvailable(request: APIRequestContext) {
    const response = await request.post(`${backendUrl}/auth/login`, {
      data: {},
    });
    expect(response.status()).toBe(400);
  }

  async function navigateModule(
    menuName: RegExp,
    pathName: string,
    headingName: RegExp,
  ) {
    await page.getByRole('link', { name: menuName }).click();
    await expect(page).toHaveURL(new RegExp(`${pathName}$`));
    await expect(page.getByRole('heading', { name: headingName })).toBeVisible();
    await expectNoCriticalIssues();
  }

  test('PH-01 Backend disponible', async ({ request }) => {
    await expectBackendAvailable(request);

    const protectedResponse = await request.get(`${backendUrl}/dashboard/tarjetas`);
    expect(protectedResponse.status()).toBe(401);
  });

  test('PH-02 Frontend disponible', async () => {
    await page.goto('/');
    await expect(page).toHaveURL(/\/login$/);
    await expect(
      page.getByRole('heading', { name: /LOGÍSTICA PORVENIR/i }).first(),
    ).toBeVisible();
    await expectNoCriticalIssues();
  });

  test('PH-03 Pantalla de login visible', async () => {
    await expect(page.getByPlaceholder('Ingrese su usuario')).toBeVisible();
    await expect(page.getByPlaceholder('Ingrese su contraseña')).toBeVisible();
    await expect(page.getByRole('button', { name: /Ingresar al sistema/i })).toBeVisible();
    await expectNoCriticalIssues();
  });

  test('PH-04 Autenticacion exitosa', async () => {
    await page.getByPlaceholder('Ingrese su usuario').fill(smokeUser);
    await page.getByPlaceholder('Ingrese su contraseña').fill(smokePassword);

    await Promise.all([
      page.waitForURL(/\/dashboard$/),
      page.getByRole('button', { name: /Ingresar al sistema/i }).click(),
    ]);

    await expect(page.getByRole('heading', { name: /^Dashboard$/ })).toBeVisible();
    await expectNoCriticalIssues();
  });

  test('PH-05 Dashboard disponible', async () => {
    await expect(page).toHaveURL(/\/dashboard$/);
    await expect(page.getByText('Insumos activos')).toBeVisible();
    await expect(page.getByText('Almacenes activos')).toBeVisible();
    await expect(page.getByText('Proveedores activos')).toBeVisible();
    await expect(page.getByText('Pedidos recientes')).toBeVisible();
    await expect(page.getByRole('heading', { name: /^Stock crítico$/ })).toBeVisible();

    await page.screenshot({ path: dashboardScreenshot, fullPage: true });
    await expectNoCriticalIssues();
  });

  test('PH-06 Navegacion principal disponible', async () => {
    await expect(page.getByRole('heading', { name: /Cooperativa Minera El Porvenir/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /Dashboard/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /Almacenes/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /Proveedores/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /Insumos/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /Inventario y Despachos/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /Pedidos/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /Compras y Comprobantes/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /Reportes/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /Notificaciones/i })).toBeVisible();
    await expectNoCriticalIssues();
  });

  test('PH-07 Almacenes disponible', async () => {
    await navigateModule(/Almacenes/i, '/almacenes', /^Almacenes$/);
    await expect(page.getByText(/Listado de almacenes/i)).toBeVisible();
  });

  test('PH-08 Proveedores disponible', async () => {
    await navigateModule(/Proveedores/i, '/proveedores', /^Proveedores$/);
    await expect(page.getByText(/Listado de proveedores/i)).toBeVisible();
  });

  test('PH-09 Insumos disponible', async () => {
    await navigateModule(/Insumos/i, '/insumos', /^Insumos$/);
    await expect(page.getByText(/Listado de insumos/i)).toBeVisible();
  });

  test('PH-10 Pedidos disponible', async () => {
    await navigateModule(/Pedidos/i, '/pedidos', /^Pedidos$/);
    await expect(page.getByText(/Listado de pedidos/i)).toBeVisible();
  });

  test('PH-11 Inventario disponible', async () => {
    await navigateModule(
      /Inventario y Despachos/i,
      '/inventario-despachos',
      /^Inventario y Despachos$/,
    );
    await expect(page.getByRole('button', { name: /^Inventario$/ })).toBeVisible();
    await expect(page.getByRole('button', { name: /Despachos/i })).toBeVisible();
  });

  test('PH-12 Compras disponible', async () => {
    await navigateModule(
      /Compras y Comprobantes/i,
      '/compras-comprobantes',
      /^Compras y Comprobantes$/,
    );
    await expect(page.getByRole('button', { name: /Órdenes|Ordenes/i })).toBeVisible();
  });

  test('PH-13 Reportes disponible', async () => {
    await navigateModule(/Reportes/i, '/reportes', /^Reportes$/);
    await expect(page.getByText(/Reportes operativos de inventario/i)).toBeVisible();
  });

  test('PH-14 Notificaciones disponible', async () => {
    await navigateModule(/Notificaciones/i, '/notificaciones', /^Notificaciones$/);
    await expect(page.getByRole('button', { name: /^Actualizar$/ })).toBeVisible();
    await expect(page.getByRole('button', { name: /^Todas$/ })).toBeVisible();
    await expect(page.getByRole('button', { name: /^No leídas$/ })).toBeVisible();
    await expect(page.getByRole('button', { name: /^Leídas$/ })).toBeVisible();
    await expect(page.getByPlaceholder(/Buscar por título/i)).toBeVisible();
  });

  test('PH-15 Cierre de sesion y proteccion de ruta', async () => {
    await page
      .locator('header button')
      .filter({ hasText: /IT Administrador Integracion|Administrador del sistema/i })
      .click();
    await page.getByRole('button', { name: /Cerrar sesi/i }).click();

    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByPlaceholder('Ingrese su usuario')).toBeVisible();
    expect(await page.evaluate(() => localStorage.getItem('logistica_porvenir_token'))).toBeNull();

    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/login$/);
    await expectNoCriticalIssues();
  });
});
