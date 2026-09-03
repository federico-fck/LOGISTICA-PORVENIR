import { Injectable } from '@angular/core';
import { tap } from 'rxjs';
import { ApiService } from './api.service';
import { LoginRequest, LoginResponse } from '../models/auth.model';
import { AuthState } from '../state/auth.state';
import { Usuario } from '../models/usuario.model';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  constructor(
    private readonly apiService: ApiService,
    private readonly authState: AuthState,
  ) {}

  login(data: LoginRequest) {
    return this.apiService.post<LoginResponse>('auth/login', data).pipe(
      tap((response) => {
        this.authState.guardarSesion(response);
      }),
    );
  }

  perfil() {
    return this.apiService.get<Usuario>('auth/perfil').pipe(
      tap((usuario) => {
        this.authState.actualizarUsuario(usuario);
      }),
    );
  }

  logout() {
    this.authState.cerrarSesion();
  }
}
