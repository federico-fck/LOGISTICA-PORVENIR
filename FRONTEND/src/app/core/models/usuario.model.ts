export interface Rol {
  idRol: number;
  nombreRol: string;
  codigoRol?: string;
  descripcion?: string;
  estado?: string;
}

export interface Area {
  idArea: number;
  nombreArea: string;
  descripcion?: string;
  estado?: string;
}

export interface Usuario {
  idUsuario: number;
  id_usuario?: number;
  idArea?: number;
  id_area?: number;
  idRol?: number;
  id_rol?: number;
  nombreUsuario: string;
  nombreCompleto: string;
  correo?: string | null;
  cedulaIdentidad?: string;
  cedula_identidad?: string;
  complementoCi?: string;
  complemento_ci?: string;
  expedidoCi?: string;
  expedido_ci?: string;
  telefono?: string | null;
  cargo?: string | null;
  estado: string;
  ultimoInicioSesion?: string;
  ultimo_inicio_sesion?: string;
  fechaCreacion?: string;
  fecha_creacion?: string;
  fechaActualizacion?: string;
  fecha_actualizacion?: string;
  rol?: Rol | string | null;
  codigoRol?: string;
  rolNombre?: string;
  nombreArea?: string;
  area?: Area | string | null;
  permisos?: string[];
}
