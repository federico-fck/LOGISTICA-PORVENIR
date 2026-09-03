import { Injectable } from '@angular/core';
import { ApiService } from './api.service';
import {
  CatalogosInsumos,
  Insumo,
} from '../models/insumo.model';

@Injectable({
  providedIn: 'root',
})
export class InsumosService {
  constructor(private readonly apiService: ApiService) {}

  listar() {
    return this.apiService.get<Insumo[]>('insumos');
  }

  catalogos() {
    return this.apiService.get<CatalogosInsumos>('insumos/catalogos');
  }

  buscarPorId(idInsumo: number) {
    return this.apiService.get<Insumo>(`insumos/${idInsumo}`);
  }

  crear(data: unknown) {
    return this.apiService.post<Insumo>('insumos', data);
  }

  actualizar(idInsumo: number, data: unknown) {
    return this.apiService.patch<Insumo>(`insumos/${idInsumo}`, data);
  }

  activar(idInsumo: number) {
    return this.apiService.patch(`insumos/${idInsumo}/activar`, {});
  }

  desactivar(idInsumo: number) {
    return this.apiService.patch(`insumos/${idInsumo}/desactivar`, {});
  }

  eliminar(idInsumo: number) {
    return this.apiService.delete(`insumos/${idInsumo}`);
  }
}
