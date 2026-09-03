export interface Almacen {
  idAlmacen: number;
  codigoAlmacen: string;
  nombreAlmacen: string;
  tipoAlmacen: string;
  ubicacion: string;
  idEncargado?: number;
  encargadoId?: number;
  idResponsablePrincipal?: number;
  responsablePrincipal?: {
    idUsuario?: number;
    nombreCompleto?: string;
    nombreUsuario?: string;
  } | null;
  encargado?: {
    idUsuario?: number;
    nombreCompleto?: string;
    nombreUsuario?: string;
  } | null;
  telefonoContacto?: string;
  horarioAtencion?: string;
  descripcion?: string;
  estado: string;
}
