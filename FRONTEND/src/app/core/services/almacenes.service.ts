import { Injectable } from '@angular/core';
import { ApiService } from './api.service';
import { Almacen } from '../models/almacen.model';

@Injectable({
  providedIn: 'root',
})
export class AlmacenesService {
  constructor(private readonly apiService: ApiService) {}

  listar() {
    return this.apiService.get<Almacen[]>('almacenes');
  }

  tipos() {
    return this.apiService.get<unknown>('almacenes/tipos');
  }

  buscarPorId(idAlmacen: number) {
    return this.apiService.get<Almacen>(`almacenes/${idAlmacen}`);
  }

  crear(data: unknown) {
    return this.apiService.post<Almacen>('almacenes', data);
  }

  actualizar(idAlmacen: number, data: unknown) {
    return this.apiService.patch<Almacen>(`almacenes/${idAlmacen}`, data);
  }

  activar(idAlmacen: number) {
    return this.apiService.patch(`almacenes/${idAlmacen}/activar`, {});
  }

  desactivar(idAlmacen: number) {
    return this.apiService.patch(`almacenes/${idAlmacen}/desactivar`, {});
  }

  eliminar(idAlmacen: number) {
    return this.apiService.delete(`almacenes/${idAlmacen}`);
  }
}
