import { computed, Injectable, signal } from '@angular/core';
import { LoginResponse } from '../models/auth.model';
import { Usuario } from '../models/usuario.model';
import { nombreRolDesdeCodigo, normalizarRol } from '../utils/roles.util';

@Injectable({
  providedIn: 'root',
})
export class AuthState {
  private readonly tokenKey = 'logistica_porvenir_token';
  private readonly userKey = 'logistica_porvenir_usuario';

  token = signal<string | null>(this.obtenerTokenInicial());

  usuario = signal<Usuario | null>(this.obtenerUsuarioInicial());

  estaAutenticado = computed(() => {
    const token = this.token();
    return !!token && !this.tokenExpirado(token);
  });

  rolActual = computed(() => {
    const usuario = this.usuario();

    return this.obtenerCodigoRol(usuario);
  });

  rolNombreActual = computed(() => {
    const usuario = this.usuario() as any;

    return (
      usuario?.rolNombre ||
      usuario?.rol?.nombreRol ||
      usuario?.rol?.nombre_rol ||
      nombreRolDesdeCodigo(this.rolActual())
    );
  });

  permisos = computed(() => this.usuario()?.permisos || []);

  guardarSesion(response: LoginResponse) {
    const usuario = this.normalizarUsuarioSesion(response.usuario);

    localStorage.setItem(this.tokenKey, response.access_token);
    localStorage.setItem(this.userKey, JSON.stringify(usuario));

    this.token.set(response.access_token);
    this.usuario.set(usuario);
  }

  actualizarUsuario(usuarioActualizado: Usuario) {
    const usuario = this.normalizarUsuarioSesion({
      ...(this.usuario() || {}),
      ...usuarioActualizado,
    });

    localStorage.setItem(this.userKey, JSON.stringify(usuario));
    this.usuario.set(usuario);
  }

  cerrarSesion() {
    localStorage.removeItem(this.tokenKey);
    localStorage.removeItem(this.userKey);

    this.token.set(null);
    this.usuario.set(null);
  }

  tieneRol(roles: string[]): boolean {
    if (roles.length === 0) {
      return true;
    }

    const rol = this.rolActual();

    return roles.map((r) => normalizarRol(r)).includes(rol);
  }

  private obtenerCodigoRol(usuario: Usuario | null): string {
    const data = usuario as any;

    if (!data) {
      return '';
    }

    return normalizarRol(
      data.codigoRol ||
        data.codigo_rol ||
        data.rol?.codigoRol ||
        data.rol?.codigo_rol ||
        data.rol?.nombreRol ||
        data.rol?.nombre_rol ||
        data.rol,
    );
  }

  private obtenerTokenInicial() {
    const token = localStorage.getItem(this.tokenKey);

    if (!token || this.tokenExpirado(token)) {
      localStorage.removeItem(this.tokenKey);
      localStorage.removeItem(this.userKey);
      return null;
    }

    return token;
  }

  private obtenerUsuarioInicial(): Usuario | null {
    const usuario = localStorage.getItem(this.userKey);

    if (!usuario) {
      return null;
    }

    try {
      return JSON.parse(usuario) as Usuario;
    } catch {
      localStorage.removeItem(this.userKey);
      return null;
    }
  }

  private normalizarUsuarioSesion(usuarioOriginal: Usuario): Usuario {
    const data = usuarioOriginal as any;
    const area = data?.area;

    return {
      ...usuarioOriginal,
      idArea:
        data?.idArea ||
        data?.id_area ||
        area?.idArea ||
        area?.id_area,
      nombreArea:
        data?.nombreArea ||
        data?.nombre_area ||
        area?.nombreArea ||
        area?.nombre_area ||
        (typeof area === 'string' ? area : undefined),
      idRol:
        data?.idRol ||
        data?.id_rol ||
        data?.rol?.idRol ||
        data?.rol?.id_rol,
      cedulaIdentidad: data?.cedulaIdentidad ?? data?.cedula_identidad,
      complementoCi: data?.complementoCi ?? data?.complemento_ci,
      expedidoCi: data?.expedidoCi ?? data?.expedido_ci,
      codigoRol: this.obtenerCodigoRol(usuarioOriginal),
    };
  }

  private tokenExpirado(token: string): boolean {
    try {
      const payloadBase64 = token.split('.')[1];

      if (!payloadBase64) {
        return true;
      }

      const payload = JSON.parse(atob(payloadBase64.replace(/-/g, '+').replace(/_/g, '/')));
      return typeof payload.exp === 'number' && payload.exp * 1000 <= Date.now();
    } catch {
      return true;
    }
  }
}
