import { Component, inject, signal } from '@angular/core';
import { forkJoin } from 'rxjs';
import {
  DashboardService,
  DashboardTarjetas,
  PedidoReciente,
  StockCritico,
} from '../../core/services/dashboard.service';
import { formatearFechaHoraBolivia } from '../../core/utils/fecha.util';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.css',
})
export class Dashboard {
  private readonly dashboardService = inject(DashboardService);

  cargando = signal(false);
  error = signal('');

  tarjetas = signal<DashboardTarjetas | null>(null);
  pedidosRecientes = signal<PedidoReciente[]>([]);
  stockCritico = signal<StockCritico[]>([]);

  ngOnInit() {
    this.cargarDashboard();
  }

  cargarDashboard() {
    this.cargando.set(true);
    this.error.set('');

    forkJoin({
      tarjetas: this.dashboardService.tarjetas(),
      pedidos: this.dashboardService.ultimosPedidos(),
      stock: this.dashboardService.stockBajo(),
    }).subscribe({
      next: (data) => {
        this.tarjetas.set(data.tarjetas);
        this.pedidosRecientes.set(data.pedidos);
        this.stockCritico.set(data.stock);
        this.cargando.set(false);
      },
      error: () => {
        this.error.set('No se pudo cargar la información del dashboard.');
        this.cargando.set(false);
      },
    });
  }

  valor(campo: keyof DashboardTarjetas) {
    const data = this.tarjetas();

    if (!data) {
      return 0;
    }

    return data[campo] || 0;
  }

  valorMoneda(campo: keyof DashboardTarjetas): string {
    const numero = Number(this.valor(campo));

    return new Intl.NumberFormat('es-BO', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(Number.isFinite(numero) ? numero : 0);
  }

  fechaFormateada(fecha: string): string {
    return formatearFechaHoraBolivia(fecha);
  }
}
