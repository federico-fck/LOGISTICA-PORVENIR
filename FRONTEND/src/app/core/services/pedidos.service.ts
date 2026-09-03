import { Injectable } from '@angular/core';
import { ApiService } from './api.service';
import {
  AprobarPedido,
  ActualizarPedido,
  CrearPedido,
  ObservarPedido,
  Pedido,
  RechazarPedido,
} from '../models/pedido.model';

@Injectable({
  providedIn: 'root',
})
export class PedidosService {
  constructor(private readonly apiService: ApiService) {}

  listar() {
    return this.apiService.get<Pedido[]>('pedidos');
  }

  estados() {
    return this.apiService.get<unknown>('pedidos/estados');
  }

  buscarPorId(idPedido: number) {
    return this.apiService.get<Pedido>(`pedidos/${idPedido}`);
  }

  crear(data: CrearPedido) {
    return this.apiService.post<Pedido>('pedidos', data);
  }

  actualizar(idPedido: number, data: ActualizarPedido) {
    return this.apiService.patch<Pedido>(`pedidos/${idPedido}`, data);
  }

  aprobar(idPedido: number, data: AprobarPedido) {
    return this.apiService.patch<Pedido>(`pedidos/${idPedido}/aprobar`, data);
  }

  rechazar(idPedido: number, data: RechazarPedido) {
    return this.apiService.patch<Pedido>(`pedidos/${idPedido}/rechazar`, data);
  }

  observar(idPedido: number, data: ObservarPedido) {
    return this.apiService.patch<Pedido>(`pedidos/${idPedido}/observar`, data);
  }

  enviarADespacho(idPedido: number) {
    return this.apiService.patch<Pedido>(
      `pedidos/${idPedido}/enviar-despacho`,
      {},
    );
  }

  cancelar(idPedido: number) {
    return this.apiService.patch<Pedido>(`pedidos/${idPedido}/cancelar`, {});
  }
}
