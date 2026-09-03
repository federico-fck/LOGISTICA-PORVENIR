import { Injectable } from '@angular/core';
import { ApiService } from './api.service';
import {
  Auditoria,
  AuditoriaFiltros,
  AuditoriaResumen,
} from '../models/auditoria.model';

@Injectable({
  providedIn: 'root',
})
export class AuditoriaService {
  constructor(private readonly apiService: ApiService) {}

  listar(filtros?: AuditoriaFiltros) {
    return this.apiService.get<Auditoria[]>(
      'auditoria',
      filtros as Record<string, unknown>,
    );
  }

  tipos() {
    return this.apiService.get<{
      tiposAccion: string[];
      modulos: string[];
    }>('auditoria/tipos');
  }

  resumen() {
    return this.apiService.get<AuditoriaResumen>('auditoria/resumen');
  }

  buscarPorId(idAuditoria: number) {
    return this.apiService.get<Auditoria>(`auditoria/${idAuditoria}`);
  }
}
