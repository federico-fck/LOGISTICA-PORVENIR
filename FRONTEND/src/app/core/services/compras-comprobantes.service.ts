import { Injectable } from '@angular/core';
import { ApiService } from './api.service';
import {
  ComprobanteCompra,
  OrdenCompra,
  RecepcionCompra,
} from '../models/compras-comprobantes.model';

@Injectable({
  providedIn: 'root',
})
export class ComprasComprobantesService {
  constructor(private readonly apiService: ApiService) {}

  estados() {
    return this.apiService.get<unknown>('compras-comprobantes/estados');
  }

  ordenesCompra() {
    return this.apiService.get<OrdenCompra[]>('compras-comprobantes/ordenes-compra');
  }

  buscarOrdenCompraPorId(idOrdenCompra: number) {
    return this.apiService.get<OrdenCompra>(
      `compras-comprobantes/ordenes-compra/${idOrdenCompra}`,
    );
  }

  crearOrdenCompra(data: unknown) {
    return this.apiService.post<OrdenCompra>('compras-comprobantes/ordenes-compra', data);
  }

  actualizarOrdenCompra(idOrdenCompra: number, data: unknown) {
    return this.apiService.patch<OrdenCompra>(
      `compras-comprobantes/ordenes-compra/${idOrdenCompra}`,
      data,
    );
  }

  eliminarOrdenCompra(idOrdenCompra: number) {
    return this.apiService.delete(`compras-comprobantes/ordenes-compra/${idOrdenCompra}`);
  }

  recepciones() {
    return this.apiService.get<RecepcionCompra[]>('compras-comprobantes/recepciones');
  }

  buscarRecepcionPorId(idRecepcionCompra: number) {
    return this.apiService.get<RecepcionCompra>(
      `compras-comprobantes/recepciones/${idRecepcionCompra}`,
    );
  }

  crearRecepcion(data: unknown) {
    return this.apiService.post<RecepcionCompra>('compras-comprobantes/recepciones', data);
  }

  comprobantes() {
    return this.apiService.get<ComprobanteCompra[]>('compras-comprobantes/comprobantes');
  }

  buscarComprobantePorId(idComprobanteCompra: number) {
    return this.apiService.get<ComprobanteCompra>(
      `compras-comprobantes/comprobantes/${idComprobanteCompra}`,
    );
  }

  crearComprobante(data: unknown) {
    return this.apiService.post<ComprobanteCompra>('compras-comprobantes/comprobantes', data);
  }

  eliminarComprobante(idComprobanteCompra: number) {
    return this.apiService.delete(`compras-comprobantes/comprobantes/${idComprobanteCompra}`);
  }
}
