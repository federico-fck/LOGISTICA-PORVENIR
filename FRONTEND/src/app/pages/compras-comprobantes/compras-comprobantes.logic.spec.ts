import { signal } from '@angular/core';
import { FormBuilder } from '@angular/forms';
import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { AlmacenesService } from '../../core/services/almacenes.service';
import { AuthState } from '../../core/state/auth.state';
import { ComprasComprobantesService } from '../../core/services/compras-comprobantes.service';
import { ConfirmacionAccionService } from '../../core/feedback/confirmacion-accion.service';
import { InsumosService } from '../../core/services/insumos.service';
import { PedidosService } from '../../core/services/pedidos.service';
import { PermissionService } from '../../core/services/permission.service';
import { ProveedoresService } from '../../core/services/proveedores.service';
import { ComprasComprobantes } from './compras-comprobantes';

type ComprasServiceMock = {
  ordenesCompra: ReturnType<typeof vi.fn>;
  recepciones: ReturnType<typeof vi.fn>;
  comprobantes: ReturnType<typeof vi.fn>;
  crearOrdenCompra: ReturnType<typeof vi.fn>;
  crearRecepcion: ReturnType<typeof vi.fn>;
  crearComprobante: ReturnType<typeof vi.fn>;
  eliminarOrdenCompra: ReturnType<typeof vi.fn>;
  eliminarComprobante: ReturnType<typeof vi.fn>;
};

describe('ComprasComprobantes logic', () => {
  let comprasService: ComprasServiceMock;
  let permissionService: {
    tienePermiso: ReturnType<typeof vi.fn>;
    mensajeSinPermiso: string;
  };
  let alertSpy: ReturnType<typeof vi.spyOn>;

  function crearComponente(tienePermiso = true) {
    comprasService = {
      ordenesCompra: vi.fn(() => of([])),
      recepciones: vi.fn(() => of([])),
      comprobantes: vi.fn(() => of([])),
      crearOrdenCompra: vi.fn(() => of({})),
      crearRecepcion: vi.fn(() => of({})),
      crearComprobante: vi.fn(() => of({})),
      eliminarOrdenCompra: vi.fn(() => of({})),
      eliminarComprobante: vi.fn(() => of({})),
    };
    permissionService = {
      tienePermiso: vi.fn(() => tienePermiso),
      mensajeSinPermiso: 'Sin permiso',
    };
    alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {});

    TestBed.configureTestingModule({
      providers: [
        FormBuilder,
        { provide: ComprasComprobantesService, useValue: comprasService },
        { provide: PedidosService, useValue: { listar: vi.fn(() => of([])) } },
        { provide: ProveedoresService, useValue: { listar: vi.fn(() => of([])) } },
        { provide: InsumosService, useValue: { listar: vi.fn(() => of([])) } },
        { provide: AlmacenesService, useValue: { listar: vi.fn(() => of([])) } },
        { provide: ConfirmacionAccionService, useValue: { mostrar: vi.fn() } },
        { provide: PermissionService, useValue: permissionService },
        {
          provide: AuthState,
          useValue: {
            usuario: signal<any>({ idUsuario: 5 }),
          },
        },
      ],
    });

    return TestBed.runInInjectionContext(() => new ComprasComprobantes());
  }

  afterEach(() => {
    alertSpy?.mockRestore();
    TestBed.resetTestingModule();
  });

  it('carga datos iniciales y calcula totales de comprobantes', () => {
    const component = crearComponente();
    comprasService.comprobantes.mockReturnValueOnce(
      of([
        { idComprobanteCompra: 1, montoSubtotal: 100, montoDescuento: 10 },
        { idComprobanteCompra: 2, monto_subtotal: 50, monto_descuento: 0 },
      ]),
    );

    component.cargarDatos();

    expect(component.cargando()).toBe(false);
    expect(component.totalComprobantes()).toBe(2);
    expect(component.montoTotalComprobantes()).toBe(140);
  });

  it('filtra ordenes, recepciones y comprobantes por texto y estado', () => {
    const component = crearComponente();
    component.ordenes.set([
      {
        idOrdenCompra: 1,
        numeroOrden: 'OC-1',
        proveedor: { razonSocial: 'Proveedor A' },
        estadoOrden: 'PENDIENTE',
      } as any,
      {
        idOrdenCompra: 2,
        numeroOrden: 'OC-2',
        proveedor: { razonSocial: 'Proveedor B' },
        estadoOrden: 'ANULADA',
      } as any,
    ]);
    component.recepciones.set([
      {
        idRecepcionCompra: 1,
        numeroRecepcion: 'REC-1',
        ordenCompra: { numeroOrden: 'OC-1' },
        estadoRecepcion: 'RECIBIDA_COMPLETA',
      } as any,
    ]);
    component.comprobantes.set([
      {
        idComprobanteCompra: 1,
        numeroComprobante: 'COMP-1',
        proveedor: { razonSocial: 'Proveedor A' },
        estadoComprobante: 'REGISTRADO',
      } as any,
    ]);

    component.busqueda.set('Proveedor A');
    expect(component.ordenesFiltradas()).toHaveLength(1);

    component.tabActual.set('recepciones');
    component.busqueda.set('REC-1');
    expect(component.recepcionesFiltradas()).toHaveLength(1);

    component.tabActual.set('comprobantes');
    component.busqueda.set('COMP-1');
    expect(component.comprobantesFiltrados()).toHaveLength(1);
  });

  it('calcula subtotal y total de orden con descuento', () => {
    const component = crearComponente();
    component.detallesOrden.set([
      { idInsumo: '1', cantidad: '2', precioUnitario: '10', observaciones: '' },
      { idInsumo: '2', cantidad: '1', precioUnitario: '5', observaciones: '' },
    ]);
    component.formOrden.patchValue({ descuento: 3 });

    expect(component.subtotalOrdenFormulario()).toBe(25);
    expect(component.totalOrdenFormulario()).toBe(22);
  });

  it('bloquea descuento mayor al subtotal al guardar orden', () => {
    const component = crearComponente();
    component.formOrden.setValue({
      idPedido: '1',
      idProveedor: '2',
      fechaEntregaEstimada: '',
      condicionPago: 'CONTADO',
      formaPago: 'TRANSFERENCIA',
      moneda: 'BOB',
      descuento: 50,
      observaciones: '',
    });
    component.detallesOrden.set([
      { idInsumo: '1', cantidad: '1', precioUnitario: '10', observaciones: '' },
    ]);

    component.guardarOrdenCompra();

    expect(comprasService.crearOrdenCompra).not.toHaveBeenCalled();
    expect(component.formOrden.controls.descuento.errors).toEqual({
      descuentoMayorSubtotal: true,
    });
  });

  it('crea orden, recepcion y comprobante con formularios validos', () => {
    const component = crearComponente();

    component.formOrden.setValue({
      idPedido: '1',
      idProveedor: '2',
      fechaEntregaEstimada: '2026-08-20T09:00',
      condicionPago: 'CONTADO',
      formaPago: 'TRANSFERENCIA',
      moneda: 'BOB',
      descuento: 5,
      observaciones: 'Compra urgente',
    });
    component.detallesOrden.set([
      { idInsumo: '1', cantidad: '2', precioUnitario: '10', observaciones: '' },
    ]);
    component.guardarOrdenCompra();

    component.formRecepcion.setValue({
      idOrdenCompra: '1',
      idAlmacen: '3',
      fechaRecepcion: '2026-08-21T10:00',
      documentoRespaldo: 'GUIA-1',
      archivoRespaldo: '',
      observaciones: '',
    });
    component.detallesRecepcion.set([
      {
        idInsumo: '1',
        cantidadRecibida: '2',
        cantidadRechazada: '0',
        estadoConformidad: 'CONFORME',
        motivoRechazo: '',
        observaciones: '',
      },
    ]);
    component.ordenes.set([
      {
        idOrdenCompra: 1,
        idProveedor: 2,
        proveedor: { nit: '123456' },
        detalles: [{ idOrdenDetalle: 99, idInsumo: 1, cantidadComprada: 2 }],
      } as any,
    ]);
    component.guardarRecepcion();

    component.ordenes.set([
      {
        idOrdenCompra: 1,
        idProveedor: 2,
        proveedor: { nit: '123456' },
        subtotal: 100,
        descuento: 0,
      } as any,
    ]);
    component.formComprobante.setValue({
      idOrdenCompra: '1',
      tipoComprobante: 'FACTURA',
      numeroComprobante: 'F-100',
      fechaEmision: '2026-08-22T11:00',
      montoSubtotal: '100',
      montoDescuento: 10,
      moneda: 'BOB',
      observaciones: '',
    });
    component.guardarComprobante();

    expect(comprasService.crearOrdenCompra).toHaveBeenCalledWith(
      expect.objectContaining({
        idPedido: 1,
        idProveedor: 2,
        descuento: 5,
        usuarioGenera: 5,
      }),
    );
    expect(comprasService.crearRecepcion).toHaveBeenCalledWith(
      expect.objectContaining({
        idOrdenCompra: 1,
        idAlmacenDestino: 3,
      }),
    );
    expect(comprasService.crearComprobante).toHaveBeenCalledWith(
      expect.objectContaining({
        idOrdenCompra: 1,
        tipoComprobante: 'FACTURA',
        numeroComprobante: 'F-100',
        montoSubtotal: 100,
        montoDescuento: 10,
      }),
    );
  });

  it('bloquea acciones sin permiso', () => {
    const component = crearComponente(false);

    component.abrirNuevaOrden();

    expect(component.modoModal()).toBe('ninguno');
    expect(alertSpy).toHaveBeenCalledWith('Sin permiso');
  });
});
