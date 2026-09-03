import { FormArray, FormBuilder, Validators } from '@angular/forms';

import {
  erroresFormulario,
  marcarFormularioInvalido,
  mensajeErrorBackend,
  mensajeErrorControl,
  mensajeFormularioInvalido,
  solicitarValidacionFormulario,
  validacionFormularioSolicitada,
} from './form-error-messages';

describe('form-error-messages', () => {
  const fb = new FormBuilder().nonNullable;

  it('traduce errores de controles conocidos', () => {
    expect(mensajeErrorControl(null)).toBe('');
    expect(mensajeErrorControl({ required: true })).toBe('Este campo es obligatorio.');
    expect(
      mensajeErrorControl({ minlength: { requiredLength: 6, actualLength: 2 } }),
    ).toBe('Debe tener al menos 6 caracteres.');
    expect(mensajeErrorControl({ maxDigits: { maxDigits: 5 } })).toBe(
      'No debe tener mas de 5 numeros.',
    );
    expect(mensajeErrorControl({ desconocido: true })).toBe('Revise este dato.');
  });

  it('marca formulario invalido y habilita visualizacion de errores', () => {
    const form = fb.group({
      usuario: ['', Validators.required],
    });

    expect(validacionFormularioSolicitada(form.controls.usuario)).toBe(false);
    expect(marcarFormularioInvalido(form)).toBe('');
    expect(validacionFormularioSolicitada(form.controls.usuario)).toBe(true);
    expect(form.controls.usuario.touched).toBe(true);
  });

  it('limpia solicitud de validacion si el formulario vuelve a pristine untouched', () => {
    const form = fb.group({
      usuario: ['', Validators.required],
    });

    solicitarValidacionFormulario(form);
    form.markAsPristine();
    form.markAsUntouched();

    expect(validacionFormularioSolicitada(form.controls.usuario)).toBe(false);
  });

  it('genera resumen de errores para grupos y arreglos', () => {
    const form = fb.group({
      nombre: ['', Validators.required],
      detalles: fb.array([
        fb.group({
          cantidad: [0, Validators.min(1)],
        }),
      ]),
    });
    const detalles = form.controls.detalles as FormArray;
    detalles.setErrors({ almacenesIguales: true });

    expect(
      erroresFormulario(form, {
        nombre: 'Nombre',
        cantidad: 'Cantidad',
        detalles: 'Detalles',
      }),
    ).toEqual([
      'Nombre: es obligatorio.',
      'Cantidad: debe ser mayor o igual a 1.',
      'Almacen destino: debe ser diferente al almacen origen.',
    ]);
    expect(mensajeFormularioInvalido(form, { nombre: 'Nombre' })).toContain(
      'Revise los campos del formulario:',
    );
  });

  it('normaliza mensajes de backend desde arrays, objetos y campos conocidos', () => {
    const error = {
      error: {
        message: [
          'correo must be an email',
          'nombreUsuario already exists',
          'Bad Request',
        ],
      },
    };

    expect(
      mensajeErrorBackend(error, {
        correo: 'Correo',
        nombreUsuario: 'Usuario',
      }),
    ).toBe(
      'Revise los datos enviados: Correo: ingrese un correo valido. | Usuario: ya existe, use otro valor.',
    );
  });

  it('usa fallback si solo llegan mensajes tecnicos', () => {
    expect(
      mensajeErrorBackend({ error: { message: 'Internal Server Error' } }, {}),
    ).toBe('No se pudo completar la operacion. Revise los datos enviados.');
  });
});
