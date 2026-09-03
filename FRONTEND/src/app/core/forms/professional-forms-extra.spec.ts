import { FormBuilder } from '@angular/forms';

import {
  almacenesDiferentesValidator,
  complementoCiValidator,
  documentoRespaldoValidator,
  horarioAtencionManualValidator,
  normalizarMayusculas,
  normalizarMinusculas,
  normalizarSoloDigitos,
  passwordUsuarioErrors,
  telefonoNumericoFlexibleValidator,
  totalConDescuento,
} from './professional-forms';

describe('Professional forms - validadores adicionales', () => {
  const fb = new FormBuilder().nonNullable;

  it('normaliza textos de entrada sin cambiar reglas del formulario', () => {
    expect(normalizarMinusculas('  ADMIN@DOMINIO.COM ')).toBe('admin@dominio.com');
    expect(normalizarMayusculas(' alm-01 ')).toBe('ALM-01');
    expect(normalizarSoloDigitos('Tel: 7000-0000', 8)).toBe('70000000');
  });

  it('valida documentos, horarios y telefonos flexibles', () => {
    const documento = fb.control('ABC-123', [documentoRespaldoValidator()]);
    const horario = fb.control('Lunes 08:00 - 18:00', [
      horarioAtencionManualValidator(),
    ]);
    const telefono = fb.control('25201234', [telefonoNumericoFlexibleValidator(8)]);

    expect(documento.valid).toBe(true);
    expect(horario.valid).toBe(true);
    expect(telefono.valid).toBe(true);

    documento.setValue('ABC/123');
    horario.setValue('Lunes @ 18');
    telefono.setValue('2520ABC');

    expect(documento.valid).toBe(false);
    expect(horario.valid).toBe(false);
    expect(telefono.valid).toBe(false);
  });

  it('valida complemento de CI en mayusculas y almacenes diferentes', () => {
    const complemento = fb.control('A1', [complementoCiValidator()]);
    const transferencia = fb.group(
      {
        origen: ['1'],
        destino: ['2'],
      },
      { validators: [almacenesDiferentesValidator('origen', 'destino')] },
    );

    expect(complemento.valid).toBe(true);
    expect(transferencia.valid).toBe(true);

    complemento.setValue('a-1');
    transferencia.controls.destino.setValue('1');

    expect(complemento.valid).toBe(false);
    expect(transferencia.errors).toEqual({ almacenesIguales: true });
  });

  it('calcula totales con descuento y evita valores negativos', () => {
    expect(totalConDescuento(100.105, 0)).toBe(100.11);
    expect(totalConDescuento(100, 150)).toBe(0);
  });

  it('valida password segun modo de usuario', () => {
    expect(passwordUsuarioErrors('nuevo', false, '123', '')).toEqual({
      passwordMinLength: true,
    });
    expect(passwordUsuarioErrors('nuevo', false, 'secreto', 'otro')).toEqual({
      passwordConfirmacion: true,
    });
    expect(passwordUsuarioErrors('nuevo', false, 'secreto', 'secreto')).toBeNull();
    expect(passwordUsuarioErrors('editar', true, '', '')).toEqual({
      passwordRequerido: true,
    });
  });
});
