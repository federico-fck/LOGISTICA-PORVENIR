import { FormBuilder, Validators } from '@angular/forms';
import {
  codigoAlfanumericoGuionValidator,
  correoProfesionalValidator,
  personaContactoValidator,
  soloNumerosMaxValidator,
  telefonoBoliviaValidator,
  telefonoNumericoFlexibleValidator,
} from '../../core/forms/professional-forms';

describe('Proveedores - validaciones de formulario', () => {
  const fb = new FormBuilder().nonNullable;

  function crearForm() {
    return fb.group({
      codigoProveedor: [
        '',
        [Validators.required, Validators.maxLength(10), codigoAlfanumericoGuionValidator()],
      ],
      razonSocial: ['', [Validators.required, Validators.maxLength(100)]],
      nombreComercial: ['', [Validators.required, Validators.maxLength(60)]],
      nit: ['', [Validators.required, soloNumerosMaxValidator(15)]],
      tipoInsumosProvee: ['', [Validators.required, Validators.maxLength(60)]],
      personaContacto: [
        '',
        [Validators.required, Validators.maxLength(50), personaContactoValidator()],
      ],
      telefono: ['', [telefonoNumericoFlexibleValidator(15)]],
      celularWhatsapp: ['', [Validators.required, telefonoBoliviaValidator()]],
      correo: [
        '',
        [Validators.required, Validators.maxLength(60), correoProfesionalValidator()],
      ],
    });
  }

  it('codigo invalido con simbolos', () => {
    const form = crearForm();
    form.controls.codigoProveedor.setValue('PROV_001');
    expect(form.controls.codigoProveedor.valid).toBe(false);
  });

  it('NIT con letras o guion es invalido', () => {
    const form = crearForm();
    form.controls.nit.setValue('123ABC');
    expect(form.controls.nit.valid).toBe(false);
    form.controls.nit.setValue('123-456');
    expect(form.controls.nit.valid).toBe(false);
  });

  it('WhatsApp con 5 es invalido', () => {
    const form = crearForm();
    form.controls.celularWhatsapp.setValue('50000000');
    expect(form.controls.celularWhatsapp.valid).toBe(false);
  });

  it('correo sin @ o con ñ es invalido', () => {
    const form = crearForm();
    form.controls.correo.setValue('ventas.local');
    expect(form.controls.correo.valid).toBe(false);
    form.controls.correo.setValue('peña@proveedor.com');
    expect(form.controls.correo.valid).toBe(false);
  });

  it('persona contacto mayor a 50 es invalida', () => {
    const form = crearForm();
    form.controls.personaContacto.setValue('Nombre Apellido Paterno Materno Extra Largo Excesivo');
    expect(form.controls.personaContacto.valid).toBe(false);
  });

  it('persona contacto acepta parentesis', () => {
    const form = crearForm();
    form.controls.personaContacto.setValue('Carlos Rojas (Ventas)');
    expect(form.controls.personaContacto.valid).toBe(true);
  });

  it('telefono es opcional pero si se llena debe ser numerico', () => {
    const form = crearForm();
    form.controls.telefono.setValue('');
    expect(form.controls.telefono.valid).toBe(true);
    form.controls.telefono.setValue('2520ABC');
    expect(form.controls.telefono.valid).toBe(false);
  });

  it('razon social mayor a 100 es invalida', () => {
    const form = crearForm();
    form.controls.razonSocial.setValue('A'.repeat(101));
    expect(form.controls.razonSocial.valid).toBe(false);
  });

  it('tipo de insumo vacio es invalido', () => {
    const form = crearForm();
    form.controls.tipoInsumosProvee.setValue('');
    expect(form.controls.tipoInsumosProvee.valid).toBe(false);
  });

  it('tipo de insumo acepta texto manual valido', () => {
    const form = crearForm();
    form.controls.tipoInsumosProvee.setValue('Repuestos industriales');
    expect(form.controls.tipoInsumosProvee.valid).toBe(true);
  });

  it('tipo de insumo mayor a 60 es invalido', () => {
    const form = crearForm();
    form.controls.tipoInsumosProvee.setValue('A'.repeat(61));
    expect(form.controls.tipoInsumosProvee.valid).toBe(false);
  });
});
