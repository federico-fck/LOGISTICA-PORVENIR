import { TestBed } from '@angular/core/testing';

import { AuthState } from './auth.state';

function jwtConExp(exp: number): string {
  const base64Url = (value: unknown) =>
    btoa(JSON.stringify(value))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/g, '');

  return `${base64Url({ alg: 'none', typ: 'JWT' })}.${base64Url({ exp })}.firma`;
}

describe('AuthState', () => {
  beforeEach(() => {
    localStorage.clear();
    TestBed.resetTestingModule();
  });

  afterEach(() => {
    localStorage.clear();
    TestBed.resetTestingModule();
  });

  it('lee una sesion inicial valida desde localStorage', () => {
    const token = jwtConExp(Math.floor(Date.now() / 1000) + 3600);
    localStorage.setItem('logistica_porvenir_token', token);
    localStorage.setItem(
      'logistica_porvenir_usuario',
      JSON.stringify({
        idUsuario: 1,
        nombreUsuario: 'admin',
        nombreCompleto: 'Admin Sistema',
        estado: 'ACTIVO',
        rol: { codigoRol: 'ADMINISTRADOR' },
      }),
    );

    const state = TestBed.inject(AuthState);

    expect(state.token()).toBe(token);
    expect(state.estaAutenticado()).toBe(true);
    expect(state.rolActual()).toBe('ADMINISTRADOR');
    expect(state.rolNombreActual()).toBe('Administrador del sistema');
  });

  it('descarta token expirado y usuario almacenado', () => {
    localStorage.setItem(
      'logistica_porvenir_token',
      jwtConExp(Math.floor(Date.now() / 1000) - 60),
    );
    localStorage.setItem('logistica_porvenir_usuario', '{"nombreUsuario":"viejo"}');

    const state = TestBed.inject(AuthState);

    expect(state.token()).toBeNull();
    expect(state.usuario()).toBeNull();
    expect(localStorage.getItem('logistica_porvenir_token')).toBeNull();
    expect(localStorage.getItem('logistica_porvenir_usuario')).toBeNull();
  });

  it('normaliza usuario al guardar sesion y al actualizar perfil', () => {
    const state = TestBed.inject(AuthState);
    const token = jwtConExp(Math.floor(Date.now() / 1000) + 3600);

    state.guardarSesion({
      access_token: token,
      usuario: {
        idUsuario: 3,
        nombreUsuario: 'jefe',
        nombreCompleto: 'Jefe Area',
        estado: 'ACTIVO',
        id_area: 4,
        area: { idArea: 4, nombreArea: 'Mina Norte' },
        rol: { idRol: 2, nombreRol: 'Jefe de area' },
        permisos: ['pedidos.aprobar'],
      } as any,
    });

    expect(state.token()).toBe(token);
    expect(state.usuario()?.idArea).toBe(4);
    expect(state.usuario()?.nombreArea).toBe('Mina Norte');
    expect(state.rolActual()).toBe('JEFE_AREA');
    expect(state.permisos()).toEqual(['pedidos.aprobar']);

    state.actualizarUsuario({
      idUsuario: 3,
      nombreUsuario: 'jefe',
      nombreCompleto: 'Jefe Area Editado',
      estado: 'ACTIVO',
      codigoRol: 'ENCARGADO_COMPRAS',
      rolNombre: 'Encargado de compras',
    } as any);

    expect(state.usuario()?.nombreCompleto).toBe('Jefe Area Editado');
    expect(state.rolActual()).toBe('ENCARGADO_COMPRAS');
    expect(localStorage.getItem('logistica_porvenir_usuario')).toContain(
      'Jefe Area Editado',
    );
  });

  it('cierra sesion y evalua roles permitidos', () => {
    const state = TestBed.inject(AuthState);
    const token = jwtConExp(Math.floor(Date.now() / 1000) + 3600);

    state.guardarSesion({
      access_token: token,
      usuario: {
        idUsuario: 1,
        nombreUsuario: 'almacen',
        nombreCompleto: 'Encargado Almacen',
        estado: 'ACTIVO',
        codigoRol: 'ENCARGADO_ALMACEN',
      },
    });

    expect(state.tieneRol([])).toBe(true);
    expect(state.tieneRol(['Jefe de almacen'])).toBe(true);
    expect(state.tieneRol(['AUDITOR'])).toBe(false);

    state.cerrarSesion();

    expect(state.token()).toBeNull();
    expect(state.usuario()).toBeNull();
    expect(state.estaAutenticado()).toBe(false);
  });
});
