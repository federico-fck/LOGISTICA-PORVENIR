import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { ConfirmacionAccionService } from '../../core/feedback/confirmacion-accion.service';
import { ApiService } from '../../core/services/api.service';
import { PermissionService } from '../../core/services/permission.service';
import { AuthState } from '../../core/state/auth.state';
import { Reportes } from './reportes';

describe('Reportes', () => {
  let apiService: { get: ReturnType<typeof vi.fn> };
  let permissionService: {
    tienePermiso: ReturnType<typeof vi.fn>;
    mensajeSinPermiso: string;
  };
  let alertSpy: ReturnType<typeof vi.spyOn>;

  function crearComponente(permisos: string[] | 'todos' = 'todos') {
    apiService = {
      get: vi.fn((endpoint: string) => {
        const respuestas: Record<string, unknown[]> = {
          insumos: [{ idInsumo: 1 }],
          almacenes: [{ idAlmacen: 1 }],
          proveedores: [{ idProveedor: 1 }],
          usuarios: [{ idUsuario: 1 }],
          pedidos: [{ idPedido: 1 }],
          'inventario-despachos/inventario': [{ idInventario: 1 }],
          'inventario-despachos/stock-bajo': [],
          'inventario-despachos/movimientos': [{ idMovimiento: 1 }],
          'inventario-despachos/despachos': [{ idDespacho: 1 }],
          'compras-comprobantes/ordenes-compra': [{ idOrdenCompra: 1 }],
          'compras-comprobantes/recepciones': [{ idRecepcionCompra: 1 }],
          'compras-comprobantes/comprobantes': [{ idComprobanteCompra: 1 }],
          'compras-comprobantes/aprobaciones': [{ idAprobacionPedido: 1 }],
        };

        return of(respuestas[endpoint] ?? []);
      }),
    };
    permissionService = {
      tienePermiso: vi.fn((permiso: string) =>
        permisos === 'todos' ? true : permisos.includes(permiso),
      ),
      mensajeSinPermiso: 'Sin permiso',
    };
    alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {});

    TestBed.configureTestingModule({
      providers: [
        { provide: ApiService, useValue: apiService },
        { provide: ConfirmacionAccionService, useValue: { mostrar: vi.fn() } },
        { provide: PermissionService, useValue: permissionService },
        {
          provide: AuthState,
          useValue: {
            usuario: signal<any>({
              nombreCompleto: 'Ana Rojas',
              nombreUsuario: 'ana',
            }),
          },
        },
      ],
    });

    return TestBed.runInInjectionContext(() => new Reportes());
  }

  afterEach(() => {
    alertSpy?.mockRestore();
    TestBed.resetTestingModule();
  });

  it('carga reportes disponibles segun permisos y normaliza respuestas', () => {
    const component = crearComponente();

    component.cargarReportes();

    expect(component.cargando()).toBe(false);
    expect(component.error()).toBe('');
    expect(component.totalInsumos()).toBe(1);
    expect(component.totalInventario()).toBe(1);
    expect(component.totalOrdenes()).toBe(1);
    expect(apiService.get).toHaveBeenCalledWith('compras-comprobantes/comprobantes');
  });

  it('omite endpoints sin permiso y cambia a primera pestana permitida', () => {
    const component = crearComponente(['pedidos.ver']);

    component.ngOnInit();

    expect(component.tabActual()).toBe('pedidos');
    expect(apiService.get).toHaveBeenCalledWith('pedidos');
    expect(apiService.get).not.toHaveBeenCalledWith('insumos');
    expect(apiService.get).not.toHaveBeenCalledWith(
      'compras-comprobantes/ordenes-compra',
    );
  });

  it('calcula totales de compras y comprobantes con subtotal y descuento', () => {
    const component = crearComponente();
    const orden = {
      numero_orden: 'OC-1',
      proveedor: { razon_social: 'Proveedor Uno' },
      subtotal: 100,
      descuento: 15,
      estado_orden: 'EN_PROCESO',
    };
    const comprobante = {
      numero_comprobante: 'COMP-1',
      tipo_comprobante: 'FACTURA',
      proveedor: { razonSocial: 'Proveedor Uno' },
      monto_subtotal: 200,
      monto_descuento: 25,
      estado_comprobante: 'REGISTRADO',
    };

    component.ordenesCompra.set([orden]);
    component.comprobantes.set([comprobante]);

    expect(component.valorOrden(orden, 'proveedor')).toBe('Proveedor Uno');
    expect(component.valorOrden(orden, 'total')).toBe(85);
    expect(component.valorComprobante(comprobante, 'monto')).toBe(175);
    expect(component.montoTotalOrdenes()).toBe(85);
    expect(component.montoTotalComprobantes()).toBe(175);
  });

  it('filtra datos de tabla por texto, estado y proveedor', () => {
    const component = crearComponente();
    component.tabActual.set('compras');
    component.ordenesCompra.set([
      {
        numeroOrden: 'OC-1',
        proveedor: { razonSocial: 'Proveedor A' },
        estadoOrden: 'EN_PROCESO',
        subtotal: 100,
      },
      {
        numeroOrden: 'OC-2',
        proveedor: { razonSocial: 'Proveedor B' },
        estadoOrden: 'FINALIZADA',
        subtotal: 50,
      },
    ]);

    component.busqueda.set('OC-1');
    component.estadoFiltro.set('EN PROCESO');
    component.proveedorFiltro.set('Proveedor A');

    expect(component.datosFiltrados()).toHaveLength(1);
    expect(component.valorCelda(component.datosFiltrados()[0], 'numero')).toBe('OC-1');
  });

  it('bloquea impresion sin permiso y expone usuario generador', () => {
    const component = crearComponente(['reportes.ver']);

    component.imprimirReporteActual();

    expect(component.error()).toBe('Sin permiso');
    expect(alertSpy).toHaveBeenCalledWith('Sin permiso');
    expect(component.usuarioGeneradorReporte()).toBe('Ana Rojas');
  });
});
