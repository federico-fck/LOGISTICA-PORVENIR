import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';
import { ApiService } from './api.service';
import { Notificacion } from '../models/notificacion.model';

@Injectable({
  providedIn: 'root',
})
export class NotificacionesService {
  private readonly cambiosSubject = new Subject<void>();
  readonly cambios$ = this.cambiosSubject.asObservable();

  constructor(private readonly apiService: ApiService) {}

  notificarCambio() {
    this.cambiosSubject.next();
  }

  listar(params?: { idUsuario?: number; estado?: string; tipo?: string; modulo?: string }) {
    return this.apiService.get<Notificacion[]>('notificaciones', params);
  }

  buscarPorId(idNotificacion: number) {
    return this.apiService.get<Notificacion>(`notificaciones/${idNotificacion}`);
  }

  marcarComoLeida(idNotificacion: number) {
    return this.apiService.patch<Notificacion>(
      `notificaciones/${idNotificacion}/marcar-leida`,
      {},
    );
  }

  marcarTodasComoLeidas(idUsuario?: number) {
    const query = idUsuario ? `?idUsuario=${idUsuario}` : '';
    return this.apiService.patch<unknown>(`notificaciones/marcar-todas-leidas${query}`, {});
  }

  contarNoLeidas(idUsuario: number) {
    return this.apiService.get<{ totalNoLeidas: number }>(
      `notificaciones/usuario/${idUsuario}/contador-no-leidas`,
    );
  }

  eliminar(idNotificacion: number) {
    return this.apiService.delete(`notificaciones/${idNotificacion}`);
  }
}
