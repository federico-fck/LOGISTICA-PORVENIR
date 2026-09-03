import { Injectable } from '@angular/core';
import { MenuGroup } from '../models/menu.model';
import { AuthState } from '../state/auth.state';
import { PermissionService } from './permission.service';

@Injectable({
  providedIn: 'root',
})
export class MenuService {
  constructor(
    private readonly authState: AuthState,
    private readonly permissionService: PermissionService,
  ) {}

  private readonly menu: MenuGroup[] = [
    {
      grupo: 'Principal',
      items: [
        {
          titulo: 'Dashboard',
          ruta: '/dashboard',
          icono: '\u{1F4CA}',
          permiso: 'dashboard.ver',
        },
      ],
    },
    {
      grupo: 'Administracion',
      items: [
        {
          titulo: 'Usuarios',
          ruta: '/usuarios',
          icono: '\u{1F465}',
          permiso: 'usuarios.ver',
        },
        {
          titulo: 'Auditoria',
          ruta: '/auditoria',
          icono: '\u{1F9FE}',
          permiso: 'auditoria.ver',
        },
      ],
    },
    {
      grupo: 'Catalogos',
      items: [
        {
          titulo: 'Almacenes',
          ruta: '/almacenes',
          icono: '\u{1F4E6}',
          permiso: 'almacenes.ver',
        },
        {
          titulo: 'Proveedores',
          ruta: '/proveedores',
          icono: '\u{1F91D}',
          permiso: 'proveedores.ver',
        },
        {
          titulo: 'Insumos',
          ruta: '/insumos',
          icono: '\u{1F9F0}',
          permiso: 'insumos.ver',
        },
      ],
    },
    {
      grupo: 'Operacion logistica',
      items: [
        {
          titulo: 'Inventario y Despachos',
          ruta: '/inventario-despachos',
          icono: '\u{1F69A}',
          permisos: ['inventario.ver', 'despachos.ver'],
        },
        {
          titulo: 'Pedidos',
          ruta: '/pedidos',
          icono: '\u{1F4DD}',
          permiso: 'pedidos.ver',
        },
        {
          titulo: 'Compras y Comprobantes',
          ruta: '/compras-comprobantes',
          icono: '\u{1F6D2}',
          permisos: ['compras.ver', 'recepciones.ver', 'comprobantes.ver'],
        },
      ],
    },
    {
      grupo: 'Seguimiento',
      items: [
        {
          titulo: 'Reportes',
          ruta: '/reportes',
          icono: '\u{1F4C8}',
          permiso: 'reportes.ver',
        },
        {
          titulo: 'Notificaciones',
          ruta: '/notificaciones',
          icono: '\u{1F514}',
          permiso: 'notificaciones.ver',
        },
      ],
    },
  ];

  obtenerMenu() {
    return this.menu
      .map((grupo) => ({
        ...grupo,
        items: grupo.items.filter((item) => {
          if (item.permiso) {
            return this.permissionService.tienePermiso(item.permiso);
          }

          if (item.permisos) {
            return this.permissionService.tieneAlgunPermiso(item.permisos);
          }

          return this.authState.tieneRol(item.roles || []);
        }),
      }))
      .filter((grupo) => grupo.items.length > 0);
  }
}
