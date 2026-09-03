import { Injectable } from '@angular/core';
import { ApiService } from './api.service';

export interface DashboardTarjetas {
  total_insumos_activos: string | number;
  total_almacenes_activos: string | number;
  total_proveedores_activos: string | number;
  total_usuarios_activos: string | number;
  pedidos_pendientes: string | number;
  pedidos_aprobados: string | number;
  pedidos_rechazados: string | number;
  compras_en_proceso: string | number;
  compras_recibidas_completas: string | number;
  despachos_entregados: string | number;
  stock_total_fisico: string | number;
  stock_total_disponible: string | number;
  valor_total_inventario: string | number;
}

export interface PedidoReciente {
  id_pedido: number;
  numero_pedido: string;
  fecha_pedido: string;
  fecha_requerida?: string;
  tipo_pedido: string;
  prioridad: string;
  estado_pedido: string;
  estado_aprobacion: string;
  estado_atencion: string;
  usuario_solicitante: string;
  area_solicitante: string;
}

export interface StockCritico {
  id_inventario: number;
  codigo_interno: string;
  nombre_insumo: string;
  nombre_almacen: string;
  tipo_almacen: string;
  stock_fisico: string | number;
  stock_reservado: string | number;
  stock_disponible: string | number;
  estado_stock: string;
}

@Injectable({
  providedIn: 'root',
})
export class DashboardService {
  constructor(private readonly apiService: ApiService) {}

  tarjetas() {
    return this.apiService.get<DashboardTarjetas>('dashboard/tarjetas');
  }

  ultimosPedidos() {
    return this.apiService.get<PedidoReciente[]>('dashboard/ultimos-pedidos');
  }

  stockBajo() {
    return this.apiService.get<StockCritico[]>('dashboard/stock-bajo');
  }

  resumen() {
    return this.apiService.get('dashboard/resumen');
  }

  alertas() {
    return this.apiService.get('dashboard/alertas');
  }
}
