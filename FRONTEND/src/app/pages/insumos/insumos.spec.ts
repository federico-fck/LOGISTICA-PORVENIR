import { FormBuilder, Validators } from '@angular/forms';
import { codigoAlfanumericoGuionValidator } from '../../core/forms/professional-forms';

describe('Insumos - validaciones de formulario', () => {
  const fb = new FormBuilder().nonNullable;

  function crearForm() {
    return fb.group({
      codigoInterno: [
        '',
        [Validators.required, Validators.maxLength(10), codigoAlfanumericoGuionValidator()],
      ],
      nombreInsumo: ['', [Validators.required, Validators.maxLength(50)]],
    });
  }

  it('codigo con simbolos es invalido', () => {
    const form = crearForm();
    form.controls.codigoInterno.setValue('INS_001');
    expect(form.controls.codigoInterno.valid).toBe(false);
  });

  it('codigo mayor a 10 es invalido', () => {
    const form = crearForm();
    form.controls.codigoInterno.setValue('INSUMO-0001');
    expect(form.controls.codigoInterno.valid).toBe(false);
  });

  it('nombre vacio es invalido', () => {
    const form = crearForm();
    form.controls.nombreInsumo.setValue('');
    expect(form.controls.nombreInsumo.valid).toBe(false);
  });

  it('nombre mayor a 50 es invalido', () => {
    const form = crearForm();
    form.controls.nombreInsumo.setValue('A'.repeat(51));
    expect(form.controls.nombreInsumo.valid).toBe(false);
  });
});
