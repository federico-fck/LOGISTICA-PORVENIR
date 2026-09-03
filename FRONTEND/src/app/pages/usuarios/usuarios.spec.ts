import { FormBuilder, Validators } from '@angular/forms';
import {
  complementoCiValidator,
  correoProfesionalValidator,
  nombrePersonaValidator,
  normalizarMinusculas,
  passwordUsuarioErrors,
  soloNumerosMaxValidator,
  telefonoBoliviaValidator,
  usuarioSistemaValidator,
} from '../../core/forms/professional-forms';

describe('Usuarios - validaciones de formulario', () => {
  const fb = new FormBuilder().nonNullable;

  function crearForm() {
    return fb.group({
      nombreUsuario: [
        '',
        [Validators.required, Validators.maxLength(25), usuarioSistemaValidator()],
      ],
      nombreCompleto: [
        '',
        [Validators.required, Validators.maxLength(50), nombrePersonaValidator()],
      ],
      correo: [
        '',
        [Validators.required, Validators.maxLength(60), correoProfesionalValidator()],
      ],
      cedulaIdentidad: ['', [Validators.required, soloNumerosMaxValidator(9)]],
      complementoCi: ['', [Validators.maxLength(2), complementoCiValidator()]],
      telefono: ['', [Validators.required, telefonoBoliviaValidator()]],
      cargo: ['', [Validators.maxLength(100)]],
      password: [''],
      confirmarPassword: [''],
    });
  }

  it('usuario mayor a 25 caracteres debe ser invalido', () => {
    const form = crearForm();
    form.controls.nombreUsuario.setValue('usuario_demasiado_largo_123');
    expect(form.controls.nombreUsuario.valid).toBe(false);
  });

  it('usuario con ñ o espacios debe ser invalido', () => {
    const form = crearForm();
    form.controls.nombreUsuario.setValue('peña');
    expect(form.controls.nombreUsuario.valid).toBe(false);
    form.controls.nombreUsuario.setValue('pedro mina');
    expect(form.controls.nombreUsuario.valid).toBe(false);
  });

  it('correo sin @ es invalido y mayusculas se convierten a minusculas', () => {
    const form = crearForm();
    form.controls.correo.setValue('usuario.local');
    expect(form.controls.correo.valid).toBe(false);
    expect(normalizarMinusculas('USUARIO@DOMINIO.COM')).toBe('usuario@dominio.com');
  });

  it('cedula con letras o mayor a 9 es invalida', () => {
    const form = crearForm();
    form.controls.cedulaIdentidad.setValue('123A');
    expect(form.controls.cedulaIdentidad.valid).toBe(false);
    form.controls.cedulaIdentidad.setValue('1234567890');
    expect(form.controls.cedulaIdentidad.valid).toBe(false);
  });

  it('complemento vacio y 1A son validos; mayor a 2 es invalido', () => {
    const form = crearForm();
    form.controls.complementoCi.setValue('');
    expect(form.controls.complementoCi.valid).toBe(true);
    form.controls.complementoCi.setValue('1A');
    expect(form.controls.complementoCi.valid).toBe(true);
    form.controls.complementoCi.setValue('1AB');
    expect(form.controls.complementoCi.valid).toBe(false);
  });

  it('contacto que no inicia con 6 o 7 o mayor a 8 es invalido', () => {
    const form = crearForm();
    form.controls.telefono.setValue('50000000');
    expect(form.controls.telefono.valid).toBe(false);
    form.controls.telefono.setValue('700000000');
    expect(form.controls.telefono.valid).toBe(false);
  });

  it('contacto valido mantiene la regla de telefono Bolivia', () => {
    const form = crearForm();
    form.controls.telefono.setValue('70000000');
    expect(form.controls.telefono.valid).toBe(true);
  });

  it('cargo manual vacio es valido y respeta maximo 100', () => {
    const form = crearForm();
    form.controls.cargo.setValue('');
    expect(form.controls.cargo.valid).toBe(true);
    form.controls.cargo.setValue('A'.repeat(101));
    expect(form.controls.cargo.valid).toBe(false);
  });

  it('crear usuario sin password es invalido', () => {
    expect(passwordUsuarioErrors('nuevo', false, '', '')).toEqual({
      passwordRequerido: true,
    });
  });

  it('editar usuario sin cambiar password es valido', () => {
    expect(passwordUsuarioErrors('editar', false, '', '')).toBeNull();
  });

  it('editar usuario con cambio de password y confirmacion distinta es invalido', () => {
    expect(passwordUsuarioErrors('editar', true, 'secreto1', 'secreto2')).toEqual({
      passwordConfirmacion: true,
    });
  });
});
