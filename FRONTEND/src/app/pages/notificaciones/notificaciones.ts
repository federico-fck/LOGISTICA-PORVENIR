import { Component, computed, inject, signal } from '@angular/core';

import { NotificacionesService } from '../../core/services/notificaciones.service';
import { PermissionService } from '../../core/services/permission.service';
import { Notificacion } from '../../core/models/notificacion.model';
import { formatearFechaHoraBolivia } from '../../core/utils/fecha.util';

type FiltroNotificacion = 'todas' | 'no-leidas' | 'leidas';
type ModoModal = 'ninguno' | 'ver' | 'eliminar';

@Component({
  selector: 'app-notificaciones',
  standalone: true,
  imports: [],
  templateUrl: './notificaciones.html',
  styleUrl: './notificaciones.css',
})
export class Notificaciones {
  private readonly notificacionesService = inject(NotificacionesService);
  private readonly permissionService = inject(PermissionService);

  cargando = signal(false);
  guardando = signal(false);
  error = signal('');
  mensaje = signal('');

  busqueda = signal('');
  filtroActual = signal<FiltroNotificacion>('todas');

  notificaciones = signal<Notificacion[]>([]);
  notificacionSeleccionada = signal<Notificacion | null>(null);
  modoModal = signal<ModoModal>('ninguno');

  modalAbierto = computed(() => this.modoModal() !== 'ninguno');

  totalNotificaciones = computed(() => this.notificaciones().length);

  totalNoLeidas = computed(() =>
    this.notificaciones().filter((item) => !this.estaLeida(item)).length,
  );

  totalLeidas = computed(() =>
    this.notificaciones().filter((item) => this.estaLeida(item)).length,
  );

  totalUrgentes = computed(() =>
    this.notificaciones().filter((item) => {
      const prioridad = this.prioridad(item).toUpperCase();
      const tipo = this.tipoNotificacion(item).toUpperCase();

      return (
        prioridad.includes('ALTA') ||
        prioridad.includes('URGENTE') ||
        tipo.includes('CRITICO') ||
        tipo.includes('CRÍTICO')
      );
    }).length,
  );

  notificacionesFiltradas = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();

    return this.notificaciones().filter((item) => {
      const cumpleFiltro =
        this.filtroActual() === 'todas' ||
        (this.filtroActual() === 'no-leidas' && !this.estaLeida(item)) ||
        (this.filtroActual() === 'leidas' && this.estaLeida(item));

      if (!cumpleFiltro) {
        return false;
      }

      if (!texto) {
        return true;
      }

      return (
        this.titulo(item).toLowerCase().includes(texto) ||
        this.mensajeNotificacion(item).toLowerCase().includes(texto) ||
        this.tipoNotificacion(item).toLowerCase().includes(texto) ||
        this.modulo(item).toLowerCase().includes(texto) ||
        this.prioridad(item).toLowerCase().includes(texto)
      );
    });
  });

  ngOnInit() {
    this.cargarNotificaciones();
  }

  cargarNotificaciones() {
    this.cargando.set(true);
    this.error.set('');
    this.mensaje.set('');

    this.notificacionesService.listar().subscribe({
      next: (data) => {
        this.notificaciones.set(this.normalizarArray(data));
        this.cargando.set(false);
      },
      error: () => {
        this.error.set('No se pudo cargar la lista de notificaciones.');
        this.cargando.set(false);
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

  tienePermiso(permiso: string): boolean {
    return this.permissionService.tienePermiso(permiso);
  }

  private verificarPermiso(permiso: string): boolean {
    if (this.permissionService.tienePermiso(permiso)) {
      return true;
    }

    this.error.set(this.permissionService.mensajeSinPermiso);
    window.alert(this.permissionService.mensajeSinPermiso);
    return false;
  }

  cambiarBusqueda(event: Event) {
    const input = event.target as HTMLInputElement;
    this.busqueda.set(input.value);
  }

  cambiarFiltro(filtro: FiltroNotificacion) {
    this.filtroActual.set(filtro);
    this.error.set('');
    this.mensaje.set('');
  }

  abrirVer(item: Notificacion) {
    const id = this.idNotificacion(item);

    if (!id) {
      this.notificacionSeleccionada.set(item);
      this.modoModal.set('ver');
      return;
    }

    this.notificacionesService.buscarPorId(id).subscribe({
      next: (data) => {
        this.notificacionSeleccionada.set(data);
        this.modoModal.set('ver');
      },
      error: () => {
        this.notificacionSeleccionada.set(item);
        this.modoModal.set('ver');
      },
    });
  }

  abrirEliminar(item: Notificacion) {
    if (!this.verificarPermiso('notificaciones.eliminar')) {
      return;
    }

    this.error.set('');
    this.mensaje.set('');
    this.notificacionSeleccionada.set(item);
    this.modoModal.set('eliminar');
  }

  cerrarModal() {
    this.modoModal.set('ninguno');
    this.notificacionSeleccionada.set(null);
  }

  marcarLeida(item: Notificacion) {
    if (!this.verificarPermiso('notificaciones.marcar_leida')) {
      return;
    }

    const id = this.idNotificacion(item);

    if (!id) {
      this.error.set('No se encontró el identificador de la notificación.');
      return;
    }

    this.guardando.set(true);
    this.error.set('');
    this.mensaje.set('');

    this.notificacionesService.marcarComoLeida(id).subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set('Notificación marcada como leída.');
        this.actualizarLeidaLocal(id);
        this.notificacionesService.notificarCambio();
      },
      error: (error) => {
        console.error('Error al marcar notificación:', error);
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
      },
    });
  }

  marcarTodasLeidas() {
    if (!this.verificarPermiso('notificaciones.marcar_leida')) {
      return;
    }

    this.guardando.set(true);
    this.error.set('');
    this.mensaje.set('');

    this.notificacionesService.marcarTodasComoLeidas().subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set('Todas las notificaciones fueron marcadas como leídas.');
        const fechaLectura = new Date().toISOString();
        this.notificaciones.update((items) =>
          items.map((notificacion) => ({
            ...notificacion,
            leida: true,
            estado: 'LEIDA',
            estadoNotificacion: 'LEIDA',
            fechaLectura,
          })),
        );
        this.notificacionesService.notificarCambio();
      },
      error: (error) => {
        console.error('Error al marcar todas:', error);
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
      },
    });
  }

  confirmarEliminar() {
    if (!this.verificarPermiso('notificaciones.eliminar')) {
      return;
    }

    const item = this.notificacionSeleccionada();

    if (!item) {
      return;
    }

    const id = this.idNotificacion(item);

    if (!id) {
      this.error.set('No se encontró el identificador de la notificación.');
      return;
    }

    this.guardando.set(true);

    this.notificacionesService.eliminar(id).subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set('Notificación eliminada correctamente.');
        this.cerrarModal();
        this.notificaciones.update((items) =>
          items.filter((notificacion) => this.idNotificacion(notificacion) !== id),
        );
        this.notificacionesService.notificarCambio();
      },
      error: (error) => {
        console.error('Error al eliminar notificación:', error);
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
      },
    });
  }

  obtenerMensajeErrorBackend(error: any): string {
    const mensaje = error?.error?.message;

    if (Array.isArray(mensaje)) return mensaje.join(' | ');
    if (typeof mensaje === 'string') return mensaje;
    if (error?.error?.error) return error.error.error;

    return 'No se pudo completar la operación. Revise el endpoint del backend.';
  }

  idNotificacion(item: Notificacion): number {
    const data = item as any;
    return Number(data.idNotificacion || data.id_notificacion || data.id || 0);
  }

  actualizarLeidaLocal(idNotificacion: number) {
    const fechaLectura = new Date().toISOString();

    this.notificaciones.update((items) =>
      items.map((item) =>
        this.idNotificacion(item) === idNotificacion
          ? {
              ...item,
              leida: true,
              estado: 'LEIDA',
              estadoNotificacion: 'LEIDA',
              fechaLectura,
            }
          : item,
      ),
    );

    const seleccionada = this.notificacionSeleccionada();

    if (seleccionada && this.idNotificacion(seleccionada) === idNotificacion) {
      this.notificacionSeleccionada.set({
        ...seleccionada,
        leida: true,
        estado: 'LEIDA',
        estadoNotificacion: 'LEIDA',
        fechaLectura,
      });
    }
  }

  titulo(item: Notificacion): string {
    const data = item as any;
    return String(data.titulo || data.asunto || 'Sin título');
  }

  mensajeNotificacion(item: Notificacion): string {
    const data = item as any;
    return String(data.mensaje || data.descripcion || data.detalle || 'Sin mensaje');
  }

  tipoNotificacion(item: Notificacion): string {
    const data = item as any;
    return String(data.tipoNotificacion || data.tipo_notificacion || data.tipo || 'INFORMATIVA');
  }

  prioridad(item: Notificacion): string {
    const data = item as any;
    return String(data.prioridad || 'NORMAL');
  }

  modulo(item: Notificacion): string {
    const data = item as any;
    return String(
      data.modulo ||
        data.moduloRelacionado ||
        data.modulo_relacionado ||
        data.origen ||
        'Sistema',
    );
  }

  fechaCreacion(item: Notificacion): string {
    const data = item as any;
    return String(data.fechaCreacion || data.fecha_creacion || data.createdAt || data.created_at || '');
  }

  fechaLectura(item: Notificacion): string {
    const data = item as any;
    return String(data.fechaLectura || data.fecha_lectura || '');
  }

  estaLeida(item: Notificacion): boolean {
    const data = item as any;

    if (typeof data.leida === 'boolean') {
      return data.leida;
    }

    if (typeof data.visto === 'boolean') {
      return data.visto;
    }

    const estado = String(
      data.estado || data.estadoNotificacion || data.estado_notificacion || '',
    ).toUpperCase();

    return estado.includes('LEIDA') || estado.includes('LEÍDA') || estado.includes('VISTA');
  }

  usuarioDestino(item: Notificacion): string {
    const data = item as any;

    return String(
      data.usuario?.nombreCompleto ||
        data.usuario?.nombre_completo ||
        data.usuario?.nombreUsuario ||
        data.usuario?.nombre_usuario ||
        data.usuarioDestino ||
        data.usuario_destino ||
        'Usuario del sistema',
    );
  }

  fechaFormateada(fecha: string): string {
    return formatearFechaHoraBolivia(fecha);
  }

  claseTipo(item: Notificacion): string {
    const tipo = this.tipoNotificacion(item).toUpperCase();

    if (tipo.includes('ERROR') || tipo.includes('CRITICO') || tipo.includes('CRÍTICO')) {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    if (tipo.includes('ALERTA') || tipo.includes('STOCK') || tipo.includes('ADVERTENCIA')) {
      return 'bg-orange-100 text-orange-700 border-orange-200';
    }

    if (tipo.includes('EXITO') || tipo.includes('ÉXITO') || tipo.includes('APROBADO')) {
      return 'bg-green-100 text-green-700 border-green-200';
    }

    return 'bg-blue-100 text-blue-700 border-blue-200';
  }

  clasePrioridad(item: Notificacion): string {
    const prioridad = this.prioridad(item).toUpperCase();

    if (prioridad.includes('URGENTE') || prioridad.includes('ALTA')) {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    if (prioridad.includes('MEDIA')) {
      return 'bg-orange-100 text-orange-700 border-orange-200';
    }

    return 'bg-slate-100 text-slate-700 border-slate-200';
  }

  iconoTipo(item: Notificacion): string {
    const tipo = this.tipoNotificacion(item).toUpperCase();

    if (tipo.includes('STOCK')) return '📦';
    if (tipo.includes('PEDIDO')) return '📝';
    if (tipo.includes('COMPRA')) return '🧾';
    if (tipo.includes('APROB')) return '✅';
    if (tipo.includes('ERROR') || tipo.includes('CRIT')) return '🚨';
    if (tipo.includes('ALERTA')) return '⚠️';

    return '🔔';
  }
}
