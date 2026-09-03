import { Injectable } from '@angular/core';
import { ApiService } from './api.service';
import { Proveedor } from '../models/proveedor.model';

@Injectable({
  providedIn: 'root',
})
export class ProveedoresService {
  constructor(private readonly apiService: ApiService) {}

  listar() {
    return this.apiService.get<Proveedor[]>('proveedores');
  }

  buscarPorId(idProveedor: number) {
    return this.apiService.get<Proveedor>(`proveedores/${idProveedor}`);
  }

  crear(data: unknown) {
    return this.apiService.post<Proveedor>('proveedores', data);
  }

  actualizar(idProveedor: number, data: unknown) {
    return this.apiService.patch<Proveedor>(`proveedores/${idProveedor}`, data);
  }

  activar(idProveedor: number) {
    return this.apiService.patch(`proveedores/${idProveedor}/activar`, {});
  }

  desactivar(idProveedor: number) {
    return this.apiService.patch(`proveedores/${idProveedor}/desactivar`, {});
  }

  eliminar(idProveedor: number) {
    return this.apiService.delete(`proveedores/${idProveedor}`);
  }
}
