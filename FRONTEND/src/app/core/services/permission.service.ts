import { Injectable } from '@angular/core';
import { AuthState } from '../state/auth.state';
import { normalizarRol, ROLES_SISTEMA } from '../utils/roles.util';
import { ALL_PERMISSIONS, obtenerPermisosPorRol } from '../security/role-permissions';

@Injectable({
  providedIn: 'root',
})
export class PermissionService {
  readonly mensajeSinPermiso = 'No tiene permisos para realizar esta acci\u00f3n.';

  constructor(private readonly authState: AuthState) {}

  tienePermiso(permiso: string): boolean {
    if (!permiso) {
      return true;
    }

    if (this.esAdministrador()) {
      return true;
    }

    return this.permisosActuales().includes(permiso);
  }

  tieneAlgunPermiso(permisos: string[]): boolean {
    if (!permisos || permisos.length === 0) {
      return true;
    }

    return permisos.some((permiso) => this.tienePermiso(permiso));
  }

  tieneTodosLosPermisos(permisos: string[]): boolean {
    if (!permisos || permisos.length === 0) {
      return true;
    }

    return permisos.every((permiso) => this.tienePermiso(permiso));
  }

  esAdministrador(): boolean {
    return this.rolActual() === ROLES_SISTEMA.ADMINISTRADOR;
  }

  permisosActuales(): string[] {
    if (this.esAdministrador()) {
      return [...ALL_PERMISSIONS];
    }

    return [
      ...new Set([
        ...obtenerPermisosPorRol(this.rolActual()),
        ...this.permisosDesdeStorage(),
        ...this.authState.permisos(),
      ]),
    ];
  }

  private rolActual(): string {
    return normalizarRol(this.authState.rolActual());
  }

  private permisosDesdeStorage(): string[] {
    try {
      const usuario = JSON.parse(
        localStorage.getItem('logistica_porvenir_usuario') || 'null',
      );
      return Array.isArray(usuario?.permisos) ? usuario.permisos : [];
    } catch {
      return [];
    }
  }
}
