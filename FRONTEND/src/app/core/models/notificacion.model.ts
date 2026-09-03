export interface Notificacion {
  idNotificacion?: number;
  id_notificacion?: number;

  titulo?: string;
  mensaje?: string;
  tipoNotificacion?: string;
  tipo_notificacion?: string;

  prioridad?: string;
  leida?: boolean;
  estado?: string;
  estadoNotificacion?: string;
  estado_notificacion?: string;

  fechaCreacion?: string;
  fecha_creacion?: string;

  fechaLectura?: string;
  fecha_lectura?: string;

  urlDestino?: string;
  url_destino?: string;

  modulo?: string;
  moduloRelacionado?: string;
  modulo_relacionado?: string;

  usuario?: {
    idUsuario?: number;
    id_usuario?: number;
    nombreUsuario?: string;
    nombre_usuario?: string;
    nombreCompleto?: string;
    nombre_completo?: string;
  };
}
