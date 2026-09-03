import { Component, computed, inject, signal } from '@angular/core';
import {
  FormBuilder,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { ProveedoresService } from '../../core/services/proveedores.service';
import { PermissionService } from '../../core/services/permission.service';
import { Proveedor } from '../../core/models/proveedor.model';
import {
  codigoAlfanumericoGuionValidator,
  correoProfesionalValidator,
  normalizarMayusculas,
  normalizarMinusculas,
  normalizarSoloDigitos,
  personaContactoValidator,
  soloNumerosMaxValidator,
  telefonoBoliviaValidator,
  telefonoNumericoFlexibleValidator,
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
  selector: 'app-proveedores',
  standalone: true,
  imports: [ReactiveFormsModule, CampoValidacionDirective],
  templateUrl: './proveedores.html',
  styleUrl: './proveedores.css',
})
export class Proveedores {
  private readonly proveedoresService = inject(ProveedoresService);
  private readonly permissionService = inject(PermissionService);
  private readonly formBuilder = inject(FormBuilder);
  private readonly etiquetasFormulario: FormFieldLabels = {
    codigoProveedor: 'Codigo de proveedor',
    razonSocial: 'Razon social',
    nombreComercial: 'Nombre comercial',
    nit: 'NIT',
    rubro: 'Rubro',
    tipoInsumosProvee: 'Tipo de insumos que provee',
    personaContacto: 'Persona de contacto',
    telefono: 'Telefono',
    celularWhatsapp: 'Celular WhatsApp',
    correo: 'Correo',
    ciudad: 'Ciudad',
    ciudadOtro: 'Otra ciudad',
  };

  cargando = signal(false);
  guardando = signal(false);
  error = signal('');
  mensaje = signal('');

  busqueda = signal('');
  proveedores = signal<Proveedor[]>([]);

  modoModal = signal<ModoModal>('ninguno');
  modoConfirmacion = signal<ModoConfirmacion>('ninguno');
  proveedorSeleccionado = signal<Proveedor | null>(null);

  modalAbierto = computed(() => this.modoModal() !== 'ninguno');
  confirmacionAbierta = computed(() => this.modoConfirmacion() !== 'ninguno');

  rubros: OpcionCatalogo[] = [
    { valor: 'HERRAMIENTAS_REPUESTOS', etiqueta: 'Herramientas y repuestos' },
    { valor: 'SEGURIDAD_INDUSTRIAL', etiqueta: 'Seguridad industrial' },
    { valor: 'LUBRICANTES', etiqueta: 'Lubricantes' },
    {
      valor: 'MATERIAL_EXPLOSIVO_CONTROLADO',
      etiqueta: 'Material explosivo controlado',
    },
    { valor: 'MATERIAL_PERFORACION', etiqueta: 'Material de perforación' },
    { valor: 'EQUIPOS_MENORES', etiqueta: 'Equipos menores' },
    { valor: 'SERVICIOS_COMPLEMENTARIOS', etiqueta: 'Servicios complementarios' },
    { valor: 'COMBUSTIBLE', etiqueta: 'Combustible' },
    { valor: 'OTROS', etiqueta: 'Otros' },
  ];

  ciudades = [
    'Oruro',
    'La Paz',
    'Cochabamba',
    'Santa Cruz',
    'Potosi',
    'Chuquisaca',
    'Tarija',
    'Beni',
    'Pando',
    'Otro',
  ];

  totalProveedores = computed(() => this.proveedores().length);

  totalActivos = computed(
    () => this.proveedores().filter((p) => p.estado === 'ACTIVO').length,
  );

  totalInactivos = computed(
    () => this.proveedores().filter((p) => p.estado === 'INACTIVO').length,
  );

  proveedoresFiltrados = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();

    if (!texto) {
      return this.proveedores();
    }

    return this.proveedores().filter((proveedor) => {
      return (
        proveedor.codigoProveedor?.toLowerCase().includes(texto) ||
        proveedor.razonSocial?.toLowerCase().includes(texto) ||
        proveedor.nombreComercial?.toLowerCase().includes(texto) ||
        proveedor.nit?.toLowerCase().includes(texto) ||
        this.etiquetaRubro(proveedor.rubro).toLowerCase().includes(texto) ||
        proveedor.tipoInsumosProvee?.toLowerCase().includes(texto) ||
        proveedor.personaContacto?.toLowerCase().includes(texto) ||
        proveedor.telefono?.toLowerCase().includes(texto) ||
        proveedor.celularWhatsapp?.toLowerCase().includes(texto) ||
        proveedor.correo?.toLowerCase().includes(texto) ||
        proveedor.ciudad?.toLowerCase().includes(texto) ||
        proveedor.estado?.toLowerCase().includes(texto)
      );
    });
  });

  form = this.formBuilder.nonNullable.group({
    codigoProveedor: [
      '',
      [Validators.required, Validators.maxLength(10), codigoAlfanumericoGuionValidator()],
    ],
    razonSocial: ['', [Validators.required, Validators.minLength(3), Validators.maxLength(100)]],
    nombreComercial: ['', [Validators.required, Validators.maxLength(60)]],
    nit: ['', [Validators.required, soloNumerosMaxValidator(15)]],
    rubro: ['', [Validators.required]],
    tipoInsumosProvee: ['', [Validators.required, Validators.maxLength(60)]],
    personaContacto: [
      '',
      [Validators.required, Validators.maxLength(50), personaContactoValidator()],
    ],
    telefono: ['', [telefonoNumericoFlexibleValidator(15)]],
    celularWhatsapp: ['', [Validators.required, telefonoBoliviaValidator()]],
    correo: [
      '',
      [
        Validators.required,
        Validators.maxLength(60),
        correoProfesionalValidator(),
      ],
    ],
    ciudad: [''],
    ciudadOtro: [''],
  });

  ngOnInit() {
    this.cargarProveedores();
  }

  cargarProveedores() {
    this.cargando.set(true);
    this.error.set('');
    this.mensaje.set('');

    this.proveedoresService.listar().subscribe({
      next: (data) => {
        this.proveedores.set((data).filter((proveedor: any) => String(proveedor.estado || '').toUpperCase() !== 'ELIMINADO'));
        this.cargando.set(false);
      },
      error: () => {
        this.error.set('No se pudo cargar la lista de proveedores.');
        this.cargando.set(false);
      },
    });
  }

  cambiarBusqueda(event: Event) {
    const input = event.target as HTMLInputElement;
    this.busqueda.set(input.value);
  }

  normalizarCodigoInput() {
    const control = this.form.controls.codigoProveedor;
    const valor = normalizarMayusculas(control.value).slice(0, 10);

    if (valor !== control.value) {
      control.setValue(valor, { emitEvent: false });
    }
  }

  normalizarNitInput() {
    const control = this.form.controls.nit;
    const valor = normalizarSoloDigitos(control.value, 15);

    if (valor !== control.value) {
      control.setValue(valor, { emitEvent: false });
    }
  }

  normalizarTelefonoInput() {
    const control = this.form.controls.telefono;
    const valor = normalizarSoloDigitos(control.value, 15);

    if (valor !== control.value) {
      control.setValue(valor, { emitEvent: false });
    }
  }

  normalizarWhatsappInput() {
    const control = this.form.controls.celularWhatsapp;
    const valor = normalizarSoloDigitos(control.value, 8);

    if (valor !== control.value) {
      control.setValue(valor, { emitEvent: false });
    }
  }

  normalizarCorreoInput() {
    const control = this.form.controls.correo;
    const valor = normalizarMinusculas(control.value);

    if (valor !== control.value) {
      control.setValue(valor, { emitEvent: false });
    }
  }

  abrirNuevo() {
    if (!this.verificarPermiso('proveedores.crear')) {
      return;
    }

    this.error.set('');
    this.mensaje.set('');
    this.proveedorSeleccionado.set(null);
    this.modoModal.set('nuevo');

    this.form.reset({
      codigoProveedor: '',
      razonSocial: '',
      nombreComercial: '',
      nit: '',
      rubro: '',
      tipoInsumosProvee: '',
      personaContacto: '',
      telefono: '',
      celularWhatsapp: '',
      correo: '',
      ciudad: '',
      ciudadOtro: '',
    });
  }

  abrirVer(proveedor: Proveedor) {
    this.proveedorSeleccionado.set(proveedor);
    this.modoModal.set('ver');
  }

  abrirEditar(proveedor: Proveedor) {
    if (!this.verificarPermiso('proveedores.editar')) {
      return;
    }

    this.error.set('');
    this.mensaje.set('');
    this.proveedorSeleccionado.set(proveedor);
    this.modoModal.set('editar');

    const ciudad = proveedor.ciudad || '';
    const ciudadCatalogo = this.ciudades.includes(ciudad) ? ciudad : ciudad ? 'Otro' : '';

    this.form.reset({
      codigoProveedor: proveedor.codigoProveedor || '',
      razonSocial: proveedor.razonSocial || '',
      nombreComercial: proveedor.nombreComercial || '',
      nit: proveedor.nit || '',
      rubro: this.normalizarRubro(proveedor.rubro),
      tipoInsumosProvee: proveedor.tipoInsumosProvee || '',
      personaContacto: proveedor.personaContacto || '',
      telefono: proveedor.telefono || '',
      celularWhatsapp: proveedor.celularWhatsapp || '',
      correo: proveedor.correo || '',
      ciudad: ciudadCatalogo,
      ciudadOtro: ciudadCatalogo === 'Otro' ? ciudad : '',
    });
  }

  cerrarModal() {
    this.modoModal.set('ninguno');
    this.proveedorSeleccionado.set(null);
    this.form.reset();
  }

  guardarProveedor() {
    this.error.set('');
    this.mensaje.set('');
    this.form.controls.ciudadOtro.setErrors(null);

    const permiso = this.modoModal() === 'nuevo' ? 'proveedores.crear' : 'proveedores.editar';

    if (!this.verificarPermiso(permiso)) {
      return;
    }

    if (this.form.invalid) {
      this.error.set(
        marcarFormularioInvalido(
          this.form,
          this.etiquetasFormulario,
          'Revise los campos del proveedor',
        ),
      );
      return;
    }

    const valores = this.form.getRawValue();
    const ciudadSeleccionada =
      valores.ciudad === 'Otro' ? valores.ciudadOtro.trim() : valores.ciudad;

    if (valores.ciudad === 'Otro' && !ciudadSeleccionada) {
      marcarFormularioInvalido(
        this.form,
        this.etiquetasFormulario,
        'Revise los campos del proveedor',
      );
      this.form.controls.ciudadOtro.setErrors({ required: true });
      this.form.controls.ciudadOtro.markAsTouched();
      return;
    }

    const payload = {
      codigoProveedor: normalizarMayusculas(valores.codigoProveedor),
      razonSocial: valores.razonSocial.trim(),
      nombreComercial: valores.nombreComercial.trim(),
      nit: normalizarSoloDigitos(valores.nit, 15),
      rubro: this.normalizarRubro(valores.rubro),
      tipoInsumosProvee: valores.tipoInsumosProvee.trim(),
      personaContacto: valores.personaContacto.trim(),
      telefono: normalizarSoloDigitos(valores.telefono, 15) || undefined,
      celularWhatsapp: normalizarSoloDigitos(valores.celularWhatsapp, 8),
      correo: normalizarMinusculas(valores.correo),
      ciudad: ciudadSeleccionada?.trim() || undefined,
    };

    this.guardando.set(true);

    if (this.modoModal() === 'nuevo') {
      this.proveedoresService.crear(payload).subscribe({
        next: () => {
          this.guardando.set(false);
          this.mensaje.set('Proveedor creado correctamente.');
          this.cerrarModal();
          this.cargarProveedores();
        },
        error: (error) => {
          console.error('Error al crear proveedor:', error);
          this.guardando.set(false);
          this.error.set(this.obtenerMensajeErrorBackend(error));
        },
      });

      return;
    }

    const proveedor = this.proveedorSeleccionado();

    if (!proveedor) {
      this.guardando.set(false);
      this.error.set('No hay proveedor seleccionado.');
      return;
    }

    this.proveedoresService.actualizar(proveedor.idProveedor, payload).subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set('Proveedor actualizado correctamente.');
        this.cerrarModal();
        this.cargarProveedores();
      },
      error: (error) => {
        console.error('Error al actualizar proveedor:', error);
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
      },
    });
  }

  abrirConfirmacionEstado(proveedor: Proveedor) {
    const permiso = this.estaActivo(proveedor)
      ? 'proveedores.desactivar'
      : 'proveedores.activar';

    if (!this.verificarPermiso(permiso)) {
      return;
    }

    this.proveedorSeleccionado.set(proveedor);
    this.modoConfirmacion.set(this.estaActivo(proveedor) ? 'desactivar' : 'activar');
  }

  abrirConfirmacionEliminar(proveedor: Proveedor) {
    if (!this.verificarPermiso('proveedores.eliminar')) {
      return;
    }

    this.proveedorSeleccionado.set(proveedor);
    this.modoConfirmacion.set('eliminar');
  }

  abrirConfirmacionDesactivar(proveedor: Proveedor) {
    this.abrirConfirmacionEstado(proveedor);
  }

  cerrarConfirmacion() {
    this.modoConfirmacion.set('ninguno');
    this.proveedorSeleccionado.set(null);
  }

  confirmarDesactivar() {
    const proveedor = this.proveedorSeleccionado();

    if (!proveedor) {
      return;
    }

    this.guardando.set(true);
    const accion = this.modoConfirmacion();
    const permiso =
      accion === 'eliminar'
        ? 'proveedores.eliminar'
        : accion === 'activar'
          ? 'proveedores.activar'
          : 'proveedores.desactivar';

    if (!this.verificarPermiso(permiso)) {
      this.guardando.set(false);
      this.cerrarConfirmacion();
      return;
    }

    const peticion =
      accion === 'eliminar'
        ? this.proveedoresService.eliminar(proveedor.idProveedor)
        : accion === 'activar'
          ? this.proveedoresService.activar(proveedor.idProveedor)
          : this.proveedoresService.desactivar(proveedor.idProveedor);

    peticion.subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set(
          accion === 'activar'
            ? 'Proveedor activado correctamente.'
            : accion === 'eliminar'
              ? 'Proveedor eliminado correctamente.'
              : 'Proveedor desactivado correctamente.',
        );
        this.cerrarConfirmacion();
        this.cargarProveedores();
      },
      error: (error) => {
        console.error('Error al cambiar estado del proveedor:', error);
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

  claseEstado(estado: string): string {
    if (estado?.toUpperCase() === 'ACTIVO') {
      return 'bg-green-100 text-green-700 border-green-200';
    }

    if (estado?.toUpperCase() === 'INACTIVO') {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    return 'bg-slate-100 text-slate-700 border-slate-200';
  }

  estaActivo(proveedor: Proveedor): boolean {
    return String(proveedor.estado || '').toUpperCase() === 'ACTIVO';
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

  normalizarRubro(valor: unknown): string {
    const data = valor as any;
    const bruto =
      typeof valor === 'object' && valor !== null
        ? data.codigo || data.valor || data.value || data.rubro || data.nombre
        : valor;

    const codigo = String(bruto || '')
      .trim()
      .toUpperCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[\s-]+/g, '_');

    const alias: Record<string, string> = {
      MINERIA: 'OTROS',
      FERRETERIA: 'HERRAMIENTAS_REPUESTOS',
      FERRETERIA_INDUSTRIAL: 'HERRAMIENTAS_REPUESTOS',
      HERRAMIENTAS: 'HERRAMIENTAS_REPUESTOS',
      REPUESTOS: 'HERRAMIENTAS_REPUESTOS',
      MAQUINARIA: 'EQUIPOS_MENORES',
      EQUIPOS: 'EQUIPOS_MENORES',
      COMBUSTIBLES: 'COMBUSTIBLE',
      SEGURIDAD: 'SEGURIDAD_INDUSTRIAL',
      TRANSPORTE: 'SERVICIOS_COMPLEMENTARIOS',
      SERVICIOS: 'SERVICIOS_COMPLEMENTARIOS',
      EXPLOSIVOS: 'MATERIAL_EXPLOSIVO_CONTROLADO',
      PERFORACION: 'MATERIAL_PERFORACION',
    };

    return alias[codigo] || codigo;
  }

  etiquetaRubro(valor: unknown): string {
    const codigo = this.normalizarRubro(valor);

    return (
      this.rubros.find((rubro) => rubro.valor === codigo)?.etiqueta ||
      codigo
        .replaceAll('_', ' ')
        .toLowerCase()
        .replace(/(^|\s)\S/g, (letra) => letra.toUpperCase())
    );
  }

  iconoRubro(rubro: string): string {
    const normalizado = this.normalizarRubro(rubro);

    if (normalizado.includes('EQUIPOS')) return '🚜';
    if (normalizado.includes('COMBUSTIBLE')) return '⛽';
    if (normalizado.includes('SEGURIDAD')) return '🦺';
    if (normalizado.includes('REPUESTO')) return '🔩';
    if (normalizado.includes('TRANSPORTE')) return '🚚';
    if (normalizado.includes('FERRETER')) return '🛠️';

    return '🏭';
  }


  tituloConfirmacion(): string {
    const accion = this.modoConfirmacion();

    if (accion === 'eliminar') {
            this.proveedores.update((lista) =>
              lista.filter((item) => item.idProveedor !== (this.proveedorSeleccionado()?.idProveedor ?? 0)),
            );

      return 'Eliminar proveedor';
    
          }

    if (accion === 'activar') {
      return 'Activar proveedor';
    }

    if (accion === 'desactivar') {
      return 'Desactivar proveedor';
    }

    return '';
  }

  mensajeConfirmacion(): string {
    const accion = this.modoConfirmacion();

    if (accion === 'eliminar') {
      return '¿Está seguro de eliminar este proveedor? Esta acción lo quitará del listado principal mediante borrado lógico.';
    }

    if (accion === 'activar') {
      return '¿Está seguro de activar este proveedor? El proveedor volverá a estar disponible en el sistema.';
    }

    if (accion === 'desactivar') {
      return '¿Está seguro de desactivar este proveedor? No se eliminará la información histórica.';
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



  proveedorConfirmacion(): any {
    const self = this as any;
    const seleccionado = self['proveedorSeleccionado'];
    return typeof seleccionado === 'function' ? seleccionado() : null;
  }

  cerrarConfirmacionProveedor(): void {
    const self = this as any;
    const seleccionado = self['proveedorSeleccionado'];

    if (seleccionado?.set) {
      seleccionado.set(null);
    }

    this.modoConfirmacion.set('ninguno');
  }

  tituloConfirmacionProveedor(): string {
    const accion = this.modoConfirmacion();

    if (accion === 'eliminar') return 'Eliminar proveedor';
    if (accion === 'activar') return 'Activar proveedor';
    if (accion === 'desactivar') return 'Desactivar proveedor';

    return 'Confirmar acción';
  }

  mensajeConfirmacionProveedor(): string {
    const accion = this.modoConfirmacion();

    if (accion === 'eliminar') {
      return '¿Está seguro de eliminar este proveedor? Esta acción lo quitará del listado principal mediante borrado lógico.';
    }

    if (accion === 'activar') {
      return '¿Está seguro de activar este proveedor? El proveedor volverá a estar disponible en el sistema.';
    }

    if (accion === 'desactivar') {
      return '¿Está seguro de desactivar este proveedor? No se eliminará la información histórica.';
    }

    return 'Confirme la acción seleccionada.';
  }

  textoBotonConfirmacionProveedor(): string {
    const accion = this.modoConfirmacion();

    if (accion === 'eliminar') return 'Sí, eliminar';
    if (accion === 'activar') return 'Sí, activar';
    if (accion === 'desactivar') return 'Sí, desactivar';

    return 'Confirmar';
  }

}
