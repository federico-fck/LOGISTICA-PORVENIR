import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { AuthState } from '../state/auth.state';

export const authGuard: CanActivateFn = () => {
  const authState = inject(AuthState);
  const router = inject(Router);

  if (authState.estaAutenticado()) {
    return true;
  }

  authState.cerrarSesion();
  router.navigate(['/login']);
  return false;
};
