import { of } from 'rxjs';

import { AuthService } from './auth.service';

describe('AuthService', () => {
  it('guarda la sesion al iniciar sesion correctamente', () => {
    const response = {
      access_token: 'token',
      usuario: {
        idUsuario: 1,
        nombreUsuario: 'admin',
        nombreCompleto: 'Admin Sistema',
        estado: 'ACTIVO',
      },
    };
    const apiService = {
      post: vi.fn(() => of(response)),
    };
    const authState = {
      guardarSesion: vi.fn(),
    };
    const service = new AuthService(apiService as any, authState as any);
    let recibido: unknown;

    service.login({ usuario: 'admin', password: 'secret' }).subscribe((data) => {
      recibido = data;
    });

    expect(apiService.post).toHaveBeenCalledWith('auth/login', {
      usuario: 'admin',
      password: 'secret',
    });
    expect(authState.guardarSesion).toHaveBeenCalledWith(response);
    expect(recibido).toBe(response);
  });

  it('actualiza el usuario al consultar perfil', () => {
    const usuario = {
      idUsuario: 2,
      nombreUsuario: 'ana',
      nombreCompleto: 'Ana Rojas',
      estado: 'ACTIVO',
    };
    const apiService = {
      get: vi.fn(() => of(usuario)),
    };
    const authState = {
      actualizarUsuario: vi.fn(),
    };
    const service = new AuthService(apiService as any, authState as any);

    service.perfil().subscribe();

    expect(apiService.get).toHaveBeenCalledWith('auth/perfil');
    expect(authState.actualizarUsuario).toHaveBeenCalledWith(usuario);
  });

  it('cierra sesion delegando al estado de autenticacion', () => {
    const authState = {
      cerrarSesion: vi.fn(),
    };
    const service = new AuthService({} as any, authState as any);

    service.logout();

    expect(authState.cerrarSesion).toHaveBeenCalledTimes(1);
  });
});
