import { Component, computed, inject, signal } from '@angular/core';
import {
  Router,
  RouterLink,
  RouterLinkActive,
  RouterOutlet,
} from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { AuthState } from '../../core/state/auth.state';
import { MenuService } from '../../core/services/menu.service';
import { NotificacionesService } from '../../core/services/notificaciones.service';
import { Notificacion } from '../../core/models/notificacion.model';

@Component({
  selector: 'app-admin-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './admin-layout.html',
  styleUrl: './admin-layout.css',
})
export class AdminLayout {
  private readonly authService = inject(AuthService);
  private readonly authState = inject(AuthState);
  private readonly menuService = inject(MenuService);
  private readonly notificacionesService = inject(NotificacionesService);
  private readonly router = inject(Router);

  usuario = this.authState.usuario;
  rolNombreActual = this.authState.rolNombreActual;
  menu = computed(() => this.menuService.obtenerMenu());
  notificaciones = signal<Notificacion[]>([]);

  menuUsuarioAbierto = signal(false);

  iniciales = computed(() => {
    const nombre =
      this.usuario()?.nombreCompleto || this.usuario()?.nombreUsuario || 'Usuario';
    const partes = nombre.trim().split(' ').filter(Boolean);

    return partes
      .slice(0, 2)
      .map((parte) => parte[0])
      .join('')
      .toUpperCase();
  });

  totalNoLeidas = computed(() => {
    return this.notificaciones().filter((item) => !this.estaLeida(item)).length;
  });

  ngOnInit() {
    this.cargarNotificaciones();
    this.notificacionesService.cambios$.subscribe(() => {
      this.cargarNotificaciones();
    });
  }

  alternarMenuUsuario() {
    this.menuUsuarioAbierto.update((valor) => !valor);
  }

  irPerfil() {
    this.menuUsuarioAbierto.set(false);
    this.router.navigate(['/perfil']);
  }

  cerrarSesion() {
    this.menuUsuarioAbierto.set(false);
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  cargarNotificaciones() {
    const idUsuario = this.usuario()?.idUsuario;

    this.notificacionesService
      .listar(idUsuario ? { idUsuario } : undefined)
      .subscribe({
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

    const estado = String(data.estado || data.estadoNotificacion || '').toUpperCase();

    return estado.includes('LEIDA') || estado.includes('LEÍDA') || estado.includes('VISTA');
  }
}
