import { signal } from '@angular/core';
import { FormBuilder } from '@angular/forms';
import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { AlmacenesService } from '../../core/services/almacenes.service';
import { AuthState } from '../../core/state/auth.state';
import { InsumosService } from '../../core/services/insumos.service';
import { InventarioDespachosService } from '../../core/services/inventario-despachos.service';
import { PermissionService } from '../../core/services/permission.service';
import { InventarioDespachos } from './inventario-despachos-flujo';

type InventarioServiceMock = {
  inventario: ReturnType<typeof vi.fn>;
  stockBajo: ReturnType<typeof vi.fn>;
  movimientos: ReturnType<typeof vi.fn>;
  despachos: ReturnType<typeof vi.fn>;
  pedidosAprobadosParaDespacho: ReturnType<typeof vi.fn>;
  usuariosSistema: ReturnType<typeof vi.fn>;
  areasSistema: ReturnType<typeof vi.fn>;
  registrarMovimiento: ReturnType<typeof vi.fn>;
  registrarTransferencia: ReturnType<typeof vi.fn>;
  registrarDevolucion: ReturnType<typeof vi.fn>;
  crearDespacho: ReturnType<typeof vi.fn>;
};

describe('InventarioDespachos flujo', () => {
  let inventarioService: InventarioServiceMock;
  let permissionService: {
    tienePermiso: ReturnType<typeof vi.fn>;
    mensajeSinPermiso: string;
  };
  let alertSpy: ReturnType<typeof vi.spyOn>;

  function crearComponente(tienePermiso = true) {
    inventarioService = {
      inventario: vi.fn(() => of([])),
      stockBajo: vi.fn(() => of([])),
      movimientos: vi.fn(() => of([])),
      despachos: vi.fn(() => of([])),
      pedidosAprobadosParaDespacho: vi.fn(() => of([])),
      usuariosSistema: vi.fn(() => of([])),
      areasSistema: vi.fn(() => of([])),
      registrarMovimiento: vi.fn(() => of({})),
      registrarTransferencia: vi.fn(() => of({})),
      registrarDevolucion: vi.fn(() => of({})),
      crearDespacho: vi.fn(() => of({})),
    };
    permissionService = {
      tienePermiso: vi.fn(() => tienePermiso),
      mensajeSinPermiso: 'Sin permiso',
    };
    alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {});

    TestBed.configureTestingModule({
      providers: [
        FormBuilder,
        { provide: InventarioDespachosService, useValue: inventarioService },
        { provide: InsumosService, useValue: { listar: vi.fn(() => of([])) } },
        { provide: AlmacenesService, useValue: { listar: vi.fn(() => of([])) } },
        { provide: PermissionService, useValue: permissionService },
        {
          provide: AuthState,
          useValue: {
            usuario: signal<any>({ idUsuario: 6, nombreCompleto: 'Ana Rojas' }),
          },
        },
      ],
    });

    return TestBed.runInInjectionContext(() => new InventarioDespachos());
  }

  afterEach(() => {
    alertSpy?.mockRestore();
    TestBed.resetTestingModule();
  });

  it('carga datos y normaliza pedidos aprobados con usuarios y areas', () => {
    const component = crearComponente();
    inventarioService.pedidosAprobadosParaDespacho.mockReturnValueOnce(
      of({
        pedidos: [
          {
            idPedido: 10,
            idUsuarioSolicitante: 2,
            idAreaSolicitante: 3,
            detalles: [
              {
                idPedidoDetalle: 1,
                idInsumo: 7,
                cantidadAprobada: 5,
                cantidadDespachada: 2,
              },
            ],
          },
        ],
      }),
    );
    inventarioService.usuariosSistema.mockReturnValueOnce(
      of([{ idUsuario: 2, nombreCompleto: 'Luis Perez' }]),
    );
    inventarioService.areasSistema.mockReturnValueOnce(
      of([{ idArea: 3, nombreArea: 'Mina Norte' }]),
    );

    component.cargarDatos();

    expect(component.cargando()).toBe(false);
    expect(component.pedidosAprobados()).toHaveLength(1);
    expect(component.nombreSolicitantePedido(component.pedidosAprobados()[0])).toBe(
      'Luis Perez',
    );
    expect(component.nombreAreaPedido(component.pedidosAprobados()[0])).toBe(
      'Mina Norte',
    );
    expect(component.pedidosAprobados()[0].detalles[0].cantidadPendiente).toBe(3);
  });

  it('calcula stock disponible y bloquea ajuste negativo sin stock', () => {
    const component = crearComponente();
    component.inventario.set([
      {
        idInsumo: 1,
        idAlmacen: 2,
        stockFisico: 10,
        stockReservado: 3,
        stockMinimo: 5,
      } as any,
    ]);

    expect(component.stockDisponibleInsumoAlmacen(1, 2)).toBe(7);
    expect(component.diferenciaStock(component.inventario()[0])).toBe(2);

    component.formAjuste.setValue({
      idInsumo: '1',
      idAlmacen: '2',
      tipoMovimiento: 'AJUSTE_NEGATIVO',
      cantidad: '8',
      motivo: 'Correccion',
      observaciones: '',
    });
    component.guardarAjuste();

    expect(component.error()).toBe(
      'Stock disponible insuficiente para el ajuste negativo.',
    );
    expect(inventarioService.registrarMovimiento).not.toHaveBeenCalled();
  });

  it('registra ajuste, transferencia, devolucion y despacho con payload esperado', () => {
    const component = crearComponente();
    component.inventario.set([
      { idInsumo: 1, idAlmacen: 2, stockFisico: 20, stockReservado: 0 } as any,
    ]);

    component.formAjuste.setValue({
      idInsumo: '1',
      idAlmacen: '2',
      tipoMovimiento: 'AJUSTE_POSITIVO',
      cantidad: '4',
      motivo: 'Sobrante',
      observaciones: 'Conteo',
    });
    component.guardarAjuste();

    component.formTransferencia.setValue({
      idInsumo: '1',
      idAlmacenOrigen: '2',
      idAlmacenDestino: '3',
      cantidad: '5',
      motivo: 'Reabastecimiento',
      observaciones: '',
    });
    component.inventario.set([
      { idInsumo: 1, idAlmacen: 2, stockFisico: 20, stockReservado: 0 } as any,
    ]);
    component.guardarTransferencia();

    component.formDevolucion.setValue({
      idInsumo: '1',
      idAlmacenDestino: '2',
      cantidad: '1',
      motivo: 'Sobrante',
      idDespacho: '',
      observaciones: '',
    });
    component.guardarDevolucion();

    const pedido = {
      idPedido: 9,
      detalles: [
        {
          idPedidoDetalle: 12,
          idInsumo: 1,
          cantidadPendiente: 2,
          insumo: { idInsumo: 1, nombreInsumo: 'Casco' },
        },
      ],
    } as any;
    component.pedidosAprobados.set([pedido]);
    component.formDespacho.setValue({
      idPedido: '9',
      idAlmacenSalida: '2',
      observaciones: '',
    });
    component.inventario.set([
      { idInsumo: 1, idAlmacen: 2, stockFisico: 20, stockReservado: 0 } as any,
    ]);
    component.seleccionarPedidoDespacho({
      target: { value: '9' },
    } as unknown as Event);
    component.guardarDespacho();

    expect(inventarioService.registrarMovimiento).toHaveBeenCalledWith(
      expect.objectContaining({ usuarioResponsable: 6, cantidad: 4 }),
    );
    expect(inventarioService.registrarTransferencia).toHaveBeenCalledWith(
      expect.objectContaining({ idAlmacenOrigen: 2, idAlmacenDestino: 3 }),
    );
    expect(inventarioService.registrarDevolucion).toHaveBeenCalledWith(
      expect.objectContaining({ idAlmacenDestino: 2, cantidad: 1 }),
    );
    expect(inventarioService.crearDespacho).toHaveBeenCalledWith(
      expect.objectContaining({
        idPedido: 9,
        idAlmacenSalida: 2,
        detalles: [expect.objectContaining({ idPedidoDetalle: 12, cantidadEntregada: 2 })],
      }),
    );
  });

  it('filtra inventario, movimientos y despachos por busqueda y permisos', () => {
    const component = crearComponente();
    component.inventario.set([
      { idInsumo: 1, codigoInterno: 'INS-1', nombreInsumo: 'Casco', idAlmacen: 2 } as any,
      { idInsumo: 2, codigoInterno: 'INS-2', nombreInsumo: 'Botas', idAlmacen: 3 } as any,
    ]);
    component.movimientos.set([
      { idMovimiento: 1, tipoMovimiento: 'ENTRADA', nombreInsumo: 'Casco' } as any,
    ]);
    component.despachos.set([
      { idDespacho: 1, codigoDespacho: 'DES-1', estadoDespacho: 'PARCIAL' } as any,
    ]);

    component.busqueda.set('casco');

    expect(component.inventarioFiltrado()).toHaveLength(1);
    expect(component.movimientosFiltrados()).toHaveLength(1);

    component.busqueda.set('DES-1');
    expect(component.despachosFiltrados()).toHaveLength(1);
    expect(component.claseDespacho('ENTREGADO_COMPLETO')).toContain('green');

    permissionService.tienePermiso.mockReturnValue(false);
    component.cambiarTab('movimientos');
    expect(alertSpy).toHaveBeenCalledWith('Sin permiso');
  });
});
