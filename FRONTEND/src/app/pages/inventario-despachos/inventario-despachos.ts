import { Component, computed, inject, signal } from '@angular/core';
import {
  AbstractControl,
  FormBuilder,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { catchError, forkJoin, of } from 'rxjs';

import { InventarioDespachosService } from '../../core/services/inventario-despachos.service';
import { InsumosService } from '../../core/services/insumos.service';
import { AlmacenesService } from '../../core/services/almacenes.service';

import { Insumo } from '../../core/models/insumo.model';
import { Almacen } from '../../core/models/almacen.model';
import {
  Despacho,
  InventarioItem,
  MovimientoInventario,
} from '../../core/models/inventario-despachos.model';
import { formatearFechaHoraBolivia } from '../../core/utils/fecha.util';
import {
  FormFieldLabels,
  marcarFormularioInvalido,
  mensajeErrorBackend,
} from '../../core/forms/form-error-messages';
import { CampoValidacionDirective } from '../../core/forms/campo-validacion.directive';

type TabInventario = 'inventario' | 'stock' | 'movimientos' | 'despachos';
type ModoModal = 'ninguno' | 'movimiento' | 'despacho' | 'detalle-despacho';

@Component({
  selector: 'app-inventario-despachos',
  standalone: true,
  imports: [ReactiveFormsModule, CampoValidacionDirective],
  templateUrl: './inventario-despachos.html',
  styleUrl: './inventario-despachos.css',
})
export class InventarioDespachos {
  private readonly inventarioService = inject(InventarioDespachosService);
  private readonly insumosService = inject(InsumosService);
  private readonly almacenesService = inject(AlmacenesService);
  private readonly formBuilder = inject(FormBuilder);
  private readonly etiquetasFormulario: FormFieldLabels = {
    idInsumo: 'Insumo',
    idAlmacen: 'Almacen',
    tipoMovimiento: 'Tipo de movimiento',
    cantidad: 'Cantidad',
    motivoMovimiento: 'Motivo',
    observaciones: 'Observaciones',
    idPedido: 'Pedido aprobado',
    idAlmacenSalida: 'Almacen origen',
  };

  cargando = signal(false);
  guardando = signal(false);
  error = signal('');
  mensaje = signal('');

  tabActual = signal<TabInventario>('inventario');
  busqueda = signal('');

  inventario = signal<InventarioItem[]>([]);
  stockCritico = signal<InventarioItem[]>([]);
  movimientos = signal<MovimientoInventario[]>([]);
  despachos = signal<Despacho[]>([]);
  pedidosAprobados = signal<any[]>([]);
  areasSistema = signal<any[]>([]);
  usuariosSistema = signal<any[]>([]);
  cantidadesDespacho = signal<Record<string, number>>({});
  despachoIntentoGuardar = signal(false);

  insumos = signal<Insumo[]>([]);
  almacenes = signal<Almacen[]>([]);

  modoModal = signal<ModoModal>('ninguno');
  despachoSeleccionado = signal<Despacho | null>(null);

  modalAbierto = computed(() => this.modoModal() !== 'ninguno');

  formDespacho = this.formBuilder.nonNullable.group({
    idPedido: ['', [Validators.required]],
    idAlmacenSalida: ['', [Validators.required]],
    observaciones: [''],
  });

  totalItemsInventario = computed(() => this.inventario().length);

  totalStockCritico = computed(() => this.stockCritico().length);

  totalMovimientos = computed(() => this.movimientos().length);

  totalDespachos = computed(() => this.despachos().length);

  stockDisponibleTotal = computed(() => {
    return this.inventario().reduce((total, item) => {
      return total + Number(this.stockDisponible(item) || 0);
    }, 0);
  });

  inventarioFiltrado = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();

    if (!texto) {
      return this.inventario();
    }

    return this.inventario().filter((item) => {
      return (
        this.codigoInsumo(item).toLowerCase().includes(texto) ||
        this.nombreInsumo(item).toLowerCase().includes(texto) ||
        this.nombreAlmacen(item).toLowerCase().includes(texto) ||
        this.tipoAlmacen(item).toLowerCase().includes(texto) ||
        this.estadoStock(item).toLowerCase().includes(texto)
      );
    });
  });

  stockFiltrado = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();

    if (!texto) {
      return this.stockCritico();
    }

    return this.stockCritico().filter((item) => {
      return (
        this.codigoInsumo(item).toLowerCase().includes(texto) ||
        this.nombreInsumo(item).toLowerCase().includes(texto) ||
        this.nombreAlmacen(item).toLowerCase().includes(texto) ||
        this.estadoStock(item).toLowerCase().includes(texto)
      );
    });
  });

  movimientosFiltrados = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();

    if (!texto) {
      return this.movimientos();
    }

    return this.movimientos().filter((item) => {
      return (
        this.movimientoTipo(item).toLowerCase().includes(texto) ||
        this.movimientoInsumo(item).toLowerCase().includes(texto) ||
        this.movimientoAlmacen(item).toLowerCase().includes(texto) ||
        this.movimientoMotivo(item).toLowerCase().includes(texto)
      );
    });
  });

  despachosFiltrados = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();

    if (!texto) {
      return this.despachos();
    }

    return this.despachos().filter((item) => {
      return (
        this.numeroDespacho(item).toLowerCase().includes(texto) ||
        this.almacenOrigen(item).toLowerCase().includes(texto) ||
        this.areaDestino(item).toLowerCase().includes(texto) ||
        this.estadoDespacho(item).toLowerCase().includes(texto) ||
        this.usuarioResponsable(item).toLowerCase().includes(texto)
      );
    });
  });

  formMovimiento = this.formBuilder.nonNullable.group({
    idInsumo: ['', [Validators.required]],
    idAlmacen: ['', [Validators.required]],
    tipoMovimiento: ['', [Validators.required]],
    cantidad: ['', [Validators.required, Validators.min(0.01)]],
    motivoMovimiento: ['', [Validators.required]],
    observaciones: [''],
  });

  tiposMovimiento = [
    'AJUSTE_POSITIVO',
    'AJUSTE_NEGATIVO',
    'ENTRADA_COMPRA',
    'SALIDA_DESPACHO',
    'DEVOLUCION',
    'CORRECCION',
  ];

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
      pedidosAprobados: this.inventarioService.pedidosAprobadosParaDespacho().pipe(catchError(() => of([]))),
      insumos: this.insumosService.listar().pipe(catchError(() => of([]))),
      almacenes: this.almacenesService.listar().pipe(catchError(() => of([]))),
      usuarios: this.inventarioService.usuariosSistema().pipe(catchError(() => of([]))),
      areas: this.inventarioService.areasSistema().pipe(catchError(() => of([]))),
    }).subscribe({
      next: (data) => {
        const usuarios = this.extraerListaGenericaDespacho(data.usuarios);
        const areas = this.extraerListaGenericaDespacho(data.areas);

        this.inventario.set(data.inventario as InventarioItem[]);
        this.stockCritico.set(data.stock as InventarioItem[]);
        this.movimientos.set(data.movimientos as MovimientoInventario[]);
        this.despachos.set(data.despachos as Despacho[]);
        this.usuariosSistema.set(usuarios);
        this.areasSistema.set(areas);
        this.actualizarPedidosAprobadosDespacho(data.pedidosAprobados, usuarios, areas);
        this.insumos.set(data.insumos as Insumo[]);
        this.almacenes.set(data.almacenes as Almacen[]);
        this.cargando.set(false);
      },
      error: () => {
        this.error.set('No se pudo cargar la información de inventario.');
        this.cargando.set(false);
      },
    });
  }

  cambiarTab(tab: TabInventario) {
    this.tabActual.set(tab);
    this.busqueda.set('');
  }

  cambiarBusqueda(event: Event) {
    const input = event.target as HTMLInputElement;
    this.busqueda.set(input.value);
  }

  abrirMovimiento() {
    this.error.set('');
    this.mensaje.set('');
    this.modoModal.set('movimiento');

    this.formMovimiento.reset({
      idInsumo: '',
      idAlmacen: '',
      tipoMovimiento: '',
      cantidad: '',
      motivoMovimiento: '',
      observaciones: '',
    });
  }

  cerrarModal() {
    this.modoModal.set('ninguno');
    this.despachoSeleccionado.set(null);
    this.cantidadesDespacho.set({});
    this.despachoIntentoGuardar.set(false);
    this.formMovimiento.reset();
    this.formDespacho.reset();
  }

  guardarMovimiento() {
    this.error.set('');
    this.mensaje.set('');

    if (this.formMovimiento.invalid) {
      this.error.set(
        marcarFormularioInvalido(
          this.formMovimiento,
          this.etiquetasFormulario,
          'Revise los campos del movimiento',
        ),
      );
      return;
    }

    const valores = this.formMovimiento.getRawValue();

    const tipoMovimiento = valores.tipoMovimiento;
    const esEntrada = ['ENTRADA_COMPRA', 'AJUSTE_POSITIVO', 'DEVOLUCION'].includes(
      tipoMovimiento,
    );

    const payload = {
      idInsumo: Number(valores.idInsumo),
      ...(esEntrada
        ? { idAlmacenDestino: Number(valores.idAlmacen) }
        : { idAlmacenOrigen: Number(valores.idAlmacen) }),
      tipoMovimiento,
      cantidad: Number(valores.cantidad),
      motivo: valores.motivoMovimiento.trim(),
      observaciones: valores.observaciones?.trim() || undefined,
    };

    this.guardando.set(true);

    this.inventarioService.registrarMovimiento(payload).subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set('Movimiento registrado correctamente.');
        this.cerrarModal();
        this.cargarDatos();
      },
      error: (error) => {
        console.error('Error al registrar movimiento:', error);
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
      },
    });
  }

  abrirDetalleDespacho(despacho: Despacho) {
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

  



  guardarDespacho() {
    this.error.set('');
    this.mensaje.set('');
    this.despachoIntentoGuardar.set(true);
    this.quitarErrorControl(this.formDespacho.controls.idPedido, 'seleccionInvalida');

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

    const valores = this.formDespacho.getRawValue();
    const pedido = this.pedidoDespachoSeleccionado();

    if (!pedido) {
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

    const detalles = this.detallesPedidoDespacho(pedido)
      .map((detalle: any) => ({
        idPedidoDetalle: this.idDetallePedidoDespacho(detalle) || undefined,
        idInsumo: this.idInsumoDetalleDespacho(detalle),
        cantidadSolicitada: this.cantidadSolicitadaDetalleDespacho(detalle),
        cantidadAprobada: this.cantidadAprobadaDetalleDespacho(detalle),
        cantidadEntregada: this.cantidadADespacharDetalle(detalle),
        cantidadPendiente: this.cantidadPendienteDetalleDespacho(detalle),
        stockDisponible: this.stockDisponibleParaDespacho(detalle),
        estadoConformidad: 'CONFORME',
        observacion: detalle?.observacion || detalle?.observaciones || undefined,
      }))
      .filter((detalle: any) => detalle.idInsumo && detalle.cantidadEntregada > 0);

    if (detalles.length === 0) {
      return;
    }

    const detalleExcedido = detalles.find((detalle: any) => {
      return detalle.cantidadEntregada > detalle.cantidadPendiente;
    });

    if (detalleExcedido) {
      return;
    }

    const detalleSinStock = detalles.find((detalle: any) => {
      return detalle.cantidadEntregada > detalle.stockDisponible;
    });

    if (detalleSinStock) {
      return;
    }

    this.despachoIntentoGuardar.set(false);

    const idAreaSolicitante = this.idAreaPedidoDespacho(pedido);
    const idUsuarioSolicitante = this.idUsuarioPedidoDespacho(pedido);

    const payload: any = {
      idPedido: Number(valores.idPedido),
      idAlmacenSalida: Number(valores.idAlmacenSalida),
      ...(idAreaSolicitante ? { idAreaSolicitante } : {}),
      ...(idUsuarioSolicitante ? { idUsuarioSolicitante } : {}),
      personaRecibe: this.solicitantePedidoDespacho(pedido),
      tipoDespacho: 'NORMAL',
      confirmacionRecepcion: true,
      observaciones: valores.observaciones?.trim() || undefined,
      detalles: detalles.map(({ cantidadPendiente, stockDisponible, ...detalle }: any) => detalle),
    };

    this.guardando.set(true);

    this.inventarioService.crearDespacho(payload).subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set('Despacho generado correctamente.');
        this.cerrarModal();
        this.cambiarTab('despachos');
        this.cargarDatos();
      },
      error: (error) => {
        console.error('Error al generar despacho:', error);
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
      },
    });
  }






  extraerListaPedidosParaDespacho(data: any): any[] {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data?.data)) return data.data;
    if (Array.isArray(data?.items)) return data.items;
    if (Array.isArray(data?.pedidos)) return data.pedidos;
    if (Array.isArray(data?.resultados)) return data.resultados;
    if (Array.isArray(data?.registros)) return data.registros;
    if (Array.isArray(data?.content)) return data.content;
    if (Array.isArray(data?.rows)) return data.rows;
    return [];
  }


















  idDetallePedidoDespacho(detalle: any): number {
    return Number(
      detalle?.idDetallePedido ||
        detalle?.id_detalle_pedido ||
        detalle?.idDetalle ||
        detalle?.id_detalle ||
        detalle?.id ||
        0,
    );
  }

  idInsumoDetalleDespacho(detalle: any): number {
    return Number(
      detalle?.idInsumo ||
        detalle?.id_insumo ||
        detalle?.insumo?.idInsumo ||
        detalle?.insumo?.id_insumo ||
        detalle?.insumo?.id ||
        0,
    );
  }













  cargarApoyosDespacho() {
    this.inventarioService.areasSistema().subscribe({
      next: (data) => {
        this.areasSistema.set(this.extraerListaGenericaDespacho(data));
      },
      error: () => {
        this.areasSistema.set([]);
      },
    });

    this.inventarioService.usuariosSistema().subscribe({
      next: (data) => {
        this.usuariosSistema.set(this.extraerListaGenericaDespacho(data));
      },
      error: () => {
        this.usuariosSistema.set([]);
      },
    });
  }

  extraerListaGenericaDespacho(data: any): any[] {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data?.data)) return data.data;
    if (Array.isArray(data?.items)) return data.items;
    if (Array.isArray(data?.registros)) return data.registros;
    if (Array.isArray(data?.areas)) return data.areas;
    if (Array.isArray(data?.usuarios)) return data.usuarios;
    if (Array.isArray(data?.pedidos)) return data.pedidos;
    if (Array.isArray(data?.resultados)) return data.resultados;
    if (Array.isArray(data?.content)) return data.content;
    if (Array.isArray(data?.rows)) return data.rows;
    return [];
  }







  normalizarClaveDespacho(valor: string): string {
    return String(valor || '')
      .toLowerCase()
      .replace(/_/g, '')
      .replace(/-/g, '')
      .trim();
  }

  buscarTextoPedidoDespacho(objeto: any, claves: string[]): string {
    const clavesNormalizadas = claves.map((clave) => this.normalizarClaveDespacho(clave));
    const visitados = new Set<any>();
    const cola: any[] = [objeto];

    while (cola.length) {
      const actual = cola.shift();

      if (!actual || visitados.has(actual)) {
        continue;
      }

      visitados.add(actual);

      if (typeof actual !== 'object') {
        continue;
      }

      for (const [clave, valor] of Object.entries(actual)) {
        const claveNormalizada = this.normalizarClaveDespacho(clave);

        if (clavesNormalizadas.includes(claveNormalizada)) {
          if (valor !== null && valor !== undefined && typeof valor !== 'object') {
            const texto = String(valor).trim();
            if (texto && texto !== '[object Object]') {
              return texto;
            }
          }

          if (valor && typeof valor === 'object') {
            for (const subValor of Object.values(valor)) {
              if (subValor !== null && subValor !== undefined && typeof subValor !== 'object') {
                const texto = String(subValor).trim();
                if (texto && texto !== '[object Object]') {
                  return texto;
                }
              }
            }
          }
        }

        if (valor && typeof valor === 'object') {
          cola.push(valor);
        }
      }
    }

    return '';
  }

















  stockDisponibleParaDespacho(detalle: any): number {
    const idInsumo = this.idInsumoDetalleDespacho(detalle);
    const idAlmacen = Number(this.formDespacho.get('idAlmacenSalida')?.value || 0);

    const item = this.inventario().find((registro: any) => {
      const registroIdInsumo = Number(
        registro?.idInsumo ||
          registro?.id_insumo ||
          registro?.insumo?.idInsumo ||
          registro?.insumo?.id_insumo ||
          0,
      );

      const registroIdAlmacen = Number(
        registro?.idAlmacen ||
          registro?.id_almacen ||
          registro?.almacen?.idAlmacen ||
          registro?.almacen?.id_almacen ||
          0,
      );

      return registroIdInsumo === idInsumo && registroIdAlmacen === idAlmacen;
    });

    return Number(
      item?.stockDisponible ||
        item?.stock_disponible ||
        item?.stockFisico ||
        item?.stock_fisico ||
        0,
    );
  }


  

  textoAlmacenDespacho(almacen: any): string {
    const codigo = String(
      almacen?.codigoAlmacen ||
        almacen?.codigo_almacen ||
        almacen?.codigo ||
        '',
    ).trim();

    const nombre = String(
      almacen?.nombreAlmacen ||
        almacen?.nombre_almacen ||
        almacen?.nombre ||
        'Sin almacén',
    ).trim();

    return codigo ? `${codigo} - ${nombre}` : nombre;
  }



  abrirGenerarDespacho() {
    this.error.set('');
    this.mensaje.set('');
    this.modoModal.set('despacho');
    this.cantidadesDespacho.set({});
    this.despachoIntentoGuardar.set(false);

    this.formDespacho.reset({
      idPedido: '',
      idAlmacenSalida: '',
      observaciones: '',
    });

    this.cargarPedidosAprobadosDespacho();
  }

  cargarPedidosAprobadosDespacho() {
    forkJoin({
      pedidos: this.inventarioService.pedidosAprobadosParaDespacho().pipe(catchError(() => of([]))),
      usuarios: this.inventarioService.usuariosSistema().pipe(catchError(() => of([]))),
      areas: this.inventarioService.areasSistema().pipe(catchError(() => of([]))),
    }).subscribe({
      next: ({ pedidos, usuarios, areas }) => {
        const usuariosLista = this.extraerListaGenericaDespacho(usuarios);
        const areasLista = this.extraerListaGenericaDespacho(areas);

        this.usuariosSistema.set(usuariosLista);
        this.areasSistema.set(areasLista);
        this.actualizarPedidosAprobadosDespacho(pedidos, usuariosLista, areasLista);
      },
      error: () => {
        this.pedidosAprobados.set([]);
        this.error.set('No se pudieron cargar los pedidos aprobados para despacho.');
      },
    });
  }

  actualizarPedidosAprobadosDespacho(data: any, usuarios = this.usuariosSistema(), areas = this.areasSistema()) {
    const pedidos = this.filtrarPedidosDisponiblesParaDespacho(data)
      .map((pedido: any) => this.normalizarPedidoDespacho(pedido, usuarios, areas))
      .filter((pedido: any) => {
        return this.detallesPedidoDespacho(pedido).some((detalle: any) => {
          return this.cantidadPendienteDetalleDespacho(detalle) > 0;
        });
      });

    this.pedidosAprobados.set(pedidos);
    this.inicializarCantidadesDespacho(pedidos);
  }

  normalizarPedidoDespacho(pedido: any, usuarios: any[], areas: any[]): any {
    const usuarioDirecto =
      pedido?.usuarioSolicitante ||
      pedido?.usuario_solicitante ||
      pedido?.solicitante ||
      null;
    const idUsuario = Number(
      pedido?.idUsuarioSolicitante ||
        pedido?.id_usuario_solicitante ||
        usuarioDirecto?.idUsuario ||
        usuarioDirecto?.id_usuario ||
        usuarioDirecto?.id ||
        0,
    );
    const usuarioPorId = usuarios.find((item: any) => {
      return Number(item?.idUsuario || item?.id_usuario || item?.id || 0) === idUsuario;
    });
    const usuarioSolicitante = usuarioDirecto || usuarioPorId || null;

    const areaDirecta =
      pedido?.areaSolicitante ||
      pedido?.area_solicitante ||
      pedido?.area ||
      null;
    const areaUsuario =
      usuarioSolicitante?.area ||
      usuarioSolicitante?.areaUsuario ||
      usuarioSolicitante?.area_usuario ||
      null;
    const idArea = Number(
      pedido?.idAreaSolicitante ||
        pedido?.id_area_solicitante ||
        areaDirecta?.idArea ||
        areaDirecta?.id_area ||
        areaDirecta?.id ||
        areaUsuario?.idArea ||
        areaUsuario?.id_area ||
        0,
    );
    const areaPorId = areas.find((item: any) => {
      return Number(item?.idArea || item?.id_area || item?.id || 0) === idArea;
    });
    const areaSolicitante = areaDirecta || areaPorId || areaUsuario || null;
    const nombreArea =
      this.textoLimpioDespacho(areaSolicitante, '') ||
      this.textoLimpioDespacho(areaPorId, '') ||
      (idArea ? `Area ${idArea}` : 'Sin area');
    const nombreUsuario =
      this.textoLimpioDespacho(usuarioSolicitante, '') ||
      this.textoLimpioDespacho(usuarioPorId, '') ||
      (idUsuario ? `Usuario ${idUsuario}` : 'Solicitante');

    const detalles = this.detallesPedidoDespacho(pedido).map((detalle: any) => ({
      ...detalle,
      cantidadSolicitada: this.cantidadSolicitadaDetalleDespacho(detalle),
      cantidadAprobada: this.cantidadAprobadaDetalleDespacho(detalle),
      cantidadDespachada: this.cantidadDespachadaDetalleDespacho(detalle),
      cantidadPendiente: this.cantidadPendienteDetalleDespacho(detalle),
      insumo: detalle?.insumo || null,
    }));

    return {
      ...pedido,
      idUsuarioSolicitante: idUsuario || pedido?.idUsuarioSolicitante,
      idAreaSolicitante: idArea || pedido?.idAreaSolicitante,
      usuarioSolicitante,
      solicitante: usuarioSolicitante,
      areaSolicitante,
      area: areaSolicitante,
      nombreAreaSolicitante: nombreArea,
      areaSolicitanteNombre: nombreArea,
      nombreUsuarioSolicitante: nombreUsuario,
      usuarioSolicitanteNombre: nombreUsuario,
      detalles,
    };
  }

  inicializarCantidadesDespacho(pedidos: any[]) {
    const cantidades: Record<string, number> = {};

    pedidos.forEach((pedido) => {
      this.detallesPedidoDespacho(pedido).forEach((detalle: any) => {
        const clave = this.claveDetalleDespacho(detalle);
        if (clave) {
          cantidades[clave] = this.cantidadPendienteDetalleDespacho(detalle);
        }
      });
    });

    this.cantidadesDespacho.set(cantidades);
  }


  textoLimpioDespacho(valor: any, fallback = 'Sin dato'): string {
    if (valor === null || valor === undefined) return fallback;

    if (typeof valor === 'object') {
      const posible =
        valor?.nombreAreaSolicitante ||
        valor?.areaSolicitanteNombre ||
        valor?.nombreUsuarioSolicitante ||
        valor?.usuarioSolicitanteNombre ||
        valor?.nombreArea ||
        valor?.nombre_area ||
        valor?.nombreCompleto ||
        valor?.nombre_completo ||
        valor?.nombreUsuario ||
        valor?.nombre_usuario ||
        valor?.nombreInsumo ||
        valor?.nombre_insumo ||
        valor?.nombre ||
        valor?.descripcion ||
        valor?.codigo ||
        valor?.codigoInsumo ||
        valor?.codigo_insumo;

      return this.textoLimpioDespacho(posible, fallback);
    }

    const texto = String(valor).trim();

    if (!texto || texto === '[object Object]' || texto.toLowerCase() === 'null') {
      return fallback;
    }

    return texto;
  }

  numeroPositivoDespacho(valor: any): number {
    const numero = Number(valor ?? 0);
    return Number.isFinite(numero) && numero > 0 ? numero : 0;
  }

  numeroFinitoDespacho(valor: any): number | null {
    if (valor === null || valor === undefined || valor === '') {
      return null;
    }

    const numero = Number(valor);
    return Number.isFinite(numero) ? numero : null;
  }

  normalizarTextoDespacho(valor: any): string {
    if (valor === null || valor === undefined) return '';

    const texto = typeof valor === 'object'
      ? JSON.stringify(valor)
      : String(valor);

    return texto
      .trim()
      .toUpperCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '');
  }

  filtrarPedidosDisponiblesParaDespacho(data: any): any[] {
    const lista = this.extraerListaGenericaDespacho(data);

    return lista.filter((pedido: any) => {
      const texto = this.normalizarTextoDespacho(pedido);

      const estado = this.normalizarTextoDespacho(
        pedido?.estadoPedido ||
          pedido?.estado_pedido ||
          pedido?.estado ||
          '',
      );

      const aprobacion = this.normalizarTextoDespacho(
        pedido?.estadoAprobacion ||
          pedido?.estado_aprobacion ||
          pedido?.aprobacion ||
          '',
      );

      if (
        texto.includes('RECHAZADO') ||
        texto.includes('CANCELADO') ||
        texto.includes('ANULADO') ||
        texto.includes('ELIMINADO') ||
        texto.includes('ENTREGADO_COMPLETO')
      ) {
        return false;
      }

      return estado === 'APROBADO' || aprobacion === 'APROBADO' || texto.includes('APROBADO');
    });
  }

  idPedidoDespacho(pedido: any): number {
    return Number(pedido?.idPedido || pedido?.id_pedido || pedido?.id || 0);
  }

  numeroPedidoDespacho(pedido: any): string {
    return String(
      pedido?.numeroPedido ||
        pedido?.numero_pedido ||
        pedido?.codigoPedido ||
        pedido?.codigo_pedido ||
        ('PED-' + this.idPedidoDespacho(pedido)),
    );
  }

  idUsuarioPedidoDespacho(pedido: any): number {
    return Number(
      pedido?.idUsuarioSolicitante ||
        pedido?.id_usuario_solicitante ||
        pedido?.usuarioSolicitante?.idUsuario ||
        pedido?.usuarioSolicitante?.id_usuario ||
        pedido?.solicitante?.idUsuario ||
        pedido?.solicitante?.id_usuario ||
        0,
    );
  }

  idAreaPedidoDespacho(pedido: any): number {
    return Number(
      pedido?.idAreaSolicitante ||
        pedido?.id_area_solicitante ||
        pedido?.areaSolicitante?.idArea ||
        pedido?.areaSolicitante?.id_area ||
        pedido?.area?.idArea ||
        pedido?.area?.id_area ||
        pedido?.usuarioSolicitante?.area?.idArea ||
        pedido?.solicitante?.area?.idArea ||
        0,
    );
  }

  areaPedidoDespacho(pedido: any): string {
    const idArea = this.idAreaPedidoDespacho(pedido);
    const areaPorId = this.areasSistema().find((area: any) => {
      return Number(area?.idArea || area?.id_area || area?.id || 0) === idArea;
    });

    return this.textoLimpioDespacho(
      pedido?.nombreAreaSolicitante ||
        pedido?.areaSolicitanteNombre ||
        pedido?.areaSolicitante ||
        pedido?.area_solicitante ||
        pedido?.area ||
        areaPorId ||
        (idArea ? `Area ${idArea}` : ''),
      'Sin área',
    );
  }

  solicitantePedidoDespacho(pedido: any): string {
    const idUsuario = this.idUsuarioPedidoDespacho(pedido);
    const usuarioPorId = this.usuariosSistema().find((usuario: any) => {
      return Number(usuario?.idUsuario || usuario?.id_usuario || usuario?.id || 0) === idUsuario;
    });

    return this.textoLimpioDespacho(
      pedido?.nombreUsuarioSolicitante ||
        pedido?.usuarioSolicitanteNombre ||
        pedido?.usuarioSolicitante ||
        pedido?.usuario_solicitante ||
        pedido?.solicitante ||
        usuarioPorId ||
        (idUsuario ? `Usuario ${idUsuario}` : ''),
      'Solicitante',
    );
  }

  labelPedidoDespacho(pedido: any): string {
    return this.numeroPedidoDespacho(pedido) + ' - ' + this.areaPedidoDespacho(pedido) + ' - ' + this.solicitantePedidoDespacho(pedido);
  }

  pedidoDespachoSeleccionado(): any {
    const id = Number(this.formDespacho.get('idPedido')?.value || 0);
    return this.pedidosAprobados().find((pedido: any) => this.idPedidoDespacho(pedido) === id) || null;
  }

  detallesPedidoDespacho(pedido: any): any[] {
    const detalles =
      pedido?.detalles ||
      pedido?.detallePedidos ||
      pedido?.detalle_pedidos ||
      pedido?.detallesPedido ||
      pedido?.detalles_pedido ||
      [];

    return Array.isArray(detalles) ? detalles : [];
  }

  nombreInsumoDetalleDespacho(detalle: any): string {
    return this.textoLimpioDespacho(
      detalle?.insumo ||
        detalle?.nombreInsumo ||
        detalle?.nombre_insumo ||
        detalle?.descripcionInsumo ||
        detalle?.descripcion_insumo,
      'Sin insumo',
    );
  }

  codigoInsumoDetalleDespacho(detalle: any): string {
    return this.textoLimpioDespacho(
      detalle?.codigoInsumo ||
        detalle?.codigo_insumo ||
        detalle?.insumo?.codigoInsumo ||
        detalle?.insumo?.codigo_insumo ||
        detalle?.insumo?.codigo ||
        detalle?.codigo,
      '',
    );
  }

  cantidadSolicitadaDetalleDespacho(detalle: any): number {
    const valores = [
      detalle?.cantidadSolicitada,
      detalle?.cantidad_solicitada,
      detalle?.cantidadPedida,
      detalle?.cantidad_pedida,
      detalle?.cantidadRequerida,
      detalle?.cantidad_requerida,
      detalle?.cantidadAprobada,
      detalle?.cantidad_aprobada,
      detalle?.cantidad,
    ];

    for (const valor of valores) {
      const numero = this.numeroPositivoDespacho(valor);
      if (numero > 0) return numero;
    }

    return 0;
  }

  cantidadAprobadaDetalleDespacho(detalle: any): number {
    const valores = [
      detalle?.cantidadAprobada,
      detalle?.cantidad_aprobada,
      detalle?.cantidadAutorizada,
      detalle?.cantidad_autorizada,
      detalle?.cantidadSolicitada,
      detalle?.cantidad_solicitada,
      detalle?.cantidad,
    ];

    for (const valor of valores) {
      const numero = this.numeroPositivoDespacho(valor);
      if (numero > 0) return numero;
    }

    return 0;
  }

  cantidadDespachadaDetalleDespacho(detalle: any): number {
    return (
      this.numeroPositivoDespacho(detalle?.cantidadDespachada) ||
      this.numeroPositivoDespacho(detalle?.cantidad_despachada) ||
      this.numeroPositivoDespacho(detalle?.cantidadEntregada) ||
      this.numeroPositivoDespacho(detalle?.cantidad_entregada) ||
      this.numeroPositivoDespacho(detalle?.cantidadAtendida) ||
      this.numeroPositivoDespacho(detalle?.cantidad_atendida) ||
      0
    );
  }

  cantidadPendienteDetalleDespacho(detalle: any): number {
    const directa =
      this.numeroFinitoDespacho(detalle?.cantidadPendiente) ??
      this.numeroFinitoDespacho(detalle?.cantidad_pendiente) ??
      this.numeroFinitoDespacho(detalle?.pendiente);

    if (directa !== null && directa !== undefined) {
      return Math.max(directa, 0);
    }

    const solicitada = this.cantidadSolicitadaDetalleDespacho(detalle);
    const despachada = this.cantidadDespachadaDetalleDespacho(detalle);

    return Math.max(solicitada - despachada, 0);
  }

  cantidadADespacharDetalle(detalle: any): number {
    const clave = this.claveDetalleDespacho(detalle);
    const valor = clave ? this.cantidadesDespacho()[clave] : undefined;

    if (valor === undefined || valor === null) {
      return this.cantidadPendienteDetalleDespacho(detalle);
    }

    return Math.max(Number(valor) || 0, 0);
  }

  claveDetalleDespacho(detalle: any): string {
    const idDetalle = this.idDetallePedidoDespacho(detalle);
    const idInsumo = this.idInsumoDetalleDespacho(detalle);

    return idDetalle ? `detalle-${idDetalle}` : idInsumo ? `insumo-${idInsumo}` : '';
  }

  cambiarCantidadDespacho(detalle: any, event: Event) {
    const input = event.target as HTMLInputElement;
    const clave = this.claveDetalleDespacho(detalle);

    if (!clave) {
      return;
    }

    const pendiente = this.cantidadPendienteDetalleDespacho(detalle);
    const valor = Math.min(Math.max(Number(input.value || 0), 0), pendiente);

    this.cantidadesDespacho.update((actual) => ({
      ...actual,
      [clave]: valor,
    }));
  }

  despachoValido(): boolean {
    const pedido = this.pedidoDespachoSeleccionado();

    if (!pedido || this.formDespacho.invalid) {
      return false;
    }

    const detalles = this.detallesPedidoDespacho(pedido);
    let tieneCantidad = false;

    for (const detalle of detalles) {
      const cantidad = this.cantidadADespacharDetalle(detalle);

      if (cantidad <= 0) {
        continue;
      }

      tieneCantidad = true;

      if (
        cantidad > this.cantidadPendienteDetalleDespacho(detalle) ||
        cantidad > this.stockDisponibleParaDespacho(detalle)
      ) {
        return false;
      }
    }

    return tieneCantidad;
  }

  cantidadDespachoInvalida(detalle: any): boolean {
    if (!this.despachoIntentoGuardar()) {
      return false;
    }

    const cantidad = this.cantidadADespacharDetalle(detalle);

    return (
      (!this.tieneAlgunaCantidadDespacho() && cantidad <= 0) ||
      cantidad > this.cantidadPendienteDetalleDespacho(detalle) ||
      cantidad > this.stockDisponibleParaDespacho(detalle)
    );
  }

  mensajeCantidadDespacho(detalle: any): string {
    const cantidad = this.cantidadADespacharDetalle(detalle);

    if (!this.tieneAlgunaCantidadDespacho() && cantidad <= 0) {
      return 'Ingrese una cantidad mayor a cero.';
    }

    if (cantidad > this.cantidadPendienteDetalleDespacho(detalle)) {
      return 'No puede superar el pendiente.';
    }

    if (cantidad > this.stockDisponibleParaDespacho(detalle)) {
      return 'No puede superar el stock disponible.';
    }

    return '';
  }

  private tieneAlgunaCantidadDespacho(): boolean {
    const pedido = this.pedidoDespachoSeleccionado();

    return Boolean(
      pedido &&
        this.detallesPedidoDespacho(pedido).some(
          (detalle: any) => this.cantidadADespacharDetalle(detalle) > 0,
        ),
    );
  }

  obtenerMensajeErrorBackend(error: any): string {
    const mensaje = mensajeErrorBackend(error, this.etiquetasFormulario);

    if (Array.isArray(mensaje)) {
      return mensaje.join(' | ');
    }

    if (typeof mensaje === 'string') {
      return mensaje;
    }

    if (error?.error?.error) {
      return error.error.error;
    }

    return 'No se pudo completar la operación. Revise los datos enviados.';
  }

  private quitarErrorControl(control: AbstractControl, codigo: string) {
    if (!control.hasError(codigo)) {
      return;
    }

    const errores = { ...(control.errors ?? {}) };
    delete errores[codigo];
    control.setErrors(Object.keys(errores).length ? errores : null);
  }

  valor(item: Record<string, unknown>, camel: string, snake: string): any {
    return item[camel] ?? item[snake] ?? '';
  }

  codigoInsumo(item: InventarioItem): string {
    return String(
      item.codigoInterno ||
        item.codigo_interno ||
        item.insumo?.codigoInterno ||
        item.insumo?.codigo_interno ||
        'Sin código',
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
        'Sin almacén',
    );
  }

  tipoAlmacen(item: InventarioItem): string {
    return String(
      item.tipoAlmacen ||
        item.tipo_almacen ||
        item.almacen?.tipoAlmacen ||
        item.almacen?.tipo_almacen ||
        'Sin tipo',
    );
  }

  stockFisico(item: InventarioItem): string | number {
    return item.stockFisico || item.stock_fisico || 0;
  }

  stockReservado(item: InventarioItem): string | number {
    return item.stockReservado || item.stock_reservado || 0;
  }

  stockDisponible(item: InventarioItem): string | number {
    return item.stockDisponible || item.stock_disponible || 0;
  }

  estadoStock(item: InventarioItem): string {
    return String(item.estadoStock || item.estado_stock || item.estado || 'NORMAL');
  }

  movimientoTipo(item: MovimientoInventario): string {
    return String(item.tipoMovimiento || item.tipo_movimiento || 'Sin tipo');
  }

  movimientoInsumo(item: MovimientoInventario): string {
    const data = item as any;
    return String(
      item.nombreInsumo ||
        item.nombre_insumo ||
        data.insumo?.nombreInsumo ||
        data.insumo?.nombre_insumo ||
        'Sin insumo',
    );
  }

  movimientoAlmacen(item: MovimientoInventario): string {
    const data = item as any;
    const origen = data.almacenOrigen || data.almacen_origen;
    const destino = data.almacenDestino || data.almacen_destino || data.almacen;
    const almacen = destino || origen;

    return String(
      item.nombreAlmacen ||
        item.nombre_almacen ||
        almacen?.nombreAlmacen ||
        almacen?.nombre_almacen ||
        almacen?.codigoAlmacen ||
        almacen?.codigo_almacen ||
        'Sin almacén',
    );
  }

  movimientoCantidad(item: MovimientoInventario): string | number {
    return item.cantidad || 0;
  }

  movimientoFecha(item: MovimientoInventario): string {
    return String(item.fechaMovimiento || item.fecha_movimiento || '');
  }

  movimientoMotivo(item: MovimientoInventario): string {
    const data = item as any;
    return String(
      item.motivoMovimiento ||
        item.motivo_movimiento ||
        data.motivo ||
        item.observaciones ||
        'Sin motivo',
    );
  }

  idDespacho(item: Despacho): number {
    return Number(item.idDespacho || item.id_despacho || 0);
  }

  numeroDespacho(item: Despacho): string {
    return String(item.numeroDespacho || item.numero_despacho || `DESP-${this.idDespacho(item)}`);
  }

  fechaDespacho(item: Despacho): string {
    const data = item as any;
    return String(
      item.fechaDespacho ||
        item.fecha_despacho ||
        data.fechaRealEntrega ||
        data.fecha_real_entrega ||
        data.fechaProgramadaEntrega ||
        data.fecha_programada_entrega ||
        '',
    );
  }

  almacenOrigen(item: Despacho): string {
    const data = item as any;
    const almacen = data.almacenSalida || data.almacen_salida || data.almacenOrigen || data.almacen_origen;

    return String(
      almacen?.nombreAlmacen ||
        almacen?.nombre_almacen ||
        almacen?.codigoAlmacen ||
        almacen?.codigo_almacen ||
        item.almacenOrigen ||
        item.almacen_origen ||
        'Sin almacén',
    );
  }

  areaDestino(item: Despacho): string {
    const data = item as any;
    const area = data.areaSolicitante || data.area_solicitante || data.areaDestino || data.area_destino;

    return String(
      area?.nombreArea ||
        area?.nombre_area ||
        item.areaDestino ||
        item.area_destino ||
        'Sin destino',
    );
  }

  usuarioResponsable(item: Despacho): string {
    const data = item as any;
    const usuario =
      data.responsableAlmacen ||
      data.responsable_almacen ||
      data.usuarioResponsable ||
      data.usuario_responsable ||
      data.usuarioSolicitante ||
      data.usuario_solicitante;

    return String(
      usuario?.nombreCompleto ||
        usuario?.nombre_completo ||
        usuario?.nombreUsuario ||
        usuario?.nombre_usuario ||
        item.usuarioResponsable ||
        item.usuario_responsable ||
        'Sin responsable',
    );
  }

  estadoDespacho(item: Despacho): string {
    return String(item.estadoDespacho || item.estado_despacho || 'Sin estado');
  }

  detallesDespacho(item: Despacho): any[] {
    return item.detalles || [];
  }

  detalleCodigo(detalle: any): string {
    return String(
      detalle.codigoInterno ||
        detalle.codigo_interno ||
        detalle.insumo?.codigoInterno ||
        detalle.insumo?.codigo_interno ||
        'Sin código',
    );
  }

  detalleInsumo(detalle: any): string {
    return String(
      detalle.nombreInsumo ||
        detalle.nombre_insumo ||
        detalle.insumo?.nombreInsumo ||
        detalle.insumo?.nombre_insumo ||
        'Sin insumo',
    );
  }

  detalleCantidadEntregada(detalle: any): string | number {
    return (
      detalle.cantidadEntregada ||
      detalle.cantidad_entregada ||
      detalle.cantidadDespachada ||
      detalle.cantidad_despachada ||
      0
    );
  }

  fechaFormateada(fecha: string): string {
    return formatearFechaHoraBolivia(fecha);
  }

  claseStock(estado: string): string {
    const normalizado = estado?.toUpperCase();

    if (normalizado.includes('CRITICO') || normalizado.includes('BAJO')) {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    if (normalizado.includes('MEDIO')) {
      return 'bg-orange-100 text-orange-700 border-orange-200';
    }

    return 'bg-green-100 text-green-700 border-green-200';
  }

  claseMovimiento(tipo: string): string {
    const normalizado = tipo?.toUpperCase();

    if (normalizado.includes('ENTRADA') || normalizado.includes('POSITIVO')) {
      return 'bg-green-100 text-green-700 border-green-200';
    }

    if (normalizado.includes('SALIDA') || normalizado.includes('NEGATIVO')) {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    return 'bg-blue-100 text-blue-700 border-blue-200';
  }

  claseDespacho(estado: string): string {
    const normalizado = estado?.toUpperCase();

    if (normalizado.includes('ENTREGADO') || normalizado.includes('COMPLETO')) {
      return 'bg-green-100 text-green-700 border-green-200';
    }

    if (normalizado.includes('PENDIENTE')) {
      return 'bg-orange-100 text-orange-700 border-orange-200';
    }

    return 'bg-blue-100 text-blue-700 border-blue-200';
  }
}
