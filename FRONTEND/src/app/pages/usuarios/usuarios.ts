import { Component, HostListener, computed, inject, signal } from '@angular/core';
import {
  AbstractControl,
  FormBuilder,
  ReactiveFormsModule,
  ValidationErrors,
  Validators,
} from '@angular/forms';
import { RouterLink } from '@angular/router';
import { UsuariosService } from '../../core/services/usuarios.service';
import { PermissionService } from '../../core/services/permission.service';
import { Area, Rol, Usuario } from '../../core/models/usuario.model';
import {
  EXPEDIDOS_CI,
  formatearDocumentoIdentidad,
  limpiarCedulaIdentidad,
  limpiarComplementoCi,
  normalizarExpedidoCi,
  obtenerDocumentoIdentidad,
} from '../../core/utils/documento-identidad.util';
import {
  complementoCiValidator,
  correoProfesionalValidator,
  nombrePersonaValidator,
  normalizarMayusculas,
  normalizarMinusculas,
  normalizarSoloDigitos,
  soloNumerosMaxValidator,
  telefonoBoliviaValidator,
  usuarioSistemaValidator,
} from '../../core/forms/professional-forms';
import {
  FormFieldLabels,
  marcarFormularioInvalido,
  mensajeErrorBackend,
  validacionFormularioSolicitada,
} from '../../core/forms/form-error-messages';
import { esRolOficialActivo } from '../../core/utils/roles.util';

type ModoModal = 'ninguno' | 'nuevo' | 'editar' | 'ver';
type ModoConfirmacion = 'ninguno' | 'activar' | 'desactivar' | 'eliminar';
type CampoFormularioUsuario =
  | 'nombreUsuario'
  | 'nombreCompleto'
  | 'correo'
  | 'cedulaIdentidad'
  | 'complementoCi'
  | 'expedidoCi'
  | 'telefono'
  | 'cargo'
  | 'password'
  | 'confirmarPassword'
  | 'idRol'
  | 'idArea'
  | 'estado';

const AREAS_POR_DEFECTO: Area[] = [
  { idArea: 1, nombreArea: 'Operaciones / Mina' },
  { idArea: 2, nombreArea: 'Mantenimiento / Maestranza' },
  { idArea: 3, nombreArea: 'Seguridad Industrial (HSE)' },
  { idArea: 4, nombreArea: 'Logística / Almacenes' },
  { idArea: 5, nombreArea: 'Administración / Gerencia' },
  { idArea: 6, nombreArea: 'Otros / Terceros' },
];

@Component({
  selector: 'app-usuarios',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink],
  templateUrl: './usuarios.html',
  styleUrl: './usuarios.css',
})
export class Usuarios {
  private readonly usuariosService = inject(UsuariosService);
  private readonly permissionService = inject(PermissionService);
  private readonly formBuilder = inject(FormBuilder);
  private readonly etiquetasFormulario: FormFieldLabels = {
    nombreUsuario: 'Nombre de usuario',
    nombreCompleto: 'Nombre completo',
    correo: 'Correo',
    cedulaIdentidad: 'Cedula de identidad',
    complementoCi: 'Complemento CI',
    expedidoCi: 'Expedido',
    telefono: 'Telefono',
    cargo: 'Cargo',
    password: 'Contrasena',
    confirmarPassword: 'Confirmar contrasena',
    idRol: 'Rol',
    idArea: 'Area',
    estado: 'Estado',
  };

  cargando = signal(false);
  guardando = signal(false);
  error = signal('');
  mensaje = signal('');

  busqueda = signal('');
  usuarios = signal<Usuario[]>([]);

  modoModal = signal<ModoModal>('ninguno');
  modoConfirmacion = signal<ModoConfirmacion>('ninguno');
  usuarioSeleccionado = signal<Usuario | null>(null);
  menuAccionesUsuarioId = signal<number | null>(null);
  menuAccionesAbreArriba = signal(false);
  readonly expedidosCi = EXPEDIDOS_CI;
  cambiarPassword = signal(false);
  mostrarPasswordInicial = signal(false);
  mostrarNuevaPassword = signal(false);
  mostrarConfirmarPassword = signal(false);

  modalAbierto = computed(() => this.modoModal() !== 'ninguno');
  confirmacionAbierta = computed(() => this.modoConfirmacion() !== 'ninguno');

  totalUsuarios = computed(() => this.usuarios().length);

  totalActivos = computed(() => this.usuarios().filter((u) => u.estado === 'ACTIVO').length);

  totalInactivos = computed(() => this.usuarios().filter((u) => u.estado === 'INACTIVO').length);

  usuariosFiltrados = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();

    if (!texto) {
      return this.usuarios();
    }

    return this.usuarios().filter((usuario) => {
      const rol = this.obtenerRol(usuario).toLowerCase();
      const area = this.obtenerArea(usuario).toLowerCase();

      return (
        usuario.nombreUsuario?.toLowerCase().includes(texto) ||
        usuario.nombreCompleto?.toLowerCase().includes(texto) ||
        usuario.correo?.toLowerCase().includes(texto) ||
        this.formatearDocumentoUsuario(usuario).toLowerCase().includes(texto) ||
        usuario.telefono?.toLowerCase().includes(texto) ||
        usuario.cargo?.toLowerCase().includes(texto) ||
        usuario.estado?.toLowerCase().includes(texto) ||
        rol.includes(texto) ||
        area.includes(texto)
      );
    });
  });

  form = this.formBuilder.nonNullable.group({
    nombreUsuario: ['', [Validators.required, Validators.maxLength(25), usuarioSistemaValidator()]],
    nombreCompleto: ['', [Validators.required, Validators.maxLength(50), nombrePersonaValidator()]],
    correo: ['', [Validators.required, Validators.maxLength(60), correoProfesionalValidator()]],
    cedulaIdentidad: ['', [Validators.required, soloNumerosMaxValidator(9)]],
    complementoCi: ['', [Validators.maxLength(2), complementoCiValidator()]],
    expedidoCi: [''],
    telefono: ['', [Validators.required, telefonoBoliviaValidator()]],
    cargo: ['', [Validators.maxLength(100)]],
    password: ['', [Validators.minLength(6)]],
    confirmarPassword: [''],
    idRol: [1, [Validators.required]],
    idArea: [1, [Validators.required]],
    estado: ['ACTIVO', [Validators.required]],
  });

  roles: Rol[] = [
    { idRol: 1, nombreRol: 'Administrador del sistema' },
    { idRol: 2, nombreRol: 'Encargado de almacén' },
    { idRol: 3, nombreRol: 'Supervisor de mina' },
    { idRol: 4, nombreRol: 'Jefe de área' },
    { idRol: 5, nombreRol: 'Encargado de compras' },
    { idRol: 6, nombreRol: 'Auditor' },
    { idRol: 7, nombreRol: 'Usuario solicitante' },
  ];

  areas: Area[] = [...AREAS_POR_DEFECTO];

  ngOnInit() {
    this.cargarCatalogos();
    this.cargarUsuarios();
  }

  @HostListener('document:click')
  cerrarMenuAcciones() {
    if (this.menuAccionesUsuarioId() !== null) {
      this.menuAccionesUsuarioId.set(null);
      this.menuAccionesAbreArriba.set(false);
    }
  }

  cargarCatalogos() {
    this.usuariosService.listarRoles().subscribe({
      next: (roles) => {
        const rolesOficiales = roles.filter((rol) => this.esRolSeleccionable(rol));
        this.roles = rolesOficiales.length > 0 ? rolesOficiales : this.roles;
      },
      error: () => {
        this.roles = this.roles.filter((rol) => this.esRolSeleccionable(rol));
      },
    });

    this.usuariosService.listarAreas().subscribe({
      next: (areas) => {
        this.areas = areas;
      },
      error: () => {
        this.areas = [...AREAS_POR_DEFECTO];
      },
    });
  }

  cargarUsuarios() {
    this.cargando.set(true);
    this.error.set('');
    this.mensaje.set('');
    this.cerrarMenuAcciones();

    this.usuariosService.listar().subscribe({
      next: (data) => {
        this.usuarios.set(
          data.filter((usuario: any) => String(usuario.estado || '').toUpperCase() !== 'ELIMINADO'),
        );
        this.cargando.set(false);
      },
      error: () => {
        this.error.set('No se pudo cargar la lista de usuarios.');
        this.cargando.set(false);
      },
    });
  }

  cambiarBusqueda(event: Event) {
    const input = event.target as HTMLInputElement;
    this.busqueda.set(input.value);
  }

  abrirNuevo() {
    if (!this.verificarPermiso('usuarios.crear')) {
      return;
    }

    this.cerrarMenuAcciones();
    this.mensaje.set('');
    this.error.set('');
    this.usuarioSeleccionado.set(null);
    this.modoModal.set('nuevo');
    this.reiniciarSeguridadPassword();

    this.form.reset({
      nombreUsuario: '',
      nombreCompleto: '',
      correo: '',
      cedulaIdentidad: '',
      complementoCi: '',
      expedidoCi: '',
      telefono: '',
      cargo: '',
      password: '',
      confirmarPassword: '',
      idRol: this.idRolPorDefecto(),
      idArea: this.idAreaPorDefecto(),
      estado: 'ACTIVO',
    });
    this.actualizarValidadoresPassword();
  }

  abrirVer(usuario: Usuario) {
    if (!this.verificarPermiso('usuarios.ver')) {
      return;
    }

    this.cerrarMenuAcciones();
    this.usuarioSeleccionado.set(usuario);
    this.modoModal.set('ver');
  }

  abrirEditar(usuario: Usuario) {
    if (!this.verificarPermiso('usuarios.editar')) {
      return;
    }

    this.cerrarMenuAcciones();
    this.mensaje.set('');
    this.error.set('');
    this.usuarioSeleccionado.set(usuario);
    this.modoModal.set('editar');
    this.reiniciarSeguridadPassword();

    const documento = obtenerDocumentoIdentidad(usuario);

    this.form.reset({
      nombreUsuario: usuario.nombreUsuario || '',
      nombreCompleto: usuario.nombreCompleto || '',
      correo: usuario.correo || '',
      cedulaIdentidad: documento.cedulaIdentidad,
      complementoCi: documento.complementoCi,
      expedidoCi: documento.expedidoCi,
      telefono: usuario.telefono || '',
      cargo: usuario.cargo || '',
      password: '',
      confirmarPassword: '',
      idRol: this.obtenerIdRol(usuario),
      idArea: this.obtenerIdArea(usuario),
      estado: usuario.estado || 'ACTIVO',
    });
    this.actualizarValidadoresPassword();
  }

  cerrarModal() {
    this.modoModal.set('ninguno');
    this.usuarioSeleccionado.set(null);
    this.reiniciarSeguridadPassword();
    this.form.reset();
  }

  reiniciarSeguridadPassword() {
    this.cambiarPassword.set(false);
    this.mostrarPasswordInicial.set(false);
    this.mostrarNuevaPassword.set(false);
    this.mostrarConfirmarPassword.set(false);
    this.form?.controls.password.setValue('', { emitEvent: false });
    this.form?.controls.confirmarPassword.setValue('', { emitEvent: false });
  }

  alternarCambioPassword(event: Event) {
    const input = event.target as HTMLInputElement;
    this.cambiarPassword.set(input.checked);

    if (!input.checked) {
      this.form.controls.password.setValue('', { emitEvent: false });
      this.form.controls.confirmarPassword.setValue('', { emitEvent: false });
      this.mostrarNuevaPassword.set(false);
      this.mostrarConfirmarPassword.set(false);
    }

    this.actualizarValidadoresPassword();
    this.validarConfirmacionPassword();
  }

  alternarPasswordInicial() {
    this.mostrarPasswordInicial.update((valor) => !valor);
  }

  alternarNuevaPassword() {
    this.mostrarNuevaPassword.update((valor) => !valor);
  }

  alternarConfirmarPassword() {
    this.mostrarConfirmarPassword.update((valor) => !valor);
  }

  abrirConfirmacionEstado(usuario: Usuario) {
    const permiso = this.estaActivo(usuario) ? 'usuarios.desactivar' : 'usuarios.activar';

    if (!this.verificarPermiso(permiso)) {
      return;
    }

    this.cerrarMenuAcciones();
    this.usuarioSeleccionado.set(usuario);
    this.modoConfirmacion.set(this.estaActivo(usuario) ? 'desactivar' : 'activar');
  }

  abrirConfirmacionEliminar(usuario: Usuario) {
    if (!this.verificarPermiso('usuarios.eliminar')) {
      return;
    }

    this.cerrarMenuAcciones();
    this.usuarioSeleccionado.set(usuario);
    this.modoConfirmacion.set('eliminar');
  }

  alternarMenuAcciones(usuario: Usuario, event: MouseEvent) {
    event.stopPropagation();
    const idUsuario = usuario.idUsuario;

    if (this.menuAccionesUsuarioId() === idUsuario) {
      this.menuAccionesUsuarioId.set(null);
      this.menuAccionesAbreArriba.set(false);
      return;
    }

    const boton = event.currentTarget as HTMLElement;
    const rect = boton.getBoundingClientRect();
    const altoMenuEstimado = 230;
    const espacioAbajo = window.innerHeight - rect.bottom;
    const espacioArriba = rect.top;

    this.menuAccionesAbreArriba.set(
      espacioAbajo < altoMenuEstimado && espacioArriba > espacioAbajo,
    );
    this.menuAccionesUsuarioId.set(idUsuario);
  }

  menuAccionesAbierto(usuario: Usuario): boolean {
    return this.menuAccionesUsuarioId() === usuario.idUsuario;
  }

  menuAccionesHaciaArriba(usuario: Usuario, indice: number, total: number): boolean {
    return (
      this.menuAccionesAbierto(usuario) && (this.menuAccionesAbreArriba() || indice >= total - 2)
    );
  }

  abrirVerDesdeMenu(usuario: Usuario) {
    this.abrirVer(usuario);
  }

  abrirEditarDesdeMenu(usuario: Usuario) {
    this.abrirEditar(usuario);
  }

  abrirEstadoDesdeMenu(usuario: Usuario) {
    this.abrirConfirmacionEstado(usuario);
  }

  abrirEliminarDesdeMenu(usuario: Usuario) {
    this.abrirConfirmacionEliminar(usuario);
  }

  cerrarConfirmacion() {
    this.modoConfirmacion.set('ninguno');
    this.usuarioSeleccionado.set(null);
  }

  confirmarCambioEstado() {
    const usuario = this.usuarioSeleccionado();

    if (!usuario) {
      return;
    }

    this.guardando.set(true);
    const accion = this.modoConfirmacion();
    const permiso =
      accion === 'eliminar'
        ? 'usuarios.eliminar'
        : accion === 'activar'
          ? 'usuarios.activar'
          : 'usuarios.desactivar';

    if (!this.verificarPermiso(permiso)) {
      this.guardando.set(false);
      this.cerrarConfirmacion();
      return;
    }

    const peticion =
      accion === 'eliminar'
        ? this.usuariosService.eliminar(usuario.idUsuario)
        : accion === 'activar'
          ? this.usuariosService.activar(usuario.idUsuario)
          : this.usuariosService.desactivar(usuario.idUsuario);

    peticion.subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set(
          accion === 'activar'
            ? 'Usuario activado correctamente.'
            : accion === 'eliminar'
              ? 'Usuario eliminado correctamente.'
              : 'Usuario desactivado correctamente.',
        );
        this.cerrarConfirmacion();
        this.cargarUsuarios();
      },
      error: (error) => {
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
        this.cerrarConfirmacion();
      },
    });
  }

  guardarUsuario() {
    this.error.set('');
    this.mensaje.set('');

    const permiso = this.modoModal() === 'nuevo' ? 'usuarios.crear' : 'usuarios.editar';

    if (!this.verificarPermiso(permiso)) {
      return;
    }

    this.validarConfirmacionPassword();

    const valores = this.form.getRawValue();
    const password = valores.password.trim();
    const confirmarPassword = valores.confirmarPassword.trim();
    const cedulaIdentidad = limpiarCedulaIdentidad(valores.cedulaIdentidad);
    const complementoCi = limpiarComplementoCi(valores.complementoCi);
    const expedidoCi = normalizarExpedidoCi(valores.expedidoCi);

    if (this.form.invalid) {
      marcarFormularioInvalido(
        this.form,
        this.etiquetasFormulario,
        'Revise los campos del usuario',
      );
      return;
    }

    const payload: any = {
      nombreUsuario: normalizarMinusculas(valores.nombreUsuario),
      nombreCompleto: valores.nombreCompleto.trim(),
      correo: normalizarMinusculas(valores.correo),
      cedulaIdentidad: cedulaIdentidad || null,
      complementoCi: complementoCi || null,
      expedidoCi: expedidoCi || null,
      telefono: normalizarSoloDigitos(valores.telefono, 8) || null,
      cargo: valores.cargo.trim() || null,
      idRol: Number(valores.idRol),
      idArea: Number(valores.idArea),
      estado: valores.estado,
    };

    if (this.modoModal() === 'nuevo' || this.cambiarPassword()) {
      payload.password = password;
    }

    this.guardando.set(true);

    if (this.modoModal() === 'nuevo') {
      this.usuariosService.crear(payload).subscribe({
        next: () => {
          this.guardando.set(false);
          this.mensaje.set('Usuario creado correctamente.');
          this.cerrarModal();
          this.cargarUsuarios();
        },
        error: (error) => {
          this.guardando.set(false);
          this.error.set(this.obtenerMensajeErrorBackend(error));
        },
      });

      return;
    }

    const usuario = this.usuarioSeleccionado();

    if (!usuario) {
      this.guardando.set(false);
      this.error.set('No hay usuario seleccionado.');
      return;
    }

    this.usuariosService.actualizar(usuario.idUsuario, payload).subscribe({
      next: () => {
        this.guardando.set(false);
        this.mensaje.set('Usuario actualizado correctamente.');
        this.cerrarModal();
        this.cargarUsuarios();
      },
      error: (error) => {
        this.guardando.set(false);
        this.error.set(this.obtenerMensajeErrorBackend(error));
      },
    });
  }

  obtenerMensajeErrorBackend(error: any): string {
    const mensaje = mensajeErrorBackend(error, this.etiquetasFormulario);

    if (Array.isArray(mensaje)) return mensaje.join(' | ');
    if (typeof mensaje === 'string') return mensaje;
    if (error?.error?.error) return error.error.error;

    return 'No se pudo completar la operacion. Revise los datos enviados.';
  }

  obtenerRol(usuario: Usuario): string {
    if (!usuario.rol) {
      return 'Sin rol';
    }

    if (typeof usuario.rol === 'string') {
      return usuario.rol;
    }

    return usuario.rol.nombreRol || 'Sin rol';
  }

  obtenerCedula(usuario: Usuario): string {
    return obtenerDocumentoIdentidad(usuario).cedulaIdentidad;
  }

  formatearDocumentoUsuario(usuario: Usuario): string {
    return formatearDocumentoIdentidad(usuario);
  }

  formatearContactoUsuario(usuario: Usuario): string {
    const telefono = String(usuario.telefono || '').trim();

    if (!telefono) {
      return 'Sin contacto';
    }

    if (telefono.startsWith('+')) {
      return telefono;
    }

    const digitos = telefono.replace(/\D/g, '');

    if (digitos.length === 8) {
      return `+591 ${digitos}`;
    }

    if (digitos.length === 11 && digitos.startsWith('591')) {
      return `+591 ${digitos.slice(3)}`;
    }

    return telefono;
  }

  normalizarCedulaInput() {
    const control = this.form.controls.cedulaIdentidad;
    const valor = normalizarSoloDigitos(limpiarCedulaIdentidad(control.value), 9);

    if (valor !== control.value) {
      control.setValue(valor, { emitEvent: false });
    }
  }

  normalizarComplementoInput() {
    const control = this.form.controls.complementoCi;
    const valor = normalizarMayusculas(limpiarComplementoCi(control.value)).slice(0, 2);

    if (valor !== control.value) {
      control.setValue(valor, { emitEvent: false });
    }
  }

  normalizarUsuarioInput() {
    const control = this.form.controls.nombreUsuario;
    const valor = normalizarMinusculas(control.value);

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

  normalizarTelefonoInput() {
    const control = this.form.controls.telefono;
    const valor = normalizarSoloDigitos(control.value, 8);

    if (valor !== control.value) {
      control.setValue(valor, { emitEvent: false });
    }
  }

  campoInvalido(campo: CampoFormularioUsuario): boolean {
    const control = this.form.controls[campo];

    return control.invalid && validacionFormularioSolicitada(control);
  }

  mensajeCampo(campo: CampoFormularioUsuario): string {
    const control = this.form.controls[campo];

    if (!this.campoInvalido(campo) || !control.errors) {
      return '';
    }

    return this.mensajeErrorCampo(control.errors);
  }

  validarConfirmacionPassword() {
    const password = this.form.controls.password.value.trim();
    const confirmarPassword = this.form.controls.confirmarPassword.value.trim();
    const confirmaEnEdicion = this.modoModal() === 'editar' && this.cambiarPassword();
    const validarConfirmacion =
      confirmaEnEdicion || (this.modoModal() === 'nuevo' && confirmarPassword);

    if (validarConfirmacion && password && confirmarPassword && password !== confirmarPassword) {
      this.agregarErrorControl(this.form.controls.confirmarPassword, 'passwordConfirmacion');
      return;
    }

    this.quitarErrorControl(this.form.controls.confirmarPassword, 'passwordConfirmacion');
  }

  private actualizarValidadoresPassword() {
    const password = this.form.controls.password;
    const confirmarPassword = this.form.controls.confirmarPassword;

    if (this.modoModal() === 'nuevo' || this.cambiarPassword()) {
      password.setValidators([Validators.required, Validators.minLength(6)]);
    } else {
      password.setValidators([Validators.minLength(6)]);
    }

    if (this.modoModal() === 'editar' && this.cambiarPassword()) {
      confirmarPassword.setValidators([Validators.required]);
    } else {
      confirmarPassword.clearValidators();
    }

    password.updateValueAndValidity({ emitEvent: false });
    confirmarPassword.updateValueAndValidity({ emitEvent: false });
  }

  private mensajeErrorCampo(errores: ValidationErrors): string {
    if (errores['required'] || errores['passwordRequerido']) {
      return 'Este campo es obligatorio.';
    }

    if (errores['minlength'] || errores['passwordMinLength']) {
      const minimo = errores['minlength']?.requiredLength ?? 6;
      return `Debe tener al menos ${minimo} caracteres.`;
    }

    if (errores['maxlength']) {
      return `Debe tener maximo ${errores['maxlength']?.requiredLength} caracteres.`;
    }

    if (errores['correoProfesional'] || errores['email']) {
      return 'Ingrese un correo valido.';
    }

    if (errores['usuarioSistema']) {
      return 'Use minusculas, numeros, punto o guion bajo.';
    }

    if (errores['nombrePersona']) {
      return 'Use solo letras y espacios.';
    }

    if (errores['soloNumerosMax']) {
      return `Use solo numeros y maximo ${errores['soloNumerosMax']?.maxLength} digitos.`;
    }

    if (errores['complementoCi']) {
      return 'Use 1 o 2 caracteres validos.';
    }

    if (errores['telefonoBolivia']) {
      return 'Debe tener 8 digitos y empezar con 6 o 7.';
    }

    if (errores['passwordConfirmacion']) {
      return 'Debe coincidir con la contrasena.';
    }

    return 'Revise este dato.';
  }

  private agregarErrorControl(control: AbstractControl, codigo: string) {
    control.setErrors({
      ...(control.errors ?? {}),
      [codigo]: true,
    });
  }

  private quitarErrorControl(control: AbstractControl, codigo: string) {
    if (!control.hasError(codigo)) {
      return;
    }

    const errores = { ...(control.errors ?? {}) };
    delete errores[codigo];

    control.setErrors(Object.keys(errores).length ? errores : null);
  }

  obtenerIdRol(usuario: Usuario): number {
    const data = usuario as any;

    if (data.idRol || data.id_rol) {
      return Number(data.idRol || data.id_rol);
    }

    if (!usuario.rol || typeof usuario.rol === 'string') {
      return this.idRolPorDefecto();
    }

    return usuario.rol.idRol || this.idRolPorDefecto();
  }

  obtenerArea(usuario: Usuario): string {
    const area = usuario.area as any;

    if (!area) {
      return 'Sin área';
    }

    if (typeof area === 'string') {
      return area;
    }

    return area.nombreArea || area.nombre_area || 'Sin área';
  }

  obtenerIdArea(usuario: Usuario): number {
    const data = usuario as any;
    const area = usuario.area as any;

    return Number(
      data.idArea || data.id_area || area?.idArea || area?.id_area || this.idAreaPorDefecto(),
    );
  }

  private esRolSeleccionable(rol: Rol): boolean {
    const estado = String(rol.estado || 'ACTIVO').toUpperCase();
    return (
      estado === 'ACTIVO' &&
      this.claveRolSinAlias(rol.nombreRol) !== 'JEFE_DE_ALMACEN' &&
      esRolOficialActivo(rol.codigoRol || rol.nombreRol)
    );
  }

  private claveRolSinAlias(nombre?: string | null): string {
    return String(nombre || '')
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .trim()
      .toUpperCase()
      .replace(/[^A-Z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '');
  }

  idRolPorDefecto(): number {
    return this.roles[0]?.idRol || 1;
  }

  idAreaPorDefecto(): number {
    return this.areas[0]?.idArea || 1;
  }

  obtenerIniciales(usuario: Usuario): string {
    const nombre = usuario.nombreCompleto || usuario.nombreUsuario || 'U';

    return nombre
      .split(' ')
      .filter(Boolean)
      .slice(0, 2)
      .map((parte) => parte[0])
      .join('')
      .toUpperCase();
  }

  claseEstado(estado: string): string {
    const estadoNormalizado = estado?.toUpperCase();

    if (estadoNormalizado === 'ACTIVO') {
      return 'usuario-badge usuario-estado estado-activo';
    }

    if (estadoNormalizado === 'INACTIVO') {
      return 'usuario-badge usuario-estado estado-inactivo';
    }

    return 'usuario-badge usuario-estado estado-neutro';
  }

  estaActivo(usuario: Usuario): boolean {
    return String(usuario.estado || '').toUpperCase() === 'ACTIVO';
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

  tituloConfirmacion(): string {
    const accion = this.modoConfirmacion();
    if (accion === 'eliminar') return 'Eliminar usuario';
    return accion === 'activar' ? 'Activar usuario' : 'Desactivar usuario';
  }

  textoConfirmacion(): string {
    const accion = this.modoConfirmacion();
    if (accion === 'eliminar') {
      return 'Esta accion eliminara el usuario del listado principal mediante borrado logico.';
    }

    return accion === 'activar'
      ? 'Esta seguro de activar este usuario?'
      : 'Esta seguro de desactivar este usuario?';
  }

  textoBotonConfirmacion(): string {
    const accion = this.modoConfirmacion();
    if (accion === 'eliminar') return 'Si, eliminar';
    return accion === 'activar' ? 'Si, activar' : 'Si, desactivar';
  }

  mensajeConfirmacion(): string {
    const accion = this.modoConfirmacion();

    if (accion === 'eliminar') {
      return 'Esta acción eliminará el usuario del listado principal.';
    }

    if (accion === 'activar') {
      return '¿Está seguro de activar este usuario?';
    }

    if (accion === 'desactivar') {
      return '¿Está seguro de desactivar este usuario?';
    }

    return '';
  }
}
