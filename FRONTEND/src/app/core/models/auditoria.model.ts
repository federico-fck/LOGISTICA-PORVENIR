import { Usuario } from './usuario.model';

export interface Auditoria {
  idAuditoria: number;
  idUsuario?: number;
  accionRealizada: string;
  tipoAccion: string;
  moduloAfectado: string;
  tablaAfectada?: string;
  idRegistroAfectado?: number;

  registroAnterior?: Record<string, unknown>;
  registroNuevo?: Record<string, unknown>;

  datosAnteriores?: Record<string, unknown>;
  datosNuevos?: Record<string, unknown>;

  fechaHora: string;
  direccionIp?: string;
  navegadorDispositivo?: string;
  motivoCambio?: string;
  observaciones?: string;

  usuario?: Usuario | null;
}

export interface AuditoriaResumen {
  totalRegistros: number;
  accionesPorTipo: {
    tipoAccion: string;
    total: string | number;
  }[];
  accionesPorModulo: {
    moduloAfectado: string;
    total: string | number;
  }[];
  ultimasAcciones: Auditoria[];
}

export interface AuditoriaFiltros {
  fechaInicio?: string;
  fechaFin?: string;
  idUsuario?: number | string;
  tipoAccion?: string;
  moduloAfectado?: string;
  tablaAfectada?: string;
}
