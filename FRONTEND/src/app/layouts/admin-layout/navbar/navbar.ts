import { Component, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';

import { AuthState } from '../../../core/state/auth.state';
import { NotificacionesService } from '../../../core/services/notificaciones.service';
import { Notificacion } from '../../../core/models/notificacion.model';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [],
  templateUrl: './navbar.html',
  styleUrl: './navbar.css',
})
export class Navbar {
  private readonly router = inject(Router);
  private readonly authState = inject(AuthState);
  private readonly notificacionesService = inject(NotificacionesService);

  menuUsuarioAbierto = signal(false);
  notificaciones = signal<Notificacion[]>([]);

  usuario = computed(() => this.obtenerUsuarioActual());

  nombreUsuario = computed(() => {
    const usuario = this.usuario() as any;

    return String(
      usuario?.nombreCompleto ||
        usuario?.nombre_completo ||
        usuario?.nombreUsuario ||
        usuario?.nombre_usuario ||
        usuario?.usuario ||
        'Usuario del sistema',
    );
  });

  rolUsuario = computed(() => {
    return this.authState.rolNombreActual() || 'Sin rol';
  });

  iniciales = computed(() => {
    const nombre = this.nombreUsuario();
    const partes = nombre.trim().split(' ').filter(Boolean);

    if (partes.length >= 2) {
      return `${partes[0][0]}${partes[1][0]}`.toUpperCase();
    }

    return nombre.substring(0, 2).toUpperCase();
  });

  totalNoLeidas = computed(() => {
    return this.notificaciones().filter((item) => !this.estaLeida(item)).length;
  });

  ngOnInit() {
    this.cargarNotificaciones();

    setInterval(() => {
      this.cargarNotificaciones();
    }, 30000);
  }

  obtenerUsuarioActual(): any {
    const auth = this.authState as any;

    const posibles = [
      auth.usuarioActual,
      auth.usuario,
      auth.usuarioAutenticado,
      auth.usuarioLogueado,
      auth.user,
    ];

    for (const posible of posibles) {
      if (typeof posible === 'function') {
        const resultado = posible.call(auth);

        if (resultado) {
          return resultado;
        }
      }

      if (posible && typeof posible === 'object') {
        return posible;
      }
    }

    const claves = [
      'usuario',
      'user',
      'auth_usuario',
      'authUser',
      'usuarioActual',
      'currentUser',
    ];

    for (const clave of claves) {
      const valor = localStorage.getItem(clave);

      if (valor) {
        try {
          return JSON.parse(valor);
        } catch {
          return valor;
        }
      }
    }

    return null;
  }

  cargarNotificaciones() {
    this.notificacionesService.listar().subscribe({
      next: (data: any) => {
        this.notificaciones.set(this.normalizarArray(data));
      },
      error: () => {
        this.notificaciones.set([]);
      },
    });
  }

  normalizarArray(data: any): Notificacion[] {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data?.data)) return data.data;
    if (Array.isArray(data?.items)) return data.items;
    if (Array.isArray(data?.registros)) return data.registros;
    return [];
  }

  estaLeida(item: Notificacion): boolean {
    const data = item as any;

    if (typeof data.leida === 'boolean') {
      return data.leida;
    }

    if (typeof data.visto === 'boolean') {
      return data.visto;
    }

    const estado = String(data.estado || '').toUpperCase();

    return estado.includes('LEIDA') || estado.includes('LEÍDA') || estado.includes('VISTA');
  }

  irNotificaciones() {
    this.menuUsuarioAbierto.set(false);
    this.router.navigate(['/notificaciones']);
  }

  irPerfil() {
    this.menuUsuarioAbierto.set(false);
    this.router.navigate(['/perfil']);
  }

  alternarMenuUsuario() {
    this.menuUsuarioAbierto.update((valor) => !valor);
  }

  cerrarSesion() {
    const auth = this.authState as any;

    if (typeof auth.cerrarSesion === 'function') {
      auth.cerrarSesion();
    } else {
      localStorage.clear();
    }

    this.router.navigate(['/login']);
  }
}
