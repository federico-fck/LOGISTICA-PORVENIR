import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthState } from '../state/auth.state';

export const roleGuard: CanActivateFn = (route) => {
  const authState = inject(AuthState);
  const router = inject(Router);

  const rolesPermitidos = (route.data?.['roles'] as string[]) || [];

  if (authState.tieneRol(rolesPermitidos)) {
    return true;
  }

  router.navigate(['/dashboard']);
  return false;
};
