import { Component, computed, inject, signal } from '@angular/core';
import {
  FormBuilder,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { AlmacenesService } from '../../core/services/almacenes.service';
import { PermissionService } from '../../core/services/permission.service';
import { Almacen } from '../../core/models/almacen.model';
import { UsuariosService } from '../../core/services/usuarios.service';
import { Usuario } from '../../core/models/usuario.model';
import {
  TIPOS_ALMACEN_RECOMENDADOS,
  codigoAlfanumericoGuionValidator,
  horarioAtencionManualValidator,
  maxDigitsValidator,
  normalizarMayusculas,
  normalizarSoloDigitos,
  telefonoBoliviaValidator,
} from '../../core/forms/professional-forms';
import {
  FormFieldLabels,
  marcarFormularioInvalido,
  mensajeErrorBackend,
} from '../../core/forms/form-error-messages';
import { CampoValidacionDirective } from '../../core/forms/campo-validacion.directive';

type ModoModal = 'ninguno' | 'nuevo' | 'editar' | 'ver';
type ModoConfirmacion = 'ninguno' | 'activar' | 'desactivar' | 'eliminar';

interface OpcionCatalogo {
  valor: string;
  etiqueta: string;
}

@Component({
  selector: 'app-almacenes',
  standalone: true,
  imports: [ReactiveFormsModule, CampoValidacionDirective],
  templateUrl: './almacenes.html',
  styleUrl: './almacenes.css',
})
export class Almacenes {
  private readonly almacenesService = inject(AlmacenesService);
  private readonly usuariosService = inject(UsuariosService);
  private readonly permissionService = inject(PermissionService);
  private readonly formBuilder = inject(FormBuilder);
  private readonly etiquetasFormulario: FormFieldLabels = {
    codigoAlmacen: 'Codigo de almacen',
    nombreAlmacen: 'Nombre de almacen',
    tipoAlmacen: 'Tipo de almacen',
    ubicacion: 'Ubicacion',
    telefonoContacto: 'Telefono de contacto',
    horarioAtencion: 'Horario de atencion',
    idEncargado: 'Encargado',
    descripcion: 'Descripcion',
  };

  cargando = signal(false);
  guardando = signal(false);
  error = signal('');
  mensaje = signal('');

  busqueda = signal('');
  almacenes = signal<Almacen[]>([]);
  tiposAlmacen = signal<OpcionCatalogo[]>([]);
  usuariosActivos = signal<Usuario[]>([]);

  private readonly tiposAlmacenFallback: OpcionCatalogo[] = [
    ...TIPOS_ALMACEN_RECOMENDADOS,
  ];

  modoModal = signal<ModoModal>('ninguno');
  modoConfirmacion = signal<ModoConfirmacion>('ninguno');
  almacenSeleccionado = signal<Almacen | null>(null);

  modalAbierto = computed(() => this.modoModal() !== 'ninguno');
  confirmacionAbierta = computed(() => this.modoConfirmacion() !== 'ninguno');

  totalAlmacenes = computed(() => this.almacenes().length);

  totalActivos = computed(
    () => this.almacenes().filter((a) => a.estado === 'ACTIVO').length,
  );

  totalInactivos = computed(
    () => this.almacenes().filter((a) => a.estado === 'INACTIVO').length,
  );

  almacenesFiltrados = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();

    if (!texto) {
      return this.almacenes();
    }

    return this.almacenes().filter((almacen) => {
      return (
        almacen.codigoAlmacen?.toLowerCase().includes(texto) ||
        almacen.nombreAlmacen?.toLowerCase().includes(texto) ||
        this.etiquetaTipoAlmacen(almacen.tipoAlmacen).toLowerCase().includes(texto) ||
        almacen.ubicacion?.toLowerCase().includes(texto) ||
        this.nombreEncargado(almacen).toLowerCase().includes(texto) ||
        almacen.estado?.toLowerCase().includes(texto)
      );
    });
  });

  form = this.formBuilder.nonNullable.group({
    codigoAlmacen: [
      '',
      [Validators.required, Validators.maxLength(10), codigoAlfanumericoGuionValidator()],
    ],
    nombreAlmacen: [
      '',
      [Validators.required, Validators.maxLength(40), maxDigitsValidator(5)],
    ],
    tipoAlmacen: ['', [Validators.required]],
    ubicacion: [
      '',
      [Validators.required, Validators.maxLength(50), maxDigitsValidator(5)],
    ],
    telefonoContacto: ['', [Validators.required, telefonoBoliviaValidator()]],
    horarioAtencion: [
      '',
      [
        Validators.required,
        Validators.maxLength(50),
        horarioAtencionManualValidator(),
      ],
    ],
    idEncargado: [''],
    descripcion: [''],
  });

  ngOnInit() {
    this.cargarAlmacenes();
    this.cargarTipos();
    this.cargarUsuariosActivos();
  }

  cargarAlmacenes() {
    this.cargando.set(true);
    this.error.set('');
    this.mensaje.set('');

    this.almacenesService.listar().subscribe({
      next: (data) => {
        this.almacenes.set((data).filter((almacen: any) => String(almacen.estado || '').toUpperCase() !== 'ELIMINADO'));
        this.cargando.set(false);
      },
      error: () => {
        this.error.set('No se pudo cargar la lista de almacenes.');
        this.cargando.set(false);
      },
    });
  }

  cargarTipos() {
    this.almacenesService.tipos().subscribe({
      next: (data) => {
        this.tiposAlmacen.set(this.normalizarOpcionesTipo(data));
      },
      error: () => {
        this.tiposAlmacen.set(this.tiposAlmacenFallback);
      },
    });
  }

  cargarUsuariosActivos() {
    this.usuariosService.listar().subscribe({
      next: (data) => {
        this.usuariosActivos.set(
          data.filter((usuario) => usuario.estado === 'ACTIVO'),
        );
      },
      error: () => {
        this.usuariosActivos.set([]);
      },
    });
  }

  cambiarBusqueda(event: Event) {
    const input = event.target as HTMLInputElement;
    this.busqueda.set(input.value);
  }

  normalizarCodigoInput() {
    const control = this.form.controls.codigoAlmacen;
    const valor = normalizarMayusculas(control.value).slice(0, 10);

    if (valor !== control.value) {
      control.setValue(valor, { emitEvent: false });
    }
  }

  normalizarContactoInput() {
    const control = this.form.controls.telefonoContacto;
    const valor = normalizarSoloDigitos(control.value, 8);

    if (valor !== control.value) {
      control.setValue(valor, { emitEvent: false });
    }
  }

  abrirNuevo() {
    if (!this.verificarPermiso('almacenes.crear')) {
      return;
    }

    this.error.set('');
    this.mensaje.set('');
    this.almacenSeleccionado.set(null);
    this.modoModal.set('nuevo');

    this.form.reset({
      codigoAlmacen: '',
      nombreAlmacen: '',
      tipoAlmacen: '',
      ubicacion: '',
      telefonoContacto: '',
      horarioAtencion: '',
      idEncargado: '',
      descripcion: '',
    });
  }

  abrirVer(almacen: Almacen) {
    this.almacenSeleccionado.set(almacen);
    this.modoModal.set('ver');
  }

  abrirEditar(almacen: Almacen) {
    if (!this.verificarPermiso('almacenes.editar')) {
      return;
    }

    this.error.set('');
    this.mensaje.set('');
    this.almacenSeleccionado.set(almacen);
    this.modoModal.set('editar');

    this.form.reset({
      codigoAlmacen: almacen.codigoAlmacen || '',
      nombreAlmacen: almacen.nombreAlmacen || '',
      tipoAlmacen: this.normalizarTipoAlmacen(almacen.tipoAlmacen),
      ubicacion: almacen.ubicacion || '',
      telefonoContacto: almacen.telefonoContacto || '',
      horarioAtencion: almacen.horarioAtencion || '',
      idEncargado: String(this.obtenerIdEncargado(almacen) || ''),
      descripcion: almacen.descripcion || '',
    });
  }

  cerrarModal() {
    this.modoModal.set('ninguno');
    this.almacenSeleccionado.set(null);
    this.form.reset();
  }

  guardarAlmacen() {
    this.error.set('');
    this.mensaje.set('');

    const permiso = this.modoModal() === 'nuevo' ? 'almacenes.crear' : 'almacenes.editar';

    if (!this.verificarPermiso(permiso)) {
      return;
    }

    if (this.form.invalid) {
      this.error.set(
        marcarFormularioInvalido(
          this.form,
          this.etiquetasFormulario,
          'Revise los campos del almacen',
        ),
      );
      return;
    }

    const valores = this.form.getRawValue();

    const payload = {
      codigoAlmacen: normalizarMayusculas(valores.codigoAlmacen),
      nombreAlmacen: valores.nombreAlmacen.trim(),
      tipoAlmacen: this.normalizarTipoAlmacen(valores.tipoAlmacen),
      ubicacion: valores.ubicacion.trim(),
      telefonoContacto: normalizarSoloDigitos(valores.telefonoContacto, 8),
      horarioAtencion: valores.horarioAtencion.trim(),
      idEncargado: valores.idEncargado ? Number(valores.idEncargado) : undefined,
      descripcion: valores.descripcion?.trim() || undefined,
    };

    this.guardando.set(true);

    if (this.modoModal() === 'nuevo') {
      this.almacenesService.crear(payload).subscribe({
        next: () => {
          this.guardando.set(false);
          this.mensaje.set('Almacén creado correctamente.');
          this.cerrarModal();
          this.cargarAlmacenes();
        },
        error: (error) => {
          console.error('Error al crear almacén:', error);
          this.guardando.set(false);
          this.error.set(this.obtenerMensajeErrorBackend(error));
        },
      });

      return;
    }

    const almacen = this.almacenSeleccionado();

    if (!almacen) {
      this.guardando.set(false);
      this.error.set('No hay almacén seleccionado.');
      return;
    }

    this.almacenesService.actualizar(almacen.idAlmacen, payload).subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set('Almacén actualizado correctamente.');
        this.cerrarModal();
        this.cargarAlmacenes();
      },
      error: (error) => {
        console.error('Error al actualizar almacén:', error);
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
      },
    });
  }

  abrirConfirmacionEstado(almacen: Almacen) {
    const permiso = this.estaActivo(almacen)
      ? 'almacenes.desactivar'
      : 'almacenes.activar';

    if (!this.verificarPermiso(permiso)) {
      return;
    }

    this.almacenSeleccionado.set(almacen);
    this.modoConfirmacion.set(this.estaActivo(almacen) ? 'desactivar' : 'activar');
  }

  abrirConfirmacionEliminar(almacen: Almacen) {
    if (!this.verificarPermiso('almacenes.eliminar')) {
      return;
    }

    this.almacenSeleccionado.set(almacen);
    this.modoConfirmacion.set('eliminar');
  }

  abrirConfirmacionDesactivar(almacen: Almacen) {
    this.abrirConfirmacionEstado(almacen);
  }

  cerrarConfirmacion() {
    this.modoConfirmacion.set('ninguno');
    this.almacenSeleccionado.set(null);
  }

  confirmarDesactivar() {
    const almacen = this.almacenSeleccionado();

    if (!almacen) {
      return;
    }

    this.guardando.set(true);
    const accion = this.modoConfirmacion();
    const permiso =
      accion === 'eliminar'
        ? 'almacenes.eliminar'
        : accion === 'activar'
          ? 'almacenes.activar'
          : 'almacenes.desactivar';

    if (!this.verificarPermiso(permiso)) {
      this.guardando.set(false);
      this.cerrarConfirmacion();
      return;
    }

    const peticion =
      accion === 'eliminar'
        ? this.almacenesService.eliminar(almacen.idAlmacen)
        : accion === 'activar'
          ? this.almacenesService.activar(almacen.idAlmacen)
          : this.almacenesService.desactivar(almacen.idAlmacen);

    peticion.subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set(
          accion === 'activar'
            ? 'Almacén activado correctamente.'
            : 'Almacén desactivado correctamente.',
        );
        if (accion === 'eliminar') {
            this.almacenes.update((lista) =>
              lista.filter((item) => item.idAlmacen !== almacen.idAlmacen),
            );

          this.mensaje.set('Almacen eliminado correctamente.');
        
          }
        this.cerrarConfirmacion();
        this.cargarAlmacenes();
      },
      error: (error) => {
        console.error('Error al cambiar estado del almacén:', error);
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

  cambiarEstadoClase(estado: string): string {
    if (estado?.toUpperCase() === 'ACTIVO') {
      return 'bg-green-100 text-green-700 border-green-200';
    }

    if (estado?.toUpperCase() === 'INACTIVO') {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    return 'bg-slate-100 text-slate-700 border-slate-200';
  }

  estaActivo(almacen: Almacen): boolean {
    return String(almacen.estado || '').toUpperCase() === 'ACTIVO';
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

  obtenerIdEncargado(almacen: Almacen): number {
    const data = almacen as any;
    return Number(
      data.idEncargado ||
        data.encargadoId ||
        data.idResponsablePrincipal ||
        data.id_responsable_principal ||
        data.encargado?.idUsuario ||
        data.encargado?.id_usuario ||
        data.responsablePrincipal?.idUsuario ||
        data.responsablePrincipal?.id_usuario ||
        0,
    );
  }

  nombreEncargado(almacen: Almacen): string {
    const data = almacen as any;
    const encargado = data.encargado || data.responsablePrincipal;

    return String(
      encargado?.nombreCompleto ||
        encargado?.nombre_completo ||
        encargado?.nombreUsuario ||
        encargado?.nombre_usuario ||
        'Sin encargado',
    );
  }

  normalizarTipoAlmacen(valor: unknown): string {
    const data = valor as any;
    const bruto =
      typeof valor === 'object' && valor !== null
        ? data.codigo || data.valor || data.value || data.tipoAlmacen || data.nombre
        : valor;

    const codigo = String(bruto || '')
      .trim()
      .toUpperCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[\s-]+/g, '_');

    const alias: Record<string, string> = {
      ALMACEN_DE_SUPERFICIE: 'SUPERFICIE',
      ALMACEN_SUPERFICIE: 'SUPERFICIE',
      INTERIOR_MINA: 'SUBTERRANEO',
      MINA: 'SUBTERRANEO',
      POLVORIN_O_ALMACEN_DE_MATERIAL_EXPLOSIVO_CONTROLADO: 'POLVORIN',
      MATERIAL_EXPLOSIVO_CONTROLADO: 'POLVORIN',
      SEGURIDAD: 'SEGURIDAD_INDUSTRIAL',
      ALMACEN_DE_SEGURIDAD_INDUSTRIAL: 'SEGURIDAD_INDUSTRIAL',
      HERRAMIENTAS: 'HERRAMIENTAS_REPUESTOS',
      REPUESTOS: 'HERRAMIENTAS_REPUESTOS',
      ALMACEN_DE_HERRAMIENTAS_Y_REPUESTOS: 'HERRAMIENTAS_REPUESTOS',
      ALMACEN_DE_COMBUSTIBLE: 'COMBUSTIBLE',
      ALMACEN_DE_LUBRICANTES: 'LUBRICANTES',
      ALMACENAMIENTO_TEMPORAL: 'TEMPORAL',
    };

    return alias[codigo] || codigo;
  }

  etiquetaTipoAlmacen(valor: unknown): string {
    const codigo = this.normalizarTipoAlmacen(valor);

    return (
      this.tiposAlmacen().find((tipo) => tipo.valor === codigo)?.etiqueta ||
      this.tiposAlmacenFallback.find((tipo) => tipo.valor === codigo)?.etiqueta ||
      codigo
        .replaceAll('_', ' ')
        .toLowerCase()
        .replace(/(^|\s)\S/g, (letra) => letra.toUpperCase())
    );
  }

  private normalizarOpcionesTipo(data: unknown): OpcionCatalogo[] {
    const opciones = (Array.isArray(data) ? data : [])
      .map((item: any) => {
        const valor = this.normalizarTipoAlmacen(item);
        const etiqueta =
          typeof item === 'object' && item !== null
            ? item.nombre || item.etiqueta || item.label
            : this.etiquetaTipoAlmacen(valor);

        return {
          valor,
          etiqueta: String(etiqueta || valor),
        };
      })
      .filter((item) => item.valor && item.valor !== 'LUBRICANTES');

    return opciones.length > 0 ? opciones : this.tiposAlmacenFallback;
  }

  iconoTipo(tipo: string): string {
    const normalizado = this.normalizarTipoAlmacen(tipo);

    if (normalizado.includes('SUPERFICIE')) {
      return '🏢';
    }

    if (normalizado.includes('SUBTERRANEO') || normalizado.includes('POLVORIN')) {
      return '⛏️';
    }

    if (normalizado.includes('TEMPORAL')) {
      return '⏱️';
    }

    if (normalizado.includes('EMERGENCIA')) {
      return '🚨';
    }

    return '📦';
  }


  tituloConfirmacion(): string {
    const accion = this.modoConfirmacion();

    if (accion === 'eliminar') {
      return 'Eliminar almacén';
    }

    if (accion === 'activar') {
      return 'Activar almacén';
    }

    if (accion === 'desactivar') {
      return 'Desactivar almacén';
    }

    return '';
  }

  mensajeConfirmacion(): string {
    const accion = this.modoConfirmacion();

    if (accion === 'eliminar') {
      return '¿Está seguro de eliminar este almacén? Esta acción lo quitará del listado principal mediante borrado lógico.';
    }

    if (accion === 'activar') {
      return '¿Está seguro de activar este almacén? El almacén volverá a estar disponible en el sistema.';
    }

    if (accion === 'desactivar') {
      return '¿Está seguro de desactivar este almacén? Esta acción cambiará su estado y no eliminará información histórica.';
    }

    return '';
  }

  textoBotonConfirmacion(): string {
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
