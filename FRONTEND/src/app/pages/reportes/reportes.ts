import { Component, computed, inject, signal } from '@angular/core';
import { catchError, forkJoin, of } from 'rxjs';

import { ApiService } from '../../core/services/api.service';
import { ConfirmacionAccionService } from '../../core/feedback/confirmacion-accion.service';
import { PermissionService } from '../../core/services/permission.service';
import { AuthState } from '../../core/state/auth.state';
import {
  convertirFechaBackendADatetimeLocal,
  formatearFechaHoraBolivia,
} from '../../core/utils/fecha.util';

type TabReporte =
  | 'inventario'
  | 'pedidos'
  | 'compras'
  | 'comprobantes'
  | 'movimientos';

type FechaRapida = 'todos' | 'hoy' | 'semana' | 'mes' | 'anio';

interface ColumnaReporte {
  key: string;
  label: string;
}

@Component({
  selector: 'app-reportes',
  standalone: true,
  imports: [],
  templateUrl: './reportes.html',
  styleUrl: './reportes.css',
})
export class Reportes {
  private readonly apiService = inject(ApiService);
  private readonly confirmacionAccionService = inject(ConfirmacionAccionService);
  private readonly permissionService = inject(PermissionService);
  private readonly authState = inject(AuthState);

  cargando = signal(false);
  error = signal('');
  mensaje = signal('');
  busqueda = signal('');
  tabActual = signal<TabReporte>('inventario');
  fechaActualizacion = signal(new Date());
  fechaRapida = signal<FechaRapida>('todos');
  fechaDesde = signal('');
  fechaHasta = signal('');
  estadoFiltro = signal('');
  tipoFiltro = signal('');
  proveedorFiltro = signal('');
  almacenFiltro = signal('');

  readonly tabsReporte: Array<{
    valor: TabReporte;
    etiqueta: string;
    permiso: string;
    claseActiva: string;
  }> = [
    {
      valor: 'inventario',
      etiqueta: 'Inventario',
      permiso: 'inventario.ver',
      claseActiva: 'bg-blue-600 text-white',
    },
    {
      valor: 'pedidos',
      etiqueta: 'Pedidos',
      permiso: 'pedidos.ver',
      claseActiva: 'bg-green-600 text-white',
    },
    {
      valor: 'compras',
      etiqueta: 'Compras',
      permiso: 'compras.ver',
      claseActiva: 'bg-orange-600 text-white',
    },
    {
      valor: 'comprobantes',
      etiqueta: 'Comprobantes',
      permiso: 'comprobantes.ver',
      claseActiva: 'bg-violet-600 text-white',
    },
    {
      valor: 'movimientos',
      etiqueta: 'Movimientos',
      permiso: 'inventario.ver_movimientos',
      claseActiva: 'bg-slate-950 text-white',
    },
  ];

  readonly opcionesFechaRapida: Array<{ valor: FechaRapida; etiqueta: string }> = [
    { valor: 'todos', etiqueta: 'Todos' },
    { valor: 'hoy', etiqueta: 'Hoy' },
    { valor: 'semana', etiqueta: 'Esta semana' },
    { valor: 'mes', etiqueta: 'Este mes' },
    { valor: 'anio', etiqueta: 'Este año' },
  ];

  insumos = signal<any[]>([]);
  almacenes = signal<any[]>([]);
  proveedores = signal<any[]>([]);
  usuarios = signal<any[]>([]);
  pedidos = signal<any[]>([]);
  inventario = signal<any[]>([]);
  stockBajo = signal<any[]>([]);
  movimientos = signal<any[]>([]);
  despachos = signal<any[]>([]);
  ordenesCompra = signal<any[]>([]);
  recepciones = signal<any[]>([]);
  comprobantes = signal<any[]>([]);
  aprobaciones = signal<any[]>([]);

  totalInsumos = computed(() => this.insumos().length);
  totalAlmacenes = computed(() => this.almacenes().length);
  totalProveedores = computed(() => this.proveedores().length);
  totalUsuarios = computed(() => this.usuarios().length);
  totalPedidos = computed(() => this.pedidos().length);
  totalInventario = computed(() => this.inventario().length);
  totalMovimientos = computed(() => this.movimientos().length);
  totalDespachos = computed(() => this.despachos().length);
  totalOrdenes = computed(() => this.ordenesCompra().length);
  totalRecepciones = computed(() => this.recepciones().length);
  totalComprobantes = computed(() => this.comprobantes().length);
  totalAprobaciones = computed(() => this.aprobaciones().length);

  totalStockBajo = computed(() => {
    if (this.stockBajo().length > 0) {
      return this.stockBajo().length;
    }

    return this.inventario().filter((item) => {
      const estado = String(this.valorInventario(item, 'estado')).toUpperCase();
      const disponible = Number(this.valorInventario(item, 'stockDisponible') || 0);

      return estado.includes('BAJO') || estado.includes('CRITICO') || disponible <= 0;
    }).length;
  });

  valorTotalInventario = computed(() => {
    return this.inventario().reduce((total, item) => {
      const data = item as any;
      const valor = Number(
        data.valorInventario ??
          data.valor_inventario ??
          data.valorTotal ??
          data.valor_total ??
          0,
      );

      return total + valor;
    }, 0);
  });

  montoTotalComprobantes = computed(() => {
    return this.comprobantes().reduce((total, item) => {
      return total + Number(this.valorComprobante(item, 'monto') || 0);
    }, 0);
  });

  montoTotalOrdenes = computed(() => {
    return this.ordenesCompra().reduce((total, item) => {
      return total + Number(this.valorOrden(item, 'total') || 0);
    }, 0);
  });

  datosTabla = computed(() => {
    if (this.tabActual() === 'inventario') return this.inventario();
    if (this.tabActual() === 'pedidos') return this.pedidos();
    if (this.tabActual() === 'compras') return this.ordenesCompra();
    if (this.tabActual() === 'comprobantes') return this.comprobantes();
    return this.movimientos();
  });

  datosFiltrados = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();

    return this.datosTabla().filter((item) => {
      return (
        (!texto || JSON.stringify(item).toLowerCase().includes(texto)) &&
        this.coincideFecha(item) &&
        this.coincideFiltroTexto(this.valorEstadoFiltro(item), this.estadoFiltro()) &&
        this.coincideFiltroTexto(this.valorTipoFiltro(item), this.tipoFiltro()) &&
        this.coincideFiltroTexto(this.valorProveedorFiltro(item), this.proveedorFiltro()) &&
        this.coincideFiltroTexto(this.valorAlmacenFiltro(item), this.almacenFiltro())
      );
    });
  });

  opcionesEstadoActual = computed(() =>
    this.opcionesUnicas(this.datosTabla().map((item) => this.valorEstadoFiltro(item))),
  );

  opcionesTipoActual = computed(() =>
    this.opcionesUnicas(this.datosTabla().map((item) => this.valorTipoFiltro(item))),
  );

  opcionesProveedorActual = computed(() =>
    this.opcionesUnicas(this.datosTabla().map((item) => this.valorProveedorFiltro(item))),
  );

  opcionesAlmacenActual = computed(() =>
    this.opcionesUnicas(this.datosTabla().map((item) => this.valorAlmacenFiltro(item))),
  );

  columnasActuales = computed<ColumnaReporte[]>(() => {
    if (this.tabActual() === 'inventario') {
      return [
        { key: 'codigo', label: 'Código' },
        { key: 'insumo', label: 'Insumo' },
        { key: 'almacen', label: 'Almacén' },
        { key: 'stockFisico', label: 'Stock físico' },
        { key: 'stockReservado', label: 'Reservado' },
        { key: 'stockDisponible', label: 'Disponible' },
        { key: 'estado', label: 'Estado' },
      ];
    }

    if (this.tabActual() === 'pedidos') {
      return [
        { key: 'numero', label: 'Numero' },
        { key: 'fecha', label: 'Fecha' },
        { key: 'solicitante', label: 'Solicitante' },
        { key: 'tipo', label: 'Tipo' },
        { key: 'area', label: 'Área' },
        { key: 'prioridad', label: 'Prioridad' },
        { key: 'estado', label: 'Estado' },
        { key: 'aprobacion', label: 'Aprobación' },
      ];
    }

    if (this.tabActual() === 'compras') {
      return [
        { key: 'numero', label: 'Orden' },
        { key: 'proveedor', label: 'Proveedor' },
        { key: 'fecha', label: 'Fecha' },
        { key: 'subtotal', label: 'Subtotal' },
        { key: 'descuento', label: 'Descuento' },
        { key: 'total', label: 'Total Bs' },
        { key: 'estado', label: 'Estado' },
      ];
    }

    if (this.tabActual() === 'comprobantes') {
      return [
        { key: 'numero', label: 'Comprobante' },
        { key: 'tipo', label: 'Tipo' },
        { key: 'proveedor', label: 'Proveedor' },
        { key: 'fecha', label: 'Fecha' },
        { key: 'orden', label: 'Orden' },
        { key: 'subtotal', label: 'Subtotal' },
        { key: 'descuento', label: 'Descuento' },
        { key: 'monto', label: 'Total Bs' },
        { key: 'estado', label: 'Estado' },
      ];
    }

    return [
      { key: 'fecha', label: 'Fecha' },
      { key: 'tipo', label: 'Tipo movimiento' },
      { key: 'insumo', label: 'Insumo' },
      { key: 'almacen', label: 'Almacén' },
      { key: 'cantidad', label: 'Cantidad' },
      { key: 'motivo', label: 'Motivo' },
    ];
  });

  ngOnInit() {
    this.asegurarTabPermitido();
    this.cargarReportes();
  }

  cargarReportes() {
    this.cargando.set(true);
    this.error.set('');
    this.mensaje.set('');

    forkJoin({
      insumos: this.getSiTienePermiso('catalogos.ver', 'insumos'),
      almacenes: this.getSiTienePermiso('catalogos.ver', 'almacenes'),
      proveedores: this.getSiTienePermiso('proveedores.ver', 'proveedores'),
      usuarios: this.getSiTienePermiso('usuarios.ver', 'usuarios'),
      pedidos: this.getSiTienePermiso('pedidos.ver', 'pedidos'),
      inventario: this.getSiTienePermiso('inventario.ver', 'inventario-despachos/inventario'),
      stockBajo: this.getSiTienePermiso(
        'inventario.ver_stock_critico',
        'inventario-despachos/stock-bajo',
      ),
      movimientos: this.getSiTienePermiso(
        'inventario.ver_movimientos',
        'inventario-despachos/movimientos',
      ),
      despachos: this.getSiTienePermiso('despachos.ver', 'inventario-despachos/despachos'),
      ordenesCompra: this.getSiTienePermiso('compras.ver', 'compras-comprobantes/ordenes-compra'),
      recepciones: this.getSiTienePermiso('recepciones.ver', 'compras-comprobantes/recepciones'),
      comprobantes: this.getSiTienePermiso(
        'comprobantes.ver',
        'compras-comprobantes/comprobantes',
      ),
      aprobaciones: this.getSiTienePermiso('compras.ver', 'compras-comprobantes/aprobaciones'),
    }).subscribe({
      next: (data) => {
        this.insumos.set(this.normalizarArray(data.insumos));
        this.almacenes.set(this.normalizarArray(data.almacenes));
        this.proveedores.set(this.normalizarArray(data.proveedores));
        this.usuarios.set(this.normalizarArray(data.usuarios));
        this.pedidos.set(this.normalizarArray(data.pedidos));
        this.inventario.set(this.normalizarArray(data.inventario));
        this.stockBajo.set(this.normalizarArray(data.stockBajo));
        this.movimientos.set(this.normalizarArray(data.movimientos));
        this.despachos.set(this.normalizarArray(data.despachos));
        this.ordenesCompra.set(this.normalizarArray(data.ordenesCompra));
        this.recepciones.set(this.normalizarArray(data.recepciones));
        this.comprobantes.set(this.normalizarArray(data.comprobantes));
        this.aprobaciones.set(this.normalizarArray(data.aprobaciones));

        this.fechaActualizacion.set(new Date());
        this.cargando.set(false);
      },
      error: () => {
        this.error.set('No se pudieron cargar los reportes.');
        this.cargando.set(false);
      },
    });
  }

  normalizarArray(data: any): any[] {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data?.data)) return data.data;
    if (Array.isArray(data?.items)) return data.items;
    if (Array.isArray(data?.resultados)) return data.resultados;
    if (Array.isArray(data?.registros)) return data.registros;
    return [];
  }

  private getSiTienePermiso(permiso: string, endpoint: string) {
    return this.tienePermiso(permiso)
      ? this.apiService.get<any>(endpoint).pipe(catchError(() => of([])))
      : of([]);
  }

  cambiarTab(tab: TabReporte) {
    if (!this.puedeVerTab(tab)) {
      return;
    }

    this.tabActual.set(tab);
    this.busqueda.set('');
    this.limpiarFiltrosReportes(false);
    this.mensaje.set('');
    this.error.set('');
  }

  tabsReporteDisponibles() {
    return this.tabsReporte.filter((tab) => this.puedeVerTab(tab.valor));
  }

  puedeVerTab(tab: TabReporte): boolean {
    const permiso = this.permisoTab(tab);
    return !permiso || this.tienePermiso(permiso);
  }

  permisoTab(tab: TabReporte): string {
    return this.tabsReporte.find((item) => item.valor === tab)?.permiso || '';
  }

  private asegurarTabPermitido() {
    if (this.puedeVerTab(this.tabActual())) {
      return;
    }

    const primera = this.tabsReporteDisponibles()[0]?.valor;

    if (primera) {
      this.tabActual.set(primera);
    }
  }

  cambiarBusqueda(event: Event) {
    const input = event.target as HTMLInputElement;
    this.busqueda.set(input.value);
  }

  cambiarFechaRapida(event: Event) {
    const select = event.target as HTMLSelectElement;
    this.fechaRapida.set((select.value || 'todos') as FechaRapida);
  }

  cambiarFechaDesde(event: Event) {
    const input = event.target as HTMLInputElement;
    this.fechaDesde.set(input.value);
  }

  cambiarFechaHasta(event: Event) {
    const input = event.target as HTMLInputElement;
    this.fechaHasta.set(input.value);
  }

  cambiarEstadoFiltro(event: Event) {
    const select = event.target as HTMLSelectElement;
    this.estadoFiltro.set(select.value);
  }

  cambiarTipoFiltro(event: Event) {
    const select = event.target as HTMLSelectElement;
    this.tipoFiltro.set(select.value);
  }

  cambiarProveedorFiltro(event: Event) {
    const select = event.target as HTMLSelectElement;
    this.proveedorFiltro.set(select.value);
  }

  cambiarAlmacenFiltro(event: Event) {
    const select = event.target as HTMLSelectElement;
    this.almacenFiltro.set(select.value);
  }

  limpiarFiltrosReportes(limpiarBusqueda = true) {
    this.fechaRapida.set('todos');
    this.fechaDesde.set('');
    this.fechaHasta.set('');
    this.estadoFiltro.set('');
    this.tipoFiltro.set('');
    this.proveedorFiltro.set('');
    this.almacenFiltro.set('');

    if (limpiarBusqueda) {
      this.busqueda.set('');
    }
  }

  muestraFiltroFechas(): boolean {
    return this.tabActual() !== 'inventario';
  }

  muestraFiltroTipo(): boolean {
    return ['pedidos', 'comprobantes', 'movimientos'].includes(this.tabActual());
  }

  muestraFiltroProveedor(): boolean {
    return ['compras', 'comprobantes'].includes(this.tabActual());
  }

  muestraFiltroAlmacen(): boolean {
    return ['inventario', 'movimientos'].includes(this.tabActual());
  }

  etiquetaTipoFiltro(): string {
    if (this.tabActual() === 'pedidos') return 'Tipo de pedido';
    if (this.tabActual() === 'comprobantes') return 'Tipo comprobante';
    if (this.tabActual() === 'movimientos') return 'Tipo movimiento';
    return 'Tipo';
  }

  tituloReporte(): string {
    if (this.tabActual() === 'inventario') return 'Reporte de inventario';
    if (this.tabActual() === 'pedidos') return 'Reporte de pedidos';
    if (this.tabActual() === 'compras') return 'Reporte de órdenes de compra';
    if (this.tabActual() === 'comprobantes') return 'Reporte de comprobantes';
    return 'Reporte de movimientos de inventario';
  }

  descripcionReporte(): string {
    if (this.tabActual() === 'inventario') {
      return 'Stock físico, reservado, disponible y estado de los insumos por almacén.';
    }

    if (this.tabActual() === 'pedidos') {
      return 'Solicitudes de insumos registradas por las áreas de operación minera.';
    }

    if (this.tabActual() === 'compras') {
      return 'Órdenes de compra generadas para proveedores.';
    }

    if (this.tabActual() === 'comprobantes') {
      return 'Facturas, recibos y comprobantes registrados en compras.';
    }

    return 'Entradas, salidas, ajustes y movimientos de inventario.';
  }

  valorCelda(item: any, key: string): string | number {
    if (this.tabActual() === 'inventario') return this.valorInventario(item, key);
    if (this.tabActual() === 'pedidos') return this.valorPedido(item, key);
    if (this.tabActual() === 'compras') return this.valorOrden(item, key);
    if (this.tabActual() === 'comprobantes') return this.valorComprobante(item, key);
    return this.valorMovimiento(item, key);
  }

  valorInventario(item: any, key: string): string | number {
    const data = item as any;

    if (key === 'codigo') {
      return (
        data.codigoInterno ||
        data.codigo_interno ||
        data.insumo?.codigoInterno ||
        data.insumo?.codigo_interno ||
        'Sin código'
      );
    }

    if (key === 'insumo') {
      return (
        data.nombreInsumo ||
        data.nombre_insumo ||
        data.insumo?.nombreInsumo ||
        data.insumo?.nombre_insumo ||
        'Sin insumo'
      );
    }

    if (key === 'almacen') {
      const almacen =
        data.almacen ||
        data.almacenDestino ||
        data.almacen_destino ||
        data.almacenOrigen ||
        data.almacen_origen;

      return this.primerTexto(
        data.nombreAlmacen ||
        data.nombre_almacen ||
        almacen?.nombreAlmacen ||
        almacen?.nombre_almacen ||
        almacen?.codigoAlmacen ||
        almacen?.codigo_almacen ||
        'Sin almacén',
      );
    }

    if (key === 'stockFisico') {
      return data.stockFisico ?? data.stock_fisico ?? data.stockActual ?? data.stock_actual ?? 0;
    }

    if (key === 'stockReservado') {
      return data.stockReservado ?? data.stock_reservado ?? data.reservado ?? 0;
    }

    if (key === 'stockDisponible') {
      return data.stockDisponible ?? data.stock_disponible ?? data.disponible ?? 0;
    }

    if (key === 'estado') {
      return this.etiquetaOperativa(data.estadoStock || data.estado_stock || data.estado || 'DISPONIBLE');
    }

    return '';
  }

  valorPedido(item: any, key: string): string | number {
    const data = item as any;

    if (key === 'numero') return data.numeroPedido || data.numero_pedido || `PED-${data.idPedido || data.id_pedido || ''}`;
    if (key === 'fecha') return this.fechaFormateada(data.fechaPedido || data.fecha_pedido || '');
    if (key === 'tipo') return data.tipoPedido || data.tipo_pedido || 'NORMAL';
    if (key === 'solicitante') {
      return this.primerTexto(
        data.usuarioSolicitante ||
        data.usuario_solicitante ||
        data.usuario?.nombreCompleto ||
        data.usuario?.nombre_completo ||
        data.usuario?.nombreUsuario ||
        'Sin solicitante',
      );
    }
    if (key === 'area') {
      return this.primerTexto(
        data.nombreAreaSolicitante,
        data.nombre_area_solicitante,
        data.areaSolicitanteNombre,
        data.area_solicitante_nombre,
        data.areaNombre,
        data.area_nombre,
        data.nombreArea,
        data.nombre_area,
        data.areaSolicitante,
        data.area_solicitante,
        data.area,
        data.usuarioSolicitante?.area,
        data.usuario_solicitante?.area,
        data.idAreaSolicitante || data.id_area_solicitante
          ? `Area ${data.idAreaSolicitante || data.id_area_solicitante}`
          : '',
        'Sin area',
      );
    }
    if (key === 'prioridad') return data.prioridad || 'MEDIA';
    if (key === 'estado') return this.etiquetaOperativa(data.estadoPedido || data.estado_pedido || 'PENDIENTE');
    if (key === 'aprobacion') return this.etiquetaOperativa(data.estadoAprobacion || data.estado_aprobacion || 'PENDIENTE');

    return '';
  }

  valorOrden(item: any, key: string): string | number {
    const data = item as any;

    if (key === 'numero') return data.numeroOrden || data.numero_orden || `OC-${data.idOrdenCompra || data.id_orden_compra || ''}`;
    if (key === 'fecha') return this.fechaFormateada(data.fechaEmision || data.fecha_emision || data.fechaOrden || data.fecha_orden || '');
    if (key === 'proveedor') {
      return this.primerTexto(
        data.proveedor?.razonSocial ||
        data.proveedor?.razon_social ||
        data.proveedor?.nombreComercial ||
        data.proveedor?.nombre_comercial ||
        data.razonSocialProveedor ||
        data.razon_social_proveedor ||
        data.proveedor ||
        'Sin proveedor',
      );
    }
    if (key === 'estado') return this.etiquetaOperativa(data.estadoCompra || data.estado_compra || data.estadoOrden || data.estado_orden || data.estado || 'PENDIENTE');
    if (key === 'subtotal') return Number(data.subtotal ?? data.montoSubtotal ?? data.monto_subtotal ?? 0);
    if (key === 'descuento') return Number(data.descuento ?? data.montoDescuento ?? data.monto_descuento ?? 0);
    if (key === 'total') return this.totalSimple(this.valorOrden(item, 'subtotal'), this.valorOrden(item, 'descuento'));

    return '';
  }

  valorComprobante(item: any, key: string): string | number {
    const data = item as any;

    if (key === 'numero') {
      return (
        data.numeroComprobante ||
        data.numero_comprobante ||
        data.nroComprobante ||
        data.nro_comprobante ||
        `COMP-${data.idComprobanteCompra || data.id_comprobante_compra || ''}`
      );
    }

    if (key === 'tipo') return data.tipoComprobante || data.tipo_comprobante || 'SIN_TIPO';
    if (key === 'fecha') return this.fechaFormateada(data.fechaComprobante || data.fecha_comprobante || data.fechaEmision || data.fecha_emision || data.fecha || '');
    if (key === 'proveedor') {
      return this.primerTexto(
        data.proveedor?.razonSocial ||
        data.proveedor?.razon_social ||
        data.proveedor?.nombreComercial ||
        data.proveedor?.nombre_comercial ||
        data.razonSocialProveedor ||
        data.razon_social_proveedor ||
        data.proveedor ||
        'Sin proveedor',
      );
    }
    if (key === 'orden') {
      return (
        data.ordenCompra?.numeroOrden ||
        data.ordenCompra?.numero_orden ||
        data.orden_compra?.numeroOrden ||
        data.orden_compra?.numero_orden ||
        data.numeroOrden ||
        data.numero_orden ||
        `OC-${data.idOrdenCompra || data.id_orden_compra || ''}`
      );
    }
    if (key === 'estado') return this.etiquetaOperativa(data.estadoComprobante || data.estado_comprobante || data.estado || 'REGISTRADO');
    if (key === 'subtotal') return Number(data.montoSubtotal ?? data.monto_subtotal ?? data.subtotal ?? 0);
    if (key === 'descuento') return Number(data.montoDescuento ?? data.monto_descuento ?? data.descuento ?? 0);
    if (key === 'monto') return this.totalSimple(this.valorComprobante(item, 'subtotal'), this.valorComprobante(item, 'descuento'));

    return '';
  }

  valorMovimiento(item: any, key: string): string | number {
    const data = item as any;

    if (key === 'fecha') {
      return this.fechaFormateada(
        data.fechaMovimiento ||
          data.fecha_movimiento ||
          data.fechaRegistro ||
          data.fecha_registro ||
          data.fecha ||
          '',
      );
    }

    if (key === 'tipo') return this.etiquetaOperativa(data.tipoMovimiento || data.tipo_movimiento || data.tipo || 'Sin tipo');

    if (key === 'insumo') {
      return (
        data.nombreInsumo ||
        data.nombre_insumo ||
        data.insumo?.nombreInsumo ||
        data.insumo?.nombre_insumo ||
        'Sin insumo'
      );
    }

    if (key === 'almacen') {
      const almacen =
        data.almacen ||
        data.almacenDestino ||
        data.almacen_destino ||
        data.almacenOrigen ||
        data.almacen_origen ||
        this.almacenPorId(
          data.idAlmacen ||
            data.id_almacen ||
            data.idAlmacenDestino ||
            data.id_almacen_destino ||
            data.idAlmacenOrigen ||
            data.id_almacen_origen,
        );

      return this.primerTexto(
        data.almacenNombre,
        data.almacen_nombre,
        data.nombreAlmacen,
        data.nombre_almacen,
        data.almacen_destino,
        data.almacen_origen,
        almacen,
        'Dato incompleto',
      );
    }

    if (key === 'cantidad') return data.cantidad || data.cantidad_movimiento || 0;

    if (key === 'motivo') {
      return (
        data.motivoMovimiento ||
        data.motivo_movimiento ||
        data.motivo ||
        data.observaciones ||
        'Sin motivo'
      );
    }

    return '';
  }

  fechaFormateada(fecha: string): string {
    return formatearFechaHoraBolivia(fecha);
  }

  fechaHoraFormateada(fecha: Date): string {
    return formatearFechaHoraBolivia(fecha);
  }

  private valorFechaFiltro(item: any): string {
    const data = item as any;

    if (this.tabActual() === 'pedidos') {
      return String(
        data.fechaPedido ||
          data.fecha_pedido ||
          data.fechaCreacion ||
          data.fecha_creacion ||
          '',
      );
    }

    if (this.tabActual() === 'compras') {
      return String(
        data.fechaEmision ||
          data.fecha_emision ||
          data.fechaOrden ||
          data.fecha_orden ||
          data.fechaCreacion ||
          data.fecha_creacion ||
          '',
      );
    }

    if (this.tabActual() === 'comprobantes') {
      return String(
        data.fechaComprobante ||
          data.fecha_comprobante ||
          data.fechaEmision ||
          data.fecha_emision ||
          data.fecha ||
          data.fechaCreacion ||
          data.fecha_creacion ||
          '',
      );
    }

    if (this.tabActual() === 'movimientos') {
      return String(
        data.fechaMovimiento ||
          data.fecha_movimiento ||
          data.fechaRegistro ||
          data.fecha_registro ||
          data.fecha ||
          '',
      );
    }

    return '';
  }

  private valorEstadoFiltro(item: any): string {
    if (this.tabActual() === 'inventario') return String(this.valorInventario(item, 'estado'));
    if (this.tabActual() === 'pedidos') return String(this.valorPedido(item, 'estado'));
    if (this.tabActual() === 'compras') return String(this.valorOrden(item, 'estado'));
    if (this.tabActual() === 'comprobantes') return String(this.valorComprobante(item, 'estado'));
    return String(this.valorMovimiento(item, 'tipo'));
  }

  private valorTipoFiltro(item: any): string {
    if (this.tabActual() === 'pedidos') return String(this.valorPedido(item, 'tipo'));
    if (this.tabActual() === 'comprobantes') return String(this.valorComprobante(item, 'tipo'));
    if (this.tabActual() === 'movimientos') return String(this.valorMovimiento(item, 'tipo'));
    return '';
  }

  private valorProveedorFiltro(item: any): string {
    if (this.tabActual() === 'compras') return String(this.valorOrden(item, 'proveedor'));
    if (this.tabActual() === 'comprobantes') return String(this.valorComprobante(item, 'proveedor'));
    return '';
  }

  private valorAlmacenFiltro(item: any): string {
    if (this.tabActual() === 'inventario') return String(this.valorInventario(item, 'almacen'));
    if (this.tabActual() === 'movimientos') return String(this.valorMovimiento(item, 'almacen'));
    return '';
  }

  private coincideFiltroTexto(valor: string, filtro: string): boolean {
    if (!filtro) {
      return true;
    }

    return this.normalizarFiltro(valor) === this.normalizarFiltro(filtro);
  }

  private coincideFecha(item: any): boolean {
    if (!this.muestraFiltroFechas()) {
      return true;
    }

    const fechaItem = this.fechaClaveBolivia(this.valorFechaFiltro(item));
    const tieneFiltro =
      this.fechaRapida() !== 'todos' || this.fechaDesde() || this.fechaHasta();

    if (!tieneFiltro) {
      return true;
    }

    if (!fechaItem) {
      return false;
    }

    const desde = this.fechaDesde();
    const hasta = this.fechaHasta();

    if (desde && fechaItem < desde) {
      return false;
    }

    if (hasta && fechaItem > hasta) {
      return false;
    }

    return this.coincideFechaRapida(fechaItem);
  }

  private coincideFechaRapida(fechaItem: string): boolean {
    const filtro = this.fechaRapida();

    if (filtro === 'todos') {
      return true;
    }

    const hoy = this.fechaClaveBolivia(new Date());

    if (!hoy) {
      return true;
    }

    if (filtro === 'hoy') {
      return fechaItem === hoy;
    }

    if (filtro === 'mes') {
      return fechaItem.slice(0, 7) === hoy.slice(0, 7);
    }

    if (filtro === 'anio') {
      return fechaItem.slice(0, 4) === hoy.slice(0, 4);
    }

    const { inicio, fin } = this.rangoSemana(hoy);
    return fechaItem >= inicio && fechaItem <= fin;
  }

  private fechaClaveBolivia(fecha: string | Date): string {
    return convertirFechaBackendADatetimeLocal(fecha).slice(0, 10);
  }

  private rangoSemana(fechaIso: string): { inicio: string; fin: string } {
    const fecha = new Date(`${fechaIso}T00:00:00`);
    const dia = fecha.getDay() || 7;
    const inicio = new Date(fecha);
    inicio.setDate(fecha.getDate() - dia + 1);
    const fin = new Date(inicio);
    fin.setDate(inicio.getDate() + 6);

    return {
      inicio: inicio.toISOString().slice(0, 10),
      fin: fin.toISOString().slice(0, 10),
    };
  }

  private opcionesUnicas(valores: string[]): string[] {
    return [...new Set(
      valores
        .map((valor) => String(valor || '').trim())
        .filter(Boolean),
    )].sort((a, b) => a.localeCompare(b, 'es'));
  }

  private normalizarFiltro(valor: string): string {
    return String(valor || '').trim().toUpperCase();
  }

  usuarioGeneradorReporte(): string {
    const usuario = this.authState.usuario() as any;

    return (
      usuario?.nombreCompleto ||
      usuario?.nombre_completo ||
      usuario?.nombreUsuario ||
      usuario?.nombre_usuario ||
      'Usuario autenticado'
    );
  }

  claseEstado(valor: string | number): string {
    const estado = String(valor || '').toUpperCase();

    if (
      estado.includes('APROBADO') ||
      estado.includes('DISPONIBLE') ||
      estado.includes('COMPLET') ||
      estado.includes('ATENDIDO') ||
      estado.includes('RECIBIDA') ||
      estado.includes('PAGADO')
    ) {
      return 'bg-green-100 text-green-700 border-green-200';
    }

    if (
      estado.includes('RECHAZADO') ||
      estado.includes('ANULADO') ||
      estado.includes('CRITICO') ||
      estado.includes('CRÍTICO') ||
      estado.includes('AGOTADO')
    ) {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    if (
      estado.includes('PENDIENTE') ||
      estado.includes('BAJO') ||
      estado.includes('PARCIAL') ||
      estado.includes('PROCESO')
    ) {
      return 'bg-orange-100 text-orange-700 border-orange-200';
    }

    return 'bg-blue-100 text-blue-700 border-blue-200';
  }

  claveFila(item: any, index: number): string {
    const data = item as any;

    return String(
      data.idInventario ||
        data.id_inventario ||
        data.idPedido ||
        data.id_pedido ||
        data.idOrdenCompra ||
        data.id_orden_compra ||
        data.idComprobanteCompra ||
        data.id_comprobante_compra ||
        data.idMovimiento ||
        data.id_movimiento ||
        index,
    );
  }

  imprimirReporte() {
    this.imprimirReporteActual();
  }

  imprimirReporteActual() {
    if (!this.verificarPermiso('reportes.imprimir')) {
      return;
    }

    this.imprimirDocumento(false);
  }

  imprimirReporteGeneral() {
    if (!this.verificarPermiso('reportes.imprimir')) {
      return;
    }

    this.imprimirDocumento(true);
  }

  tienePermiso(permiso: string): boolean {
    return this.permissionService.tienePermiso(permiso);
  }

  private verificarPermiso(permiso: string): boolean {
    if (this.permissionService.tienePermiso(permiso)) {
      return true;
    }

    this.error.set(this.permissionService.mensajeSinPermiso);
    window.alert(this.permissionService.mensajeSinPermiso);
    return false;
  }

  private imprimirDocumento(general: boolean) {
    const ventana = window.open('', '_blank', 'width=1024,height=768');

    if (!ventana) {
      window.print();
      this.confirmacionAccionService.mostrar('Reporte enviado a impresion.');
      return;
    }

    ventana.document.write(
      general ? this.htmlReporteGeneral() : this.htmlReporteProfesional(),
    );
    ventana.document.close();
    ventana.focus();
    setTimeout(() => ventana.print(), 250);
    this.confirmacionAccionService.mostrar('Reporte enviado a impresion.');
  }

  exportarExcelCsv() {
    if (!this.verificarPermiso('reportes.exportar')) {
      return;
    }

    const columnas = this.columnasActuales();
    const filas = this.datosFiltrados();

    const encabezado = columnas.map((col) => this.limpiarCsv(col.label)).join(';');

    const contenido = filas.map((item) => {
      return columnas
        .map((col) => this.limpiarCsv(this.valorCelda(item, col.key)))
        .join(';');
    });

    const csv = ['\ufeff' + encabezado, ...contenido].join('\n');
    const blob = new Blob([csv], {
      type: 'text/csv;charset=utf-8;',
    });

    const url = URL.createObjectURL(blob);
    const enlace = document.createElement('a');

    enlace.href = url;
    enlace.download = `${this.tabActual()}-${convertirFechaBackendADatetimeLocal(new Date()).slice(0, 10)}.csv`;
    enlace.click();

    URL.revokeObjectURL(url);

    this.confirmacionAccionService.mostrar('Reporte exportado correctamente.');
  }

  limpiarCsv(valor: unknown): string {
    const texto = this.textoPlano(valor).replaceAll('"', '""');
    return `"${texto}"`;
  }

  private almacenPorId(idAlmacen: unknown): any | null {
    const id = Number(idAlmacen || 0);

    if (!id) {
      return null;
    }

    return (
      this.almacenes().find((almacen) => {
        const data = almacen as any;
        return Number(data.idAlmacen || data.id_almacen || 0) === id;
      }) || null
    );
  }

  private primerTexto(...valores: unknown[]): string {
    for (const valor of valores) {
      const texto = this.textoPlano(valor);

      if (texto) {
        return texto;
      }
    }

    return '';
  }

  private textoPlano(valor: unknown): string {
    if (valor === null || valor === undefined) return '';
    if (typeof valor !== 'object') return String(valor);

    const data = valor as any;
    const texto =
      data.nombreCompleto ||
      data.nombre_completo ||
      data.nombreUsuario ||
      data.nombre_usuario ||
      data.razonSocial ||
      data.razon_social ||
      data.nombreComercial ||
      data.nombre_comercial ||
      data.nombreAreaSolicitante ||
      data.nombre_area_solicitante ||
      data.areaSolicitanteNombre ||
      data.area_solicitante_nombre ||
      data.areaNombre ||
      data.area_nombre ||
      data.nombreArea ||
      data.nombre_area ||
      data.nombreAlmacen ||
      data.nombre_almacen ||
      data.codigoAlmacen ||
      data.codigo_almacen ||
      data.nombreInsumo ||
      data.nombre_insumo ||
      data.numeroOrden ||
      data.numero_orden ||
      data.numeroPedido ||
      data.numero_pedido ||
      data.numeroComprobante ||
      data.numero_comprobante ||
      '';

    return String(texto || '').trim();
  }

  private etiquetaOperativa(valor: unknown): string {
    return String(valor || 'Sin dato')
      .replace(/[_-]+/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  private htmlReporteProfesional(): string {
    const tab = this.tabActual();
    return this.htmlDocumentoReporte([this.crearSeccionReporte(tab, true)], false);
  }

  private htmlReporteGeneral(): string {
    const secciones = this.tabsReporteDisponibles().map((tab) => tab.valor);

    return this.htmlDocumentoReporte(
      secciones.map((tab) => this.crearSeccionReporte(tab, false)),
      true,
    );
  }

  private crearSeccionReporte(tab: TabReporte, usarFiltro: boolean) {
    const filas = usarFiltro && tab === this.tabActual()
      ? this.datosFiltrados()
      : this.datosPorTab(tab);

    return {
      tab,
      codigo: this.codigoReporte(tab),
      titulo: this.tituloPorTab(tab),
      descripcion: this.descripcionPorTab(tab),
      columnas: this.columnasPorTab(tab),
      filas,
      resumen: this.resumenPorTab(tab, filas),
    };
  }

  private datosPorTab(tab: TabReporte): any[] {
    if (tab === 'inventario') return this.inventario();
    if (tab === 'pedidos') return this.pedidos();
    if (tab === 'compras') return this.ordenesCompra();
    if (tab === 'comprobantes') return this.comprobantes();
    return this.movimientos();
  }

  private columnasPorTab(tab: TabReporte): ColumnaReporte[] {
    if (tab === 'inventario') {
      return [
        { key: 'codigo', label: 'Codigo' },
        { key: 'insumo', label: 'Insumo' },
        { key: 'almacen', label: 'Almacen' },
        { key: 'stockFisico', label: 'Stock fisico' },
        { key: 'stockReservado', label: 'Reservado' },
        { key: 'stockDisponible', label: 'Disponible' },
        { key: 'estado', label: 'Estado' },
      ];
    }

    if (tab === 'pedidos') {
      return [
        { key: 'numero', label: 'Numero' },
        { key: 'solicitante', label: 'Solicitante' },
        { key: 'area', label: 'Area' },
        { key: 'tipo', label: 'Tipo' },
        { key: 'prioridad', label: 'Prioridad' },
        { key: 'estado', label: 'Estado' },
        { key: 'aprobacion', label: 'Aprobacion' },
        { key: 'fecha', label: 'Fecha' },
      ];
    }

    if (tab === 'compras') {
      return [
        { key: 'numero', label: 'Orden' },
        { key: 'proveedor', label: 'Proveedor' },
        { key: 'fecha', label: 'Fecha' },
        { key: 'subtotal', label: 'Subtotal' },
        { key: 'descuento', label: 'Descuento' },
        { key: 'total', label: 'Total' },
        { key: 'estado', label: 'Estado' },
      ];
    }

    if (tab === 'comprobantes') {
      return [
        { key: 'numero', label: 'Comprobante' },
        { key: 'tipo', label: 'Tipo' },
        { key: 'proveedor', label: 'Proveedor' },
        { key: 'orden', label: 'Orden' },
        { key: 'fecha', label: 'Fecha' },
        { key: 'subtotal', label: 'Subtotal' },
        { key: 'descuento', label: 'Descuento' },
        { key: 'monto', label: 'Total' },
        { key: 'estado', label: 'Estado' },
      ];
    }

    return [
      { key: 'fecha', label: 'Fecha' },
      { key: 'tipo', label: 'Tipo movimiento' },
      { key: 'insumo', label: 'Insumo' },
      { key: 'almacen', label: 'Almacen' },
      { key: 'cantidad', label: 'Cantidad' },
      { key: 'motivo', label: 'Motivo' },
    ];
  }

  private valorCeldaPorTab(tab: TabReporte, item: any, key: string): string | number {
    if (tab === 'inventario') return this.valorInventario(item, key);
    if (tab === 'pedidos') return this.valorPedido(item, key);
    if (tab === 'compras') return this.valorOrden(item, key);
    if (tab === 'comprobantes') return this.valorComprobante(item, key);
    return this.valorMovimiento(item, key);
  }

  private codigoReporte(tab: TabReporte): string {
    const codigos: Record<TabReporte, string> = {
      inventario: 'REP-INV',
      pedidos: 'REP-PED',
      compras: 'REP-COM',
      comprobantes: 'REP-COMP',
      movimientos: 'REP-MOV',
    };

    return codigos[tab];
  }

  private tituloPorTab(tab: TabReporte): string {
    const titulos: Record<TabReporte, string> = {
      inventario: 'Reporte de inventario',
      pedidos: 'Reporte de pedidos',
      compras: 'Reporte de compras',
      comprobantes: 'Reporte de comprobantes',
      movimientos: 'Reporte de movimientos',
    };

    return titulos[tab];
  }

  private descripcionPorTab(tab: TabReporte): string {
    const descripciones: Record<TabReporte, string> = {
      inventario: 'Stock fisico, reservado y disponible por almacen.',
      pedidos: 'Solicitudes de insumos registradas por area solicitante.',
      compras: 'Ordenes de compra generadas para proveedores.',
      comprobantes: 'Comprobantes y documentos de compra registrados.',
      movimientos: 'Entradas, salidas y ajustes de inventario.',
    };

    return descripciones[tab];
  }

  private resumenPorTab(tab: TabReporte, filas: any[]) {
    if (tab === 'inventario') {
      return [
        { label: 'Total registros', value: filas.length },
        { label: 'Stock fisico total', value: this.sumar(filas, (item) => this.valorInventario(item, 'stockFisico')) },
        { label: 'Stock disponible total', value: this.sumar(filas, (item) => this.valorInventario(item, 'stockDisponible')) },
        { label: 'Valor aproximado', value: `Bs ${this.valorTotalInventario()}` },
      ];
    }

    if (tab === 'pedidos') {
      return [
        { label: 'Total pedidos', value: filas.length },
        { label: 'Pendientes', value: filas.filter((item) => String(this.valorPedido(item, 'aprobacion')).includes('PENDIENTE')).length },
        { label: 'Aprobados', value: filas.filter((item) => String(this.valorPedido(item, 'aprobacion')).includes('APROBADO')).length },
        { label: 'Rechazados', value: filas.filter((item) => String(this.valorPedido(item, 'aprobacion')).includes('RECHAZADO')).length },
      ];
    }

    if (tab === 'compras') {
      return [
        { label: 'Total ordenes', value: filas.length },
        { label: 'Monto total', value: `Bs ${this.sumar(filas, (item) => this.valorOrden(item, 'total'))}` },
        { label: 'En proceso', value: filas.filter((item) => String(this.valorOrden(item, 'estado')).includes('PROCESO')).length },
        { label: 'Finalizadas', value: filas.filter((item) => String(this.valorOrden(item, 'estado')).includes('FINAL')).length },
      ];
    }

    if (tab === 'comprobantes') {
      return [
        { label: 'Total comprobantes', value: filas.length },
        { label: 'Monto total', value: `Bs ${this.sumar(filas, (item) => this.valorComprobante(item, 'monto'))}` },
      ];
    }

    return [
      { label: 'Total movimientos', value: filas.length },
      { label: 'Entradas', value: filas.filter((item) => String(this.valorMovimiento(item, 'tipo')).includes('ENTRADA')).length },
      { label: 'Salidas', value: filas.filter((item) => String(this.valorMovimiento(item, 'tipo')).includes('SALIDA')).length },
      { label: 'Ajustes', value: filas.filter((item) => String(this.valorMovimiento(item, 'tipo')).includes('AJUSTE')).length },
    ];
  }

  private sumar(filas: any[], selector: (item: any) => unknown): number {
    return filas.reduce((total, item) => total + Number(selector(item) || 0), 0);
  }

  private totalSimple(subtotal: unknown, descuento: unknown): number {
    return Math.max(Number(subtotal || 0) - Number(descuento || 0), 0);
  }

  private htmlDocumentoReporte(secciones: any[], general: boolean): string {
    const fecha = this.fechaHoraFormateada(this.fechaActualizacion());
    const usuario = this.usuarioGeneradorReporte();
    const titulo = general ? 'Reporte general del sistema logistico' : secciones[0].titulo;
    const codigo = general ? 'REP-GEN' : secciones[0].codigo;

    return `<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>${this.escaparHtml(titulo)}</title>
  <style>${this.cssReporteProfesional()}
/* OCULTAR_RESUMEN_GENERAL_PDF */
.resumen-general,
.resumen-reporte,
.summary-grid,
.report-summary,
.stats-grid,
.cards-resumen,
.tarjetas-resumen,
.reporte-resumen,
.print-summary,
.general-summary {
  display: none !important;
}

h2.resumen-general,
h2.summary-title,
h3.resumen-general {
  display: none !important;
}
</style>
</head>
<body>
  ${this.htmlEncabezadoReporte(titulo, codigo, fecha, usuario)}
  ${general ? this.htmlPortadaGeneral(fecha, usuario) : ''}
  ${general ? this.htmlResumenGeneral() : ''}
  ${secciones.map((seccion, index) => this.htmlSeccionReporte(seccion, general && index > 0)).join('')}
  <footer>
    <span>Sistema web para la gestion logistica de insumos y compras en operacion mina</span>
    <span>Cooperativa Minera El Porvenir R.L.</span>
  </footer>
</body>
</html>`;
  }

  private htmlEncabezadoReporte(
    titulo: string,
    codigo: string,
    fecha: string,
    usuario: string,
  ): string {
    return `<header class="document-header">
      <div class="brand">
        <div class="brand-mark">LP</div>
        <div>
          <div class="institution">COOPERATIVA MINERA EL PORVENIR R.L.</div>
          <div class="subtitle">Sistema logistico de insumos, inventario, pedidos, compras y despachos.</div>
        </div>
      </div>
      <div class="report-meta">
        <div class="code">${this.escaparHtml(codigo)}</div>
        <h1>${this.escaparHtml(titulo)}</h1>
        <p><strong>Fecha:</strong> ${this.escaparHtml(fecha)}</p>
        <p><strong>Usuario:</strong> ${this.escaparHtml(usuario)}</p>
      </div>
    </header>`;
  }

  private htmlPortadaGeneral(fecha: string, usuario: string): string {
    return `<section class="cover">
      <div class="brand-mark large">LP</div>
      <h2>Cooperativa Minera El Porvenir R.L.</h2>
      <p>Reporte general del sistema logistico.</p>
      <div class="cover-meta">
        <span>Fecha de generacion: ${this.escaparHtml(fecha)}</span>
        <span>Usuario generador: ${this.escaparHtml(usuario)}</span>
      </div>
    </section>`;
  }

  private htmlResumenGeneral(): string {
    const resumen = [
      { label: 'Inventario', value: this.totalInventario() },
      { label: 'Pedidos', value: this.totalPedidos() },
      { label: 'Compras', value: this.totalOrdenes() },
      { label: 'Comprobantes', value: this.totalComprobantes() },
      { label: 'Movimientos', value: this.totalMovimientos() },
    ];

    return `<section class="summary-section">
      
    </section>`;
  }

  private htmlSeccionReporte(seccion: any, saltoPagina: boolean): string {
    const encabezado = seccion.columnas
      .map((col: ColumnaReporte) => `<th>${this.escaparHtml(col.label)}</th>`)
      .join('');
    const filas = seccion.filas
      .map((item: any) => {
        const celdas = seccion.columnas
          .map((col: ColumnaReporte) => {
            const valor = this.textoPlano(this.valorCeldaPorTab(seccion.tab, item, col.key));
            const esEstado = ['estado', 'aprobacion', 'prioridad'].includes(col.key);
            return `<td>${esEstado ? this.htmlEstado(valor) : this.escaparHtml(valor)}</td>`;
          })
          .join('');
        return `<tr>${celdas}</tr>`;
      })
      .join('');

    return `<section class="report-section ${saltoPagina ? 'page-break' : ''}">
      <div class="section-title">
        <div>
          <span>${this.escaparHtml(seccion.codigo)}</span>
          <h2>${this.escaparHtml(seccion.titulo)}</h2>
          <p>${this.escaparHtml(seccion.descripcion)}</p>
        </div>
        <strong>${seccion.filas.length} registros</strong>
      </div>
      <table>
        <thead><tr>${encabezado}</tr></thead>
        <tbody>${filas || `<tr><td colspan="${seccion.columnas.length}">No se encontraron registros.</td></tr>`}</tbody>
      </table>
    </section>`;
  }

  private htmlTarjetaResumen(item: { label: string; value: unknown }): string {
    return `<div class="summary-card">
      <span>${this.escaparHtml(item.label)}</span>
      <strong>${this.escaparHtml(item.value)}</strong>
    </div>`;
  }

  private htmlEstado(valor: string): string {
    const estado = String(valor || 'SIN_ESTADO');
    const normalizado = estado.toUpperCase();
    const clase = normalizado.includes('RECHAZADO') || normalizado.includes('ANULADO') || normalizado.includes('CRITICO')
      ? 'danger'
      : normalizado.includes('PENDIENTE') || normalizado.includes('BAJO') || normalizado.includes('PROCESO')
        ? 'warning'
        : normalizado.includes('APROBADO') || normalizado.includes('DISPONIBLE') || normalizado.includes('COMPLETO') || normalizado.includes('REGISTRADO')
          ? 'success'
          : 'info';

    return `<span class="status ${clase}">${this.escaparHtml(estado)}</span>`;
  }

  private cssReporteProfesional(): string {
    return `
      @page { size: A4; margin: 14mm; }
      * { box-sizing: border-box; }
      body { margin: 0; color: #0f172a; font-family: Arial, Helvetica, sans-serif; background: #fff; }
      .document-header { display: flex; justify-content: space-between; gap: 24px; padding: 18px 0 14px; border-bottom: 4px solid #1d4ed8; margin-bottom: 18px; }
      .brand { display: flex; align-items: center; gap: 14px; }
      .brand-mark { width: 54px; height: 54px; border-radius: 12px; display: grid; place-items: center; background: linear-gradient(135deg, #0f172a, #1d4ed8 58%, #38bdf8); color: #fff; font-weight: 900; letter-spacing: .08em; box-shadow: inset 0 -10px 18px rgba(255,255,255,.12); }
      .brand-mark.large { width: 82px; height: 82px; margin: 0 auto 18px; font-size: 24px; }
      .institution { font-size: 14px; font-weight: 900; letter-spacing: .04em; color: #0f172a; }
      .subtitle { margin-top: 4px; max-width: 420px; font-size: 11px; line-height: 1.45; color: #475569; }
      .report-meta { min-width: 240px; text-align: right; }
      .report-meta .code { display: inline-block; margin-bottom: 7px; border: 1px solid #bfdbfe; border-radius: 999px; padding: 5px 10px; background: #eff6ff; color: #1d4ed8; font-size: 10px; font-weight: 900; }
      h1 { margin: 0 0 7px; font-size: 22px; color: #0f172a; }
      h2 { margin: 0; font-size: 18px; color: #0f172a; }
      p { margin: 0; }
      .report-meta p { margin-top: 3px; font-size: 11px; color: #475569; }
      .cover { text-align: center; padding: 34px 20px; border: 1px solid #bfdbfe; background: linear-gradient(180deg, #eff6ff, #fff); margin-bottom: 20px; }
      .cover h2 { font-size: 24px; margin-bottom: 8px; text-transform: uppercase; }
      .cover p { color: #1d4ed8; font-weight: 800; }
      .cover-meta { display: flex; justify-content: center; gap: 20px; margin-top: 18px; color: #475569; font-size: 12px; }
      .summary-section { margin: 16px 0 18px; }
      .summary-section h2 { margin-bottom: 10px; }
      .summary-grid { display: none !important; }
      .summary-card { border: 1px solid #dbeafe; border-left: 4px solid #1d4ed8; background: #f8fafc; padding: 9px 10px; min-height: 58px; }
      .summary-card span { display: block; color: #64748b; font-size: 9px; text-transform: uppercase; font-weight: 900; letter-spacing: .04em; }
      .summary-card strong { display: block; margin-top: 6px; color: #0f172a; font-size: 15px; }
      .report-section { margin-top: 16px; }
      .page-break { page-break-before: always; }
      .section-title { display: flex; justify-content: space-between; gap: 12px; align-items: flex-end; margin-bottom: 8px; border-bottom: 1px solid #dbeafe; padding-bottom: 8px; }
      .section-title span { display: inline-block; margin-bottom: 4px; color: #1d4ed8; font-size: 10px; font-weight: 900; }
      .section-title p { margin-top: 4px; color: #64748b; font-size: 11px; }
      .section-title strong { color: #1d4ed8; font-size: 11px; }
      table { width: 100%; border-collapse: collapse; font-size: 10px; page-break-inside: auto; }
      thead { display: table-header-group; }
      tr { page-break-inside: avoid; }
      th { background: #0f172a; color: #fff; text-align: left; text-transform: uppercase; letter-spacing: .04em; font-size: 9px; }
      th, td { border: 1px solid #cbd5e1; padding: 7px; vertical-align: top; }
      tbody tr:nth-child(even) td { background: #f8fafc; }
      .status { display: inline-block; border-radius: 999px; padding: 3px 7px; font-size: 8px; font-weight: 900; border: 1px solid transparent; }
      .status.success { background: #dcfce7; color: #166534; border-color: #bbf7d0; }
      .status.warning { background: #ffedd5; color: #9a3412; border-color: #fed7aa; }
      .status.danger { background: #fee2e2; color: #991b1b; border-color: #fecaca; }
      .status.info { background: #dbeafe; color: #1e40af; border-color: #bfdbfe; }
      footer { display: flex; justify-content: space-between; gap: 12px; margin-top: 18px; padding-top: 10px; border-top: 1px solid #cbd5e1; color: #64748b; font-size: 9px; }
      @media print { body { -webkit-print-color-adjust: exact; print-color-adjust: exact; } }
    `;
  }

  private htmlReporteImpresion(): string {
    const columnas = this.columnasActuales();
    const filas = this.datosFiltrados();
    const fecha = this.fechaHoraFormateada(this.fechaActualizacion());
    const usuario = this.usuarioGeneradorReporte();

    const filasHtml = filas
      .map((item) => {
        const celdas = columnas
          .map((col) => `<td>${this.escaparHtml(this.textoPlano(this.valorCelda(item, col.key)))}</td>`)
          .join('');

        return `<tr>${celdas}</tr>`;
      })
      .join('');

    const encabezado = columnas
      .map((col) => `<th>${this.escaparHtml(col.label)}</th>`)
      .join('');

    return `<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>${this.escaparHtml(this.tituloReporte())}</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: Arial, sans-serif; color: #0f172a; margin: 28px; }
    header { border-bottom: 2px solid #0f172a; padding-bottom: 14px; margin-bottom: 18px; }
    .eyebrow { font-size: 11px; text-transform: uppercase; letter-spacing: .08em; color: #475569; font-weight: 700; }
    h1 { margin: 6px 0 4px; font-size: 24px; }
    .meta { display: flex; justify-content: space-between; gap: 16px; margin: 16px 0; font-size: 12px; color: #475569; }
    table { width: 100%; border-collapse: collapse; font-size: 11px; }
    th { background: #f1f5f9; text-align: left; text-transform: uppercase; font-size: 10px; }
    th, td { border: 1px solid #cbd5e1; padding: 7px; vertical-align: top; }
    tfoot td { font-weight: 700; background: #f8fafc; }
    footer { margin-top: 18px; border-top: 1px solid #cbd5e1; padding-top: 10px; font-size: 11px; color: #64748b; }
  
/* OCULTAR_RESUMEN_GENERAL_PDF */
.resumen-general,
.resumen-reporte,
.summary-grid,
.report-summary,
.stats-grid,
.cards-resumen,
.tarjetas-resumen,
.reporte-resumen,
.print-summary,
.general-summary {
  display: none !important;
}

h2.resumen-general,
h2.summary-title,
h3.resumen-general {
  display: none !important;
}
</style>
</head>
<body>
  <header>
    <div class="eyebrow">Cooperativa Minera El Porvenir R.L.</div>
    <h1>${this.escaparHtml(this.tituloReporte())}</h1>
    <div><strong>Sistema logístico</strong></div>
    <div>${this.escaparHtml(this.descripcionReporte())}</div>
  </header>
  <section class="meta">
    <div><strong>Fecha de generación:</strong> ${this.escaparHtml(fecha)}</div>
    <div><strong>Usuario generador:</strong> ${this.escaparHtml(usuario)}</div>
    <div><strong>Registros:</strong> ${filas.length}</div>
  </section>
  <table>
    <thead><tr>${encabezado}</tr></thead>
    <tbody>${filasHtml || `<tr><td colspan="${columnas.length}">No se encontraron registros.</td></tr>`}</tbody>
    <tfoot><tr><td colspan="${columnas.length}">Total de registros: ${filas.length}</td></tr></tfoot>
  </table>
  <footer>Sistema web para la gestión logística de insumos y compras en operación mina.</footer>
</body>
</html>`;
  }

  private escaparHtml(valor: unknown): string {
    return String(valor ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
  }
}
