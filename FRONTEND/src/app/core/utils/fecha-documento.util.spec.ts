import {
  convertirDatetimeLocalParaBackend,
  convertirFechaBackendADatetimeLocal,
  formatearFechaBolivia,
  formatearFechaHoraBolivia,
} from './fecha.util';
import {
  formatearDocumentoIdentidad,
  limpiarCedulaIdentidad,
  limpiarComplementoCi,
  normalizarExpedidoCi,
  obtenerDocumentoIdentidad,
} from './documento-identidad.util';

describe('fecha.util', () => {
  it('devuelve fallback para fechas vacias o invalidas', () => {
    expect(formatearFechaBolivia('', 'Vacio')).toBe('Vacio');
    expect(formatearFechaHoraBolivia('fecha rota', 'Sin dato')).toBe('Sin dato');
  });

  it('formatea fechas de calendario usando zona horaria Bolivia', () => {
    expect(formatearFechaBolivia('2026-08-15')).toContain('15');
    expect(formatearFechaBolivia('2026-08-15')).toContain('08');
    expect(formatearFechaHoraBolivia('2026-08-15T10:30')).toContain('10:30');
  });

  it('convierte datetime-local a ISO para backend', () => {
    expect(convertirDatetimeLocalParaBackend('')).toBe('');
    expect(convertirDatetimeLocalParaBackend('no fecha')).toBe('');
    expect(convertirDatetimeLocalParaBackend('2026-08-15T10:30')).toBe(
      '2026-08-15T14:30:00.000Z',
    );
  });

  it('convierte fechas backend a datetime-local en Bolivia', () => {
    expect(convertirFechaBackendADatetimeLocal(null)).toBe('');
    expect(convertirFechaBackendADatetimeLocal('2026-08-15T14:30:00.000Z')).toBe(
      '2026-08-15T10:30',
    );
  });
});

describe('documento-identidad.util', () => {
  it('limpia partes de documento boliviano', () => {
    expect(limpiarCedulaIdentidad('CI 123-456')).toBe('123456');
    expect(limpiarComplementoCi(' a-1 ')).toBe('A1');
    expect(normalizarExpedidoCi('lp')).toBe('LP');
    expect(normalizarExpedidoCi('xx')).toBe('');
  });

  it('separa formato legado con complemento y expedido', () => {
    expect(
      obtenerDocumentoIdentidad({
        cedulaIdentidad: '123456-1A LP',
      }),
    ).toEqual({
      cedulaIdentidad: '123456',
      complementoCi: '1A',
      expedidoCi: 'LP',
    });
  });

  it('prioriza campos separados y formatea documento', () => {
    const usuario = {
      cedula_identidad: '987654',
      complemento_ci: 'b2',
      expedido_ci: 'SC',
    };

    expect(obtenerDocumentoIdentidad(usuario)).toEqual({
      cedulaIdentidad: '987654',
      complementoCi: 'B2',
      expedidoCi: 'SC',
    });
    expect(formatearDocumentoIdentidad(usuario)).toBe('987654-B2 SC');
    expect(formatearDocumentoIdentidad(null)).toBe('Sin documento');
  });
});
