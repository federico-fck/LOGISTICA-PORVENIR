import { FormBuilder, Validators } from '@angular/forms';
import {
  TIPOS_ALMACEN_RECOMENDADOS,
  codigoAlfanumericoGuionValidator,
  horarioAtencionManualValidator,
  maxDigitsValidator,
  telefonoBoliviaValidator,
} from '../../core/forms/professional-forms';

describe('Almacenes - validaciones de formulario', () => {
  const fb = new FormBuilder().nonNullable;

  function crearForm() {
    return fb.group({
      codigoAlmacen: [
        '',
        [Validators.required, Validators.maxLength(10), codigoAlfanumericoGuionValidator()],
      ],
      nombreAlmacen: [
        '',
        [Validators.required, Validators.maxLength(40), maxDigitsValidator(5)],
      ],
      tipoAlmacen: ['', [Validators.required]],
      ubicacion: ['', [Validators.required, Validators.maxLength(50), maxDigitsValidator(5)]],
      telefonoContacto: ['', [Validators.required, telefonoBoliviaValidator()]],
      horarioAtencion: [
        '',
        [
          Validators.required,
          Validators.maxLength(50),
          horarioAtencionManualValidator(),
        ],
      ],
    });
  }

  it('codigo con simbolos es invalido', () => {
    const form = crearForm();
    form.controls.codigoAlmacen.setValue('ALM_001');
    expect(form.controls.codigoAlmacen.valid).toBe(false);
  });

  it('codigo mayor a 10 es invalido', () => {
    const form = crearForm();
    form.controls.codigoAlmacen.setValue('ALMACEN-0001');
    expect(form.controls.codigoAlmacen.valid).toBe(false);
  });

  it('nombre vacio es invalido y mas de 5 numeros es invalido', () => {
    const form = crearForm();
    form.controls.nombreAlmacen.setValue('');
    expect(form.controls.nombreAlmacen.valid).toBe(false);
    form.controls.nombreAlmacen.setValue('Almacen 123456');
    expect(form.controls.nombreAlmacen.valid).toBe(false);
  });

  it('tipo Almacen de lubricantes no existe', () => {
    expect(
      TIPOS_ALMACEN_RECOMENDADOS.some((tipo) =>
        tipo.etiqueta.toLowerCase().includes('lubricante'),
      ),
    ).toBe(false);
  });

  it('ubicacion mayor a 50 es invalida', () => {
    const form = crearForm();
    form.controls.ubicacion.setValue('Sector Mina Norte Bloque A Pasillo Central Nivel Dos');
    expect(form.controls.ubicacion.valid).toBe(false);
  });

  it('contacto que empieza con 5 o mayor a 8 es invalido', () => {
    const form = crearForm();
    form.controls.telefonoContacto.setValue('50000000');
    expect(form.controls.telefonoContacto.valid).toBe(false);
    form.controls.telefonoContacto.setValue('700000000');
    expect(form.controls.telefonoContacto.valid).toBe(false);
  });

  it('horario vacio es invalido', () => {
    const form = crearForm();
    form.controls.horarioAtencion.setValue('');
    expect(form.controls.horarioAtencion.valid).toBe(false);
  });

  it('horario de atencion acepta texto manual valido', () => {
    const form = crearForm();
    form.controls.horarioAtencion.setValue('Lunes a sábado 08:00 - 18:00');
    expect(form.controls.horarioAtencion.valid).toBe(true);
  });

  it('horario de atencion rechaza caracteres no permitidos', () => {
    const form = crearForm();
    form.controls.horarioAtencion.setValue('Lunes @ sábado');
    expect(form.controls.horarioAtencion.valid).toBe(false);
  });
});
