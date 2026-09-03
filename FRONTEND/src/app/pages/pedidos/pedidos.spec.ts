import { signal } from '@angular/core';
import { FormBuilder } from '@angular/forms';
import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';

import { AuthState } from '../../core/state/auth.state';
import { InsumosService } from '../../core/services/insumos.service';
import { PedidosService } from '../../core/services/pedidos.service';
import { PermissionService } from '../../core/services/permission.service';
import { Pedidos } from './pedidos';

type PedidosServiceMock = {
  listar: ReturnType<typeof vi.fn>;
  buscarPorId: ReturnType<typeof vi.fn>;
  crear: ReturnType<typeof vi.fn>;
  actualizar: ReturnType<typeof vi.fn>;
  aprobar: ReturnType<typeof vi.fn>;
  rechazar: ReturnType<typeof vi.fn>;
  observar: ReturnType<typeof vi.fn>;
  cancelar: ReturnType<typeof vi.fn>;
  enviarADespacho: ReturnType<typeof vi.fn>;
};

describe('Pedidos page', () => {
  let pedidosService: PedidosServiceMock;
  let permissionService: {
    tienePermiso: ReturnType<typeof vi.fn>;
    mensajeSinPermiso: string;
  };
  let alertSpy: ReturnType<typeof vi.spyOn>;

  function crearComponente(tienePermiso = true) {
    pedidosService = {
      listar: vi.fn(() => of([])),
      buscarPorId: vi.fn((id: number) => of({ idPedido: id })),
      crear: vi.fn(() => of({ idPedido: 1 })),
      actualizar: vi.fn(() => of({})),
      aprobar: vi.fn(() => of({ message: 'OK' })),
      rechazar: vi.fn(() => of({})),
      observar: vi.fn(() => of({})),
      cancelar: vi.fn(() => of({})),
      enviarADespacho: vi.fn(() => of({})),
    };
    permissionService = {
      tienePermiso: vi.fn(() => tienePermiso),
      mensajeSinPermiso: 'Sin permiso',
    };
    alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {});

    TestBed.configureTestingModule({
      providers: [
        FormBuilder,
        { provide: PedidosService, useValue: pedidosService },
        { provide: InsumosService, useValue: { listar: vi.fn(() => of([])) } },
        { provide: PermissionService, useValue: permissionService },
        {
          provide: AuthState,
          useValue: {
            usuario: signal<any>({
              idUsuario: 9,
              idArea: 4,
              nombreCompleto: 'Ana Rojas',
              nombreArea: 'Mina Norte',
            }),
          },
        },
      ],
    });

    return TestBed.runInInjectionContext(() => new Pedidos());
  }

  afterEach(() => {
    alertSpy?.mockRestore();
    TestBed.resetTestingModule();
  });

  it('carga pedidos, filtra por busqueda y calcula totales', () => {
    const component = crearComponente();
    pedidosService.listar.mockReturnValueOnce(
      of([
        {
          idPedido: 1,
          numeroPedido: 'PED-1',
          estadoPedido: 'PENDIENTE',
          estadoAprobacion: 'PENDIENTE',
          prioridad: 'ALTA',
          usuarioSolicitante: { nombreCompleto: 'Ana Rojas' },
        },
        {
          idPedido: 2,
          numeroPedido: 'PED-2',
          estadoPedido: 'APROBADO',
          estadoAprobacion: 'APROBADO',
          prioridad: 'MEDIA',
        },
      ]),
    );

    component.cargarDatos();
    component.busqueda.set('ana');

    expect(component.totalPedidos()).toBe(2);
    expect(component.totalPendientes()).toBe(1);
    expect(component.totalAprobados()).toBe(1);
    expect(component.pedidosFiltrados()).toHaveLength(1);
  });

  it('prepara modal nuevo y crea pedido con detalle valido', () => {
    const component = crearComponente();

    component.abrirNuevo();
    component.form.setValue({
      prioridad: 'ALTA',
      fechaRequerida: '2026-08-20',
      horaRequerida: '08:30',
      centroCosto: '',
      lugarUso: ' Frente Norte ',
      turnoGuardia: '',
      motivoSolicitud: 'Reposicion operativa',
      observaciones: '',
    });
    component.detallesFormulario.set([
      {
        idInsumo: '7',
        cantidadSolicitada: '2.5',
        observaciones: 'Urgente',
      },
    ]);

    component.guardarPedido();

    expect(component.modoModal()).toBe('ninguno');
    expect(pedidosService.crear).toHaveBeenCalledWith(
      expect.objectContaining({
        idUsuarioSolicitante: 9,
        idAreaSolicitante: 4,
        prioridad: 'ALTA',
        fechaRequerida: '2026-08-20T12:30:00.000Z',
        lugarUso: 'Frente Norte',
        motivoSolicitud: 'Reposicion operativa',
        detalles: [
          {
            idInsumo: 7,
            cantidadSolicitada: 2.5,
            observacion: 'Urgente',
          },
        ],
      }),
    );
  });

  it('no crea pedido con detalle incompleto ni sin permiso', () => {
    const component = crearComponente();
    component.abrirNuevo();
    component.form.patchValue({
      prioridad: 'ALTA',
      fechaRequerida: '2026-08-20',
      horaRequerida: '08:30',
      motivoSolicitud: 'Reposicion',
    });
    component.detallesFormulario.set([
      { idInsumo: '', cantidadSolicitada: '0', observaciones: '' },
    ]);

    component.guardarPedido();

    expect(component.detallesIntentoGuardar()).toBe(true);
    expect(pedidosService.crear).not.toHaveBeenCalled();

    permissionService.tienePermiso.mockReturnValue(false);
    component.abrirNuevo();

    expect(alertSpy).toHaveBeenCalledWith('Sin permiso');
  });

  it('actualiza, aprueba, rechaza, observa, anula y envia a despacho segun estado', () => {
    const component = crearComponente();
    const pedido = {
      idPedido: 3,
      estadoPedido: 'PENDIENTE',
      estadoAprobacion: 'PENDIENTE',
      prioridad: 'MEDIA',
      fechaRequerida: '2026-08-20T12:30:00.000Z',
      justificacion: 'Reposicion',
      detalles: [{ idPedidoDetalle: 10, cantidadSolicitada: 2 }],
    } as any;

    component.abrirEditar(pedido);
    component.form.patchValue({
      prioridad: 'ALTA',
      fechaRequerida: '2026-08-21',
      horaRequerida: '09:00',
      motivoSolicitud: 'Cambio prioridad',
    });
    component.guardarPedido();

    component.abrirAprobar(pedido);
    component.confirmarAprobar();

    component.abrirRechazar(pedido);
    component.formAccion.controls.motivoRechazo.setValue('Sin sustento');
    component.confirmarRechazar();

    component.abrirObservar(pedido);
    component.formAccion.controls.motivoRechazo.setValue('Falta detalle');
    component.confirmarObservar();

    component.abrirAnular(pedido);
    component.confirmarAnular();

    const aprobado = {
      ...pedido,
      estadoPedido: 'APROBADO',
      estadoAprobacion: 'APROBADO',
    };
    component.abrirEnviarDespacho(aprobado);
    component.confirmarEnviarDespacho();

    expect(pedidosService.actualizar).toHaveBeenCalled();
    expect(pedidosService.aprobar).toHaveBeenCalledWith(
      3,
      expect.objectContaining({ usuarioRevisa: 9 }),
    );
    expect(pedidosService.rechazar).toHaveBeenCalledWith(
      3,
      expect.objectContaining({ motivoRechazo: 'Sin sustento' }),
    );
    expect(pedidosService.observar).toHaveBeenCalledWith(
      3,
      expect.objectContaining({ motivoObservacion: 'Falta detalle' }),
    );
    expect(pedidosService.cancelar).toHaveBeenCalledWith(3);
    expect(pedidosService.enviarADespacho).toHaveBeenCalledWith(3);
  });

  it('muestra errores de carga y backend sin romper estado', () => {
    const component = crearComponente();
    pedidosService.listar.mockReturnValueOnce(throwError(() => new Error('fallo')));

    component.cargarDatos();

    expect(component.cargando()).toBe(false);
    expect(component.error()).toBe('No se pudo cargar la lista de pedidos.');
    expect(
      component.obtenerMensajeErrorBackend({
        error: { message: ['prioridad should not be empty'] },
      }),
    ).toContain('Prioridad');
  });
});
