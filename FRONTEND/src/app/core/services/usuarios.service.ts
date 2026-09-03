import { Injectable } from '@angular/core';
import { ApiService } from './api.service';
import { Area, Rol, Usuario } from '../models/usuario.model';

@Injectable({
  providedIn: 'root',
})
export class UsuariosService {
  constructor(private readonly apiService: ApiService) {}

  listar() {
    return this.apiService.get<Usuario[]>('usuarios');
  }

  listarRoles() {
    return this.apiService.get<Rol[]>('usuarios/roles');
  }

  listarAreas() {
    return this.apiService.get<Area[]>('usuarios/areas');
  }

  buscarPorId(idUsuario: number) {
    return this.apiService.get<Usuario>(`usuarios/${idUsuario}`);
  }

  crear(data: unknown) {
    return this.apiService.post<Usuario>('usuarios', data);
  }

  actualizar(idUsuario: number, data: unknown) {
    return this.apiService.patch<Usuario>(`usuarios/${idUsuario}`, data);
  }

  activar(idUsuario: number) {
    return this.apiService.patch(`usuarios/${idUsuario}/activar`, {});
  }

  desactivar(idUsuario: number) {
    return this.apiService.patch(`usuarios/${idUsuario}/desactivar`, {});
  }

  eliminar(idUsuario: number) {
    return this.apiService.delete(`usuarios/${idUsuario}`);
  }
}
