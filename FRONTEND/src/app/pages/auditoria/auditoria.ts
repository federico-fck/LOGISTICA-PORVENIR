import { Component, computed, inject, signal } from '@angular/core';
import { AuditoriaService } from '../../core/services/auditoria.service';
import { PermissionService } from '../../core/services/permission.service';
import {
  Auditoria as AuditoriaModel,
  AuditoriaFiltros,
  AuditoriaResumen,
} from '../../core/models/auditoria.model';
import { formatearFechaHoraBolivia } from '../../core/utils/fecha.util';

@Component({
  selector: 'app-auditoria',
  standalone: true,
  imports: [],
  templateUrl: './auditoria.html',
  styleUrl: './auditoria.css',
})
export class Auditoria {
  private readonly auditoriaService = inject(AuditoriaService);
  private readonly permissionService = inject(PermissionService);

  cargando = signal(false);
  error = signal('');
  busqueda = signal('');

  auditorias = signal<AuditoriaModel[]>([]);
  resumen = signal<AuditoriaResumen | null>(null);

  tiposAccion = signal<string[]>([]);
  modulos = signal<string[]>([]);

  tipoSeleccionado = signal('');
  moduloSeleccionado = signal('');
  fechaInicio = signal('');
  fechaFin = signal('');

  detalleAbierto = signal(false);
  auditoriaSeleccionada = signal<AuditoriaModel | null>(null);

  auditoriasFiltradas = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();

    if (!texto) {
      return this.auditorias();
    }

    return this.auditorias().filter((item) => {
      const usuario =
        item.usuario?.nombreCompleto ||
        item.usuario?.nombreUsuario ||
        '';

      return (
        item.accionRealizada?.toLowerCase().includes(texto) ||
        item.tipoAccion?.toLowerCase().includes(texto) ||
        item.moduloAfectado?.toLowerCase().includes(texto) ||
        item.tablaAfectada?.toLowerCase().includes(texto) ||
        usuario.toLowerCase().includes(texto) ||
        item.direccionIp?.toLowerCase().includes(texto)
      );
    });
  });

  totalRegistros = computed(() => this.auditorias().length);

  totalCrear = computed(
    () => this.auditorias().filter((a) => a.tipoAccion === 'CREAR').length,
  );

  totalEditar = computed(
    () => this.auditorias().filter((a) => a.tipoAccion === 'EDITAR').length,
  );

  totalEliminar = computed(
    () => this.auditorias().filter((a) => a.tipoAccion === 'ELIMINAR').length,
  );

  ngOnInit() {
    this.cargarDatosIniciales();
  }

  cargarDatosIniciales() {
    this.cargarTipos();
    this.cargarResumen();
    this.cargarAuditoria();
  }

  cargarAuditoria() {
    this.cargando.set(true);
    this.error.set('');

    const filtros: AuditoriaFiltros = {};

    if (this.tipoSeleccionado()) {
      filtros.tipoAccion = this.tipoSeleccionado();
    }

    if (this.moduloSeleccionado()) {
      filtros.moduloAfectado = this.moduloSeleccionado();
    }

    if (this.fechaInicio()) {
      filtros.fechaInicio = this.fechaInicio();
    }

    if (this.fechaFin()) {
      filtros.fechaFin = this.fechaFin();
    }

    this.auditoriaService.listar(filtros).subscribe({
      next: (data) => {
        this.auditorias.set(data);
        this.cargando.set(false);
      },
      error: () => {
        this.error.set('No se pudo cargar la auditoría del sistema.');
        this.cargando.set(false);
      },
    });
  }

  cargarTipos() {
    this.auditoriaService.tipos().subscribe({
      next: (data) => {
        this.tiposAccion.set(data.tiposAccion || []);
        this.modulos.set(data.modulos || []);
      },
      error: () => {
        this.tiposAccion.set([]);
        this.modulos.set([]);
      },
    });
  }

  cargarResumen() {
    this.auditoriaService.resumen().subscribe({
      next: (data) => {
        this.resumen.set(data);
      },
      error: () => {
        this.resumen.set(null);
      },
    });
  }

  actualizar() {
    this.cargarResumen();
    this.cargarAuditoria();
  }

  limpiarFiltros() {
    this.busqueda.set('');
    this.tipoSeleccionado.set('');
    this.moduloSeleccionado.set('');
    this.fechaInicio.set('');
    this.fechaFin.set('');
    this.cargarAuditoria();
  }

  cambiarBusqueda(event: Event) {
    const input = event.target as HTMLInputElement;
    this.busqueda.set(input.value);
  }

  cambiarTipo(event: Event) {
    const select = event.target as HTMLSelectElement;
    this.tipoSeleccionado.set(select.value);
    this.cargarAuditoria();
  }

  cambiarModulo(event: Event) {
    const select = event.target as HTMLSelectElement;
    this.moduloSeleccionado.set(select.value);
    this.cargarAuditoria();
  }

  cambiarFechaInicio(event: Event) {
    const input = event.target as HTMLInputElement;
    this.fechaInicio.set(input.value);
  }

  cambiarFechaFin(event: Event) {
    const input = event.target as HTMLInputElement;
    this.fechaFin.set(input.value);
  }

  aplicarFechas() {
    this.cargarAuditoria();
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

  abrirDetalle(item: AuditoriaModel) {
    if (!this.verificarPermiso('auditoria.detalle')) {
      return;
    }

    this.auditoriaSeleccionada.set(item);
    this.detalleAbierto.set(true);
  }

  cerrarDetalle() {
    this.auditoriaSeleccionada.set(null);
    this.detalleAbierto.set(false);
  }

  nombreUsuario(item: AuditoriaModel): string {
    return (
      item.usuario?.nombreCompleto ||
      item.usuario?.nombreUsuario ||
      'Sistema / Sin usuario'
    );
  }

  fechaFormateada(fecha: string): string {
    return formatearFechaHoraBolivia(fecha);
  }

  claseTipo(tipo: string): string {
    const normalizado = tipo?.toUpperCase();

    if (normalizado === 'CREAR') {
      return 'bg-green-100 text-green-700 border-green-200';
    }

    if (normalizado === 'EDITAR') {
      return 'bg-blue-100 text-blue-700 border-blue-200';
    }

    if (normalizado === 'ELIMINAR') {
      return 'bg-red-100 text-red-700 border-red-200';
    }

    if (normalizado === 'APROBAR') {
      return 'bg-emerald-100 text-emerald-700 border-emerald-200';
    }

    if (normalizado === 'RECHAZAR') {
      return 'bg-orange-100 text-orange-700 border-orange-200';
    }

    if (normalizado === 'INICIAR_SESION' || normalizado === 'LOGIN') {
      return 'bg-violet-100 text-violet-700 border-violet-200';
    }

    return 'bg-slate-100 text-slate-700 border-slate-200';
  }

  etiquetaTipo(tipo: string): string {
    const etiquetas: Record<string, string> = {
      ACTIVAR: 'Activar',
      DESACTIVAR: 'Desactivar',
      CREAR: 'Crear',
      EDITAR: 'Editar',
      ELIMINAR: 'Eliminar',
      REGISTRAR_COMPRA: 'Registrar compra',
      REGISTRAR_RECEPCION: 'Registrar recepción',
      REGISTRAR_COMPROBANTE: 'Registrar comprobante',
      REALIZAR_DESPACHO: 'Realizar despacho',
      AJUSTAR_INVENTARIO: 'Ajustar inventario',
      INICIAR_SESION: 'Iniciar sesión',
      CERRAR_SESION: 'Cerrar sesión',
      APROBAR: 'Aprobar',
      RECHAZAR: 'Rechazar',
    };

    return etiquetas[tipo?.toUpperCase()] || tipo || 'No especificado';
  }

  iconoTipo(tipo: string): string {
    const normalizado = tipo?.toUpperCase();

    if (normalizado === 'CREAR') {
      return '✅';
    }

    if (normalizado === 'EDITAR') {
      return '✏️';
    }

    if (normalizado === 'ELIMINAR') {
      return '🗑️';
    }

    if (normalizado === 'APROBAR') {
      return '🟢';
    }

    if (normalizado === 'RECHAZAR') {
      return '🔴';
    }

    if (normalizado === 'INICIAR_SESION' || normalizado === 'LOGIN') {
      return '🔐';
    }

    return '🛡️';
  }

  jsonTexto(valor: unknown): string {
    if (!valor) {
      return 'Sin datos';
    }

    return JSON.stringify(valor, null, 2);
  }

  registroAnterior(item: AuditoriaModel) {
    return item.registroAnterior || item.datosAnteriores || null;
  }

  registroNuevo(item: AuditoriaModel) {
    return item.registroNuevo || item.datosNuevos || null;
  }


  filasRegistroAuditoria(registro: unknown): Array<{ campo: string; valor: string }> {
    const datos = this.normalizarRegistroAuditoria(registro);

    return Object.entries(datos)
      .filter(([_, valor]) => valor !== null && valor !== undefined && valor !== '')
      .map(([campo, valor]) => ({
        campo: this.etiquetaCampoAuditoria(campo),
        valor: this.valorAuditoria(valor),
      }));
  }

  filasRegistroAnteriorAuditoria(item: AuditoriaModel): Array<{ campo: string; valor: string }> {
    const filas = this.filasRegistroAuditoria(this.registroAnterior(item));

    if (filas.length > 0) {
      return filas;
    }

    return [
      { campo: 'Tabla afectada', valor: item.tablaAfectada || 'Sin tabla registrada' },
      {
        campo: 'Registro afectado',
        valor: String(item.idRegistroAfectado || 'Referencia no especificada'),
      },
      { campo: 'Accion auditada', valor: this.etiquetaTipo(item.tipoAccion) },
      { campo: 'Responsable', valor: this.nombreUsuario(item) },
    ];
  }

  private normalizarRegistroAuditoria(registro: unknown): Record<string, unknown> {
    if (!registro) {
      return {};
    }

    if (typeof registro === 'string') {
      try {
        const parseado = JSON.parse(registro);
        return parseado && typeof parseado === 'object' ? parseado : { detalle: registro };
      } catch {
        return { detalle: registro };
      }
    }

    if (typeof registro === 'object') {
      return registro as Record<string, unknown>;
    }

    return { detalle: registro };
  }

  private etiquetaCampoAuditoria(campo: string): string {
    const etiquetas: Record<string, string> = {
      estado: 'Estado',
      tieneRelaciones: 'Tiene relaciones',
      idUsuario: 'Usuario',
      id_usuario: 'Usuario',
      nombreUsuario: 'Nombre de usuario',
      nombre_usuario: 'Nombre de usuario',
      nombreCompleto: 'Nombre completo',
      nombre_completo: 'Nombre completo',
      correo: 'Correo',
      telefono: 'Teléfono',
      rol: 'Rol',
      area: 'Área',
      fechaActualizacion: 'Fecha de actualización',
      fecha_actualizacion: 'Fecha de actualización',
      cantidad: 'Cantidad',
      stock: 'Stock',
      precio: 'Precio',
      total: 'Total',
      descripcion: 'Descripción',
      detalle: 'Detalle',
    };

    return etiquetas[campo] || campo
      .replace(/_/g, ' ')
      .replace(/([A-Z])/g, ' $1')
      .trim()
      .replace(/^./, (letra) => letra.toUpperCase());
  }

  private valorAuditoria(valor: unknown): string {
    if (typeof valor === 'boolean') {
      return valor ? 'Sí' : 'No';
    }

    if (valor instanceof Date) {
      return formatearFechaHoraBolivia(valor);
    }

    if (Array.isArray(valor)) {
      return valor.length ? valor.join(', ') : 'Sin datos';
    }

    if (valor && typeof valor === 'object') {
      return Object.entries(valor as Record<string, unknown>)
        .map(([campo, dato]) => `${this.etiquetaCampoAuditoria(campo)}: ${this.valorAuditoria(dato)}`)
        .join(' | ');
    }

    const texto = String(valor ?? '').trim();

    if (!texto) {
      return 'No especificado';
    }

    if (texto === 'true') return 'Sí';
    if (texto === 'false') return 'No';

    return this.corregirTextoAuditoria(texto);
  }

  navegadorAuditoria(item: any): string {
    const texto = String(
      item?.navegador ||
      item?.dispositivoNavegador ||
      item?.userAgent ||
      item?.dispositivo ||
      ''
    );

    if (!texto.trim()) {
      return 'Equipo local del sistema';
    }

    const sistema = texto.includes('Windows') ? 'Windows' :
      texto.includes('Android') ? 'Android' :
      texto.includes('iPhone') || texto.includes('iPad') ? 'iOS' :
      texto.includes('Linux') ? 'Linux' :
      'Sistema no identificado';

    const navegador = texto.includes('Edg/') || texto.includes('Edge') ? 'Microsoft Edge' :
      texto.includes('Chrome') ? 'Google Chrome' :
      texto.includes('Firefox') ? 'Mozilla Firefox' :
      texto.includes('Safari') ? 'Safari' :
      'Navegador no identificado';

    return `${navegador} - ${sistema}`;
  }

  motivoAuditoria(item: any): string {
    const motivo = String(item?.motivoCambio || item?.motivo || '').trim();

    if (motivo) {
      return this.corregirTextoAuditoria(motivo);
    }

    const accion = String(item?.tipoAccion || item?.accion || '').toUpperCase();
    const modulo = String(item?.modulo || item?.tablaAfectada || item?.tabla || 'el sistema');

    if (accion.includes('ELIMINAR')) {
      return `Eliminación lógica registrada desde el módulo ${modulo}.`;
    }

    if (accion.includes('DESACTIVAR')) {
      return `Desactivación registrada desde el módulo ${modulo}.`;
    }

    if (accion.includes('ACTIVAR')) {
      return `Activación registrada desde el módulo ${modulo}.`;
    }

    if (accion.includes('CREAR')) {
      return `Creación de registro desde el módulo ${modulo}.`;
    }

    if (accion.includes('EDITAR') || accion.includes('ACTUALIZAR')) {
      return `Actualización de información desde el módulo ${modulo}.`;
    }

    return 'Acción generada automáticamente por el sistema.';
  }

  observacionesAuditoria(item: any): string {
    const observacion = String(item?.observaciones || item?.observacion || '').trim();

    if (observacion) {
      return this.corregirTextoAuditoria(observacion);
    }

    return 'Registro generado automáticamente para mantener trazabilidad y control de cambios.';
  }



  private corregirTextoAuditoria(texto: string): string {
    return String(texto || '')
      .replace(/Ã¡/g, 'á')
      .replace(/Ã©/g, 'é')
      .replace(/Ã­/g, 'í')
      .replace(/Ã³/g, 'ó')
      .replace(/Ãº/g, 'ú')
      .replace(/Ã±/g, 'ñ')
      .replace(/Ã/g, 'Á')
      .replace(/Ã‰/g, 'É')
      .replace(/Ã/g, 'Í')
      .replace(/Ã“/g, 'Ó')
      .replace(/Ãš/g, 'Ú')
      .replace(/Ã‘/g, 'Ñ')
      .replace(/Â¿/g, '¿')
      .replace(/Â¡/g, '¡')
      .replace(/â€“/g, '–')
      .replace(/â€”/g, '—')
      .replace(/â€œ/g, '“')
      .replace(/â€/g, '”')
      .replace(/â€™/g, '’')
      .replace(/Â/g, '');
  }

}
