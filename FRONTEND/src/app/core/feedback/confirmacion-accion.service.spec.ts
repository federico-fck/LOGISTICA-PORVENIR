import { ConfirmacionAccionService } from './confirmacion-accion.service';

describe('ConfirmacionAccionService', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('muestra confirmacion con titulo por defecto y la cierra automaticamente', () => {
    const service = new ConfirmacionAccionService();

    service.mostrar('Guardado correctamente.');

    expect(service.confirmacion()).toMatchObject({
      id: 1,
      titulo: 'Operacion exitosa',
      mensaje: 'Guardado correctamente.',
    });

    vi.advanceTimersByTime(2400);

    expect(service.confirmacion()).toBeNull();
  });

  it('reemplaza temporizador cuando se muestra una nueva confirmacion', () => {
    const service = new ConfirmacionAccionService();

    service.mostrar('Primera');
    service.mostrar('Segunda', 'Lista');

    expect(service.confirmacion()).toMatchObject({
      id: 2,
      titulo: 'Lista',
      mensaje: 'Segunda',
    });

    vi.advanceTimersByTime(2399);
    expect(service.confirmacion()?.mensaje).toBe('Segunda');

    vi.advanceTimersByTime(1);
    expect(service.confirmacion()).toBeNull();
  });

  it('cerrar limpia el mensaje vigente', () => {
    const service = new ConfirmacionAccionService();

    service.mostrar();
    service.cerrar();

    expect(service.confirmacion()).toBeNull();
  });
});
