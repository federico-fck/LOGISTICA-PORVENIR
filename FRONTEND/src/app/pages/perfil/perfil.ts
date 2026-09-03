import { Component, computed, inject, signal } from '@angular/core';
import { AuthState } from '../../core/state/auth.state';
import { AuthService } from '../../core/services/auth.service';
import { Usuario } from '../../core/models/usuario.model';
import { formatearFechaHoraBolivia } from '../../core/utils/fecha.util';
import { formatearDocumentoIdentidad } from '../../core/utils/documento-identidad.util';

@Component({
  selector: 'app-perfil',
  standalone: true,
  imports: [],
  templateUrl: './perfil.html',
  styleUrl: './perfil.css',
})
export class Perfil {
  private readonly authState = inject(AuthState);
  private readonly authService = inject(AuthService);

  usuario = this.authState.usuario;
  rolNombreActual = this.authState.rolNombreActual;
  cargando = signal(false);
  error = signal('');

  iniciales = computed(() => {
    const nombre =
      this.usuario()?.nombreCompleto || this.usuario()?.nombreUsuario || 'Usuario';

    return nombre
      .trim()
      .split(' ')
      .filter(Boolean)
      .slice(0, 2)
      .map((parte) => parte[0])
      .join('')
      .toUpperCase();
  });

  ngOnInit() {
    this.cargarPerfil();
  }

  cargarPerfil() {
    this.cargando.set(true);
    this.error.set('');

    this.authService.perfil().subscribe({
      next: () => {
        this.cargando.set(false);
      },
      error: () => {
        this.cargando.set(false);
        this.error.set('No se pudo actualizar la información del perfil.');
      },
    });
  }

  documento(usuario?: Usuario | null): string {
    return formatearDocumentoIdentidad(usuario);
  }

  telefono(usuario?: Usuario | null): string {
    return usuario?.telefono || '';
  }

  cargo(usuario?: Usuario | null): string {
    return usuario?.cargo || '';
  }

  estado(usuario?: Usuario | null): string {
    return usuario?.estado || '';
  }

  area(usuario?: Usuario | null): string {
    const data = usuario as any;
    const area = data?.area;

    return (
      data?.nombreArea ||
      data?.nombre_area ||
      area?.nombreArea ||
      area?.nombre_area ||
      (typeof area === 'string' ? area : '') ||
      ''
    );
  }

  fecha(usuario: Usuario | null | undefined, campo: 'ultimo' | 'creacion'): string {
    const data = usuario as any;
    const valor =
      campo === 'ultimo'
        ? data?.ultimoInicioSesion || data?.ultimo_inicio_sesion
        : data?.fechaCreacion || data?.fecha_creacion;

    return valor ? formatearFechaHoraBolivia(valor) : '';
  }

  claseEstado(usuario?: Usuario | null): string {
    const estado = this.estado(usuario).toUpperCase();

    if (estado === 'ACTIVO') {
      return 'text-green-700';
    }

    if (estado === 'INACTIVO') {
      return 'text-red-700';
    }

    return 'text-slate-900';
  }
}
