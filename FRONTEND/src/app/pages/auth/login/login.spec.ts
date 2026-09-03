import { FormBuilder } from '@angular/forms';
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { of, throwError } from 'rxjs';

import { AuthService } from '../../../core/services/auth.service';
import { Login } from './login';

describe('Login', () => {
  let authService: { login: ReturnType<typeof vi.fn> };
  let router: { navigate: ReturnType<typeof vi.fn> };

  function crearComponente(loginResult = of({})) {
    authService = {
      login: vi.fn(() => loginResult),
    };
    router = {
      navigate: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [
        FormBuilder,
        { provide: AuthService, useValue: authService },
        { provide: Router, useValue: router },
      ],
    });

    return TestBed.runInInjectionContext(() => new Login());
  }

  afterEach(() => {
    TestBed.resetTestingModule();
  });

  it('inicia con formulario invalido y visibilidad por defecto', () => {
    const component = crearComponente();

    expect(component.form.invalid).toBe(true);
    expect(component.cargando()).toBe(false);
    expect(component.error()).toBe('');
    expect(component.mostrarUsuario()).toBe(true);
    expect(component.mostrarPassword()).toBe(false);
  });

  it('alterna visualizacion de usuario y password', () => {
    const component = crearComponente();

    component.alternarUsuario();
    component.alternarPassword();

    expect(component.mostrarUsuario()).toBe(false);
    expect(component.mostrarPassword()).toBe(true);
  });

  it('no llama AuthService si el formulario es invalido', () => {
    const component = crearComponente();

    component.ingresar();

    expect(authService.login).not.toHaveBeenCalled();
    expect(component.cargando()).toBe(false);
  });

  it('envia credenciales y navega al dashboard al autenticar', () => {
    const component = crearComponente(of({ access_token: 'token' }));

    component.form.setValue({
      usuario: 'admin',
      password: 'secreto',
    });
    component.ingresar();

    expect(authService.login).toHaveBeenCalledWith({
      usuario: 'admin',
      password: 'secreto',
    });
    expect(component.cargando()).toBe(false);
    expect(router.navigate).toHaveBeenCalledWith(['/dashboard']);
  });

  it('muestra error si las credenciales son rechazadas', () => {
    const component = crearComponente(
      throwError(() => new Error('credenciales invalidas')),
    );

    component.form.setValue({
      usuario: 'admin',
      password: 'mala',
    });
    component.ingresar();

    expect(component.cargando()).toBe(false);
    expect(component.error()).toBe('Usuario o contraseña incorrectos.');
    expect(router.navigate).not.toHaveBeenCalled();
  });
});
