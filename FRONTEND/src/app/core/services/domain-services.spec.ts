import { of } from 'rxjs';

import { AlmacenesService } from './almacenes.service';
import { AuditoriaService } from './auditoria.service';
import { ComprasComprobantesService } from './compras-comprobantes.service';
import { DashboardService } from './dashboard.service';
import { InsumosService } from './insumos.service';
import { InventarioDespachosService } from './inventario-despachos.service';
import { NotificacionesService } from './notificaciones.service';
import { PedidosService } from './pedidos.service';
import { ProveedoresService } from './proveedores.service';
import { UsuariosService } from './usuarios.service';

function crearApiMock() {
  return {
    get: vi.fn(() => of([])),
    post: vi.fn(() => of({})),
    patch: vi.fn(() => of({})),
    delete: vi.fn(() => of({})),
  };
}

describe('Servicios de dominio', () => {
  it('AlmacenesService delega endpoints CRUD y acciones de estado', () => {
    const api = crearApiMock();
    const service = new AlmacenesService(api as any);
    const body = { codigoAlmacen: 'ALM-1' };

    service.listar().subscribe();
    service.tipos().subscribe();
    service.buscarPorId(7).subscribe();
    service.crear(body).subscribe();
    service.actualizar(7, body).subscribe();
    service.activar(7).subscribe();
    service.desactivar(7).subscribe();
    service.eliminar(7).subscribe();

    expect(api.get).toHaveBeenNthCalledWith(1, 'almacenes');
    expect(api.get).toHaveBeenNthCalledWith(2, 'almacenes/tipos');
    expect(api.get).toHaveBeenNthCalledWith(3, 'almacenes/7');
    expect(api.post).toHaveBeenCalledWith('almacenes', body);
    expect(api.patch).toHaveBeenCalledWith('almacenes/7', body);
    expect(api.patch).toHaveBeenCalledWith('almacenes/7/activar', {});
    expect(api.patch).toHaveBeenCalledWith('almacenes/7/desactivar', {});
    expect(api.delete).toHaveBeenCalledWith('almacenes/7');
  });

  it('ProveedoresService e InsumosService usan los contratos HTTP esperados', () => {
    const api = crearApiMock();
    const proveedores = new ProveedoresService(api as any);
    const insumos = new InsumosService(api as any);

    proveedores.listar().subscribe();
    proveedores.actualizar(4, { nit: '123' }).subscribe();
    proveedores.eliminar(4).subscribe();
    insumos.catalogos().subscribe();
    insumos.buscarPorId(8).subscribe();
    insumos.crear({ codigoInterno: 'INS-1' }).subscribe();
    insumos.desactivar(8).subscribe();

    expect(api.get).toHaveBeenCalledWith('proveedores');
    expect(api.patch).toHaveBeenCalledWith('proveedores/4', { nit: '123' });
    expect(api.delete).toHaveBeenCalledWith('proveedores/4');
    expect(api.get).toHaveBeenCalledWith('insumos/catalogos');
    expect(api.get).toHaveBeenCalledWith('insumos/8');
    expect(api.post).toHaveBeenCalledWith('insumos', { codigoInterno: 'INS-1' });
    expect(api.patch).toHaveBeenCalledWith('insumos/8/desactivar', {});
  });

  it('UsuariosService conserva rutas de roles, areas y estado', () => {
    const api = crearApiMock();
    const service = new UsuariosService(api as any);

    service.listar().subscribe();
    service.listarRoles().subscribe();
    service.listarAreas().subscribe();
    service.buscarPorId(2).subscribe();
    service.crear({ nombreUsuario: 'ana' }).subscribe();
    service.actualizar(2, { estado: 'ACTIVO' }).subscribe();
    service.activar(2).subscribe();
    service.desactivar(2).subscribe();
    service.eliminar(2).subscribe();

    expect(api.get).toHaveBeenCalledWith('usuarios');
    expect(api.get).toHaveBeenCalledWith('usuarios/roles');
    expect(api.get).toHaveBeenCalledWith('usuarios/areas');
    expect(api.get).toHaveBeenCalledWith('usuarios/2');
    expect(api.post).toHaveBeenCalledWith('usuarios', { nombreUsuario: 'ana' });
    expect(api.patch).toHaveBeenCalledWith('usuarios/2', { estado: 'ACTIVO' });
    expect(api.patch).toHaveBeenCalledWith('usuarios/2/activar', {});
    expect(api.patch).toHaveBeenCalledWith('usuarios/2/desactivar', {});
    expect(api.delete).toHaveBeenCalledWith('usuarios/2');
  });

  it('PedidosService delega estados y transiciones permitidas', () => {
    const api = crearApiMock();
    const service = new PedidosService(api as any);

    service.listar().subscribe();
    service.estados().subscribe();
    service.buscarPorId(11).subscribe();
    service.crear({ prioridad: 'ALTA' } as any).subscribe();
    service.actualizar(11, { prioridad: 'MEDIA' } as any).subscribe();
    service.aprobar(11, { usuarioRevisa: 1, detalles: [] } as any).subscribe();
    service.rechazar(11, { usuarioRevisa: 1, motivoRechazo: 'Duplicado' }).subscribe();
    service.observar(11, { usuarioRevisa: 1, motivoObservacion: 'Falta dato' }).subscribe();
    service.enviarADespacho(11).subscribe();
    service.cancelar(11).subscribe();

    expect(api.get).toHaveBeenCalledWith('pedidos');
    expect(api.get).toHaveBeenCalledWith('pedidos/estados');
    expect(api.get).toHaveBeenCalledWith('pedidos/11');
    expect(api.post).toHaveBeenCalledWith('pedidos', { prioridad: 'ALTA' });
    expect(api.patch).toHaveBeenCalledWith('pedidos/11', { prioridad: 'MEDIA' });
    expect(api.patch).toHaveBeenCalledWith('pedidos/11/aprobar', {
      usuarioRevisa: 1,
      detalles: [],
    });
    expect(api.patch).toHaveBeenCalledWith('pedidos/11/rechazar', {
      usuarioRevisa: 1,
      motivoRechazo: 'Duplicado',
    });
    expect(api.patch).toHaveBeenCalledWith('pedidos/11/observar', {
      usuarioRevisa: 1,
      motivoObservacion: 'Falta dato',
    });
    expect(api.patch).toHaveBeenCalledWith('pedidos/11/enviar-despacho', {});
    expect(api.patch).toHaveBeenCalledWith('pedidos/11/cancelar', {});
  });

  it('ComprasComprobantesService no altera endpoints de ordenes, recepciones y comprobantes', () => {
    const api = crearApiMock();
    const service = new ComprasComprobantesService(api as any);

    service.estados().subscribe();
    service.ordenesCompra().subscribe();
    service.buscarOrdenCompraPorId(3).subscribe();
    service.crearOrdenCompra({ idProveedor: 1 }).subscribe();
    service.actualizarOrdenCompra(3, { estado: 'BORRADOR' }).subscribe();
    service.eliminarOrdenCompra(3).subscribe();
    service.recepciones().subscribe();
    service.buscarRecepcionPorId(6).subscribe();
    service.crearRecepcion({ idOrdenCompra: 3 }).subscribe();
    service.comprobantes().subscribe();
    service.buscarComprobantePorId(9).subscribe();
    service.crearComprobante({ numeroComprobante: 'F-1' }).subscribe();
    service.eliminarComprobante(9).subscribe();

    expect(api.get).toHaveBeenCalledWith('compras-comprobantes/estados');
    expect(api.get).toHaveBeenCalledWith('compras-comprobantes/ordenes-compra');
    expect(api.get).toHaveBeenCalledWith('compras-comprobantes/ordenes-compra/3');
    expect(api.post).toHaveBeenCalledWith('compras-comprobantes/ordenes-compra', {
      idProveedor: 1,
    });
    expect(api.patch).toHaveBeenCalledWith('compras-comprobantes/ordenes-compra/3', {
      estado: 'BORRADOR',
    });
    expect(api.delete).toHaveBeenCalledWith('compras-comprobantes/ordenes-compra/3');
    expect(api.get).toHaveBeenCalledWith('compras-comprobantes/recepciones');
    expect(api.get).toHaveBeenCalledWith('compras-comprobantes/recepciones/6');
    expect(api.post).toHaveBeenCalledWith('compras-comprobantes/recepciones', {
      idOrdenCompra: 3,
    });
    expect(api.get).toHaveBeenCalledWith('compras-comprobantes/comprobantes');
    expect(api.get).toHaveBeenCalledWith('compras-comprobantes/comprobantes/9');
    expect(api.post).toHaveBeenCalledWith('compras-comprobantes/comprobantes', {
      numeroComprobante: 'F-1',
    });
    expect(api.delete).toHaveBeenCalledWith('compras-comprobantes/comprobantes/9');
  });

  it('InventarioDespachosService conserva rutas operativas', () => {
    const api = crearApiMock();
    const service = new InventarioDespachosService(api as any);

    service.inventario().subscribe();
    service.stockBajo().subscribe();
    service.movimientos().subscribe();
    service.registrarMovimiento({ idInsumo: 1 } as any).subscribe();
    service.registrarTransferencia({ idInsumo: 1 } as any).subscribe();
    service.registrarDevolucion({ idInsumo: 1 } as any).subscribe();
    service.despachos().subscribe();
    service.pedidosAprobadosParaDespacho().subscribe();
    service.buscarDespachoPorId(12).subscribe();
    service.crearDespacho({ idPedido: 2 } as any).subscribe();
    service.areasSistema().subscribe();
    service.usuariosSistema().subscribe();

    expect(api.get).toHaveBeenCalledWith('inventario-despachos/inventario');
    expect(api.get).toHaveBeenCalledWith('inventario-despachos/stock-bajo');
    expect(api.get).toHaveBeenCalledWith('inventario-despachos/movimientos');
    expect(api.post).toHaveBeenCalledWith('inventario-despachos/movimientos', {
      idInsumo: 1,
    });
    expect(api.post).toHaveBeenCalledWith('inventario-despachos/transferencias', {
      idInsumo: 1,
    });
    expect(api.post).toHaveBeenCalledWith('inventario-despachos/devoluciones', {
      idInsumo: 1,
    });
    expect(api.get).toHaveBeenCalledWith('inventario-despachos/despachos');
    expect(api.get).toHaveBeenCalledWith(
      'inventario-despachos/despachos/pedidos-aprobados',
    );
    expect(api.get).toHaveBeenCalledWith('inventario-despachos/despachos/12');
    expect(api.post).toHaveBeenCalledWith('inventario-despachos/despachos', {
      idPedido: 2,
    });
    expect(api.get).toHaveBeenCalledWith('usuarios/areas');
    expect(api.get).toHaveBeenCalledWith('usuarios');
  });

  it('DashboardService, AuditoriaService y NotificacionesService delegan consultas y cambios', () => {
    const api = crearApiMock();
    const dashboard = new DashboardService(api as any);
    const auditoria = new AuditoriaService(api as any);
    const notificaciones = new NotificacionesService(api as any);
    const cambios = vi.fn();

    notificaciones.cambios$.subscribe(cambios);
    notificaciones.notificarCambio();

    dashboard.tarjetas().subscribe();
    dashboard.ultimosPedidos().subscribe();
    dashboard.stockBajo().subscribe();
    dashboard.resumen().subscribe();
    dashboard.alertas().subscribe();
    auditoria.listar({ tipoAccion: 'CREAR' } as any).subscribe();
    auditoria.tipos().subscribe();
    auditoria.resumen().subscribe();
    auditoria.buscarPorId(5).subscribe();
    notificaciones.listar({ idUsuario: 1, estado: 'NO_LEIDA' }).subscribe();
    notificaciones.buscarPorId(9).subscribe();
    notificaciones.marcarComoLeida(9).subscribe();
    notificaciones.marcarTodasComoLeidas(1).subscribe();
    notificaciones.marcarTodasComoLeidas().subscribe();
    notificaciones.contarNoLeidas(1).subscribe();
    notificaciones.eliminar(9).subscribe();

    expect(cambios).toHaveBeenCalledTimes(1);
    expect(api.get).toHaveBeenCalledWith('dashboard/tarjetas');
    expect(api.get).toHaveBeenCalledWith('dashboard/ultimos-pedidos');
    expect(api.get).toHaveBeenCalledWith('dashboard/stock-bajo');
    expect(api.get).toHaveBeenCalledWith('dashboard/resumen');
    expect(api.get).toHaveBeenCalledWith('dashboard/alertas');
    expect(api.get).toHaveBeenCalledWith('auditoria', { tipoAccion: 'CREAR' });
    expect(api.get).toHaveBeenCalledWith('auditoria/tipos');
    expect(api.get).toHaveBeenCalledWith('auditoria/resumen');
    expect(api.get).toHaveBeenCalledWith('auditoria/5');
    expect(api.get).toHaveBeenCalledWith('notificaciones', {
      idUsuario: 1,
      estado: 'NO_LEIDA',
    });
    expect(api.get).toHaveBeenCalledWith('notificaciones/9');
    expect(api.patch).toHaveBeenCalledWith('notificaciones/9/marcar-leida', {});
    expect(api.patch).toHaveBeenCalledWith(
      'notificaciones/marcar-todas-leidas?idUsuario=1',
      {},
    );
    expect(api.patch).toHaveBeenCalledWith('notificaciones/marcar-todas-leidas', {});
    expect(api.get).toHaveBeenCalledWith(
      'notificaciones/usuario/1/contador-no-leidas',
    );
    expect(api.delete).toHaveBeenCalledWith('notificaciones/9');
  });
});
