export interface PedidoDetalle {
  idPedidoDetalle?: number;
  id_pedido_detalle?: number;

  idInsumo?: number;
  id_insumo?: number;

  cantidadSolicitada?: string | number;
  cantidad_solicitada?: string | number;

  cantidadAprobada?: string | number;
  cantidad_aprobada?: string | number;

  observacion?: string;
  observaciones?: string;

  insumo?: {
    idInsumo?: number;
    id_insumo?: number;
    codigoInterno?: string;
    codigo_interno?: string;
    nombreInsumo?: string;
    nombre_insumo?: string;
    unidadMedida?: {
      nombreUnidad?: string;
      nombre_unidad?: string;
      abreviatura?: string;
    };
    unidad_medida?: {
      nombreUnidad?: string;
      nombre_unidad?: string;
      abreviatura?: string;
    };
  };
}

export interface Pedido {
  idPedido?: number;
  id_pedido?: number;

  numeroPedido?: string;
  numero_pedido?: string;

  fechaPedido?: string;
  fecha_pedido?: string;

  fechaRequerida?: string;
  fecha_requerida?: string;

  fechaCreacion?: string;
  fecha_creacion?: string;

  tipoPedido?: string;
  tipo_pedido?: string;

  prioridad?: string;

  estadoPedido?: string;
  estado_pedido?: string;
  estado?: string;

  estadoAprobacion?: string;
  estado_aprobacion?: string;

  estadoAtencion?: string;
  estado_atencion?: string;

  fechaRevision?: string;
  fecha_revision?: string;

  idUsuarioRevisa?: number;
  id_usuario_revisa?: number;
  idUsuarioRevisor?: number;
  id_usuario_revisor?: number;

  motivoSolicitud?: string;
  motivo_solicitud?: string;
  justificacion?: string;

  centroCosto?: string;
  centro_costo?: string;
  lugarUso?: string;
  lugar_uso?: string;
  turnoGuardia?: string;
  turno_guardia?: string;

  motivoObservacion?: string;
  motivo_observacion?: string;
  motivoRechazo?: string;
  motivo_rechazo?: string;

  observaciones?: string;
  observacion?: string;

  usuarioSolicitante?: string | PedidoUsuario;
  usuario_solicitante?: string | PedidoUsuario;

  areaSolicitante?: string | PedidoArea;
  area_solicitante?: string | PedidoArea;

  usuarioRevision?: string | PedidoUsuario;
  usuario_revision?: string | PedidoUsuario;
  usuarioRevisa?: number | string | PedidoUsuario;
  usuario_revisa?: number | string | PedidoUsuario;

  usuario?: {
    nombreUsuario?: string;
    nombre_usuario?: string;
    nombreCompleto?: string;
    nombre_completo?: string;
  };

  area?: {
    nombreArea?: string;
    nombre_area?: string;
  };

  detalles?: PedidoDetalle[];
  pedidoDetalles?: PedidoDetalle[];
  pedido_detalles?: PedidoDetalle[];
  message?: string;
}

export interface PedidoUsuario {
  nombreUsuario?: string;
  nombre_usuario?: string;
  nombreCompleto?: string;
  nombre_completo?: string;
  usuario?: string;
}

export interface PedidoArea {
  nombreArea?: string;
  nombre_area?: string;
}

export interface CrearPedidoDetalle {
  idInsumo: number;
  cantidadSolicitada: number;
  observacion?: string;
}

export interface CrearPedido {
  numeroPedido?: string;
  idUsuarioSolicitante?: number;
  idAreaSolicitante?: number;
  tipoPedido?: string;
  prioridad: string;
  fechaRequerida: string;
  justificacion: string;
  motivoSolicitud?: string;
  centroCosto?: string;
  lugarUso?: string;
  turnoGuardia?: string;
  observaciones?: string;
  detalles: CrearPedidoDetalle[];
}

export interface ActualizarPedido {
  prioridad?: string;
  fechaRequerida?: string;
  justificacion?: string;
  centroCosto?: string;
  lugarUso?: string;
  turnoGuardia?: string;
  observaciones?: string;
}

export interface AprobarPedido {
  usuarioRevisa: number;
  observaciones?: string;
  detalles: {
    idPedidoDetalle: number;
    cantidadAprobada: number;
  }[];
}

export interface RechazarPedido {
  usuarioRevisa: number;
  motivoRechazo: string;
}

export interface ObservarPedido {
  usuarioRevisa: number;
  motivoObservacion: string;
}
