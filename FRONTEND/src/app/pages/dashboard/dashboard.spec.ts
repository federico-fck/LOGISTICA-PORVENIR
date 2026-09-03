import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';

import { DashboardService } from '../../core/services/dashboard.service';
import { Dashboard } from './dashboard';

describe('Dashboard', () => {
  let dashboardService: {
    tarjetas: ReturnType<typeof vi.fn>;
    ultimosPedidos: ReturnType<typeof vi.fn>;
    stockBajo: ReturnType<typeof vi.fn>;
  };

  function crearComponente(overrides: Partial<typeof dashboardService> = {}) {
    dashboardService = {
      tarjetas: vi.fn(() =>
        of({
          total_insumos_activos: '7',
          total_almacenes_activos: 2,
          total_proveedores_activos: 3,
          total_usuarios_activos: 4,
          pedidos_pendientes: 1,
          pedidos_aprobados: 5,
          pedidos_rechazados: 0,
          compras_en_proceso: 2,
          compras_recibidas_completas: 1,
          despachos_entregados: 6,
          stock_total_fisico: 100,
          stock_total_disponible: 80,
          valor_total_inventario: '1250.5',
        }),
      ),
      ultimosPedidos: vi.fn(() =>
        of([
          {
            id_pedido: 1,
            numero_pedido: 'PED-1',
            fecha_pedido: '2026-08-15T10:00:00.000Z',
            tipo_pedido: 'NORMAL',
            prioridad: 'ALTA',
            estado_pedido: 'PENDIENTE',
            estado_aprobacion: 'PENDIENTE',
            estado_atencion: 'SIN_ATENDER',
            usuario_solicitante: 'Ana',
            area_solicitante: 'Mina',
          },
        ]),
      ),
      stockBajo: vi.fn(() =>
        of([
          {
            id_inventario: 1,
            codigo_interno: 'INS-1',
            nombre_insumo: 'Casco',
            nombre_almacen: 'Central',
            tipo_almacen: 'PRINCIPAL',
            stock_fisico: 2,
            stock_reservado: 0,
            stock_disponible: 2,
            estado_stock: 'BAJO',
          },
        ]),
      ),
      ...overrides,
    };

    TestBed.configureTestingModule({
      providers: [{ provide: DashboardService, useValue: dashboardService }],
    });

    return TestBed.runInInjectionContext(() => new Dashboard());
  }

  afterEach(() => {
    TestBed.resetTestingModule();
  });

  it('carga tarjetas, pedidos recientes y stock critico', () => {
    const component = crearComponente();

    component.cargarDashboard();

    expect(component.cargando()).toBe(false);
    expect(component.error()).toBe('');
    expect(component.valor('total_insumos_activos')).toBe('7');
    expect(component.pedidosRecientes()).toHaveLength(1);
    expect(component.stockCritico()).toHaveLength(1);
  });

  it('formatea valores monetarios y usa cero cuando no hay tarjetas', () => {
    const component = crearComponente();

    expect(component.valor('valor_total_inventario')).toBe(0);
    component.cargarDashboard();

    expect(component.valorMoneda('valor_total_inventario')).toBe('1.250,50');
  });

  it('maneja error de carga sin conservar estado cargando', () => {
    const component = crearComponente({
      tarjetas: vi.fn(() => throwError(() => new Error('fallo'))),
    });

    component.cargarDashboard();

    expect(component.cargando()).toBe(false);
    expect(component.error()).toBe('No se pudo cargar la información del dashboard.');
  });

  it('delegates date formatting helper', () => {
    const component = crearComponente();

    expect(component.fechaFormateada('')).toBe('Sin fecha');
  });
});
