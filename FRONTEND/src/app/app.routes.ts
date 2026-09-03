import { Routes } from '@angular/router';

import { authGuard } from './core/guards/auth.guard';
import { permissionGuard } from './core/guards/permission.guard';

import { AdminLayout } from './layouts/admin-layout/admin-layout';

import { Login } from './pages/auth/login/login';
import { Dashboard } from './pages/dashboard/dashboard';

import { Perfil } from './pages/perfil/perfil';
import { Usuarios } from './pages/usuarios/usuarios';
import { RolesPermisos } from './pages/roles-permisos/roles-permisos';
import { Almacenes } from './pages/almacenes/almacenes';
import { Proveedores } from './pages/proveedores/proveedores';
import { Insumos } from './pages/insumos/insumos';
import { InventarioDespachos } from './pages/inventario-despachos/inventario-despachos-flujo';
import { Pedidos } from './pages/pedidos/pedidos';
import { ComprasComprobantes } from './pages/compras-comprobantes/compras-comprobantes';
import { Reportes } from './pages/reportes/reportes';
import { Notificaciones } from './pages/notificaciones/notificaciones';
import { Auditoria } from './pages/auditoria/auditoria';
import { AccesoDenegado } from './pages/acceso-denegado/acceso-denegado';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'login',
    pathMatch: 'full',
  },
  {
    path: 'login',
    component: Login,
  },
  {
    path: '',
    component: AdminLayout,
    canActivate: [authGuard],
    children: [
      {
        path: 'dashboard',
        component: Dashboard,
        canActivate: [permissionGuard],
        data: { permissions: ['dashboard.ver'] },
      },
      {
        path: 'perfil',
        component: Perfil,
        canActivate: [permissionGuard],
        data: { permissions: ['perfil.ver'] },
      },
      {
        path: 'usuarios',
        component: Usuarios,
        canActivate: [permissionGuard],
        data: { permissions: ['usuarios.ver'] },
      },
      {
        path: 'usuarios/roles-permisos',
        component: RolesPermisos,
        canActivate: [permissionGuard],
        data: { permissions: ['roles.ver'] },
      },
      {
        path: 'roles-permisos',
        redirectTo: 'usuarios/roles-permisos',
        pathMatch: 'full',
      },
      {
        path: 'almacenes',
        component: Almacenes,
        canActivate: [permissionGuard],
        data: { permissions: ['almacenes.ver'] },
      },
      {
        path: 'proveedores',
        component: Proveedores,
        canActivate: [permissionGuard],
        data: { permissions: ['proveedores.ver'] },
      },
      {
        path: 'insumos',
        component: Insumos,
        canActivate: [permissionGuard],
        data: { permissions: ['insumos.ver'] },
      },
      {
        path: 'inventario-despachos',
        component: InventarioDespachos,
        canActivate: [permissionGuard],
        data: { permissions: ['inventario.ver', 'despachos.ver'] },
      },
      {
        path: 'pedidos',
        component: Pedidos,
        canActivate: [permissionGuard],
        data: { permissions: ['pedidos.ver'] },
      },
      {
        path: 'compras-comprobantes',
        component: ComprasComprobantes,
        canActivate: [permissionGuard],
        data: { permissions: ['compras.ver', 'recepciones.ver', 'comprobantes.ver'] },
      },
      {
        path: 'reportes',
        component: Reportes,
        canActivate: [permissionGuard],
        data: { permissions: ['reportes.ver'] },
      },
      {
        path: 'notificaciones',
        component: Notificaciones,
        canActivate: [permissionGuard],
        data: { permissions: ['notificaciones.ver'] },
      },
      {
        path: 'auditoria',
        component: Auditoria,
        canActivate: [permissionGuard],
        data: { permissions: ['auditoria.ver'] },
      },
      {
        path: 'acceso-denegado',
        component: AccesoDenegado,
      },
    ],
  },
  {
    path: '**',
    redirectTo: 'login',
  },
];
