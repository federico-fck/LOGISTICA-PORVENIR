import { TestBed } from '@angular/core/testing';
import { ActivatedRouteSnapshot, Router, RouterStateSnapshot } from '@angular/router';

import { AuthState } from '../state/auth.state';
import { PermissionService } from '../services/permission.service';
import { authGuard } from './auth.guard';
import { permissionGuard } from './permission.guard';
import { roleGuard } from './role.guard';

describe('Guards funcionales', () => {
  const route = (data: Record<string, unknown> = {}) =>
    ({ data }) as ActivatedRouteSnapshot;
  const state = {} as RouterStateSnapshot;

  afterEach(() => {
    TestBed.resetTestingModule();
  });

  it('authGuard permite usuario autenticado', () => {
    TestBed.configureTestingModule({
      providers: [
        { provide: AuthState, useValue: { estaAutenticado: () => true } },
        { provide: Router, useValue: { navigate: vi.fn() } },
      ],
    });

    const result = TestBed.runInInjectionContext(() => authGuard(route(), state));

    expect(result).toBe(true);
  });

  it('authGuard cierra sesion y redirige si no hay autenticacion', () => {
    const router = { navigate: vi.fn() };
    const authState = {
      estaAutenticado: () => false,
      cerrarSesion: vi.fn(),
    };
    TestBed.configureTestingModule({
      providers: [
        { provide: AuthState, useValue: authState },
        { provide: Router, useValue: router },
      ],
    });

    const result = TestBed.runInInjectionContext(() => authGuard(route(), state));

    expect(result).toBe(false);
    expect(authState.cerrarSesion).toHaveBeenCalledTimes(1);
    expect(router.navigate).toHaveBeenCalledWith(['/login']);
  });

  it('permissionGuard usa algun permiso por defecto', () => {
    const permissionService = {
      tieneAlgunPermiso: vi.fn(() => true),
      tieneTodosLosPermisos: vi.fn(() => false),
    };
    TestBed.configureTestingModule({
      providers: [
        { provide: PermissionService, useValue: permissionService },
        { provide: Router, useValue: { navigate: vi.fn() } },
      ],
    });

    const result = TestBed.runInInjectionContext(() =>
      permissionGuard(route({ permissions: ['dashboard.ver'] }), state),
    );

    expect(result).toBe(true);
    expect(permissionService.tieneAlgunPermiso).toHaveBeenCalledWith([
      'dashboard.ver',
    ]);
    expect(permissionService.tieneTodosLosPermisos).not.toHaveBeenCalled();
  });

  it('permissionGuard exige todos los permisos cuando la ruta lo declara', () => {
    const router = { navigate: vi.fn() };
    const permissionService = {
      tieneAlgunPermiso: vi.fn(() => true),
      tieneTodosLosPermisos: vi.fn(() => false),
    };
    TestBed.configureTestingModule({
      providers: [
        { provide: PermissionService, useValue: permissionService },
        { provide: Router, useValue: router },
      ],
    });

    const result = TestBed.runInInjectionContext(() =>
      permissionGuard(
        route({
          permissions: ['compras.ver', 'comprobantes.ver'],
          requireAllPermissions: true,
        }),
        state,
      ),
    );

    expect(result).toBe(false);
    expect(permissionService.tieneTodosLosPermisos).toHaveBeenCalledWith([
      'compras.ver',
      'comprobantes.ver',
    ]);
    expect(router.navigate).toHaveBeenCalledWith(['/acceso-denegado']);
  });

  it('roleGuard permite rol compatible y rechaza rol distinto', () => {
    const router = { navigate: vi.fn() };
    const authState = {
      tieneRol: vi.fn((roles: string[]) => roles.includes('ADMINISTRADOR')),
    };
    TestBed.configureTestingModule({
      providers: [
        { provide: AuthState, useValue: authState },
        { provide: Router, useValue: router },
      ],
    });

    const permitido = TestBed.runInInjectionContext(() =>
      roleGuard(route({ roles: ['ADMINISTRADOR'] }), state),
    );
    const rechazado = TestBed.runInInjectionContext(() =>
      roleGuard(route({ roles: ['AUDITOR'] }), state),
    );

    expect(permitido).toBe(true);
    expect(rechazado).toBe(false);
    expect(router.navigate).toHaveBeenCalledWith(['/dashboard']);
  });
});
