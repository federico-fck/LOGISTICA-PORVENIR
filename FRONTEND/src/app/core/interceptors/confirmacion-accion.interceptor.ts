import { HttpEventType, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { tap } from 'rxjs';

import { ConfirmacionAccionService } from '../feedback/confirmacion-accion.service';

const METODOS_CON_ACCION = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);

export const confirmacionAccionInterceptor: HttpInterceptorFn = (request, next) => {
  const metodo = request.method.toUpperCase();

  if (!METODOS_CON_ACCION.has(metodo) || esAccionSilenciosa(request.url)) {
    return next(request);
  }

  const confirmacionService = inject(ConfirmacionAccionService);

  return next(request).pipe(
    tap((event) => {
      if (event.type !== HttpEventType.Response) {
        return;
      }

      confirmacionService.mostrar(mensajeParaAccion(metodo, request.urlWithParams));
    }),
  );
};

function esAccionSilenciosa(url: string): boolean {
  return rutaLimpia(url).endsWith('/auth/login');
}

function mensajeParaAccion(metodo: string, url: string): string {
  const ruta = rutaLimpia(url);

  if (ruta.includes('/notificaciones/marcar-todas-leidas')) {
    return 'Notificaciones marcadas como leidas correctamente.';
  }

  if (ruta.includes('/marcar-leida')) {
    return 'Notificacion marcada como leida correctamente.';
  }

  if (ruta.includes('/aprobar')) {
    return 'Pedido aprobado correctamente.';
  }

  if (ruta.includes('/rechazar')) {
    return 'Pedido rechazado correctamente.';
  }

  if (ruta.includes('/observar')) {
    return 'Pedido observado correctamente.';
  }

  if (ruta.includes('/cancelar')) {
    return 'Pedido anulado correctamente.';
  }

  if (ruta.includes('/enviar-despacho')) {
    return 'Pedido enviado a preparacion de despacho.';
  }

  if (ruta.includes('/activar')) {
    return mensajeEntidad(ruta, 'activado', 'activada') ?? 'Registro activado correctamente.';
  }

  if (ruta.includes('/desactivar')) {
    return mensajeEntidad(ruta, 'desactivado', 'desactivada') ?? 'Registro desactivado correctamente.';
  }

  if (ruta.includes('/inventario-despachos/transferencias')) {
    return 'Transferencia registrada correctamente.';
  }

  if (ruta.includes('/inventario-despachos/devoluciones')) {
    return 'Devolucion registrada correctamente.';
  }

  if (ruta.includes('/inventario-despachos/movimientos')) {
    return 'Movimiento de inventario registrado correctamente.';
  }

  if (ruta.includes('/inventario-despachos/despachos')) {
    return metodo === 'DELETE'
      ? 'Despacho eliminado correctamente.'
      : 'Despacho generado correctamente.';
  }

  if (metodo === 'POST') {
    return mensajeEntidad(ruta, 'creado', 'creada') ?? 'Registro creado correctamente.';
  }

  if (metodo === 'DELETE') {
    return mensajeEntidad(ruta, 'eliminado', 'eliminada') ?? 'Registro eliminado correctamente.';
  }

  return mensajeEntidad(ruta, 'actualizado', 'actualizada') ?? 'Registro actualizado correctamente.';
}

function mensajeEntidad(ruta: string, masculino: string, femenino: string): string | null {
  const entidad = entidadParaRuta(ruta);

  if (!entidad) {
    return null;
  }

  const accion = entidad.genero === 'femenino' ? femenino : masculino;
  return `${entidad.nombre} ${accion} correctamente.`;
}

function entidadParaRuta(ruta: string): { nombre: string; genero: 'masculino' | 'femenino' } | null {
  const entidades: Array<{
    patron: string;
    nombre: string;
    genero: 'masculino' | 'femenino';
  }> = [
    {
      patron: '/compras-comprobantes/ordenes-compra',
      nombre: 'Orden de compra',
      genero: 'femenino',
    },
    {
      patron: '/compras-comprobantes/recepciones',
      nombre: 'Recepcion',
      genero: 'femenino',
    },
    {
      patron: '/compras-comprobantes/comprobantes',
      nombre: 'Comprobante',
      genero: 'masculino',
    },
    {
      patron: '/notificaciones',
      nombre: 'Notificacion',
      genero: 'femenino',
    },
    {
      patron: '/proveedores',
      nombre: 'Proveedor',
      genero: 'masculino',
    },
    {
      patron: '/almacenes',
      nombre: 'Almacen',
      genero: 'masculino',
    },
    {
      patron: '/usuarios',
      nombre: 'Usuario',
      genero: 'masculino',
    },
    {
      patron: '/insumos',
      nombre: 'Insumo',
      genero: 'masculino',
    },
    {
      patron: '/pedidos',
      nombre: 'Pedido',
      genero: 'masculino',
    },
  ];

  return entidades.find((entidad) => ruta.includes(entidad.patron)) ?? null;
}

function rutaLimpia(url: string): string {
  const sinQuery = url.split('?')[0].toLowerCase();

  try {
    return new URL(sinQuery, window.location.origin).pathname;
  } catch {
    return sinQuery.startsWith('/') ? sinQuery : `/${sinQuery}`;
  }
}
