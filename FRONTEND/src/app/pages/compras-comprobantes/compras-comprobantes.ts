import { Component, computed, inject, signal } from '@angular/core';
import {
  AbstractControl,
  FormBuilder,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { catchError, forkJoin, of } from 'rxjs';
import type { jsPDF } from 'jspdf';

import { ComprasComprobantesService } from '../../core/services/compras-comprobantes.service';
import { PedidosService } from '../../core/services/pedidos.service';
import { ProveedoresService } from '../../core/services/proveedores.service';
import { InsumosService } from '../../core/services/insumos.service';
import { AlmacenesService } from '../../core/services/almacenes.service';
import { ConfirmacionAccionService } from '../../core/feedback/confirmacion-accion.service';
import { PermissionService } from '../../core/services/permission.service';
import { AuthState } from '../../core/state/auth.state';

import {
  ComprobanteCompra,
  OrdenCompra,
  RecepcionCompra,
} from '../../core/models/compras-comprobantes.model';
import { Pedido } from '../../core/models/pedido.model';
import { Proveedor } from '../../core/models/proveedor.model';
import { Insumo } from '../../core/models/insumo.model';
import { Almacen } from '../../core/models/almacen.model';
import {
  convertirDatetimeLocalParaBackend,
  convertirFechaBackendADatetimeLocal,
  formatearFechaHoraBolivia,
} from '../../core/utils/fecha.util';
import {
  TIPOS_COMPROBANTE,
  documentoRespaldoValidator,
  totalConDescuento,
  validarArchivoRecepcion,
} from '../../core/forms/professional-forms';
import {
  FormFieldLabels,
  marcarFormularioInvalido,
  mensajeErrorBackend,
} from '../../core/forms/form-error-messages';
import { CampoValidacionDirective } from '../../core/forms/campo-validacion.directive';

type TabCompras = 'ordenes' | 'recepciones' | 'comprobantes';
type FechaRapida = 'todos' | 'hoy' | 'semana' | 'mes' | 'anio';

type ModoModal =
  | 'ninguno'
  | 'orden'
  | 'recepcion'
  | 'comprobante'
  | 'nueva-orden'
  | 'nueva-recepcion'
  | 'nuevo-comprobante';

interface DetalleOrdenForm {
  idInsumo: string;
  cantidad: string;
  precioUnitario: string;
  observaciones: string;
}

interface DetalleRecepcionForm {
  idInsumo: string;
  cantidadRecibida: string;
  cantidadRechazada: string;
  estadoConformidad: 'CONFORME' | 'OBSERVADO' | 'RECHAZADO';
  motivoRechazo: string;
  observaciones: string;
}

@Component({
  selector: 'app-compras-comprobantes',
  standalone: true,
  imports: [ReactiveFormsModule, CampoValidacionDirective],
  templateUrl: './compras-comprobantes.html',
  styleUrl: './compras-comprobantes.css',
})
export class ComprasComprobantes {
  private readonly comprasService = inject(ComprasComprobantesService);
  private readonly pedidosService = inject(PedidosService);
  private readonly proveedoresService = inject(ProveedoresService);
  private readonly insumosService = inject(InsumosService);
  private readonly almacenesService = inject(AlmacenesService);
  private readonly confirmacionAccionService = inject(ConfirmacionAccionService);
  private readonly permissionService = inject(PermissionService);
  private readonly authState = inject(AuthState);
  private readonly formBuilder = inject(FormBuilder);
  private readonly etiquetasFormulario: FormFieldLabels = {
    idPedido: 'Pedido',
    idProveedor: 'Proveedor',
    fechaEntregaEstimada: 'Fecha estimada de entrega',
    fechaEstimadaEntrega: 'Fecha estimada de entrega',
    condicionPago: 'Condicion de pago',
    formaPago: 'Forma de pago',
    moneda: 'Moneda',
    descuento: 'Descuento',
    observaciones: 'Observaciones',
    idOrdenCompra: 'Orden de compra',
    idAlmacen: 'Almacen destino',
    idAlmacenDestino: 'Almacen destino',
    fechaRecepcion: 'Fecha de recepcion',
    fechaRealRecepcion: 'Fecha de recepcion',
    documentoRespaldo: 'Documento de respaldo',
    archivoRespaldo: 'Archivo de respaldo',
    tipoComprobante: 'Tipo de comprobante',
    numeroComprobante: 'Numero de comprobante',
    fechaEmision: 'Fecha de emision',
    fechaComprobante: 'Fecha de emision',
    montoSubtotal: 'Monto subtotal',
    montoDescuento: 'Monto descuento',
  };

  cargando = signal(false);
  guardando = signal(false);
  error = signal('');
  mensaje = signal('');
  busqueda = signal('');

  tabActual = signal<TabCompras>('ordenes');

  ordenes = signal<OrdenCompra[]>([]);
  recepciones = signal<RecepcionCompra[]>([]);
  comprobantes = signal<ComprobanteCompra[]>([]);

  pedidos = signal<Pedido[]>([]);
  pedidoOrdenSeleccionado = signal<Pedido | null>(null);
  proveedores = signal<Proveedor[]>([]);
  insumos = signal<Insumo[]>([]);
  almacenes = signal<Almacen[]>([]);

  modoModal = signal<ModoModal>('ninguno');

  ordenSeleccionada = signal<OrdenCompra | null>(null);
  recepcionSeleccionada = signal<RecepcionCompra | null>(null);
  comprobanteSeleccionado = signal<ComprobanteCompra | null>(null);

  fechaRapidaOrdenes = signal<FechaRapida>('todos');
  fechaDesdeOrdenes = signal('');
  fechaHastaOrdenes = signal('');
  estadoFiltroOrdenes = signal('');
  proveedorFiltroOrdenes = signal('');
  pedidoFiltroOrdenes = signal('');

  fechaRapidaRecepciones = signal<FechaRapida>('todos');
  fechaDesdeRecepciones = signal('');
  fechaHastaRecepciones = signal('');
  estadoFiltroRecepciones = signal('');
  proveedorFiltroRecepciones = signal('');
  ordenFiltroRecepciones = signal('');

  fechaRapidaComprobantes = signal<FechaRapida>('todos');
  fechaDesdeComprobantes = signal('');
  fechaHastaComprobantes = signal('');
  tipoFiltroComprobantes = signal('');
  estadoFiltroComprobantes = signal('');
  proveedorFiltroComprobantes = signal('');

  detallesOrden = signal<DetalleOrdenForm[]>([]);
  detallesRecepcion = signal<DetalleRecepcionForm[]>([]);
  archivoRecepcion = signal('');
  archivoRecepcionError = signal('');
  detallesOrdenIntentoGuardar = signal(false);
  detallesRecepcionIntentoGuardar = signal(false);

  modalAbierto = computed(() => this.modoModal() !== 'ninguno');

  totalOrdenes = computed(() => this.ordenes().length);
  totalRecepciones = computed(() => this.recepciones().length);
  totalComprobantes = computed(() => this.comprobantes().length);

  pedidosEnCompra = computed(() =>
    this.pedidos().filter((pedido) => {
      const data = pedido as any;
      return this.normalizarEstado(
        data.estadoPedido || data.estado_pedido || data.estado,
      ) === 'EN_COMPRA';
    }),
  );

  montoTotalComprobantes = computed(() => {
    return this.comprobantes().reduce((total, item) => {
      return total + Number(this.montoComprobante(item) || 0);
    }, 0);
  });

  ordenesFiltradas = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();
    return this.ordenes().filter((item) => {
      return (
        this.coincideTexto(
          texto,
          this.numeroOrden(item),
          this.proveedorOrden(item),
          this.pedidoOrden(item),
        ) &&
        this.coincideFecha(
          this.fechaOrden(item),
          this.fechaRapidaOrdenes(),
          this.fechaDesdeOrdenes(),
          this.fechaHastaOrdenes(),
        ) &&
        this.coincideValor(this.estadoOrden(item), this.estadoFiltroOrdenes()) &&
        this.coincideValor(
          String(this.idProveedorOrden(item)),
          this.proveedorFiltroOrdenes(),
        ) &&
        this.coincideValor(
          String(this.idPedidoOrden(item)),
          this.pedidoFiltroOrdenes(),
        )
      );
    });
  });

  recepcionesFiltradas = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();
    return this.recepciones().filter((item) => {
      return (
        this.coincideTexto(
          texto,
          this.numeroRecepcion(item),
          this.numeroOrdenRecepcion(item),
          this.proveedorRecepcion(item),
        ) &&
        this.coincideFecha(
          this.fechaRecepcion(item),
          this.fechaRapidaRecepciones(),
          this.fechaDesdeRecepciones(),
          this.fechaHastaRecepciones(),
        ) &&
        this.coincideValor(
          this.estadoRecepcion(item),
          this.estadoFiltroRecepciones(),
        ) &&
        this.coincideValor(
          String(this.idProveedorRecepcion(item)),
          this.proveedorFiltroRecepciones(),
        ) &&
        this.coincideValor(
          String(this.idOrdenRecepcion(item)),
          this.ordenFiltroRecepciones(),
        )
      );
    });
  });

  comprobantesFiltrados = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();
    return this.comprobantes().filter((item) => {
      return (
        this.coincideTexto(
          texto,
          this.numeroComprobante(item),
          this.proveedorComprobante(item),
          this.numeroOrdenComprobante(item),
        ) &&
        this.coincideFecha(
          this.fechaComprobante(item),
          this.fechaRapidaComprobantes(),
          this.fechaDesdeComprobantes(),
          this.fechaHastaComprobantes(),
        ) &&
        this.coincideValor(
          this.tipoComprobante(item),
          this.tipoFiltroComprobantes(),
        ) &&
        this.coincideValor(
          this.estadoComprobante(item),
          this.estadoFiltroComprobantes(),
        ) &&
        this.coincideValor(
          String(this.idProveedorComprobante(item)),
          this.proveedorFiltroComprobantes(),
        )
      );
    });
  });

  formOrden = this.formBuilder.nonNullable.group({
    idPedido: ['', [Validators.required]],
    idProveedor: ['', [Validators.required]],
    fechaEntregaEstimada: [''],
    condicionPago: ['CONTADO'],
    formaPago: ['TRANSFERENCIA'],
    moneda: ['BOB'],
    descuento: [0, [Validators.min(0)]],
    observaciones: [''],
  });

  formRecepcion = this.formBuilder.nonNullable.group({
    idOrdenCompra: ['', [Validators.required]],
    idAlmacen: ['', [Validators.required]],
    fechaRecepcion: ['', [Validators.required]],
    documentoRespaldo: ['', [Validators.maxLength(50), documentoRespaldoValidator()]],
    archivoRespaldo: [''],
    observaciones: [''],
  });

  formComprobante = this.formBuilder.nonNullable.group({
    idOrdenCompra: ['', [Validators.required]],
    tipoComprobante: ['', [Validators.required]],
    numeroComprobante: ['', [Validators.required]],
    fechaEmision: ['', [Validators.required]],
    montoSubtotal: ['', [Validators.required, Validators.min(0.01)]],
    montoDescuento: [0, [Validators.min(0)]],
    moneda: ['BOB', [Validators.required]],
    observaciones: [''],
  });

  readonly tiposComprobante = TIPOS_COMPROBANTE;
  readonly opcionesFechaRapida: Array<{ valor: FechaRapida; etiqueta: string }> = [
    { valor: 'todos', etiqueta: 'Todos' },
    { valor: 'hoy', etiqueta: 'Hoy' },
    { valor: 'semana', etiqueta: 'Esta semana' },
    { valor: 'mes', etiqueta: 'Este mes' },
    { valor: 'anio', etiqueta: 'Este año' },
  ];
  readonly estadosOrden = [
    'PENDIENTE',
    'EN_PROCESO',
    'RECIBIDA_PARCIAL',
    'RECIBIDA_COMPLETA',
    'ANULADA',
  ];
  readonly estadosRecepcion = [
    'PENDIENTE',
    'RECIBIDA_PARCIAL',
    'RECIBIDA_COMPLETA',
    'OBSERVADA',
    'RECHAZADA',
  ];
  readonly estadosComprobante = ['REGISTRADO', 'OBSERVADO', 'ANULADO'];

  ngOnInit() {
    this.cargarDatos();
  }

  cargarDatos() {
    this.cargando.set(true);
    this.error.set('');
    this.mensaje.set('');

    forkJoin({
      ordenes: this.comprasService.ordenesCompra().pipe(catchError(() => of([]))),
      recepciones: this.comprasService.recepciones().pipe(catchError(() => of([]))),
      comprobantes: this.comprasService.comprobantes().pipe(catchError(() => of([]))),
      pedidos: this.pedidosService.listar().pipe(catchError(() => of([]))),
      proveedores: this.proveedoresService.listar().pipe(catchError(() => of([]))),
      insumos: this.insumosService.listar().pipe(catchError(() => of([]))),
      almacenes: this.almacenesService.listar().pipe(catchError(() => of([]))),
    }).subscribe({
      next: (data) => {
        this.ordenes.set(data.ordenes as OrdenCompra[]);
        this.recepciones.set(data.recepciones as RecepcionCompra[]);
        this.comprobantes.set(data.comprobantes as ComprobanteCompra[]);
        this.pedidos.set(data.pedidos as Pedido[]);
        this.proveedores.set(data.proveedores as Proveedor[]);
        this.insumos.set(data.insumos as Insumo[]);
        this.almacenes.set(data.almacenes as Almacen[]);
        this.cargando.set(false);
      },
      error: () => {
        this.error.set('No se pudo cargar la información de compras y comprobantes.');
        this.cargando.set(false);
      },
    });
  }

  cambiarTab(tab: TabCompras) {
    if (!this.puedeVerTab(tab)) {
      this.verificarPermiso(this.permisoTab(tab));
      return;
    }

    this.tabActual.set(tab);
    this.busqueda.set('');
  }

  limpiarFiltros() {
    this.busqueda.set('');

    if (this.tabActual() === 'ordenes') {
      this.fechaRapidaOrdenes.set('todos');
      this.fechaDesdeOrdenes.set('');
      this.fechaHastaOrdenes.set('');
      this.estadoFiltroOrdenes.set('');
      this.proveedorFiltroOrdenes.set('');
      this.pedidoFiltroOrdenes.set('');
      return;
    }

    if (this.tabActual() === 'recepciones') {
      this.fechaRapidaRecepciones.set('todos');
      this.fechaDesdeRecepciones.set('');
      this.fechaHastaRecepciones.set('');
      this.estadoFiltroRecepciones.set('');
      this.proveedorFiltroRecepciones.set('');
      this.ordenFiltroRecepciones.set('');
      return;
    }

    this.fechaRapidaComprobantes.set('todos');
    this.fechaDesdeComprobantes.set('');
    this.fechaHastaComprobantes.set('');
    this.tipoFiltroComprobantes.set('');
    this.estadoFiltroComprobantes.set('');
    this.proveedorFiltroComprobantes.set('');
  }

  cambiarBusqueda(event: Event) {
    const input = event.target as HTMLInputElement;
    this.busqueda.set(input.value);
  }

  cerrarModal() {
    this.modoModal.set('ninguno');
    this.ordenSeleccionada.set(null);
    this.recepcionSeleccionada.set(null);
    this.comprobanteSeleccionado.set(null);
    this.pedidoOrdenSeleccionado.set(null);
    this.detallesOrden.set([]);
    this.detallesRecepcion.set([]);
    this.archivoRecepcion.set('');
    this.archivoRecepcionError.set('');
    this.detallesOrdenIntentoGuardar.set(false);
    this.detallesRecepcionIntentoGuardar.set(false);
    this.formOrden.reset();
    this.formRecepcion.reset();
    this.formComprobante.reset();
  }

  abrirNuevaOrden() {
    if (!this.verificarPermiso('compras.crear_orden')) {
      return;
    }

    this.error.set('');
    this.mensaje.set('');
    this.modoModal.set('nueva-orden');
    this.pedidoOrdenSeleccionado.set(null);

    this.formOrden.reset({
      idPedido: '',
      idProveedor: '',
      fechaEntregaEstimada: '',
      condicionPago: 'CONTADO',
      formaPago: 'TRANSFERENCIA',
      moneda: 'BOB',
      descuento: 0,
      observaciones: '',
    });

    this.detallesOrden.set([
      {
        idInsumo: '',
        cantidad: '',
        precioUnitario: '',
        observaciones: '',
      },
    ]);
    this.detallesOrdenIntentoGuardar.set(false);
  }

  abrirNuevaRecepcion() {
    if (!this.verificarPermiso('recepciones.crear')) {
      return;
    }

    this.error.set('');
    this.mensaje.set('');
    this.modoModal.set('nueva-recepcion');
    this.archivoRecepcion.set('');
    this.archivoRecepcionError.set('');

    this.formRecepcion.reset({
      idOrdenCompra: '',
      idAlmacen: '',
      fechaRecepcion: this.ahoraDatetimeLocalBolivia(),
      documentoRespaldo: '',
      archivoRespaldo: '',
      observaciones: '',
    });

    this.detallesRecepcion.set([
      {
        idInsumo: '',
        cantidadRecibida: '',
        cantidadRechazada: '0',
        estadoConformidad: 'CONFORME',
        motivoRechazo: '',
        observaciones: '',
      },
    ]);
    this.detallesRecepcionIntentoGuardar.set(false);
  }

  abrirNuevoComprobante() {
    if (!this.verificarPermiso('comprobantes.crear')) {
      return;
    }

    this.error.set('');
    this.mensaje.set('');
    this.modoModal.set('nuevo-comprobante');

    this.formComprobante.reset({
      idOrdenCompra: '',
      tipoComprobante: '',
      numeroComprobante: '',
      fechaEmision: this.ahoraDatetimeLocalBolivia(),
      montoSubtotal: '',
      montoDescuento: 0,
      moneda: 'BOB',
      observaciones: '',
    });
  }

  agregarDetalleOrden() {
    this.detallesOrden.update((items) => [
      ...items,
      {
        idInsumo: '',
        cantidad: '',
        precioUnitario: '',
        observaciones: '',
      },
    ]);
  }

  quitarDetalleOrden(index: number) {
    this.detallesOrden.update((items) => items.filter((_, i) => i !== index));
  }

  cambiarDetalleOrden(index: number, campo: keyof DetalleOrdenForm, event: Event) {
    const input = event.target as HTMLInputElement | HTMLSelectElement;

    this.detallesOrden.update((items) => {
      const copia = [...items];
      const precioSugerido =
        campo === 'idInsumo'
          ? this.precioReferencialInsumo(Number(input.value))
          : Number(copia[index]?.precioUnitario || 0);
      copia[index] = {
        ...copia[index],
        [campo]: input.value,
        ...(campo === 'idInsumo' && precioSugerido > 0
          ? { precioUnitario: String(precioSugerido) }
          : {}),
      };
      return copia;
    });
  }

  cambiarPedidoOrden(event: Event) {
    const select = event.target as HTMLSelectElement;
    this.formOrden.controls.idPedido.setValue(select.value);
    const pedido = this.pedidosEnCompra().find(
      (item) =>
        Number((item as any).idPedido || (item as any).id_pedido) ===
        Number(select.value),
    ) as any;
    this.pedidoOrdenSeleccionado.set(pedido || null);
    const detalles =
      pedido?.detalles ||
      pedido?.pedidoDetalles ||
      pedido?.pedido_detalles ||
      [];

    this.detallesOrden.set(
      detalles.length > 0
        ? detalles.map((detalle: any) => ({
            idInsumo: String(
              detalle.idInsumo ||
                detalle.id_insumo ||
                detalle.insumo?.idInsumo ||
                detalle.insumo?.id_insumo ||
                '',
            ),
            cantidad: String(
              detalle.cantidadAprobada ||
                detalle.cantidad_aprobada ||
                detalle.cantidadSolicitada ||
                detalle.cantidad_solicitada ||
                '',
            ),
            precioUnitario: String(
              this.precioReferencialInsumo(
                Number(
                  detalle.idInsumo ||
                    detalle.id_insumo ||
                    detalle.insumo?.idInsumo ||
                    detalle.insumo?.id_insumo ||
                    0,
                ),
              ) || '',
            ),
            observaciones:
              detalle.observacion || detalle.observaciones || '',
          }))
        : [
            {
              idInsumo: '',
              cantidad: '',
              precioUnitario: '',
              observaciones: '',
            },
          ],
    );
  }

  cambiarProveedorOrden(event: Event) {
    const select = event.target as HTMLSelectElement;
    this.formOrden.controls.idProveedor.setValue(select.value);
  }

  cambiarArchivoRecepcion(event: Event) {
    const input = event.target as HTMLInputElement;
    const archivo = input.files?.[0];

    if (!archivo) {
      this.archivoRecepcion.set('');
      this.archivoRecepcionError.set('');
      this.formRecepcion.controls.archivoRespaldo.setValue('');
      return;
    }

    if (!validarArchivoRecepcion(archivo.name)) {
      input.value = '';
      this.archivoRecepcion.set('');
      this.formRecepcion.controls.archivoRespaldo.setValue('');
      this.error.set('');
      this.archivoRecepcionError.set(
        'Formato no permitido. Use PDF, JPG, JPEG o PNG.',
      );
      return;
    }

    this.error.set('');
    this.archivoRecepcionError.set('');
    this.archivoRecepcion.set(archivo.name);
    this.formRecepcion.controls.archivoRespaldo.setValue(archivo.name);
  }

  agregarDetalleRecepcion() {
    this.detallesRecepcion.update((items) => [
      ...items,
      {
        idInsumo: '',
        cantidadRecibida: '',
        cantidadRechazada: '0',
        estadoConformidad: 'CONFORME',
        motivoRechazo: '',
        observaciones: '',
      },
    ]);
  }

  quitarDetalleRecepcion(index: number) {
    this.detallesRecepcion.update((items) => items.filter((_, i) => i !== index));
  }

  cambiarDetalleRecepcion(index: number, campo: keyof DetalleRecepcionForm, event: Event) {
    const input = event.target as HTMLInputElement | HTMLSelectElement;

    this.detallesRecepcion.update((items) => {
      const copia = [...items];
      copia[index] = {
        ...copia[index],
        [campo]: input.value,
      };
      return copia;
    });
  }

  cambiarOrdenRecepcion(event: Event) {
    const select = event.target as HTMLSelectElement;
    this.formRecepcion.controls.idOrdenCompra.setValue(select.value);

    const detallesOrden = this.detallesOrdenRecepcion();

    this.detallesRecepcion.set(
      detallesOrden.length > 0
        ? detallesOrden.map((detalle) => ({
            idInsumo: String(this.idInsumoDetalleOrden(detalle)),
            cantidadRecibida: String(
              detalle.cantidadPendiente ||
                detalle.cantidad_pendiente ||
                detalle.cantidadComprada ||
                detalle.cantidad_comprada ||
                '',
            ),
            cantidadRechazada: '0',
            estadoConformidad: 'CONFORME',
            motivoRechazo: '',
            observaciones: '',
          }))
        : [
            {
              idInsumo: '',
              cantidadRecibida: '',
              cantidadRechazada: '0',
              estadoConformidad: 'CONFORME',
              motivoRechazo: '',
              observaciones: '',
            },
          ],
    );
  }

  cambiarOrdenComprobante(event: Event) {
    const select = event.target as HTMLSelectElement;
    this.formComprobante.controls.idOrdenCompra.setValue(select.value);
    const orden = this.ordenPorId(Number(select.value));

    if (!orden) {
      this.formComprobante.patchValue({
        montoSubtotal: '',
        montoDescuento: 0,
        moneda: 'BOB',
      });
      return;
    }

    const subtotal = this.subtotalOrden(orden);

    this.formComprobante.patchValue({
      montoSubtotal: String(subtotal),
      montoDescuento: this.descuentoOrden(orden),
      moneda: this.monedaOrden(orden),
    });
  }

  cambiarTipoComprobante(event: Event) {
    const select = event.target as HTMLSelectElement;
    this.formComprobante.controls.tipoComprobante.setValue(select.value);
  }

  guardarOrdenCompra() {
    this.error.set('');
    this.mensaje.set('');
    this.detallesOrdenIntentoGuardar.set(true);
    this.quitarErrorControl(
      this.formOrden.controls.descuento,
      'descuentoMayorSubtotal',
    );

    if (!this.verificarPermiso('compras.crear_orden')) {
      return;
    }

    if (this.formOrden.invalid) {
      this.error.set(
        marcarFormularioInvalido(
          this.formOrden,
          this.etiquetasFormulario,
          'Revise los campos de la orden de compra',
        ),
      );
      return;
    }

    const detallesFormulario = this.detallesOrden();

    const indiceDetalleOrdenInvalido = detallesFormulario.findIndex(
      (detalle) =>
        !detalle.idInsumo ||
        Number(detalle.cantidad) <= 0 ||
        Number(detalle.precioUnitario) <= 0,
    );

    if (detallesFormulario.length === 0 || indiceDetalleOrdenInvalido >= 0) {
      return;
    }

    this.detallesOrdenIntentoGuardar.set(false);

    const detalles = detallesFormulario.map((d) => ({
        idInsumo: Number(d.idInsumo),
        cantidadSolicitada: Number(d.cantidad),
        cantidadComprada: Number(d.cantidad),
        precioUnitario: Number(d.precioUnitario),
        observacion: d.observaciones?.trim() || undefined,
      }));

    const valores = this.formOrden.getRawValue();
    const subtotalOrden = this.subtotalOrdenFormulario();
    const descuentoOrden = Number(valores.descuento || 0);

    if (descuentoOrden > subtotalOrden) {
      marcarFormularioInvalido(
        this.formOrden,
        this.etiquetasFormulario,
        'Revise los campos de la orden de compra',
      );
      this.formOrden.controls.descuento.setErrors({
        ...(this.formOrden.controls.descuento.errors ?? {}),
        descuentoMayorSubtotal: true,
      });
      this.formOrden.controls.descuento.markAsTouched();
      return;
    }

    const payload = {
      numeroOrden: this.generarNumero('OC'),
      codigoCorrelativo: this.generarNumero('CORR-OC'),
      idPedido: Number(valores.idPedido),
      idProveedor: Number(valores.idProveedor),
      fechaEstimadaEntrega:
        convertirDatetimeLocalParaBackend(valores.fechaEntregaEstimada) ||
        undefined,
      condicionPago: valores.condicionPago.trim() || undefined,
      formaPago: valores.formaPago.trim() || undefined,
      moneda: valores.moneda,
      descuento: descuentoOrden,
      observaciones: valores.observaciones?.trim() || undefined,
      usuarioGenera: this.idUsuarioActual() || undefined,
      detalles,
    };

    this.guardando.set(true);

    this.comprasService.crearOrdenCompra(payload).subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set('Orden de compra creada correctamente.');
        this.cerrarModal();
        this.cargarDatos();
        this.tabActual.set('ordenes');
      },
      error: (error) => {
        console.error('Error al crear orden de compra:', error);
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
      },
    });
  }

  guardarRecepcion() {
    this.error.set('');
    this.mensaje.set('');
    this.detallesRecepcionIntentoGuardar.set(true);
    this.quitarErrorControl(
      this.formRecepcion.controls.idOrdenCompra,
      'seleccionInvalida',
    );

    if (!this.verificarPermiso('recepciones.crear')) {
      return;
    }

    if (this.formRecepcion.invalid) {
      this.error.set(
        marcarFormularioInvalido(
          this.formRecepcion,
          this.etiquetasFormulario,
          'Revise los campos de la recepcion',
        ),
      );
      return;
    }

    const detallesFormulario = this.detallesRecepcion();

    const indiceDetalleRecepcionInvalido = detallesFormulario.findIndex(
      (detalle) =>
        !detalle.idInsumo || Number(detalle.cantidadRecibida) <= 0,
    );

    if (detallesFormulario.length === 0 || indiceDetalleRecepcionInvalido >= 0) {
      return;
    }

    const indiceDetalleRechazoInvalido = detallesFormulario.findIndex(
      (detalle) =>
        Number(detalle.cantidadRechazada || 0) >
          Number(detalle.cantidadRecibida) ||
        ((Number(detalle.cantidadRechazada || 0) > 0 ||
          detalle.estadoConformidad !== 'CONFORME') &&
          detalle.motivoRechazo.trim().length < 3),
    );

    if (indiceDetalleRechazoInvalido >= 0) {
      return;
    }

    this.detallesRecepcionIntentoGuardar.set(false);

    const detalles = detallesFormulario.map((d) => ({
      idInsumo: Number(d.idInsumo),
      cantidadRecibida: Number(d.cantidadRecibida),
      cantidadRechazada: Number(d.cantidadRechazada || 0),
      estadoConformidad: d.estadoConformidad,
      motivoRechazo: d.motivoRechazo.trim() || undefined,
      observaciones: d.observaciones?.trim() || undefined,
    }));

    const valores = this.formRecepcion.getRawValue();
    const idOrdenCompra = Number(valores.idOrdenCompra);
    const orden = this.ordenPorId(idOrdenCompra);

    if (!orden) {
      marcarFormularioInvalido(
        this.formRecepcion,
        this.etiquetasFormulario,
        'Revise los campos de la recepcion',
      );
      this.formRecepcion.controls.idOrdenCompra.setErrors({
        ...(this.formRecepcion.controls.idOrdenCompra.errors ?? {}),
        seleccionInvalida: true,
      });
      this.formRecepcion.controls.idOrdenCompra.markAsTouched();
      return;
    }

    if (!this.idProveedorOrden(orden)) {
      this.error.set('La orden seleccionada no tiene proveedor asociado.');
      return;
    }

    const detallesNormalizados = detalles.map((detalle) => {
      const detalleOrden = this.detalleOrdenPorInsumo(idOrdenCompra, detalle.idInsumo);
      const cantidadComprada = Number(
        detalleOrden?.cantidadComprada ||
          detalleOrden?.cantidad_comprada ||
          detalle.cantidadRecibida,
      );
      const cantidadRecibida = Number(detalle.cantidadRecibida);
      const cantidadRechazada = Number(detalle.cantidadRechazada || 0);
      const cantidadAceptada = cantidadRecibida - cantidadRechazada;

      return {
        idOrdenDetalle: this.idOrdenDetalle(detalleOrden),
        idInsumo: detalle.idInsumo,
        cantidadComprada,
        cantidadRecibida,
        cantidadAceptada,
        cantidadRechazada,
        cantidadFaltante: Math.max(cantidadComprada - cantidadAceptada, 0),
        estadoConformidad:
          cantidadRechazada > 0 && detalle.estadoConformidad === 'CONFORME'
            ? 'OBSERVADO'
            : detalle.estadoConformidad,
        motivoRechazo: detalle.motivoRechazo,
        observaciones: detalle.observaciones,
      };
    });

    const tieneObservaciones = detallesNormalizados.some(
      (detalle) =>
        detalle.cantidadRechazada > 0 ||
        detalle.estadoConformidad !== 'CONFORME',
    );
    const recepcionCompleta = detallesNormalizados.every(
      (detalle) => detalle.cantidadFaltante <= 0,
    );
    const estadoRecepcion = tieneObservaciones
      ? 'OBSERVADA'
      : recepcionCompleta
        ? 'RECIBIDA_COMPLETA'
        : 'RECIBIDA_PARCIAL';

    const payload = {
      numeroRecepcion: this.generarNumero('REC'),
      idOrdenCompra,
      idProveedor: this.idProveedorOrden(orden),
      idAlmacenDestino: Number(valores.idAlmacen),
      fechaRealRecepcion:
        convertirDatetimeLocalParaBackend(valores.fechaRecepcion) ||
        new Date().toISOString(),
      idResponsableRecepcion: this.idUsuarioActual() || undefined,
      estadoRecepcion,
      documentoRespaldo: valores.documentoRespaldo.trim() || undefined,
      observaciones: valores.observaciones?.trim() || undefined,
      detalles: detallesNormalizados,
    };

    this.guardando.set(true);

    this.comprasService.crearRecepcion(payload).subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set('Recepción registrada correctamente.');
        this.cerrarModal();
        this.cargarDatos();
        this.tabActual.set('recepciones');
      },
      error: (error) => {
        console.error('Error al registrar recepción:', error);
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
      },
    });
  }

  guardarComprobante() {
    this.error.set('');
    this.mensaje.set('');
    this.quitarErrorControl(
      this.formComprobante.controls.montoDescuento,
      'descuentoMayorSubtotal',
    );
    this.quitarErrorControl(
      this.formComprobante.controls.idOrdenCompra,
      'seleccionInvalida',
    );

    if (!this.verificarPermiso('comprobantes.crear')) {
      return;
    }

    if (this.formComprobante.invalid) {
      this.error.set(
        marcarFormularioInvalido(
          this.formComprobante,
          this.etiquetasFormulario,
          'Revise los campos del comprobante',
        ),
      );
      return;
    }

    const valores = this.formComprobante.getRawValue();
    const orden = this.ordenPorId(Number(valores.idOrdenCompra));

    if (!orden) {
      marcarFormularioInvalido(
        this.formComprobante,
        this.etiquetasFormulario,
        'Revise los campos del comprobante',
      );
      this.formComprobante.controls.idOrdenCompra.setErrors({
        ...(this.formComprobante.controls.idOrdenCompra.errors ?? {}),
        seleccionInvalida: true,
      });
      this.formComprobante.controls.idOrdenCompra.markAsTouched();
      return;
    }

    if (!this.idProveedorOrden(orden) || !this.nitProveedorOrden(orden)) {
      this.error.set('La orden seleccionada no tiene proveedor o NIT asociado.');
      return;
    }

    const subtotalComprobante = Number(valores.montoSubtotal || 0);
    const descuentoComprobante = Number(valores.montoDescuento || 0);

    if (descuentoComprobante > subtotalComprobante) {
      marcarFormularioInvalido(
        this.formComprobante,
        this.etiquetasFormulario,
        'Revise los campos del comprobante',
      );
      this.formComprobante.controls.montoDescuento.setErrors({
        ...(this.formComprobante.controls.montoDescuento.errors ?? {}),
        descuentoMayorSubtotal: true,
      });
      this.formComprobante.controls.montoDescuento.markAsTouched();
      return;
    }

    const payload = {
      idOrdenCompra: Number(valores.idOrdenCompra),
      idProveedor: this.idProveedorOrden(orden),
      nitProveedor: this.nitProveedorOrden(orden),
      tipoComprobante: valores.tipoComprobante,
      numeroComprobante: valores.numeroComprobante.trim(),
      fechaComprobante:
        convertirDatetimeLocalParaBackend(valores.fechaEmision) ||
        new Date().toISOString(),
      montoSubtotal: subtotalComprobante,
      montoDescuento: descuentoComprobante,
      moneda: valores.moneda,
      usuarioRegistra: this.idUsuarioActual() || undefined,
      observaciones: valores.observaciones?.trim() || undefined,
    };

    this.guardando.set(true);

    this.comprasService.crearComprobante(payload).subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set('Comprobante registrado correctamente.');
        this.cerrarModal();
        this.cargarDatos();
        this.tabActual.set('comprobantes');
      },
      error: (error) => {
        console.error('Error al registrar comprobante:', error);
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
      },
    });
  }

  detalleOrdenInsumoInvalido(index: number): boolean {
    const detalle = this.detallesOrden()[index];
    return this.detallesOrdenIntentoGuardar() && !detalle?.idInsumo;
  }

  detalleOrdenCantidadInvalida(index: number): boolean {
    const detalle = this.detallesOrden()[index];
    return this.detallesOrdenIntentoGuardar() && Number(detalle?.cantidad) <= 0;
  }

  detalleOrdenPrecioInvalido(index: number): boolean {
    const detalle = this.detallesOrden()[index];
    return (
      this.detallesOrdenIntentoGuardar() &&
      Number(detalle?.precioUnitario) <= 0
    );
  }

  detalleRecepcionInsumoInvalido(index: number): boolean {
    const detalle = this.detallesRecepcion()[index];
    return this.detallesRecepcionIntentoGuardar() && !detalle?.idInsumo;
  }

  detalleRecepcionCantidadInvalida(index: number): boolean {
    const detalle = this.detallesRecepcion()[index];
    return (
      this.detallesRecepcionIntentoGuardar() &&
      Number(detalle?.cantidadRecibida) <= 0
    );
  }

  detalleRecepcionCantidadRechazadaInvalida(index: number): boolean {
    const detalle = this.detallesRecepcion()[index];
    return (
      this.detallesRecepcionIntentoGuardar() &&
      Number(detalle?.cantidadRechazada || 0) >
        Number(detalle?.cantidadRecibida || 0)
    );
  }

  detalleRecepcionMotivoInvalido(index: number): boolean {
    const detalle = this.detallesRecepcion()[index];
    return (
      this.detallesRecepcionIntentoGuardar() &&
      (Number(detalle?.cantidadRechazada || 0) > 0 ||
        detalle?.estadoConformidad !== 'CONFORME') &&
      String(detalle?.motivoRechazo || '').trim().length < 3
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

  obtenerMensajeErrorBackend(error: any): string {
    const mensaje = mensajeErrorBackend(error, this.etiquetasFormulario);

    if (Array.isArray(mensaje)) return mensaje.join(' | ');
    if (typeof mensaje === 'string') return mensaje;
    if (error?.error?.error) return error.error.error;

    return 'No se pudo completar la operación. Revise los datos enviados.';
  }

  tienePermiso(permiso: string): boolean {
    return this.permissionService.tienePermiso(permiso);
  }

  puedeVerTab(tab: TabCompras): boolean {
    return this.tienePermiso(this.permisoTab(tab));
  }

  permisoTab(tab: TabCompras): string {
    const permisos: Record<TabCompras, string> = {
      ordenes: 'compras.ver',
      recepciones: 'recepciones.ver',
      comprobantes: 'comprobantes.ver',
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

  abrirOrden(item: OrdenCompra) {
    if (!this.verificarPermiso('compras.detalle_orden')) {
      return;
    }

    const id = this.idOrden(item);

    if (!id) {
      this.ordenSeleccionada.set(item);
      this.modoModal.set('orden');
      return;
    }

    this.comprasService.buscarOrdenCompraPorId(id).subscribe({
      next: (data) => {
        this.ordenSeleccionada.set(data);
        this.modoModal.set('orden');
      },
      error: () => {
        this.ordenSeleccionada.set(item);
        this.modoModal.set('orden');
      },
    });
  }

  abrirRecepcion(item: RecepcionCompra) {
    if (!this.verificarPermiso('recepciones.detalle')) {
      return;
    }

    const id = this.idRecepcion(item);

    if (!id) {
      this.recepcionSeleccionada.set(item);
      this.modoModal.set('recepcion');
      return;
    }

    this.comprasService.buscarRecepcionPorId(id).subscribe({
      next: (data) => {
        this.recepcionSeleccionada.set(data);
        this.modoModal.set('recepcion');
      },
      error: () => {
        this.recepcionSeleccionada.set(item);
        this.modoModal.set('recepcion');
      },
    });
  }

  abrirComprobante(item: ComprobanteCompra) {
    if (!this.verificarPermiso('comprobantes.detalle')) {
      return;
    }

    const id = this.idComprobante(item);

    if (!id) {
      this.comprobanteSeleccionado.set(item);
      this.modoModal.set('comprobante');
      return;
    }

    this.comprasService.buscarComprobantePorId(id).subscribe({
      next: (data) => {
        this.comprobanteSeleccionado.set(data);
        this.modoModal.set('comprobante');
      },
      error: () => {
        this.comprobanteSeleccionado.set(item);
        this.modoModal.set('comprobante');
      },
    });
  }

  idOrden(item: OrdenCompra): number {
    const data = item as any;
    return Number(data.idOrdenCompra || data.id_orden_compra || 0);
  }

  numeroOrden(item: OrdenCompra): string {
    const data = item as any;
    return this.codigoCompacto(data.numeroOrden || data.numero_orden || `OC-${this.idOrden(item)}`);
  }

  fechaOrden(item: OrdenCompra): string {
    const data = item as any;
    return this.fechaConHoraReal(data, [
      'fechaEmision',
      'fecha_emision',
      'fechaOrden',
      'fecha_orden',
    ]);
  }

  estadoOrden(item: OrdenCompra): string {
    const data = item as any;
    return this.etiquetaOperativa(
      data.estadoCompra ||
        data.estado_compra ||
        data.estadoOrden ||
        data.estado_orden ||
        data.estado ||
        'PENDIENTE',
    );
  }

  proveedorOrden(item: OrdenCompra): string {
    const data = item as any;

    return String(
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

  totalOrden(item: OrdenCompra): string | number {
    return totalConDescuento(this.subtotalOrden(item), this.descuentoOrden(item));
  }

  subtotalOrden(item: OrdenCompra): number {
    const data = item as any;
    const subtotal = data.subtotal ?? data.montoSubtotal ?? data.monto_subtotal;

    if (subtotal !== undefined) {
      return Number(subtotal || 0);
    }

    return this.detallesOrdenItem(item).reduce(
      (total, detalle) => total + this.subtotalDetalleOrden(detalle),
      0,
    );
  }

  descuentoOrden(item: OrdenCompra): number {
    const data = item as any;
    return Number(data.descuento || 0);
  }

  monedaOrden(item: OrdenCompra): string {
    return String((item as any).moneda || 'BOB');
  }

  condicionPagoOrden(item: OrdenCompra): string {
    const data = item as any;
    return String(data.condicionPago || data.condicion_pago || 'No especificada');
  }

  formaPagoOrden(item: OrdenCompra): string {
    const data = item as any;
    return String(data.formaPago || data.forma_pago || 'No especificada');
  }

  pedidoOrden(item: OrdenCompra): string {
    const data = item as any;
    return String(
      data.pedido?.numeroPedido ||
        data.pedido?.numero_pedido ||
        data.numeroPedido ||
        data.numero_pedido ||
        (data.idPedido ? `PED-${data.idPedido}` : 'Sin pedido'),
    );
  }

  idPedidoOrden(item: OrdenCompra): number {
    const data = item as any;
    return Number(data.idPedido || data.id_pedido || data.pedido?.idPedido || data.pedido?.id_pedido || 0);
  }

  fechaEntregaOrden(item: OrdenCompra): string {
    const data = item as any;
    return this.fechaConHoraReal(data, [
      'fechaEstimadaEntrega',
      'fechaEntregaEstimada',
      'fecha_estimada_entrega',
      'fecha_entrega_estimada',
    ], undefined, false);
  }

  observacionesOrden(item: OrdenCompra): string {
    return String(item.observaciones || 'Sin observaciones');
  }

  detallesOrdenItem(item: OrdenCompra): any[] {
    const data = item as any;
    return data.detalles || data.ordenCompraDetalles || data.orden_compra_detalles || [];
  }

  precioDetalleOrden(detalle: any): number {
    return Number(detalle.precioUnitario ?? detalle.precio_unitario ?? 0);
  }

  subtotalDetalleOrden(detalle: any): number {
    const subtotal = detalle.subtotal;
    return subtotal !== undefined
      ? Number(subtotal || 0)
      : Number(this.cantidadDetalle(detalle)) * this.precioDetalleOrden(detalle);
  }

  observacionDetalle(detalle: any): string {
    return String(detalle.observacion || detalle.observaciones || 'Sin observación');
  }

  idRecepcion(item: RecepcionCompra): number {
    const data = item as any;
    return Number(data.idRecepcion || data.id_recepcion || data.idRecepcionCompra || data.id_recepcion_compra || 0);
  }

  numeroRecepcion(item: RecepcionCompra): string {
    const data = item as any;
    return this.codigoCompacto(data.numeroRecepcion || data.numero_recepcion || `REC-${this.idRecepcion(item)}`);
  }

  fechaRecepcion(item: RecepcionCompra): string {
    const data = item as any;
    return this.fechaConHoraReal(data, [
      'fechaRealRecepcion',
      'fecha_real_recepcion',
      'fechaRecepcion',
      'fecha_recepcion',
    ]);
  }

  estadoRecepcion(item: RecepcionCompra): string {
    const data = item as any;
    return this.etiquetaOperativa(data.estadoRecepcion || data.estado_recepcion || data.estado || 'PENDIENTE');
  }

  numeroOrdenRecepcion(item: RecepcionCompra): string {
    const data = item as any;

    return this.codigoCompacto(
      data.ordenCompra?.numeroOrden ||
        data.ordenCompra?.numero_orden ||
        data.orden_compra?.numeroOrden ||
        data.orden_compra?.numero_orden ||
        data.numeroOrden ||
        data.numero_orden ||
        'Sin orden',
    );
  }

  idOrdenRecepcion(item: RecepcionCompra): number {
    const data = item as any;
    return Number(
      data.idOrdenCompra ||
        data.id_orden_compra ||
        data.ordenCompra?.idOrdenCompra ||
        data.orden_compra?.id_orden_compra ||
        0,
    );
  }

  idProveedorRecepcion(item: RecepcionCompra): number {
    const data = item as any;
    return Number(
      data.idProveedor ||
        data.id_proveedor ||
        data.proveedor?.idProveedor ||
        data.proveedor?.id_proveedor ||
        0,
    );
  }

  responsableRecepcion(item: RecepcionCompra): string {
    const data = item as any;
    const responsable = data.responsableRecepcion || data.responsable_recepcion;

    return String(
      responsable?.nombreCompleto ||
        responsable?.nombre_completo ||
        responsable?.nombreUsuario ||
        responsable?.nombre_usuario ||
        data.usuarioResponsable?.nombreCompleto ||
        data.usuario_responsable?.nombreCompleto ||
        data.usuarioResponsable ||
        data.usuario_responsable ||
        'Sin responsable',
    );
  }

  detallesRecepcionItem(item: RecepcionCompra): any[] {
    const data = item as any;
    return data.detalles || data.recepcionDetalles || data.recepcion_detalles || [];
  }

  proveedorRecepcion(item: RecepcionCompra): string {
    const data = item as any;
    return String(
      data.proveedor?.razonSocial ||
        data.proveedor?.razon_social ||
        data.ordenCompra?.proveedor?.razonSocial ||
        'Sin proveedor',
    );
  }

  almacenRecepcion(item: RecepcionCompra): string {
    const data = item as any;
    return String(
      data.almacenDestino?.nombreAlmacen ||
        data.almacen_destino?.nombre_almacen ||
        data.almacenDestinoNombre ||
        'Sin almacén',
    );
  }

  documentoRecepcion(item: RecepcionCompra): string {
    const data = item as any;
    return String(data.documentoRespaldo || data.documento_respaldo || 'Sin documento');
  }

  cantidadCompradaRecepcion(detalle: any): number {
    return Number(
      detalle.cantidadComprada ??
        detalle.cantidad_comprada ??
        detalle.ordenDetalle?.cantidadComprada ??
        detalle.ordenDetalle?.cantidad_comprada ??
        detalle.orden_detalle?.cantidadComprada ??
        detalle.orden_detalle?.cantidad_comprada ??
        detalle.cantidadOrdenada ??
        detalle.cantidad_ordenada ??
        detalle.cantidadSolicitada ??
        detalle.cantidad_solicitada ??
        0,
    );
  }

  cantidadRecibidaDetalle(detalle: any): number {
    const recibida = detalle.cantidadRecibida ?? detalle.cantidad_recibida;

    if (recibida !== undefined && recibida !== null && recibida !== '') {
      return Number(recibida || 0);
    }

    return (
      this.cantidadAceptadaDetalle(detalle) +
      this.cantidadRechazadaDetalle(detalle)
    );
  }

  cantidadAceptadaDetalle(detalle: any): number {
    return Number(detalle.cantidadAceptada ?? detalle.cantidad_aceptada ?? 0);
  }

  cantidadRechazadaDetalle(detalle: any): number {
    return Number(detalle.cantidadRechazada ?? detalle.cantidad_rechazada ?? 0);
  }

  cantidadFaltanteDetalle(detalle: any): number {
    return Number(detalle.cantidadFaltante ?? detalle.cantidad_faltante ?? 0);
  }

  conformidadDetalle(detalle: any): string {
    const estado = String(
      detalle.estadoConformidad || detalle.estado_conformidad || '',
    ).trim();

    if (estado) {
      return estado;
    }

    return this.cantidadRechazadaDetalle(detalle) > 0
      ? 'OBSERVADO'
      : 'CONFORME';
  }

  motivoRechazoDetalle(detalle: any): string {
    return String(detalle.motivoRechazo || detalle.motivo_rechazo || '');
  }

  idComprobante(item: ComprobanteCompra): number {
    const data = item as any;
    return Number(data.idComprobante || data.id_comprobante || data.idComprobanteCompra || data.id_comprobante_compra || 0);
  }

  numeroComprobante(item: ComprobanteCompra): string {
    const data = item as any;

    return this.codigoCompacto(
      data.numeroComprobante ||
        data.numero_comprobante ||
        data.nroComprobante ||
        data.nro_comprobante ||
        `COMP-${this.idComprobante(item)}`,
    );
  }

  tipoComprobante(item: ComprobanteCompra): string {
    const data = item as any;
    return String(data.tipoComprobante || data.tipo_comprobante || 'SIN_TIPO');
  }

  etiquetaTipoComprobante(valor: string): string {
    return (
      this.tiposComprobante.find((tipo) => tipo.valor === valor)?.etiqueta ||
      valor.replaceAll('_', ' ')
    );
  }

  fechaComprobante(item: ComprobanteCompra): string {
    const data = item as any;
    return this.fechaConHoraReal(data, [
      'fechaComprobante',
      'fecha_comprobante',
      'fechaEmision',
      'fecha_emision',
      'fecha',
    ]);
  }

  fechaPagoComprobante(item: ComprobanteCompra): string {
    const data = item as any;
    return String(data.fechaPago || data.fecha_pago || '');
  }

  montoComprobante(item: ComprobanteCompra): string | number {
    return totalConDescuento(
      this.subtotalComprobante(item),
      this.descuentoComprobante(item),
    );
  }

  subtotalComprobante(item: ComprobanteCompra): number {
    const data = item as any;
    return Number(data.montoSubtotal ?? data.monto_subtotal ?? 0);
  }

  descuentoComprobante(item: ComprobanteCompra): number {
    const data = item as any;
    return Number(data.montoDescuento ?? data.monto_descuento ?? 0);
  }

  monedaComprobante(item: ComprobanteCompra): string {
    return String((item as any).moneda || 'BOB');
  }

  nitComprobante(item: ComprobanteCompra): string {
    const data = item as any;
    return String(data.nitProveedor || data.nit_proveedor || data.proveedor?.nit || 'Sin NIT');
  }

  montoTotalComprobanteFormulario(): number {
    const valores = this.formComprobante.getRawValue();
    return totalConDescuento(
      Number(valores.montoSubtotal || 0),
      Number(valores.montoDescuento || 0),
    );
  }

  subtotalOrdenFormulario(): number {
    return this.detallesOrden().reduce(
      (total, detalle) =>
        total +
        Number(detalle.cantidad || 0) * Number(detalle.precioUnitario || 0),
      0,
    );
  }

  totalOrdenFormulario(): number {
    const valores = this.formOrden.getRawValue();
    return totalConDescuento(
      this.subtotalOrdenFormulario(),
      Number(valores.descuento || 0),
    );
  }

  cantidadCompradaFormularioRecepcion(idInsumo: string): number {
    const detalle = this.detallesOrdenRecepcion().find(
      (item) => this.idInsumoDetalleOrden(item) === Number(idInsumo),
    );
    return Number(
      detalle?.cantidadPendiente ??
        detalle?.cantidad_pendiente ??
        detalle?.cantidadComprada ??
        detalle?.cantidad_comprada ??
        0,
    );
  }

  estadoRecepcionFormulario(): string {
    if (
      this.detallesRecepcion().some(
        (detalle) =>
          Number(detalle.cantidadRechazada || 0) > 0 ||
          detalle.estadoConformidad !== 'CONFORME',
      )
    ) {
      return 'OBSERVADA';
    }

    const completa =
      this.detallesRecepcion().length > 0 &&
      this.detallesRecepcion().every(
        (detalle) =>
          Number(detalle.cantidadRecibida || 0) >=
          this.cantidadCompradaFormularioRecepcion(detalle.idInsumo),
      );

    return completa ? 'RECIBIDA_COMPLETA' : 'RECIBIDA_PARCIAL';
  }

  estadoComprobante(item: ComprobanteCompra): string {
    const data = item as any;
    return this.etiquetaOperativa(data.estadoComprobante || data.estado_comprobante || data.estado || 'REGISTRADO');
  }

  proveedorComprobante(item: ComprobanteCompra): string {
    const data = item as any;

    return String(
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

  numeroOrdenComprobante(item: ComprobanteCompra): string {
    const data = item as any;

    return this.codigoCompacto(
      data.ordenCompra?.numeroOrden ||
        data.ordenCompra?.numero_orden ||
        data.orden_compra?.numeroOrden ||
        data.orden_compra?.numero_orden ||
        data.numeroOrden ||
        data.numero_orden ||
        'Sin orden',
    );
  }

  idProveedorComprobante(item: ComprobanteCompra): number {
    const data = item as any;
    return Number(
      data.idProveedor ||
        data.id_proveedor ||
        data.proveedor?.idProveedor ||
        data.proveedor?.id_proveedor ||
        0,
    );
  }

  fechaFormateada(fecha: string): string {
    return formatearFechaHoraBolivia(fecha);
  }

  private fechaConHoraReal(
    data: Record<string, any>,
    camposPrincipales: string[],
    camposRespaldo: string[] = [
      'fechaCreacion',
      'fecha_creacion',
      'fechaRegistro',
      'fecha_registro',
      'createdAt',
      'created_at',
    ],
    usarRespaldoSiFalta = true,
  ): string {
    const principal = this.leerFecha(data, camposPrincipales);
    const respaldo = this.leerFecha(data, camposRespaldo);

    if (!principal) {
      return usarRespaldoSiFalta ? respaldo : '';
    }

    if (
      respaldo &&
      this.esFechaSinHoraUtil(principal) &&
      !this.esFechaSinHoraUtil(respaldo) &&
      this.esMismoDiaCalendario(principal, respaldo)
    ) {
      return respaldo;
    }

    return principal;
  }

  private leerFecha(data: Record<string, any>, campos: string[]): string {
    for (const campo of campos) {
      const valor = data?.[campo];

      if (valor instanceof Date) {
        return valor.toISOString();
      }

      if (valor !== undefined && valor !== null && String(valor).trim()) {
        return String(valor);
      }
    }

    return '';
  }

  private esFechaSinHoraUtil(fecha: string): boolean {
    const valor = String(fecha || '').trim();

    if (!valor) {
      return true;
    }

    if (/^\d{4}-\d{2}-\d{2}$/.test(valor)) {
      return true;
    }

    if (/T00:00(?::00(?:\.0{1,3})?)?(?:Z|[+-]\d{2}:?\d{2})?$/i.test(valor)) {
      return true;
    }

    const local = convertirFechaBackendADatetimeLocal(valor);
    return !!local && local.endsWith('T00:00');
  }

  private esMismoDiaCalendario(primeraFecha: string, segundaFecha: string): boolean {
    const fechasPrimera = this.fechasPosiblesBolivia(primeraFecha);
    const fechasSegunda = this.fechasPosiblesBolivia(segundaFecha);

    return [...fechasPrimera].some((fecha) => fechasSegunda.has(fecha));
  }

  private fechasPosiblesBolivia(fecha: string): Set<string> {
    const fechas = new Set<string>();
    const valor = String(fecha || '').trim();
    const fechaTexto = valor.match(/^(\d{4}-\d{2}-\d{2})/)?.[1];
    const fechaLocal = convertirFechaBackendADatetimeLocal(valor).slice(0, 10);

    if (fechaTexto) {
      fechas.add(fechaTexto);
    }

    if (fechaLocal) {
      fechas.add(fechaLocal);
    }

    return fechas;
  }

  private etiquetaOperativa(valor: unknown): string {
    return String(valor || 'Sin dato')
      .replace(/[_-]+/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  claseEstado(estado: string): string {
    const normalizado = estado?.toUpperCase();

    if (
      normalizado.includes('APROBADO') ||
      normalizado.includes('COMPLETA') ||
      normalizado.includes('RECIBIDA') ||
      normalizado.includes('PAGADO')
    ) {
      return 'bg-green-100 text-green-700 border-green-200';
    }

    if (
      normalizado.includes('RECHAZADO') ||
      normalizado.includes('ANULADO') ||
      normalizado.includes('OBSERVADO')
    ) {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    if (
      normalizado.includes('PENDIENTE') ||
      normalizado.includes('PROCESO') ||
      normalizado.includes('PARCIAL')
    ) {
      return 'bg-orange-100 text-orange-700 border-orange-200';
    }

    return 'bg-blue-100 text-blue-700 border-blue-200';
  }

  claseConformidad(estado: string): string {
    const normalizado = this.normalizarEstado(estado);

    if (normalizado.includes('RECHAZADO')) {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    if (normalizado.includes('OBSERV')) {
      return 'bg-amber-100 text-amber-700 border-amber-200';
    }

    return 'bg-green-100 text-green-700 border-green-200';
  }

  nombreDetalle(detalle: any): string {
    return String(
      detalle.nombreInsumo ||
        detalle.nombre_insumo ||
        detalle.insumo?.nombreInsumo ||
        detalle.insumo?.nombre_insumo ||
        'Sin insumo',
    );
  }

  cantidadDetalle(detalle: any): string | number {
    return (
      detalle.cantidad ||
      detalle.cantidadSolicitada ||
      detalle.cantidad_solicitada ||
      detalle.cantidadOrdenada ||
      detalle.cantidad_ordenada ||
      detalle.cantidadRecibida ||
      detalle.cantidad_recibida ||
      0
    );
  }

  pedidoTexto(pedido: Pedido): string {
    const data = pedido as any;
    return String(data.numeroPedido || data.numero_pedido || `PED-${data.idPedido || data.id_pedido}`);
  }

  estadoPedido(pedido?: Pedido | null): string {
    const data = pedido as any;
    return String(data?.estadoPedido || data?.estado_pedido || data?.estado || 'Sin estado');
  }

  solicitantePedido(pedido?: Pedido | null): string {
    const data = pedido as any;
    const usuario = data?.usuarioSolicitante || data?.usuario_solicitante || data?.solicitante;
    return this.nombrePersona(usuario) || data?.nombreUsuarioSolicitante || 'Sin solicitante';
  }

  areaPedido(pedido?: Pedido | null): string {
    const data = pedido as any;
    const area = data?.areaSolicitante || data?.area_solicitante || data?.area;
    return String(
      area?.nombreArea ||
        area?.nombre_area ||
        data?.nombreAreaSolicitante ||
        data?.areaSolicitanteNombre ||
        'Sin área',
    );
  }

  aprobadorPedido(pedido?: Pedido | null): string {
    const data = pedido as any;
    const aprobador =
      data?.usuarioRevision ||
      data?.usuario_revision ||
      (typeof data?.usuarioRevisa === 'object' ? data.usuarioRevisa : null) ||
      (typeof data?.usuario_revisa === 'object' ? data.usuario_revisa : null);

    return (
      this.nombrePersona(aprobador) ||
      data?.nombreUsuarioRevision ||
      data?.nombre_usuario_revision ||
      data?.nombreRevisor ||
      data?.nombre_revisor ||
      data?.aprobadoPor ||
      data?.aprobado_por ||
      data?.usuarioAprobador ||
      data?.usuario_aprobador ||
      'Sin información de aprobación'
    );
  }

  fechaAprobacionPedido(pedido?: Pedido | null): string {
    const data = pedido as any;
    return String(
      data?.fechaRevision ||
        data?.fecha_revision ||
        data?.fechaAprobacion ||
        data?.fecha_aprobacion ||
        '',
    );
  }

  aprobadorOrden(item: OrdenCompra): string {
    const data = item as any;
    const aprobador = this.aprobadorPedido(data.pedido);

    if (aprobador !== 'Sin información de aprobación') {
      return aprobador;
    }

    return (
      this.nombrePersona(data.usuarioRevision || data.usuario_revision) ||
      data.nombreUsuarioRevision ||
      data.nombre_usuario_revision ||
      data.aprobadoPor ||
      data.aprobado_por ||
      data.usuarioAprobador ||
      data.usuario_aprobador ||
      aprobador
    );
  }

  fechaAprobacionOrden(item: OrdenCompra): string {
    return this.fechaAprobacionPedido((item as any).pedido);
  }

  proveedorTexto(proveedor: Proveedor): string {
    const data = proveedor as any;
    return String(data.razonSocial || data.razon_social || data.nombreComercial || data.nombre_comercial || 'Proveedor');
  }

  proveedorEmiteFactura(proveedor?: Proveedor): boolean {
    const data = proveedor as any;
    const valor = data?.emiteFactura ?? data?.emite_factura;

    if (valor === undefined || valor === null || valor === '') {
      return true;
    }

    if (typeof valor === 'boolean') {
      return valor;
    }

    return ['true', '1', 'si', 'sí'].includes(String(valor).trim().toLowerCase());
  }

  insumoTexto(insumo: Insumo): string {
    const data = insumo as any;
    return String(`${data.codigoInterno || data.codigo_interno || 'SIN-COD'} · ${data.nombreInsumo || data.nombre_insumo || 'Insumo'}`);
  }

  precioReferencialInsumo(idInsumo: number): number {
    const insumo = this.insumos().find(
      (item) => Number(item.idInsumo) === Number(idInsumo),
    );
    return Number(
      insumo?.precioReferencial ?? insumo?.precio_referencial ?? 0,
    );
  }

  almacenTexto(almacen: Almacen): string {
    const data = almacen as any;
    return String(`${data.codigoAlmacen || data.codigo_almacen || 'SIN-COD'} · ${data.nombreAlmacen || data.nombre_almacen || 'Almacén'}`);
  }

  codigoDetalle(detalle: any): string {
    return String(
      detalle.codigoInterno ||
        detalle.codigo_interno ||
        detalle.insumo?.codigoInterno ||
        detalle.insumo?.codigo_interno ||
        'SIN-COD',
    );
  }

  async exportarPdf(
    tipo: 'orden' | 'recepcion' | 'comprobante',
    item: OrdenCompra | RecepcionCompra | ComprobanteCompra,
  ) {
    if (!this.verificarPermiso('comprobantes.exportar_pdf')) {
      return;
    }

    const documento = await this.crearDocumentoPdf(tipo, item);
    documento.save(`${tipo}-${this.codigoDocumentoPdf(tipo, item)}.pdf`);
    this.confirmacionAccionService.mostrar('Documento PDF exportado correctamente.');
  }

  async imprimirPdf(
    tipo: 'orden' | 'recepcion' | 'comprobante',
    item: OrdenCompra | RecepcionCompra | ComprobanteCompra,
  ) {
    if (!this.verificarPermiso('comprobantes.exportar_pdf')) {
      return;
    }

    const documento = await this.crearDocumentoPdf(tipo, item);
    documento.autoPrint();
    const url = documento.output('bloburl');
    window.open(url.toString(), '_blank', 'noopener,noreferrer');
    this.confirmacionAccionService.mostrar('Documento PDF enviado a impresion.');
  }

  private async crearDocumentoPdf(
    tipo: 'orden' | 'recepcion' | 'comprobante',
    item: OrdenCompra | RecepcionCompra | ComprobanteCompra,
  ): Promise<jsPDF> {
    const [{ jsPDF }, { default: autoTable }] = await Promise.all([
      import('jspdf'),
      import('jspdf-autotable'),
    ]);
    const doc = new jsPDF({ unit: 'mm', format: 'a4' });
    const azul: [number, number, number] = [30, 64, 175];
    const codigo = this.codigoDocumentoPdf(tipo, item);
    const titulo =
      tipo === 'orden'
        ? 'ORDEN DE COMPRA'
        : tipo === 'recepcion'
          ? 'ACTA DE RECEPCION'
          : 'COMPROBANTE DE COMPRA';

    doc.setFillColor(...azul);
    doc.rect(0, 0, 210, 31, 'F');
    doc.setTextColor(255, 255, 255);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(15);
    doc.text('COOPERATIVA MINERA EL PORVENIR R.L.', 14, 13);
    doc.setFontSize(10);
    doc.text(titulo, 14, 21);
    doc.setFont('helvetica', 'normal');
    doc.text(codigo, 196, 21, { align: 'right' });
    doc.setTextColor(15, 23, 42);

    const informacion = this.informacionPdf(tipo, item);
    autoTable(doc, {
      startY: 38,
      body: informacion,
      theme: 'grid',
      styles: { fontSize: 9, cellPadding: 2.5 },
      columnStyles: {
        0: { fontStyle: 'bold', fillColor: [241, 245, 249], cellWidth: 35 },
        2: { fontStyle: 'bold', fillColor: [241, 245, 249], cellWidth: 35 },
      },
      margin: { left: 14, right: 14 },
    });

    let posicionY = ((doc as any).lastAutoTable?.finalY || 38) + 8;
    const detallePdf = this.detallePdf(tipo, item);

    if (detallePdf) {
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(11);
      doc.text(detallePdf.titulo, 14, posicionY);
      autoTable(doc, {
        startY: posicionY + 4,
        head: [detallePdf.encabezados],
        body: detallePdf.filas,
        theme: 'striped',
        headStyles: { fillColor: azul, textColor: 255, fontSize: 8 },
        styles: { fontSize: 8, cellPadding: 2.2, overflow: 'linebreak' },
        margin: { left: 14, right: 14 },
      });
      posicionY = ((doc as any).lastAutoTable?.finalY || posicionY) + 8;
    }

    const observaciones = this.observacionesPdf(tipo, item);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10);
    doc.text('Observaciones', 14, posicionY);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.text(doc.splitTextToSize(observaciones, 180), 14, posicionY + 5);

    const paginas = doc.getNumberOfPages();
    for (let pagina = 1; pagina <= paginas; pagina += 1) {
      doc.setPage(pagina);
      doc.setFontSize(8);
      doc.setTextColor(100, 116, 139);
      doc.text(
        `Generado por el Sistema Logistico - Pagina ${pagina} de ${paginas}`,
        105,
        290,
        { align: 'center' },
      );
    }

    return doc;
  }

  private informacionPdf(
    tipo: 'orden' | 'recepcion' | 'comprobante',
    item: OrdenCompra | RecepcionCompra | ComprobanteCompra,
  ): string[][] {
    if (tipo === 'orden') {
      const orden = item as OrdenCompra;
      return [
        ['Orden', this.numeroOrden(orden), 'Estado', this.estadoOrden(orden)],
        ['Pedido', this.pedidoOrden(orden), 'Proveedor', this.proveedorOrden(orden)],
        ['Emision', this.fechaFormateada(this.fechaOrden(orden)), 'Entrega estimada', this.fechaFormateada(this.fechaEntregaOrden(orden))],
        ['Aprobado por', this.aprobadorOrden(orden), 'Fecha aprobacion', this.fechaFormateada(this.fechaAprobacionOrden(orden))],
        ['Condicion de pago', this.condicionPagoOrden(orden), 'Forma de pago', this.formaPagoOrden(orden)],
        ['Subtotal', `${this.monedaOrden(orden)} ${this.subtotalOrden(orden).toFixed(2)}`, 'Descuento', `${this.monedaOrden(orden)} ${this.descuentoOrden(orden).toFixed(2)}`],
        ['Total', `${this.monedaOrden(orden)} ${Number(this.totalOrden(orden)).toFixed(2)}`, '', ''],
      ];
    }

    if (tipo === 'recepcion') {
      const recepcion = item as RecepcionCompra;
      return [
        ['Recepcion', this.numeroRecepcion(recepcion), 'Estado', this.estadoRecepcion(recepcion)],
        ['Orden', this.numeroOrdenRecepcion(recepcion), 'Proveedor', this.proveedorRecepcion(recepcion)],
        ['Almacen', this.almacenRecepcion(recepcion), 'Responsable', this.responsableRecepcion(recepcion)],
        ['Fecha', this.fechaFormateada(this.fechaRecepcion(recepcion)), 'Documento', this.documentoRecepcion(recepcion)],
      ];
    }

    const comprobante = item as ComprobanteCompra;
    return [
      ['Comprobante', this.numeroComprobante(comprobante), 'Tipo', this.tipoComprobante(comprobante)],
      ['Orden', this.numeroOrdenComprobante(comprobante), 'Estado', this.estadoComprobante(comprobante)],
      ['Proveedor', this.proveedorComprobante(comprobante), 'NIT', this.nitComprobante(comprobante)],
      ['Fecha', this.fechaFormateada(this.fechaComprobante(comprobante)), 'Moneda', this.monedaComprobante(comprobante)],
      ['Subtotal', this.subtotalComprobante(comprobante).toFixed(2), 'Descuento', this.descuentoComprobante(comprobante).toFixed(2)],
      ['Total', Number(this.montoComprobante(comprobante)).toFixed(2), '', ''],
    ];
  }

  private detallePdf(
    tipo: 'orden' | 'recepcion' | 'comprobante',
    item: OrdenCompra | RecepcionCompra | ComprobanteCompra,
  ): { titulo: string; encabezados: string[]; filas: (string | number)[][] } | null {
    if (tipo === 'orden') {
      const detalles = this.detallesOrdenItem(item as OrdenCompra);
      return {
        titulo: 'Detalle de insumos',
        encabezados: ['Codigo', 'Insumo', 'Cantidad', 'Precio unit.', 'Subtotal'],
        filas: detalles.map((detalle) => [
          this.codigoDetalle(detalle),
          this.nombreDetalle(detalle),
          this.cantidadDetalle(detalle),
          this.precioDetalleOrden(detalle).toFixed(2),
          this.subtotalDetalleOrden(detalle).toFixed(2),
        ]),
      };
    }

    if (tipo === 'recepcion') {
      const detalles = this.detallesRecepcionItem(item as RecepcionCompra);
      return {
        titulo: 'Detalle recibido',
        encabezados: ['Insumo', 'Comprada', 'Recibida', 'Aceptada', 'Rechazada', 'Faltante'],
        filas: detalles.map((detalle) => [
          this.nombreDetalle(detalle),
          this.cantidadCompradaRecepcion(detalle),
          this.cantidadRecibidaDetalle(detalle),
          this.cantidadAceptadaDetalle(detalle),
          this.cantidadRechazadaDetalle(detalle),
          this.cantidadFaltanteDetalle(detalle),
        ]),
      };
    }

    if (tipo === 'comprobante') {
      const comprobante = item as ComprobanteCompra;
      return {
        titulo: 'Resumen economico',
        encabezados: ['Concepto', 'Importe'],
        filas: [
          ['Subtotal', this.subtotalComprobante(comprobante).toFixed(2)],
          ['Descuento', this.descuentoComprobante(comprobante).toFixed(2)],
          ['TOTAL', Number(this.montoComprobante(comprobante)).toFixed(2)],
        ],
      };
    }

    return null;
  }

  private observacionesPdf(
    tipo: 'orden' | 'recepcion' | 'comprobante',
    item: OrdenCompra | RecepcionCompra | ComprobanteCompra,
  ): string {
    if (tipo === 'orden') return this.observacionesOrden(item as OrdenCompra);
    if (tipo === 'recepcion') return (item as RecepcionCompra).observaciones || 'Sin observaciones';
    return (item as ComprobanteCompra).observaciones || 'Sin observaciones';
  }

  private codigoDocumentoPdf(
    tipo: 'orden' | 'recepcion' | 'comprobante',
    item: OrdenCompra | RecepcionCompra | ComprobanteCompra,
  ): string {
    const codigo =
      tipo === 'orden'
        ? this.numeroOrden(item as OrdenCompra)
        : tipo === 'recepcion'
          ? this.numeroRecepcion(item as RecepcionCompra)
          : this.numeroComprobante(item as ComprobanteCompra);
    return codigo.replace(/[^a-zA-Z0-9_-]/g, '_');
  }

  private coincideTexto(texto: string, ...valores: string[]): boolean {
    return !texto || valores.some((valor) => valor.toLowerCase().includes(texto));
  }

  private coincideValor(valor: string, filtro: string): boolean {
    return !filtro || String(valor) === String(filtro);
  }

  private coincideFecha(
    fecha: string,
    rapida: FechaRapida,
    desde: string,
    hasta: string,
  ): boolean {
    const clave = convertirFechaBackendADatetimeLocal(fecha).slice(0, 10);
    if (!clave) return rapida === 'todos' && !desde && !hasta;

    if (desde && clave < desde) return false;
    if (hasta && clave > hasta) return false;

    const hoy = convertirFechaBackendADatetimeLocal(new Date()).slice(0, 10);
    if (rapida === 'todos') return true;
    if (rapida === 'hoy') return clave === hoy;
    if (rapida === 'mes') return clave.slice(0, 7) === hoy.slice(0, 7);
    if (rapida === 'anio') return clave.slice(0, 4) === hoy.slice(0, 4);

    const inicioSemana = new Date(`${hoy}T00:00:00Z`);
    const dia = inicioSemana.getUTCDay() || 7;
    inicioSemana.setUTCDate(inicioSemana.getUTCDate() - dia + 1);
    const finSemana = new Date(inicioSemana);
    finSemana.setUTCDate(finSemana.getUTCDate() + 6);
    return (
      clave >= inicioSemana.toISOString().slice(0, 10) &&
      clave <= finSemana.toISOString().slice(0, 10)
    );
  }

  private ahoraDatetimeLocalBolivia(): string {
    return convertirFechaBackendADatetimeLocal(new Date());
  }

  private nombrePersona(persona: any): string {
    if (!persona) return '';

    if (typeof persona === 'string') {
      return /^\d+$/.test(persona.trim()) ? '' : persona.trim();
    }

    if (typeof persona !== 'object') return '';

    return String(
      persona.nombreCompleto ||
        persona.nombre_completo ||
        persona.nombreUsuario ||
        persona.nombre_usuario ||
        persona.usuario ||
        '',
    );
  }

  private idUsuarioActual(): number {
    const usuario = this.authState.usuario() as any;
    return Number(usuario?.idUsuario || usuario?.id_usuario || 0);
  }

  private generarNumero(prefijo: string): string {
    const tiempo = Date.now().toString(36).slice(-5).toUpperCase();
    const aleatorio = Math.floor(Math.random() * 36 ** 2)
      .toString(36)
      .padStart(2, '0')
      .toUpperCase();

    return `${prefijo}-${tiempo}${aleatorio}`;
  }

  private codigoCompacto(valor: unknown): string {
    const codigo = String(valor || '').trim();
    const partes = codigo.match(/^([A-Za-z]+(?:-[A-Za-z]+)*)-\d{8}-([A-Za-z0-9]+)$/);

    if (partes) {
      return `${partes[1].toUpperCase()}-${partes[2].toUpperCase()}`;
    }

    return codigo;
  }

  private normalizarEstado(valor: unknown): string {
    return String(valor || '')
      .trim()
      .toUpperCase()
      .replace(/[\s-]+/g, '_');
  }

  private ordenPorId(idOrdenCompra: number): OrdenCompra | undefined {
    return this.ordenes().find((orden) => this.idOrden(orden) === idOrdenCompra);
  }

  detallesOrdenRecepcion(): any[] {
    const idOrdenCompra = Number(this.formRecepcion.controls.idOrdenCompra.value || 0);
    const orden = this.ordenPorId(idOrdenCompra) as any;

    return orden?.detalles || orden?.ordenCompraDetalles || orden?.orden_compra_detalles || [];
  }

  idInsumoDetalleOrden(detalle: any): number {
    return Number(
      detalle?.idInsumo ||
        detalle?.id_insumo ||
        detalle?.insumo?.idInsumo ||
        detalle?.insumo?.id_insumo ||
        0,
    );
  }

  private idProveedorOrden(orden: OrdenCompra): number {
    const data = orden as any;
    return Number(
      data.idProveedor ||
        data.id_proveedor ||
        data.proveedor?.idProveedor ||
        data.proveedor?.id_proveedor ||
        0,
    );
  }

  private nitProveedorOrden(orden: OrdenCompra): string {
    const data = orden as any;
    return String(data.proveedor?.nit || data.nitProveedor || data.nit_proveedor || 'SIN-NIT');
  }

  private detalleOrdenPorInsumo(idOrdenCompra: number, idInsumo: number): any {
    const orden = this.ordenPorId(idOrdenCompra) as any;
    const detalles = orden?.detalles || orden?.ordenCompraDetalles || orden?.orden_compra_detalles || [];

    return detalles.find((detalle: any) => this.idInsumoDetalleOrden(detalle) === idInsumo);
  }

  private idOrdenDetalle(detalle: any): number {
    return Number(detalle?.idOrdenDetalle || detalle?.id_orden_detalle || 0);
  }
}
