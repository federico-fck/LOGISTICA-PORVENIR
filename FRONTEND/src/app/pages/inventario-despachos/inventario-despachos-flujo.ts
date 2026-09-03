import { Component, inject, signal } from '@angular/core';
import { AbstractControl, FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { catchError, forkJoin, of } from 'rxjs';

import { InventarioDespachosService } from '../../core/services/inventario-despachos.service';
import { InsumosService } from '../../core/services/insumos.service';
import { AlmacenesService } from '../../core/services/almacenes.service';
import { PermissionService } from '../../core/services/permission.service';
import { AuthState } from '../../core/state/auth.state';

import { Insumo } from '../../core/models/insumo.model';
import { Almacen } from '../../core/models/almacen.model';
import {
  Despacho,
  InventarioItem,
  MovimientoInventario,
  PedidoAprobadoDespacho,
  PedidoDespachoDetalle,
} from '../../core/models/inventario-despachos.model';
import { formatearFechaHoraBolivia } from '../../core/utils/fecha.util';
import {
  MOTIVOS_AJUSTE_INVENTARIO,
  MOTIVOS_DEVOLUCION_INVENTARIO,
  MOTIVOS_TRANSFERENCIA_INVENTARIO,
  almacenesDiferentesValidator,
} from '../../core/forms/professional-forms';
import {
  FormFieldLabels,
  marcarFormularioInvalido,
  mensajeErrorBackend,
} from '../../core/forms/form-error-messages';
import { CampoValidacionDirective } from '../../core/forms/campo-validacion.directive';

type TabInventario = 'inventario' | 'stock' | 'movimientos' | 'despachos';
type PeriodoFecha = 'todos' | 'hoy' | 'semana' | 'mes' | 'anio';
type ModoModal =
  | 'ninguno'
  | 'ajuste'
  | 'transferencia'
  | 'devolucion'
  | 'despacho'
  | 'detalle-despacho'
  | 'detalle-stock-critico';

@Component({
  selector: 'app-inventario-despachos-flujo',
  standalone: true,
  imports: [ReactiveFormsModule, CampoValidacionDirective],
  templateUrl: './inventario-despachos-flujo.html',
  styleUrl: './inventario-despachos.css',
})
export class InventarioDespachos {
  private readonly inventarioService = inject(InventarioDespachosService);
  private readonly insumosService = inject(InsumosService);
  private readonly almacenesService = inject(AlmacenesService);
  private readonly permissionService = inject(PermissionService);
  private readonly authState = inject(AuthState);
  private readonly formBuilder = inject(FormBuilder);
  private readonly etiquetasFormulario: FormFieldLabels = {
    idInsumo: 'Insumo',
    idAlmacen: 'Almacen',
    tipoMovimiento: 'Tipo de movimiento',
    cantidad: 'Cantidad',
    motivo: 'Motivo',
    observaciones: 'Observaciones',
    idAlmacenOrigen: 'Almacen origen',
    idAlmacenDestino: 'Almacen destino',
    idDespacho: 'Despacho relacionado',
    idPedido: 'Pedido aprobado',
    idAlmacenSalida: 'Almacen origen',
  };

  cargando = signal(false);
  guardando = signal(false);
  error = signal('');
  mensaje = signal('');
  tabActual = signal<TabInventario>('inventario');
  busqueda = signal('');
  modoModal = signal<ModoModal>('ninguno');
  filtroInventarioAlmacen = signal('');
  filtroInventarioEstado = signal('');
  filtroStockAlmacen = signal('');
  filtroStockEstado = signal('');
  filtroMovimientoPeriodo = signal<PeriodoFecha>('todos');
  filtroMovimientoDesde = signal('');
  filtroMovimientoHasta = signal('');
  filtroMovimientoTipo = signal('');
  filtroMovimientoAlmacen = signal('');
  filtroDespachoPeriodo = signal<PeriodoFecha>('todos');
  filtroDespachoDesde = signal('');
  filtroDespachoHasta = signal('');
  filtroDespachoEstado = signal('');
  filtroDespachoAlmacen = signal('');
  filtroDespachoArea = signal('');

  inventario = signal<InventarioItem[]>([]);
  stockCritico = signal<InventarioItem[]>([]);
  movimientos = signal<MovimientoInventario[]>([]);
  despachos = signal<Despacho[]>([]);
  pedidosAprobados = signal<PedidoAprobadoDespacho[]>([]);
  insumos = signal<Insumo[]>([]);
  almacenes = signal<Almacen[]>([]);
  usuariosSistema = signal<any[]>([]);
  areasSistema = signal<any[]>([]);

  despachoSeleccionado = signal<Despacho | null>(null);
  stockSeleccionado = signal<InventarioItem | null>(null);
  pedidoSeleccionado = signal<PedidoAprobadoDespacho | null>(null);
  cantidadesDespacho = signal<Record<string, string>>({});
  despachoIntentoGuardar = signal(false);

  tiposAjuste = ['AJUSTE_POSITIVO', 'AJUSTE_NEGATIVO'];
  readonly motivosAjusteInventario = MOTIVOS_AJUSTE_INVENTARIO;
  readonly motivosTransferenciaInventario = MOTIVOS_TRANSFERENCIA_INVENTARIO;
  readonly motivosDevolucionInventario = MOTIVOS_DEVOLUCION_INVENTARIO;

  formAjuste = this.formBuilder.nonNullable.group({
    idInsumo: ['', [Validators.required]],
    idAlmacen: ['', [Validators.required]],
    tipoMovimiento: ['AJUSTE_POSITIVO', [Validators.required]],
    cantidad: ['', [Validators.required, Validators.min(0.01)]],
    motivo: ['', [Validators.required]],
    observaciones: [''],
  });

  formTransferencia = this.formBuilder.nonNullable.group(
    {
      idInsumo: ['', [Validators.required]],
      idAlmacenOrigen: ['', [Validators.required]],
      idAlmacenDestino: ['', [Validators.required]],
      cantidad: ['', [Validators.required, Validators.min(0.01)]],
      motivo: ['', [Validators.required]],
      observaciones: [''],
    },
    {
      validators: [almacenesDiferentesValidator('idAlmacenOrigen', 'idAlmacenDestino')],
    },
  );

  formDevolucion = this.formBuilder.nonNullable.group({
    idInsumo: ['', [Validators.required]],
    idAlmacenDestino: ['', [Validators.required]],
    cantidad: ['', [Validators.required, Validators.min(0.01)]],
    motivo: ['', [Validators.required]],
    idDespacho: [''],
    observaciones: [''],
  });

  formDespacho = this.formBuilder.nonNullable.group({
    idPedido: ['', [Validators.required]],
    idAlmacenSalida: ['', [Validators.required]],
    observaciones: [''],
  });

  ngOnInit() {
    this.cargarDatos();
  }

  cargarDatos() {
    this.cargando.set(true);
    this.error.set('');
    this.mensaje.set('');

    forkJoin({
      inventario: this.inventarioService.inventario().pipe(catchError(() => of([]))),
      stock: this.inventarioService.stockBajo().pipe(catchError(() => of([]))),
      movimientos: this.inventarioService.movimientos().pipe(catchError(() => of([]))),
      despachos: this.inventarioService.despachos().pipe(catchError(() => of([]))),
      pedidos: this.inventarioService.pedidosAprobadosParaDespacho().pipe(catchError(() => of([]))),
      insumos: this.insumosService.listar().pipe(catchError(() => of([]))),
      almacenes: this.almacenesService.listar().pipe(catchError(() => of([]))),
      usuarios: this.tienePermiso('usuarios.ver')
        ? this.inventarioService.usuariosSistema().pipe(catchError(() => of([])))
        : of([]),
      areas: this.inventarioService.areasSistema().pipe(catchError(() => of([]))),
    }).subscribe({
      next: (data) => {
        const usuarios = this.extraerListaApi(data.usuarios);
        const areas = this.extraerListaApi(data.areas);

        this.inventario.set(data.inventario as InventarioItem[]);
        this.stockCritico.set(data.stock as InventarioItem[]);
        this.movimientos.set(data.movimientos as MovimientoInventario[]);
        this.despachos.set(data.despachos as Despacho[]);
        this.usuariosSistema.set(usuarios);
        this.areasSistema.set(areas);
        this.pedidosAprobados.set(this.normalizarPedidosAprobados(data.pedidos, usuarios, areas));
        this.insumos.set(data.insumos as Insumo[]);
        this.almacenes.set(data.almacenes as Almacen[]);
        this.cargando.set(false);
      },
      error: () => {
        this.error.set('No se pudo cargar la informacion de inventario.');
        this.cargando.set(false);
      },
    });
  }

  extraerListaApi(data: unknown): any[] {
    const valor = data as any;

    if (Array.isArray(valor)) return valor;
    if (Array.isArray(valor?.data)) return valor.data;
    if (Array.isArray(valor?.items)) return valor.items;
    if (Array.isArray(valor?.registros)) return valor.registros;
    if (Array.isArray(valor?.rows)) return valor.rows;
    if (Array.isArray(valor?.pedidos)) return valor.pedidos;
    if (Array.isArray(valor?.usuarios)) return valor.usuarios;
    if (Array.isArray(valor?.areas)) return valor.areas;

    return [];
  }

  normalizarPedidosAprobados(data: unknown, usuarios: any[], areas: any[]) {
    return this.extraerListaApi(data)
      .map((pedido) => this.normalizarPedidoAprobado(pedido, usuarios, areas))
      .filter((pedido: any) =>
        pedido.detalles.some((detalle: any) => {
          return this.cantidadPendienteDetallePedido(detalle) > 0;
        }),
      ) as PedidoAprobadoDespacho[];
  }

  normalizarPedidoAprobado(pedido: any, usuarios: any[], areas: any[]) {
    const usuarioDirecto =
      pedido?.usuarioSolicitante || pedido?.usuario_solicitante || pedido?.solicitante || null;
    const idUsuario = Number(
      pedido?.idUsuarioSolicitante ||
        pedido?.id_usuario_solicitante ||
        usuarioDirecto?.idUsuario ||
        usuarioDirecto?.id_usuario ||
        usuarioDirecto?.id ||
        0,
    );
    const usuarioPorId = usuarios.find((usuario) => {
      return Number(usuario?.idUsuario || usuario?.id_usuario || usuario?.id || 0) === idUsuario;
    });
    const solicitante = usuarioDirecto || usuarioPorId || null;

    const areaDirecta = pedido?.areaSolicitante || pedido?.area_solicitante || pedido?.area || null;
    const areaDelUsuario =
      solicitante?.area || solicitante?.areaUsuario || solicitante?.area_usuario || null;
    const idArea = Number(
      pedido?.idAreaSolicitante ||
        pedido?.id_area_solicitante ||
        areaDirecta?.idArea ||
        areaDirecta?.id_area ||
        areaDirecta?.id ||
        areaDelUsuario?.idArea ||
        areaDelUsuario?.id_area ||
        solicitante?.idArea ||
        solicitante?.id_area ||
        0,
    );
    const areaPorId = areas.find((area) => {
      return Number(area?.idArea || area?.id_area || area?.id || 0) === idArea;
    });
    const area = areaDirecta || areaPorId || areaDelUsuario || null;

    const nombreArea =
      this.textoLimpio(area, '') ||
      this.textoLimpio(areaPorId, '') ||
      (idArea ? `Area ${idArea}` : '');
    const nombreSolicitante =
      this.textoLimpio(solicitante, '') ||
      this.textoLimpio(usuarioPorId, '') ||
      (idUsuario ? `Usuario ${idUsuario}` : '');

    return {
      ...pedido,
      idUsuarioSolicitante: idUsuario || pedido?.idUsuarioSolicitante,
      idAreaSolicitante: idArea || pedido?.idAreaSolicitante,
      solicitante,
      usuarioSolicitante: solicitante,
      area,
      areaSolicitante: area,
      nombreAreaSolicitante: nombreArea,
      areaSolicitanteNombre: nombreArea,
      nombreUsuarioSolicitante: nombreSolicitante,
      usuarioSolicitanteNombre: nombreSolicitante,
      detalles: this.extraerDetallesPedido(pedido).map((detalle) =>
        this.normalizarDetallePedido(detalle),
      ),
    };
  }

  extraerDetallesPedido(pedido: any): any[] {
    const detalles =
      pedido?.detalles ||
      pedido?.detallePedidos ||
      pedido?.detalle_pedidos ||
      pedido?.detallesPedido ||
      pedido?.detalles_pedido ||
      [];

    return Array.isArray(detalles) ? detalles : [];
  }

  normalizarDetallePedido(detalle: any): PedidoDespachoDetalle {
    const cantidadSolicitada = this.cantidadSolicitadaDetallePedido(detalle);
    const cantidadAprobada = this.cantidadAprobadaDetallePedido(detalle);
    const cantidadDespachada = this.cantidadDespachadaDetallePedido(detalle);
    const cantidadPendiente = this.cantidadPendienteDetallePedido({
      ...detalle,
      cantidadSolicitada,
      cantidadAprobada,
      cantidadDespachada,
    });

    return {
      ...detalle,
      idPedidoDetalle:
        detalle?.idPedidoDetalle ||
        detalle?.id_pedido_detalle ||
        detalle?.idDetallePedido ||
        detalle?.id_detalle_pedido,
      idInsumo:
        detalle?.idInsumo ||
        detalle?.id_insumo ||
        detalle?.insumo?.idInsumo ||
        detalle?.insumo?.id_insumo,
      cantidadSolicitada,
      cantidadAprobada,
      cantidadDespachada,
      cantidadPendiente,
      insumo: detalle?.insumo || null,
      observacion: detalle?.observacion || detalle?.observaciones,
    };
  }

  cambiarTab(tab: TabInventario) {
    if (!this.puedeVerTab(tab)) {
      this.verificarPermiso(this.permisoTab(tab));
      return;
    }

    this.tabActual.set(tab);
    this.busqueda.set('');
  }

  cambiarBusqueda(event: Event) {
    this.busqueda.set((event.target as HTMLInputElement).value);
  }

  abrirAjuste() {
    if (!this.verificarPermiso('inventario.ajustar')) {
      return;
    }

    this.limpiarMensajes();
    this.modoModal.set('ajuste');
    this.formAjuste.reset({
      idInsumo: '',
      idAlmacen: '',
      tipoMovimiento: 'AJUSTE_POSITIVO',
      cantidad: '',
      motivo: '',
      observaciones: '',
    });
  }

  abrirTransferencia() {
    if (!this.verificarPermiso('inventario.transferir')) {
      return;
    }

    this.limpiarMensajes();
    this.modoModal.set('transferencia');
    this.formTransferencia.reset({
      idInsumo: '',
      idAlmacenOrigen: '',
      idAlmacenDestino: '',
      cantidad: '',
      motivo: '',
      observaciones: '',
    });
  }

  abrirDevolucion() {
    if (!this.verificarPermiso('inventario.devolver')) {
      return;
    }

    this.limpiarMensajes();
    this.modoModal.set('devolucion');
    this.formDevolucion.reset({
      idInsumo: '',
      idAlmacenDestino: '',
      cantidad: '',
      motivo: '',
      idDespacho: '',
      observaciones: '',
    });
  }

  abrirDespacho() {
    if (!this.verificarPermiso('despachos.crear')) {
      return;
    }

    this.limpiarMensajes();
    this.modoModal.set('despacho');
    this.pedidoSeleccionado.set(null);
    this.cantidadesDespacho.set({});
    this.despachoIntentoGuardar.set(false);
    this.formDespacho.reset({
      idPedido: '',
      idAlmacenSalida: '',
      observaciones: '',
    });
  }

  cerrarModal() {
    this.modoModal.set('ninguno');
    this.despachoSeleccionado.set(null);
    this.stockSeleccionado.set(null);
    this.pedidoSeleccionado.set(null);
    this.cantidadesDespacho.set({});
    this.despachoIntentoGuardar.set(false);
  }

  guardarAjuste() {
    this.limpiarMensajes();

    if (!this.verificarPermiso('inventario.ajustar')) {
      return;
    }

    if (this.formAjuste.invalid) {
      this.error.set(
        marcarFormularioInvalido(
          this.formAjuste,
          this.etiquetasFormulario,
          'Revise los campos del ajuste',
        ),
      );
      return;
    }

    const valores = this.formAjuste.getRawValue();
    const cantidad = Number(valores.cantidad);
    const idInsumo = Number(valores.idInsumo);
    const idAlmacen = Number(valores.idAlmacen);

    if (
      valores.tipoMovimiento === 'AJUSTE_NEGATIVO' &&
      this.stockDisponibleInsumoAlmacen(idInsumo, idAlmacen) < cantidad
    ) {
      this.error.set('Stock disponible insuficiente para el ajuste negativo.');
      return;
    }

    this.guardando.set(true);
    this.inventarioService
      .registrarMovimiento({
        idInsumo,
        idAlmacen,
        tipoMovimiento: valores.tipoMovimiento,
        cantidad,
        motivo: valores.motivo.trim(),
        observaciones: valores.observaciones.trim() || undefined,
        usuarioResponsable: this.idUsuarioActual(),
      })
      .subscribe({
        next: () => this.operacionCompletada('Ajuste de inventario registrado.'),
        error: (error) => this.operacionFallida(error),
      });
  }

  guardarTransferencia() {
    this.limpiarMensajes();

    if (!this.verificarPermiso('inventario.transferir')) {
      return;
    }

    if (this.formTransferencia.invalid) {
      this.error.set(
        marcarFormularioInvalido(
          this.formTransferencia,
          this.etiquetasFormulario,
          'Revise los campos de la transferencia',
        ),
      );
      return;
    }

    const valores = this.formTransferencia.getRawValue();
    const idInsumo = Number(valores.idInsumo);
    const idAlmacenOrigen = Number(valores.idAlmacenOrigen);
    const idAlmacenDestino = Number(valores.idAlmacenDestino);
    const cantidad = Number(valores.cantidad);

    if (idAlmacenOrigen === idAlmacenDestino) {
      this.error.set('El almacen origen y destino no pueden ser iguales.');
      return;
    }

    if (this.stockDisponibleInsumoAlmacen(idInsumo, idAlmacenOrigen) < cantidad) {
      this.error.set('Stock disponible insuficiente en el almacen origen.');
      return;
    }

    this.guardando.set(true);
    this.inventarioService
      .registrarTransferencia({
        idInsumo,
        idAlmacenOrigen,
        idAlmacenDestino,
        cantidad,
        motivo: valores.motivo.trim(),
        observaciones: valores.observaciones.trim() || undefined,
        usuarioResponsable: this.idUsuarioActual(),
      })
      .subscribe({
        next: () => this.operacionCompletada('Transferencia registrada.'),
        error: (error) => this.operacionFallida(error),
      });
  }

  guardarDevolucion() {
    this.limpiarMensajes();

    if (!this.verificarPermiso('inventario.devolver')) {
      return;
    }

    if (this.formDevolucion.invalid) {
      this.error.set(
        marcarFormularioInvalido(
          this.formDevolucion,
          this.etiquetasFormulario,
          'Revise los campos de la devolucion',
        ),
      );
      return;
    }

    const valores = this.formDevolucion.getRawValue();

    this.guardando.set(true);
    this.inventarioService
      .registrarDevolucion({
        idInsumo: Number(valores.idInsumo),
        idAlmacenDestino: Number(valores.idAlmacenDestino),
        cantidad: Number(valores.cantidad),
        motivo: valores.motivo.trim(),
        idDespacho: valores.idDespacho ? Number(valores.idDespacho) : undefined,
        observaciones: valores.observaciones.trim() || undefined,
        usuarioResponsable: this.idUsuarioActual(),
      })
      .subscribe({
        next: () => this.operacionCompletada('Devolucion registrada.'),
        error: (error) => this.operacionFallida(error),
      });
  }

  seleccionarPedidoDespacho(event: Event) {
    const idPedido = Number((event.target as HTMLSelectElement).value || 0);
    const pedido = this.pedidosAprobados().find((item) => Number(item.idPedido || 0) === idPedido);

    this.pedidoSeleccionado.set(pedido || null);
    this.cantidadesDespacho.set(pedido ? this.cantidadesInicialesPedido(pedido) : {});
  }

  actualizarCantidadDespacho(detalle: PedidoDespachoDetalle, event: Event) {
    const key = this.detalleDespachoKey(detalle);
    const valor = (event.target as HTMLInputElement).value;

    this.cantidadesDespacho.update((actual) => ({
      ...actual,
      [key]: valor,
    }));
  }

  guardarDespacho() {
    this.limpiarMensajes();
    this.despachoIntentoGuardar.set(true);
    this.quitarErrorControl(this.formDespacho.controls.idPedido, 'seleccionInvalida');
    this.quitarErrorControl(this.formDespacho.controls.observaciones, 'minlength');

    if (!this.verificarPermiso('despachos.crear')) {
      return;
    }

    if (this.formDespacho.invalid) {
      this.error.set(
        marcarFormularioInvalido(
          this.formDespacho,
          this.etiquetasFormulario,
          'Revise los campos del despacho',
        ),
      );
      return;
    }

    if (!this.pedidoSeleccionado()) {
      marcarFormularioInvalido(
        this.formDespacho,
        this.etiquetasFormulario,
        'Revise los campos del despacho',
      );
      this.formDespacho.controls.idPedido.setErrors({
        ...(this.formDespacho.controls.idPedido.errors ?? {}),
        seleccionInvalida: true,
      });
      this.formDespacho.controls.idPedido.markAsTouched();
      return;
    }

    const pedido = this.pedidoSeleccionado();

    if (!pedido?.idPedido) {
      this.error.set('No se pudo identificar el pedido seleccionado.');
      return;
    }

    const valores = this.formDespacho.getRawValue();
    const idAlmacenSalida = Number(valores.idAlmacenSalida);
    const detalles = pedido.detalles
      .map((detalle) => {
        const cantidad = Number(this.cantidadesDespacho()[this.detalleDespachoKey(detalle)] || 0);

        return {
          detalle,
          cantidad,
        };
      })
      .filter((item) => item.cantidad > 0);

    if (detalles.length === 0) {
      return;
    }

    for (const item of detalles) {
      const pendiente = this.cantidadPendienteDetallePedido(item.detalle);
      const stockDisponible = this.stockDisponibleDetallePedido(item.detalle);

      if (item.cantidad > pendiente) {
        return;
      }

      if (item.cantidad > stockDisponible) {
        return;
      }
    }

    if (this.esDespachoParcialSeleccionado() && valores.observaciones.trim().length < 5) {
      marcarFormularioInvalido(
        this.formDespacho,
        this.etiquetasFormulario,
        'Revise los campos del despacho',
      );
      this.formDespacho.controls.observaciones.setErrors({
        ...(this.formDespacho.controls.observaciones.errors ?? {}),
        minlength: {
          requiredLength: 5,
          actualLength: valores.observaciones.trim().length,
        },
      });
      this.formDespacho.controls.observaciones.markAsTouched();
      return;
    }

    this.guardando.set(true);
    this.despachoIntentoGuardar.set(false);
    this.inventarioService
      .crearDespacho({
        idPedido: pedido.idPedido,
        idAlmacenSalida,
        idResponsableAlmacen: this.idUsuarioActual(),
        personaRecibe: this.nombreSolicitantePedido(pedido),
        tipoDespacho: 'NORMAL',
        observaciones: valores.observaciones.trim() || undefined,
        usuarioRegistra: this.idUsuarioActual(),
        detalles: detalles.map((item) => ({
          idPedidoDetalle: item.detalle.idPedidoDetalle,
          idInsumo: this.idInsumoDetallePedido(item.detalle),
          cantidadSolicitada: this.cantidadSolicitadaDetallePedido(item.detalle),
          cantidadAprobada: this.cantidadAprobadaDetallePedido(item.detalle),
          cantidadEntregada: item.cantidad,
          estadoConformidad: 'CONFORME',
          observacion: item.detalle.observacion,
        })),
      })
      .subscribe({
        next: () => this.operacionCompletada('Despacho generado correctamente.'),
        error: (error) => this.operacionFallida(error),
      });
  }

  cantidadDespachoInvalida(detalle: PedidoDespachoDetalle): boolean {
    if (!this.despachoIntentoGuardar()) {
      return false;
    }

    const cantidad = Number(
      this.cantidadesDespacho()[this.detalleDespachoKey(detalle)] || 0,
    );

    return (
      (!this.tieneAlgunaCantidadDespacho() && cantidad <= 0) ||
      cantidad > this.cantidadPendienteDetallePedido(detalle) ||
      cantidad > this.stockDisponibleDetallePedido(detalle)
    );
  }

  mensajeCantidadDespacho(detalle: PedidoDespachoDetalle): string {
    const cantidad = Number(
      this.cantidadesDespacho()[this.detalleDespachoKey(detalle)] || 0,
    );

    if (!this.tieneAlgunaCantidadDespacho() && cantidad <= 0) {
      return 'Ingrese una cantidad mayor a cero.';
    }

    if (cantidad > this.cantidadPendienteDetallePedido(detalle)) {
      return 'No puede superar la cantidad pendiente.';
    }

    if (cantidad > this.stockDisponibleDetallePedido(detalle)) {
      return 'No puede superar el stock disponible.';
    }

    return '';
  }

  private tieneAlgunaCantidadDespacho(): boolean {
    const pedido = this.pedidoSeleccionado();

    return Boolean(
      pedido?.detalles?.some(
        (detalle) =>
          Number(this.cantidadesDespacho()[this.detalleDespachoKey(detalle)] || 0) >
          0,
      ),
    );
  }

  private quitarErrorControl(control: AbstractControl, codigo: string) {
    if (!control.hasError(codigo)) {
      return;
    }

    const errores = { ...(control.errors ?? {}) };
    delete errores[codigo];
    control.setErrors(Object.keys(errores).length ? errores : null);
  }

  abrirDetalleDespacho(despacho: Despacho) {
    if (!this.verificarPermiso('despachos.detalle')) {
      return;
    }

    const id = this.idDespacho(despacho);

    if (!id) {
      this.despachoSeleccionado.set(despacho);
      this.modoModal.set('detalle-despacho');
      return;
    }

    this.inventarioService.buscarDespachoPorId(id).subscribe({
      next: (data) => {
        this.despachoSeleccionado.set(data);
        this.modoModal.set('detalle-despacho');
      },
      error: () => {
        this.despachoSeleccionado.set(despacho);
        this.modoModal.set('detalle-despacho');
      },
    });
  }

  abrirDetalleStockCritico(item: InventarioItem) {
    if (!this.verificarPermiso('inventario.ver_stock_critico')) {
      return;
    }

    this.stockSeleccionado.set(item);
    this.modoModal.set('detalle-stock-critico');
  }

  inventarioFiltrado() {
    const texto = this.busqueda().trim().toLowerCase();
    const idAlmacen = Number(this.filtroInventarioAlmacen() || 0);
    const estado = this.filtroInventarioEstado();

    return this.inventario().filter((item) => {
      const estadoItem = this.estadoStock(item).toUpperCase();
      const coincideEstado =
        !estado ||
        estadoItem === estado ||
        (estado === 'STOCK_BAJO' && estadoItem === 'STOCK_CRITICO');

      return (
        (!idAlmacen || this.idAlmacenInventario(item) === idAlmacen) &&
        coincideEstado &&
        (!texto ||
          [
            this.codigoInsumo(item),
            this.nombreInsumo(item),
            this.nombreAlmacen(item),
            this.codigoAlmacen(item),
            estadoItem,
          ]
            .join(' ')
            .toLowerCase()
            .includes(texto))
      );
    });
  }

  stockFiltrado() {
    const texto = this.busqueda().trim().toLowerCase();
    const idAlmacen = Number(this.filtroStockAlmacen() || 0);
    const estado = this.filtroStockEstado();

    return this.stockCritico().filter((item) => {
      return (
        (!idAlmacen || this.idAlmacenInventario(item) === idAlmacen) &&
        (!estado || this.estadoStock(item).toUpperCase() === estado) &&
        (!texto ||
          [
            this.codigoInsumo(item),
            this.nombreInsumo(item),
            this.nombreAlmacen(item),
            this.codigoAlmacen(item),
            this.estadoStock(item),
          ]
            .join(' ')
            .toLowerCase()
            .includes(texto))
      );
    });
  }

  movimientosFiltrados() {
    const texto = this.busqueda().trim().toLowerCase();
    const tipo = this.filtroMovimientoTipo();
    const idAlmacen = Number(this.filtroMovimientoAlmacen() || 0);

    return this.movimientos().filter((item) => {
      return (
        (!tipo || this.movimientoTipo(item) === tipo) &&
        (!idAlmacen || this.idsAlmacenesMovimiento(item).includes(idAlmacen)) &&
        this.coincideFiltroFecha(
          this.movimientoFecha(item),
          this.filtroMovimientoPeriodo(),
          this.filtroMovimientoDesde(),
          this.filtroMovimientoHasta(),
        ) &&
        (!texto ||
          [
            this.numeroMovimiento(item),
            this.movimientoTipo(item),
            this.movimientoInsumo(item),
            this.movimientoAlmacen(item),
            this.referenciaMovimiento(item),
            this.movimientoMotivo(item),
          ]
            .join(' ')
            .toLowerCase()
            .includes(texto))
      );
    });
  }

  despachosFiltrados() {
    const texto = this.busqueda().trim().toLowerCase();
    const estado = this.filtroDespachoEstado();
    const idAlmacen = Number(this.filtroDespachoAlmacen() || 0);
    const idArea = Number(this.filtroDespachoArea() || 0);

    return this.despachos().filter((item) => {
      return (
        (!estado || this.estadoDespacho(item) === estado) &&
        (!idAlmacen || this.idAlmacenDespacho(item) === idAlmacen) &&
        (!idArea || this.idAreaDespacho(item) === idArea) &&
        this.coincideFiltroFecha(
          this.fechaDespacho(item),
          this.filtroDespachoPeriodo(),
          this.filtroDespachoDesde(),
          this.filtroDespachoHasta(),
        ) &&
        (!texto ||
          [
            this.numeroDespacho(item),
            this.numeroPedidoDespacho(item),
            this.areaSolicitanteDespacho(item),
            this.solicitanteDespacho(item),
            this.almacenOrigen(item),
            this.estadoDespacho(item),
          ]
            .join(' ')
            .toLowerCase()
            .includes(texto))
      );
    });
  }

  almacenesDisponibles() {
    const almacenes = new Map<
      number,
      { idAlmacen: number; codigoAlmacen: string; nombreAlmacen: string }
    >();

    const agregar = (id: number, nombre: string, codigo = '') => {
      if (!id) {
        return;
      }

      const actual = almacenes.get(id);
      almacenes.set(id, {
        idAlmacen: id,
        codigoAlmacen: codigo || actual?.codigoAlmacen || '',
        nombreAlmacen: nombre || actual?.nombreAlmacen || `Almacen ${id}`,
      });
    };

    this.almacenes().forEach((almacen: any) => {
      agregar(
        Number(almacen.idAlmacen || almacen.id_almacen || almacen.id || 0),
        String(almacen.nombreAlmacen || almacen.nombre_almacen || almacen.nombre || ''),
        String(almacen.codigoAlmacen || almacen.codigo_almacen || almacen.codigo || ''),
      );
    });

    [...this.inventario(), ...this.stockCritico()].forEach((item) => {
      agregar(this.idAlmacenInventario(item), this.nombreAlmacen(item), this.codigoAlmacen(item));
    });

    this.despachos().forEach((despacho) => {
      agregar(this.idAlmacenDespacho(despacho), this.almacenOrigen(despacho));
    });

    return [...almacenes.values()].sort((a, b) =>
      a.nombreAlmacen.localeCompare(b.nombreAlmacen, 'es'),
    );
  }

  areasDisponibles() {
    const areas = new Map<number, { idArea: number; nombreArea: string }>();

    const agregar = (id: number, nombre: string) => {
      if (!id) {
        return;
      }

      const actual = areas.get(id);
      areas.set(id, {
        idArea: id,
        nombreArea: nombre || actual?.nombreArea || `Area ${id}`,
      });
    };

    this.areasSistema().forEach((area: any) => {
      agregar(
        Number(area.idArea || area.id_area || area.id || 0),
        String(area.nombreArea || area.nombre_area || area.nombre || ''),
      );
    });

    this.pedidosAprobados().forEach((pedido: any) => {
      const area = pedido.areaSolicitante || pedido.area || {};
      agregar(
        Number(pedido.idAreaSolicitante || pedido.id_area_solicitante || area.idArea || area.id_area || area.id || 0),
        this.nombreAreaPedido(pedido),
      );
    });

    this.despachos().forEach((despacho) => {
      agregar(this.idAreaDespacho(despacho), this.areaSolicitanteDespacho(despacho));
    });

    return [...areas.values()].sort((a, b) => a.nombreArea.localeCompare(b.nombreArea, 'es'));
  }

  limpiarFiltros() {
    this.busqueda.set('');

    if (this.tabActual() === 'inventario') {
      this.filtroInventarioAlmacen.set('');
      this.filtroInventarioEstado.set('');
    } else if (this.tabActual() === 'stock') {
      this.filtroStockAlmacen.set('');
      this.filtroStockEstado.set('');
    } else if (this.tabActual() === 'movimientos') {
      this.filtroMovimientoPeriodo.set('todos');
      this.filtroMovimientoDesde.set('');
      this.filtroMovimientoHasta.set('');
      this.filtroMovimientoTipo.set('');
      this.filtroMovimientoAlmacen.set('');
    } else {
      this.filtroDespachoPeriodo.set('todos');
      this.filtroDespachoDesde.set('');
      this.filtroDespachoHasta.set('');
      this.filtroDespachoEstado.set('');
      this.filtroDespachoAlmacen.set('');
      this.filtroDespachoArea.set('');
    }
  }

  tiposMovimientoDisponibles(): string[] {
    return [...new Set(this.movimientos().map((item) => this.movimientoTipo(item)))].sort();
  }

  estadosDespachoDisponibles(): string[] {
    return [...new Set(this.despachos().map((item) => this.estadoDespacho(item)))].sort();
  }

  private coincideFiltroFecha(
    fecha: string,
    periodo: PeriodoFecha,
    desde: string,
    hasta: string,
  ): boolean {
    const clave = this.claveFechaBolivia(fecha);

    if (!clave) {
      return periodo === 'todos' && !desde && !hasta;
    }

    if ((desde && clave < desde) || (hasta && clave > hasta)) {
      return false;
    }

    const hoy = this.claveFechaBolivia(new Date());

    if (!hoy || periodo === 'todos') {
      return true;
    }

    if (periodo === 'hoy') {
      return clave === hoy;
    }

    if (periodo === 'mes') {
      return clave.slice(0, 7) === hoy.slice(0, 7);
    }

    if (periodo === 'anio') {
      return clave.slice(0, 4) === hoy.slice(0, 4);
    }

    const hoyUtc = new Date(`${hoy}T00:00:00Z`);
    const diaSemana = hoyUtc.getUTCDay() || 7;
    const inicio = new Date(hoyUtc);
    const fin = new Date(hoyUtc);
    inicio.setUTCDate(hoyUtc.getUTCDate() - diaSemana + 1);
    fin.setUTCDate(inicio.getUTCDate() + 6);

    return clave >= inicio.toISOString().slice(0, 10) && clave <= fin.toISOString().slice(0, 10);
  }

  private claveFechaBolivia(fecha: string | Date): string {
    if (typeof fecha === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(fecha)) {
      return fecha;
    }

    const valor =
      typeof fecha === 'string' &&
      /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,3})?)?$/.test(fecha)
        ? `${fecha}Z`
        : fecha;
    const fechaValida = valor instanceof Date ? valor : new Date(valor);

    if (Number.isNaN(fechaValida.getTime())) {
      return '';
    }

    const partes = new Intl.DateTimeFormat('en-CA', {
      timeZone: 'America/La_Paz',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).formatToParts(fechaValida);
    const parte = (tipo: Intl.DateTimeFormatPartTypes) =>
      partes.find((item) => item.type === tipo)?.value || '';

    return `${parte('year')}-${parte('month')}-${parte('day')}`;
  }

  idUsuarioActual(): number | undefined {
    const usuario = this.authState.usuario() as { idUsuario?: number; id_usuario?: number } | null;
    return usuario?.idUsuario || usuario?.id_usuario;
  }

  limpiarMensajes() {
    this.error.set('');
    this.mensaje.set('');
  }

  tienePermiso(permiso: string): boolean {
    return this.permissionService.tienePermiso(permiso);
  }

  puedeVerTab(tab: TabInventario): boolean {
    return this.tienePermiso(this.permisoTab(tab));
  }

  permisoTab(tab: TabInventario): string {
    const permisos: Record<TabInventario, string> = {
      inventario: 'inventario.ver',
      stock: 'inventario.ver_stock_critico',
      movimientos: 'inventario.ver_movimientos',
      despachos: 'despachos.ver',
    };

    return permisos[tab];
  }

  private verificarPermiso(permiso: string): boolean {
    if (this.permissionService.tienePermiso(permiso)) {
      return true;
    }

    this.error.set(this.permissionService.mensajeSinPermiso);
    window.alert(this.permissionService.mensajeSinPermiso);
    return false;
  }

  operacionCompletada(mensaje: string) {
    this.guardando.set(false);
    this.mensaje.set(mensaje);
    this.cerrarModal();
    this.cargarDatos();
  }

  operacionFallida(error: unknown) {
    this.guardando.set(false);
    this.error.set(this.obtenerMensajeErrorBackend(error));
  }

  obtenerMensajeErrorBackend(error: unknown): string {
    const data = error as { error?: { message?: string | string[]; error?: string } };
    const mensaje = mensajeErrorBackend(error, this.etiquetasFormulario);

    if (Array.isArray(mensaje)) {
      return mensaje.join(' | ');
    }

    if (typeof mensaje === 'string') {
      return mensaje;
    }

    return data.error?.error || 'No se pudo completar la operacion.';
  }

  codigoInsumo(item: InventarioItem): string {
    return String(
      item.codigoInterno ||
        item.codigo_interno ||
        item.insumo?.codigoInterno ||
        item.insumo?.codigo_interno ||
        'Sin codigo',
    );
  }

  nombreInsumo(item: InventarioItem): string {
    return String(
      item.nombreInsumo ||
        item.nombre_insumo ||
        item.insumo?.nombreInsumo ||
        item.insumo?.nombre_insumo ||
        'Sin insumo',
    );
  }

  nombreAlmacen(item: InventarioItem): string {
    return String(
      item.nombreAlmacen ||
        item.nombre_almacen ||
        item.almacen?.nombreAlmacen ||
        item.almacen?.nombre_almacen ||
        'Sin almacen',
    );
  }

  codigoAlmacen(item: InventarioItem): string {
    return String(
      item.almacen?.codigoAlmacen ||
        item.almacen?.codigo_almacen ||
        item.tipoAlmacen ||
        item.tipo_almacen ||
        '',
    );
  }

  idInventario(item: InventarioItem): number {
    return Number(item.idInventario || item.id_inventario || 0);
  }

  idInsumoInventario(item: InventarioItem): number {
    return Number(
      item.idInsumo || item.id_insumo || item.insumo?.idInsumo || item.insumo?.id_insumo || 0,
    );
  }

  idAlmacenInventario(item: InventarioItem): number {
    return Number(
      item.idAlmacen || item.id_almacen || item.almacen?.idAlmacen || item.almacen?.id_almacen || 0,
    );
  }

  stockFisico(item: InventarioItem): number {
    return Number(item.stockFisico || item.stock_fisico || 0);
  }

  stockReservado(item: InventarioItem): number {
    return Number(item.stockReservado || item.stock_reservado || 0);
  }

  stockDisponible(item: InventarioItem): number {
    const disponible = item.stockDisponible ?? item.stock_disponible;
    return disponible !== undefined
      ? Number(disponible)
      : this.stockFisico(item) - this.stockReservado(item);
  }

  estadoStock(item: InventarioItem): string {
    return String(item.estadoStock || item.estado_stock || item.estado || 'DISPONIBLE');
  }

  stockMinimo(item: InventarioItem): number {
    return Number(item.stock_minimo ?? item.stockMinimo ?? 0);
  }

  diferenciaStock(item: InventarioItem): number {
    return this.stockDisponible(item) - this.stockMinimo(item);
  }

  unidadMedidaStock(item: InventarioItem): string {
    const unidad = item.insumo?.unidadMedida;
    return String(unidad?.abreviatura || unidad?.nombreUnidad || unidad?.nombre_unidad || '');
  }

  categoriaStock(item: InventarioItem): string {
    return String(
      item.insumo?.categoria?.nombreCategoria ||
        item.insumo?.categoria?.nombre_categoria ||
        '',
    );
  }

  ultimoMovimientoStock(item: InventarioItem): string {
    return String(item.fechaUltimaActualizacion || item.fecha_ultima_actualizacion || '');
  }

  recomendacionStock(item: InventarioItem): string {
    const disponible = this.stockDisponible(item);
    const minimo = this.stockMinimo(item);

    if (disponible < minimo) {
      return 'Reponer stock — Stock crítico';
    }

    if (disponible === minimo) {
      return 'Reponer stock — Stock en límite mínimo';
    }

    return 'Stock suficiente';
  }

  stockDisponibleInsumoAlmacen(idInsumo: number, idAlmacen: number): number {
    const item = this.inventario().find(
      (registro) =>
        this.idInsumoInventario(registro) === idInsumo &&
        this.idAlmacenInventario(registro) === idAlmacen,
    );

    return item ? this.stockDisponible(item) : 0;
  }

  movimientoTipo(item: MovimientoInventario): string {
    return this.etiquetaOperativa(item.tipoMovimiento || item.tipo_movimiento || 'Sin tipo');
  }

  numeroMovimiento(item: MovimientoInventario): string {
    const data = item as Record<string, unknown>;
    return String(
      data['numeroMovimiento'] ||
        data['numero_movimiento'] ||
        item.codigoReferencia ||
        item.codigo_referencia ||
        '',
    );
  }

  idsAlmacenesMovimiento(item: MovimientoInventario): number[] {
    const data = item as Record<string, any>;
    return [
      item.idAlmacen,
      item.id_almacen,
      item.almacen?.idAlmacen,
      item.almacen?.id_almacen,
      item.almacenOrigen?.idAlmacen,
      item.almacenDestino?.idAlmacen,
      data['idAlmacenOrigen'],
      data['idAlmacenDestino'],
      data['id_almacen_origen'],
      data['id_almacen_destino'],
    ]
      .map((id) => Number(id || 0))
      .filter((id) => id > 0);
  }

  movimientoInsumo(item: MovimientoInventario): string {
    const data = item as MovimientoInventario;
    return String(
      item.nombreInsumo ||
        item.nombre_insumo ||
        data.insumo?.nombreInsumo ||
        data.insumo?.nombre_insumo ||
        'Sin insumo',
    );
  }

  movimientoAlmacen(item: MovimientoInventario): string {
    const data = item as MovimientoInventario;
    return String(
      item.nombreAlmacen ||
        item.nombre_almacen ||
        data.almacen?.nombreAlmacen ||
        data.almacen?.nombre_almacen ||
        'Sin almacen',
    );
  }

  movimientoCantidad(item: MovimientoInventario): number {
    return Number(item.cantidad || 0);
  }

  movimientoFecha(item: MovimientoInventario): string {
    return String(item.fechaMovimiento || item.fecha_movimiento || '');
  }

  referenciaMovimiento(item: MovimientoInventario): string {
    return String(
      item.referencia || item.codigoReferencia || item.codigo_referencia || 'Sin referencia',
    );
  }

  usuarioResponsableMovimiento(item: MovimientoInventario): string {
    const usuario = item.usuarioResponsable;

    if (typeof usuario === 'object' && usuario) {
      return String(
        usuario.nombreCompleto ||
          usuario.nombre_completo ||
          usuario.nombreUsuario ||
          usuario.nombre_usuario ||
          'Sin responsable',
      );
    }

    return String(usuario || item.usuario_responsable || 'Sin responsable');
  }

  movimientoMotivo(item: MovimientoInventario): string {
    const data = item as Record<string, unknown>;
    return String(
      item.motivoMovimiento ||
        item.motivo_movimiento ||
        data['motivo'] ||
        item.observaciones ||
        'Sin motivo',
    );
  }

  idDespacho(item: Despacho): number {
    return Number(item.idDespacho || item.id_despacho || 0);
  }

  numeroDespacho(item: Despacho): string {
    return String(
      item.codigoDespacho ||
        item.numeroDespacho ||
        item.numero_despacho ||
        `DES-${this.idDespacho(item)}`,
    );
  }

  numeroPedidoDespacho(item: Despacho): string {
    const data = item as Record<string, unknown>;
    const pedido = item.pedido as Despacho['pedido'];
    return String(
      pedido?.codigoPedido || pedido?.numeroPedido || data['numeroPedido'] || 'Sin pedido',
    );
  }

  areaSolicitanteDespacho(item: Despacho): string {
    const data = item as Record<string, unknown>;
    const pedido = item.pedido as Despacho['pedido'];
    const areaDestino = data['areaDestino'] as
      { nombreArea?: string; nombre_area?: string } | undefined;

    return String(
      pedido?.area?.nombreArea ||
        areaDestino?.nombreArea ||
        areaDestino?.nombre_area ||
        item.areaDestino ||
        item.area_destino ||
        'Sin area',
    );
  }

  solicitanteDespacho(item: Despacho): string {
    const data = item as Record<string, unknown>;
    const pedido = item.pedido as Despacho['pedido'];
    const solicitante = data['solicitante'] as
      { nombreCompleto?: string; nombreUsuario?: string } | undefined;

    return String(
      pedido?.solicitante?.nombreCompleto ||
        pedido?.solicitante?.nombreUsuario ||
        solicitante?.nombreCompleto ||
        solicitante?.nombreUsuario ||
        item.usuarioSolicitante ||
        item.usuario_solicitante ||
        'Sin solicitante',
    );
  }

  almacenOrigen(item: Despacho): string {
    const data = item as Record<string, unknown>;
    const almacen = (item.almacenSalida || data['almacenOrigen']) as
      { nombreAlmacen?: string; codigoAlmacen?: string } | undefined;

    return String(
      almacen?.nombreAlmacen ||
        almacen?.codigoAlmacen ||
        item.almacenOrigen ||
        item.almacen_origen ||
        'Sin almacen',
    );
  }

  idAlmacenDespacho(item: Despacho): number {
    const data = item as Record<string, any>;
    const almacen = item.almacenSalida || data['almacenOrigen'];
    return Number(
      almacen?.idAlmacen ||
        data['idAlmacenSalida'] ||
        data['id_almacen_salida'] ||
        item.idAlmacenOrigen ||
        item.id_almacen_origen ||
        0,
    );
  }

  idAreaDespacho(item: Despacho): number {
    const data = item as Record<string, any>;
    return Number(
      item.pedido?.area?.idArea ||
        item.pedido?.areaSolicitante?.idArea ||
        data['areaDestino']?.idArea ||
        data['idAreaSolicitante'] ||
        data['id_area_solicitante'] ||
        0,
    );
  }

  usuarioResponsableDespacho(item: Despacho): string {
    const responsable = item.responsableAlmacen;
    return String(
      responsable?.nombreCompleto ||
        responsable?.nombreUsuario ||
        item.usuarioResponsable ||
        item.usuario_responsable ||
        'Sin responsable',
    );
  }

  fechaDespacho(item: Despacho): string {
    const data = item as Record<string, unknown>;
    return String(item.fechaDespacho || item.fecha_despacho || data['fechaRealEntrega'] || '');
  }

  estadoDespacho(item: Despacho): string {
    return this.etiquetaOperativa(item.estadoDespacho || item.estado_despacho || 'Sin estado');
  }

  detallesDespacho(item: Despacho): unknown[] {
    return item.detalles || [];
  }

  detalleCodigo(detalle: unknown): string {
    const data = detalle as Record<string, any>;
    return String(
      data['codigoInterno'] ||
        data['codigo_interno'] ||
        data['insumo']?.codigoInterno ||
        'Sin codigo',
    );
  }

  detalleInsumo(detalle: unknown): string {
    const data = detalle as Record<string, any>;
    return String(
      data['nombreInsumo'] || data['nombre_insumo'] || data['insumo']?.nombreInsumo || 'Sin insumo',
    );
  }

  detalleCantidadEntregada(detalle: unknown): number {
    const data = detalle as Record<string, unknown>;
    return Number(
      data['cantidadEntregada'] || data['cantidad_entregada'] || data['cantidadDespachada'] || 0,
    );
  }

  detalleCantidadSolicitada(detalle: unknown): number {
    const data = detalle as Record<string, unknown>;
    return Number(data['cantidadSolicitada'] ?? data['cantidad_solicitada'] ?? 0);
  }

  detalleCantidadPendienteAntes(detalle: unknown): number {
    const data = detalle as Record<string, unknown>;
    return Number(data['cantidadAprobada'] ?? data['cantidad_aprobada'] ?? 0);
  }

  detalleCantidadPendienteDespues(detalle: unknown): number {
    const data = detalle as Record<string, unknown>;
    const pendiente = data['cantidadPendiente'] ?? data['cantidad_pendiente'];

    return pendiente !== undefined
      ? Number(pendiente)
      : Math.max(
          this.detalleCantidadPendienteAntes(detalle) -
            this.detalleCantidadEntregada(detalle),
          0,
        );
  }

  detalleObservacion(detalle: unknown): string {
    const data = detalle as Record<string, unknown>;
    return String(
      data['observaciones'] || data['observacion'] || 'Sin observación del insumo',
    );
  }

  esDespachoParcial(despacho: Despacho): boolean {
    return this.estadoDespacho(despacho).toUpperCase().includes('PARCIAL');
  }

  motivoEntregaParcial(despacho: Despacho): string {
    return despacho.observaciones?.trim() || 'Motivo no registrado en este despacho.';
  }

  esDespachoParcialSeleccionado(): boolean {
    const pedido = this.pedidoSeleccionado();

    if (!pedido) {
      return false;
    }

    const totalPendiente = pedido.detalles.reduce(
      (total, detalle) => total + this.cantidadPendienteDetallePedido(detalle),
      0,
    );
    const totalAEntregar = pedido.detalles.reduce((total, detalle) => {
      const cantidad = Number(
        this.cantidadesDespacho()[this.detalleDespachoKey(detalle)] || 0,
      );
      return total + (Number.isFinite(cantidad) && cantidad > 0 ? cantidad : 0);
    }, 0);

    return totalAEntregar > 0 && totalAEntregar < totalPendiente;
  }

  textoLimpio(valor: any, fallback = 'Sin dato'): string {
    if (valor === null || valor === undefined) {
      return fallback;
    }

    if (typeof valor === 'object') {
      const texto =
        valor.nombreAreaSolicitante ||
        valor.areaSolicitanteNombre ||
        valor.nombreUsuarioSolicitante ||
        valor.usuarioSolicitanteNombre ||
        valor.nombreCompleto ||
        valor.nombre_completo ||
        valor.nombreUsuario ||
        valor.nombre_usuario ||
        valor.nombreArea ||
        valor.nombre_area ||
        valor.nombre ||
        valor.descripcion ||
        valor.codigo;

      return this.textoLimpio(texto, fallback);
    }

    const texto = String(valor).trim();
    return texto && texto !== '[object Object]' && texto.toLowerCase() !== 'null'
      ? texto
      : fallback;
  }

  etiquetaOperativa(valor: any): string {
    return this.textoLimpio(valor, 'Sin dato')
      .replace(/[_-]+/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  numeroFinito(valor: unknown): number | null {
    if (valor === null || valor === undefined || valor === '') {
      return null;
    }

    const numero = Number(valor);
    return Number.isFinite(numero) ? numero : null;
  }

  numeroPositivo(valor: unknown): number {
    const numero = this.numeroFinito(valor);
    return numero !== null && numero > 0 ? numero : 0;
  }

  cantidadSolicitadaDetallePedido(detalle: any): number {
    return (
      this.numeroPositivo(detalle?.cantidadSolicitada) ||
      this.numeroPositivo(detalle?.cantidad_solicitada) ||
      this.numeroPositivo(detalle?.cantidadPedida) ||
      this.numeroPositivo(detalle?.cantidad_pedida) ||
      this.numeroPositivo(detalle?.cantidadRequerida) ||
      this.numeroPositivo(detalle?.cantidad_requerida) ||
      this.numeroPositivo(detalle?.cantidad) ||
      this.numeroPositivo(detalle?.cantidadAprobada) ||
      this.numeroPositivo(detalle?.cantidad_aprobada)
    );
  }

  cantidadAprobadaDetallePedido(detalle: any): number {
    return (
      this.numeroPositivo(detalle?.cantidadAprobada) ||
      this.numeroPositivo(detalle?.cantidad_aprobada) ||
      this.cantidadSolicitadaDetallePedido(detalle)
    );
  }

  cantidadDespachadaDetallePedido(detalle: any): number {
    return (
      this.numeroPositivo(detalle?.cantidadDespachada) ||
      this.numeroPositivo(detalle?.cantidad_despachada) ||
      this.numeroPositivo(detalle?.cantidadEntregada) ||
      this.numeroPositivo(detalle?.cantidad_entregada) ||
      this.numeroPositivo(detalle?.cantidadAtendida) ||
      this.numeroPositivo(detalle?.cantidad_atendida)
    );
  }

  cantidadPendienteDetallePedido(detalle: any): number {
    const pendienteDirecto =
      this.numeroFinito(detalle?.cantidadPendiente) ??
      this.numeroFinito(detalle?.cantidad_pendiente) ??
      this.numeroFinito(detalle?.pendiente);

    if (pendienteDirecto !== null && pendienteDirecto > 0) {
      return pendienteDirecto;
    }

    const base = this.cantidadAprobadaDetallePedido(detalle);
    const despachada = this.cantidadDespachadaDetallePedido(detalle);

    return Math.max(base - despachada, 0);
  }

  cantidadesInicialesPedido(pedido: PedidoAprobadoDespacho): Record<string, string> {
    const cantidades: Record<string, string> = {};

    for (const detalle of pedido.detalles || []) {
      const key = this.detalleDespachoKey(detalle);
      const pendiente = this.cantidadPendienteDetallePedido(detalle);

      if (key && pendiente > 0) {
        cantidades[key] = String(pendiente);
      }
    }

    return cantidades;
  }

  detalleDespachoKey(detalle: PedidoDespachoDetalle): string {
    return String(detalle.idPedidoDetalle || detalle.idInsumo || detalle.insumo?.idInsumo || '');
  }

  idInsumoDetallePedido(detalle: PedidoDespachoDetalle): number {
    return Number(detalle.idInsumo || detalle.insumo?.idInsumo || 0);
  }

  codigoDetallePedido(detalle: PedidoDespachoDetalle): string {
    return String(detalle.insumo?.codigoInterno || 'Sin codigo');
  }

  nombreDetallePedido(detalle: PedidoDespachoDetalle): string {
    return String(detalle.insumo?.nombreInsumo || 'Sin insumo');
  }

  stockDisponibleDetallePedido(detalle: PedidoDespachoDetalle): number {
    const idAlmacen = Number(this.formDespacho.controls.idAlmacenSalida.value || 0);
    const reservas = detalle.reservasStock || [];

    if (reservas.length > 0) {
      return reservas
        .filter((reserva) => Number(reserva.idAlmacen) === idAlmacen)
        .reduce((total, reserva) => total + Number(reserva.cantidadReservada || 0), 0);
    }

    return this.stockDisponibleInsumoAlmacen(this.idInsumoDetallePedido(detalle), idAlmacen);
  }

  labelPedidoAprobado(pedido: PedidoAprobadoDespacho): string {
    return `${pedido.codigoPedido || pedido.numeroPedido || 'Sin pedido'} - ${this.nombreAreaPedido(pedido)} - ${this.nombreSolicitantePedido(pedido)}`;
  }

  nombreSolicitantePedido(pedido: PedidoAprobadoDespacho): string {
    const data = pedido as any;

    return String(
      data.nombreUsuarioSolicitante ||
        data.usuarioSolicitanteNombre ||
        this.textoLimpio(data.usuarioSolicitante, '') ||
        this.textoLimpio(data.solicitante, '') ||
        (data.idUsuarioSolicitante ? `Usuario ${data.idUsuarioSolicitante}` : '') ||
        'Solicitante',
    );
  }

  nombreAreaPedido(pedido: PedidoAprobadoDespacho): string {
    const data = pedido as any;

    return String(
      data.nombreAreaSolicitante ||
        data.areaSolicitanteNombre ||
        this.textoLimpio(data.areaSolicitante, '') ||
        this.textoLimpio(data.area, '') ||
        (data.idAreaSolicitante ? `Area ${data.idAreaSolicitante}` : '') ||
        'Sin area',
    );
  }

  fechaFormateada(fecha: string): string {
    return formatearFechaHoraBolivia(fecha);
  }

  claseStock(estado: string): string {
    const normalizado = estado.toUpperCase();

    if (normalizado.includes('SIN') || normalizado.includes('AGOTADO')) {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    if (normalizado.includes('BAJO') || normalizado.includes('CRITICO')) {
      return 'bg-orange-100 text-orange-700 border-orange-200';
    }

    return 'bg-green-100 text-green-700 border-green-200';
  }

  claseMovimiento(tipo: string): string {
    const normalizado = tipo.toUpperCase();

    if (
      normalizado.includes('ENTRADA') ||
      normalizado.includes('POSITIVO') ||
      normalizado.includes('DEVOLUCION')
    ) {
      return 'bg-green-100 text-green-700 border-green-200';
    }

    if (normalizado.includes('SALIDA') || normalizado.includes('NEGATIVO')) {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    return 'bg-blue-100 text-blue-700 border-blue-200';
  }

  claseDespacho(estado: string): string {
    const normalizado = estado.toUpperCase();

    if (normalizado.includes('COMPLETO')) {
      return 'bg-green-100 text-green-700 border-green-200';
    }

    if (normalizado.includes('PARCIAL') || normalizado.includes('PENDIENTE')) {
      return 'bg-orange-100 text-orange-700 border-orange-200';
    }

    return 'bg-blue-100 text-blue-700 border-blue-200';
  }
}
