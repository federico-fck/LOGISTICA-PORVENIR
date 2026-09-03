import {
  MOTIVOS_PEDIDO,
  TIPOS_COMPROBANTE,
  formatearNumeroPedidoAnual,
  totalConDescuento,
  validarArchivoRecepcion,
} from './professional-forms';

describe('Professional forms - reglas logisticas', () => {
  it('formatea numero de pedido anual con correlativo corto', () => {
    expect(formatearNumeroPedidoAnual(1, 2026)).toBe('PED-0001/2026');
    expect(formatearNumeroPedidoAnual(25, 2026)).toBe('PED-0025/2026');
  });

  it('motivo de pedido es obligatorio en formularios que usen el catalogo', () => {
    expect(MOTIVOS_PEDIDO).toContain('Requerimiento para frente de trabajo');
    expect(MOTIVOS_PEDIDO).toContain('Otro');
  });

  it('calcula total con descuento', () => {
    expect(totalConDescuento(1000, 100)).toBe(900);
    expect(totalConDescuento(500, 0)).toBe(500);
  });

  it('mantiene opciones visuales limpias de comprobante', () => {
    expect(TIPOS_COMPROBANTE.map((tipo) => tipo.etiqueta)).toEqual([
      'Factura',
      'Recibo',
      'Nota de Venta',
      'Comprobante Interno',
    ]);
  });

  it('valida extensiones permitidas para respaldo de recepcion', () => {
    expect(validarArchivoRecepcion('respaldo.pdf')).toBe(true);
    expect(validarArchivoRecepcion('respaldo.exe')).toBe(false);
  });
});
