import { Component, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { InsumosService } from '../../core/services/insumos.service';
import { PermissionService } from '../../core/services/permission.service';
import { CategoriaInsumo, Insumo, TipoInsumo, UnidadMedida } from '../../core/models/insumo.model';
import {
  codigoAlfanumericoGuionValidator,
  normalizarMayusculas,
} from '../../core/forms/professional-forms';
import {
  FormFieldLabels,
  marcarFormularioInvalido,
  mensajeErrorBackend,
} from '../../core/forms/form-error-messages';
import { CampoValidacionDirective } from '../../core/forms/campo-validacion.directive';

type ModoModal = 'ninguno' | 'nuevo' | 'editar' | 'ver';
type ModoConfirmacion = 'ninguno' | 'activar' | 'desactivar' | 'eliminar';

@Component({
  selector: 'app-insumos',
  standalone: true,
  imports: [ReactiveFormsModule, CampoValidacionDirective],
  templateUrl: './insumos.html',
  styleUrl: './insumos.css',
})
export class Insumos {
  private readonly insumosService = inject(InsumosService);
  private readonly permissionService = inject(PermissionService);
  private readonly formBuilder = inject(FormBuilder);
  private readonly etiquetasFormulario: FormFieldLabels = {
    codigoInterno: 'Codigo interno',
    nombreInsumo: 'Nombre del insumo',
    descripcion: 'Descripcion',
    precioReferencial: 'Precio referencial',
    stockMinimo: 'Stock minimo',
    idCategoria: 'Categoria',
    idTipoInsumo: 'Tipo de insumo',
    idUnidadMedida: 'Unidad de medida',
  };

  cargando = signal(false);
  guardando = signal(false);
  error = signal('');
  mensaje = signal('');

  busqueda = signal('');
  insumos = signal<Insumo[]>([]);

  categorias = signal<CategoriaInsumo[]>([]);
  tipos = signal<TipoInsumo[]>([]);
  unidadesMedida = signal<UnidadMedida[]>([]);

  modoModal = signal<ModoModal>('ninguno');
  modoConfirmacion = signal<ModoConfirmacion>('ninguno');
  insumoSeleccionado = signal<Insumo | null>(null);

  modalAbierto = computed(() => this.modoModal() !== 'ninguno');
  confirmacionAbierta = computed(() => this.modoConfirmacion() !== 'ninguno');

  totalInsumos = computed(() => this.insumos().length);

  totalActivos = computed(() => this.insumos().filter((i) => i.estado === 'ACTIVO').length);

  totalInactivos = computed(() => this.insumos().filter((i) => i.estado === 'INACTIVO').length);

  insumosFiltrados = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();

    if (!texto) {
      return this.insumos();
    }

    return this.insumos().filter((insumo) => {
      return (
        insumo.codigoInterno?.toLowerCase().includes(texto) ||
        insumo.nombreInsumo?.toLowerCase().includes(texto) ||
        insumo.descripcion?.toLowerCase().includes(texto) ||
        insumo.estado?.toLowerCase().includes(texto) ||
        this.obtenerCategoriaNombre(insumo).toLowerCase().includes(texto) ||
        this.obtenerTipoNombre(insumo).toLowerCase().includes(texto) ||
        this.obtenerUnidadNombre(insumo).toLowerCase().includes(texto)
      );
    });
  });

  form = this.formBuilder.nonNullable.group({
    codigoInterno: [
      '',
      [Validators.required, Validators.maxLength(10), codigoAlfanumericoGuionValidator()],
    ],
    nombreInsumo: ['', [Validators.required, Validators.maxLength(50)]],
    descripcion: [''],
    precioReferencial: [0, [Validators.required, Validators.min(0)]],
    stockMinimo: [0, [Validators.required, Validators.min(0)]],
    idCategoria: ['', [Validators.required]],
    idTipoInsumo: ['', [Validators.required]],
    idUnidadMedida: ['', [Validators.required]],
  });

  ngOnInit() {
    this.cargarInsumos();
    this.cargarCatalogos();
  }

  cargarInsumos() {
    this.cargando.set(true);
    this.error.set('');
    this.mensaje.set('');

    this.insumosService.listar().subscribe({
      next: (data) => {
        this.insumos.set(data);
        this.cargando.set(false);
      },
      error: () => {
        this.error.set('No se pudo cargar la lista de insumos.');
        this.cargando.set(false);
      },
    });
  }

  cargarCatalogos() {
    this.insumosService.catalogos().subscribe({
      next: (data) => {
        this.categorias.set(data?.categorias || []);
        this.tipos.set(data?.tiposInsumo || data?.tipos || []);
        this.unidadesMedida.set(data?.unidadesMedida || []);
      },
      error: () => {
        this.categorias.set([]);
        this.tipos.set([]);
        this.unidadesMedida.set([]);
      },
    });
  }

  cambiarBusqueda(event: Event) {
    const input = event.target as HTMLInputElement;
    this.busqueda.set(input.value);
  }

  normalizarCodigoInput() {
    const control = this.form.controls.codigoInterno;
    const valor = normalizarMayusculas(control.value).slice(0, 10);

    if (valor !== control.value) {
      control.setValue(valor, { emitEvent: false });
    }
  }

  abrirNuevo() {
    if (!this.verificarPermiso('insumos.crear')) {
      return;
    }

    this.error.set('');
    this.mensaje.set('');
    this.insumoSeleccionado.set(null);
    this.modoModal.set('nuevo');

    this.form.reset({
      codigoInterno: '',
      nombreInsumo: '',
      descripcion: '',
      precioReferencial: 0,
      stockMinimo: 0,
      idCategoria: '',
      idTipoInsumo: '',
      idUnidadMedida: '',
    });
  }

  abrirVer(insumo: Insumo) {
    this.insumoSeleccionado.set(insumo);
    this.modoModal.set('ver');
  }

  abrirEditar(insumo: Insumo) {
    if (!this.verificarPermiso('insumos.editar')) {
      return;
    }

    this.error.set('');
    this.mensaje.set('');
    this.insumoSeleccionado.set(insumo);
    this.modoModal.set('editar');

    this.form.reset({
      codigoInterno: insumo.codigoInterno || '',
      nombreInsumo: insumo.nombreInsumo || '',
      descripcion: insumo.descripcion || '',
      precioReferencial: Number(
        insumo.precioReferencial ?? insumo.precio_referencial ?? 0,
      ),
      stockMinimo: Number(insumo.stockMinimo ?? insumo.stock_minimo ?? 0),
      idCategoria: String(this.obtenerIdCategoria(insumo) || ''),
      idTipoInsumo: String(this.obtenerIdTipo(insumo) || ''),
      idUnidadMedida: String(this.obtenerIdUnidad(insumo) || ''),
    });
  }

  cerrarModal() {
    this.modoModal.set('ninguno');
    this.insumoSeleccionado.set(null);
    this.form.reset();
  }

  guardarInsumo() {
    this.error.set('');
    this.mensaje.set('');

    const permiso = this.modoModal() === 'nuevo' ? 'insumos.crear' : 'insumos.editar';

    if (!this.verificarPermiso(permiso)) {
      return;
    }

    if (this.form.invalid) {
      this.error.set(
        marcarFormularioInvalido(
          this.form,
          this.etiquetasFormulario,
          'Revise los campos del insumo',
        ),
      );
      return;
    }

    const valores = this.form.getRawValue();

    const payload = {
      codigoInterno: normalizarMayusculas(valores.codigoInterno),
      nombreInsumo: valores.nombreInsumo.trim(),
      descripcion: valores.descripcion?.trim() || undefined,
      precioReferencial: Number(valores.precioReferencial),
      stockMinimo: Number(valores.stockMinimo),
      idCategoria: Number(valores.idCategoria),
      idTipoInsumo: Number(valores.idTipoInsumo),
      idUnidadMedida: Number(valores.idUnidadMedida),
    };

    this.guardando.set(true);

    if (this.modoModal() === 'nuevo') {
      this.insumosService.crear(payload).subscribe({
        next: () => {
          this.guardando.set(false);
          this.mensaje.set('Insumo creado correctamente.');
          this.cerrarModal();
          this.cargarInsumos();
        },
        error: (error) => {
          console.error('Error al crear insumo:', error);
          this.guardando.set(false);
          this.error.set(this.obtenerMensajeErrorBackend(error));
        },
      });

      return;
    }

    const insumo = this.insumoSeleccionado();

    if (!insumo) {
      this.guardando.set(false);
      this.error.set('No hay insumo seleccionado.');
      return;
    }

    this.insumosService.actualizar(insumo.idInsumo, payload).subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set('Insumo actualizado correctamente.');
        this.cerrarModal();
        this.cargarInsumos();
      },
      error: (error) => {
        console.error('Error al actualizar insumo:', error);
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
      },
    });
  }

  abrirConfirmacionEstado(insumo: Insumo) {
    const permiso = this.estaActivo(insumo)
      ? 'insumos.desactivar'
      : 'insumos.activar';

    if (!this.verificarPermiso(permiso)) {
      return;
    }

    this.insumoSeleccionado.set(insumo);
    this.modoConfirmacion.set(this.estaActivo(insumo) ? 'desactivar' : 'activar');
  }

  abrirConfirmacionEliminar(insumo: Insumo) {
    if (!this.verificarPermiso('insumos.eliminar')) {
      return;
    }

    this.insumoSeleccionado.set(insumo);
    this.modoConfirmacion.set('eliminar');
  }

  abrirConfirmacionDesactivar(insumo: Insumo) {
    this.abrirConfirmacionEstado(insumo);
  }

  cerrarConfirmacion() {
    this.modoConfirmacion.set('ninguno');
    this.insumoSeleccionado.set(null);
  }

  confirmarDesactivar() {
    const insumo = this.insumoSeleccionado();

    if (!insumo) {
      return;
    }

    this.guardando.set(true);
    const accion = this.modoConfirmacion();
    const permiso =
      accion === 'eliminar'
        ? 'insumos.eliminar'
        : accion === 'activar'
          ? 'insumos.activar'
          : 'insumos.desactivar';

    if (!this.verificarPermiso(permiso)) {
      this.guardando.set(false);
      this.cerrarConfirmacion();
      return;
    }

    const peticion =
      accion === 'eliminar'
        ? this.insumosService.eliminar(insumo.idInsumo)
        : accion === 'activar'
          ? this.insumosService.activar(insumo.idInsumo)
          : this.insumosService.desactivar(insumo.idInsumo);

    peticion.subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set(
          accion === 'activar'
            ? 'Insumo activado correctamente.'
            : accion === 'eliminar'
              ? 'Insumo eliminado correctamente.'
              : 'Insumo desactivado correctamente.',
        );
        this.cerrarConfirmacion();
        this.cargarInsumos();
      },
      error: (error) => {
        console.error('Error al cambiar estado del insumo:', error);
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
        this.cerrarConfirmacion();
      },
    });
  }

  confirmarCambioEstado() {
    this.confirmarDesactivar();
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

  obtenerCategoriaNombre(insumo: Insumo): string {
    return (
      insumo.categoria?.nombreCategoria ||
      insumo.categoriaInsumo?.nombreCategoria ||
      'Sin categoría'
    );
  }

  obtenerTipoNombre(insumo: Insumo): string {
    return insumo.tipo?.nombreTipo || insumo.tipoInsumo?.nombreTipo || 'Sin tipo';
  }

  obtenerUnidadNombre(insumo: Insumo): string {
    const unidad = insumo.unidad || insumo.unidadMedida;

    if (!unidad) {
      return 'Sin unidad';
    }

    return unidad.abreviatura
      ? `${unidad.nombreUnidad} (${unidad.abreviatura})`
      : unidad.nombreUnidad;
  }

  obtenerIdCategoria(insumo: Insumo): number {
    return (
      insumo.idCategoria ||
      insumo.categoria?.idCategoria ||
      insumo.categoriaInsumo?.idCategoria ||
      0
    );
  }

  obtenerIdTipo(insumo: Insumo): number {
    return insumo.idTipoInsumo || insumo.tipo?.idTipoInsumo || insumo.tipoInsumo?.idTipoInsumo || 0;
  }

  obtenerIdUnidad(insumo: Insumo): number {
    return (
      insumo.idUnidadMedida ||
      insumo.unidad?.idUnidadMedida ||
      insumo.unidadMedida?.idUnidadMedida ||
      0
    );
  }

  claseEstado(estado: string): string {
    if (estado?.toUpperCase() === 'ACTIVO') {
      return 'bg-green-100 text-green-700 border-green-200';
    }

    if (estado?.toUpperCase() === 'INACTIVO') {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    return 'bg-slate-100 text-slate-700 border-slate-200';
  }

  estaActivo(insumo: Insumo): boolean {
    return String(insumo.estado || '').toUpperCase() === 'ACTIVO';
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

  iconoCategoria(nombre: string): string {
    const normalizado = nombre?.toUpperCase();

    if (normalizado.includes('EXPLOSIVO')) return '💥';
    if (normalizado.includes('SEGURIDAD')) return '🦺';
    if (normalizado.includes('HERRAMIENTA')) return '🛠️';
    if (normalizado.includes('REPUESTO')) return '🔩';
    if (normalizado.includes('COMBUSTIBLE')) return '⛽';

    return '📦';
  }

  tituloConfirmacionInsumo(): string {
    const accion = this.modoConfirmacion();

    if (accion === 'eliminar') {
      return 'Eliminar insumo';
    }

    if (accion === 'activar') {
      return 'Activar insumo';
    }

    if (accion === 'desactivar') {
      return 'Desactivar insumo';
    }

    return '';
  }

  mensajeConfirmacionInsumo(): string {
    const accion = this.modoConfirmacion();

    if (accion === 'eliminar') {
      return '¿Está seguro de eliminar este insumo? Esta acción lo quitará del listado principal mediante borrado lógico.';
    }

    if (accion === 'activar') {
      return '¿Está seguro de activar este insumo? El insumo volverá a estar disponible para inventario, pedidos y compras.';
    }

    if (accion === 'desactivar') {
      return '¿Está seguro de desactivar este insumo? No se eliminará la información histórica.';
    }

    return '';
  }

  textoBotonConfirmacionInsumo(): string {
    const accion = this.modoConfirmacion();

    if (accion === 'eliminar') {
      return 'Sí, eliminar';
    }

    if (accion === 'activar') {
      return 'Sí, activar';
    }

    if (accion === 'desactivar') {
      return 'Sí, desactivar';
    }

    return 'Confirmar';
  }
}
