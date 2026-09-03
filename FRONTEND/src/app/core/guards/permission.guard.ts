import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { PermissionService } from '../services/permission.service';

export const permissionGuard: CanActivateFn = (route) => {
  const permissions = (route.data?.['permissions'] as string[]) || [];
  const requireAll = Boolean(route.data?.['requireAllPermissions']);
  const permissionService = inject(PermissionService);
  const router = inject(Router);

  const autorizado = requireAll
    ? permissionService.tieneTodosLosPermisos(permissions)
    : permissionService.tieneAlgunPermiso(permissions);

  if (autorizado) {
    return true;
  }

  router.navigate(['/acceso-denegado']);
  return false;
};
