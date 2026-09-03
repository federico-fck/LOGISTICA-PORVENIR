import { TestBed } from '@angular/core/testing';

import { ALL_PERMISSIONS } from '../security/role-permissions';
import { AuthState } from '../state/auth.state';
import { PermissionService } from './permission.service';

describe('PermissionService', () => {
  beforeEach(() => {
    localStorage.clear();
    TestBed.resetTestingModule();
  });

  afterEach(() => {
    localStorage.clear();
    TestBed.resetTestingModule();
  });

  function crearService(rol: string, permisos: string[] = []) {
    TestBed.configureTestingModule({
      providers: [
        PermissionService,
        {
          provide: AuthState,
          useValue: {
            rolActual: vi.fn(() => rol),
            permisos: vi.fn(() => permisos),
          },
        },
      ],
    });

    return TestBed.inject(PermissionService);
  }

  it('permite todo al administrador', () => {
    const service = crearService('ADMINISTRADOR');

    expect(service.esAdministrador()).toBe(true);
    expect(service.tienePermiso('usuarios.eliminar')).toBe(true);
    expect(service.permisosActuales()).toEqual([...ALL_PERMISSIONS]);
  });

  it('combina permisos por rol, estado y localStorage sin duplicados', () => {
    localStorage.setItem(
      'logistica_porvenir_usuario',
      JSON.stringify({ permisos: ['manual.ver', 'inventario.ver'] }),
    );
    const service = crearService('ENCARGADO_ALMACEN', [
      'manual.ver',
      'inventario.transferir',
    ]);

    expect(service.tienePermiso('inventario.ajustar')).toBe(true);
    expect(service.tienePermiso('manual.ver')).toBe(true);
    expect(service.tienePermiso('usuarios.crear')).toBe(false);
    expect(service.permisosActuales().filter((p) => p === 'manual.ver')).toHaveLength(1);
  });

  it('evalua algun permiso, todos los permisos y permisos vacios', () => {
    const service = crearService('AUDITOR');

    expect(service.tienePermiso('')).toBe(true);
    expect(service.tieneAlgunPermiso([])).toBe(true);
    expect(service.tieneTodosLosPermisos([])).toBe(true);
    expect(
      service.tieneAlgunPermiso(['usuarios.crear', 'auditoria.ver']),
    ).toBe(true);
    expect(
      service.tieneTodosLosPermisos(['auditoria.ver', 'reportes.imprimir']),
    ).toBe(true);
    expect(
      service.tieneTodosLosPermisos(['auditoria.ver', 'usuarios.eliminar']),
    ).toBe(false);
  });

  it('ignora permisos corruptos de localStorage', () => {
    localStorage.setItem('logistica_porvenir_usuario', '{mal json');
    const service = crearService('USUARIO_SOLICITANTE');

    expect(service.permisosActuales()).toContain('pedidos.crear');
    expect(service.tienePermiso('usuarios.eliminar')).toBe(false);
  });
});
