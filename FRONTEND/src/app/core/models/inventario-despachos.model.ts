export interface InventarioItem {
  idInventario?: number;
  id_inventario?: number;

  idInsumo?: number;
  id_insumo?: number;

  idAlmacen?: number;
  id_almacen?: number;

  codigoInterno?: string;
  codigo_interno?: string;

  nombreInsumo?: string;
  nombre_insumo?: string;

  nombreAlmacen?: string;
  nombre_almacen?: string;

  tipoAlmacen?: string;
  tipo_almacen?: string;

  stockFisico?: string | number;
  stock_fisico?: string | number;

  stockReservado?: string | number;
  stock_reservado?: string | number;

  stockDisponible?: string | number;
  stock_disponible?: string | number;

  stockMinimo?: string | number;
  stock_minimo?: string | number;
  diferencia?: string | number;
  fechaUltimaActualizacion?: string;
  fecha_ultima_actualizacion?: string;

  estadoStock?: string;
  estado_stock?: string;

  valorInventario?: string | number;
  valor_inventario?: string | number;

  estado?: string;

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
    categoria?: {
      nombreCategoria?: string;
      nombre_categoria?: string;
    };
  };

  almacen?: {
    idAlmacen?: number;
    id_almacen?: number;
    codigoAlmacen?: string;
    codigo_almacen?: string;
    nombreAlmacen?: string;
    nombre_almacen?: string;
    tipoAlmacen?: string;
    tipo_almacen?: string;
  };

}

export interface MovimientoInventario {
  idMovimiento?: number;
  id_movimiento?: number;

  idInsumo?: number;
  id_insumo?: number;

  idAlmacen?: number;
  id_almacen?: number;

  codigoInterno?: string;
  codigo_interno?: string;

  nombreInsumo?: string;
  nombre_insumo?: string;

  nombreAlmacen?: string;
  nombre_almacen?: string;

  tipoMovimiento?: string;
  tipo_movimiento?: string;

  cantidad?: string | number;
  fechaMovimiento?: string;
  fecha_movimiento?: string;

  motivoMovimiento?: string;
  motivo_movimiento?: string;

  observaciones?: string;
  referencia?: string;
  codigoReferencia?: string;
  codigo_referencia?: string;
  usuarioResponsable?:
    | string
    | {
        idUsuario?: number;
        id_usuario?: number;
        nombreCompleto?: string;
        nombre_completo?: string;
        nombreUsuario?: string;
        nombre_usuario?: string;
      };
  usuario_responsable?: string;

  insumo?: {
    idInsumo?: number;
    id_insumo?: number;
    codigoInterno?: string;
    codigo_interno?: string;
    nombreInsumo?: string;
    nombre_insumo?: string;
  };

  almacen?: {
    idAlmacen?: number;
    id_almacen?: number;
    codigoAlmacen?: string;
    codigo_almacen?: string;
    nombreAlmacen?: string;
    nombre_almacen?: string;
  };

  almacenOrigen?: {
    idAlmacen?: number;
    codigoAlmacen?: string;
    nombreAlmacen?: string;
  };
  almacenDestino?: {
    idAlmacen?: number;
    codigoAlmacen?: string;
    nombreAlmacen?: string;
  };
}

export interface DespachoDetalle {
  idDespachoDetalle?: number;
  id_despacho_detalle?: number;

  idInsumo?: number;
  id_insumo?: number;

  codigoInterno?: string;
  codigo_interno?: string;

  nombreInsumo?: string;
  nombre_insumo?: string;

  cantidadDespachada?: string | number;
  cantidad_despachada?: string | number;

  observaciones?: string;

  cantidadSolicitada?: string | number;
  cantidad_solicitada?: string | number;
  cantidadAprobada?: string | number;
  cantidad_aprobada?: string | number;
  cantidadEntregada?: string | number;
  cantidad_entregada?: string | number;
  cantidadPendiente?: string | number;
  cantidad_pendiente?: string | number;
  observacion?: string;

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
  };
}

export interface Despacho {
  idDespacho?: number;
  id_despacho?: number;

  numeroDespacho?: string;
  numero_despacho?: string;

  fechaDespacho?: string;
  fecha_despacho?: string;

  idAlmacenOrigen?: number;
  id_almacen_origen?: number;

  almacenOrigen?: string;
  almacen_origen?: string;

  areaDestino?: string;
  area_destino?: string;

  usuarioSolicitante?: string;
  usuario_solicitante?: string;

  usuarioResponsable?: string;
  usuario_responsable?: string;

  estadoDespacho?: string;
  estado_despacho?: string;

  observaciones?: string;

  detalles?: DespachoDetalle[];

  codigoDespacho?: string;
  pedido?: {
    idPedido?: number;
    numeroPedido?: string;
    codigoPedido?: string;
    tipoPedido?: string;
    prioridad?: string;
    estado?: string;
    estadoPedido?: string;
    solicitante?: {
      idUsuario?: number;
      nombreCompleto?: string;
      nombreUsuario?: string;
    } | null;
    area?: {
      idArea?: number;
      nombreArea?: string;
    } | null;
    areaSolicitante?: {
      idArea?: number;
      nombreArea?: string;
    } | null;
  } | null;

  almacenSalida?: {
    idAlmacen?: number;
    codigoAlmacen?: string;
    nombreAlmacen?: string;
  };

  responsableAlmacen?: {
    idUsuario?: number;
    nombreCompleto?: string;
    nombreUsuario?: string;
  };
}

export interface CrearMovimientoInventario {
  idInsumo: number;
  idAlmacen?: number;
  idAlmacenOrigen?: number;
  idAlmacenDestino?: number;
  tipoMovimiento: string;
  cantidad: number;
  motivo?: string;
  motivoMovimiento?: string;
  observaciones?: string;
  usuarioResponsable?: number;
}

export interface CrearTransferenciaInventario {
  idInsumo: number;
  idAlmacenOrigen: number;
  idAlmacenDestino: number;
  cantidad: number;
  motivo: string;
  observaciones?: string;
  usuarioResponsable?: number;
}

export interface CrearDevolucionInventario {
  idInsumo: number;
  idAlmacenDestino: number;
  cantidad: number;
  motivo: string;
  idDespacho?: number;
  observaciones?: string;
  usuarioResponsable?: number;
}

export interface CrearDespachoInventario {
  idPedido: number;
  idAlmacenSalida: number;
  idResponsableAlmacen?: number;
  personaRecibe?: string;
  tipoDespacho?: string;
  observaciones?: string;
  usuarioRegistra?: number;
  detalles: {
    idPedidoDetalle?: number;
    idInsumo: number;
    cantidadSolicitada: number;
    cantidadAprobada: number;
    cantidadEntregada: number;
    estadoConformidad: string;
    observacion?: string;
  }[];
}

export interface PedidoDespachoDetalle {
  idPedidoDetalle?: number;
  idInsumo?: number;
  cantidadSolicitada?: string | number;
  cantidadAprobada?: string | number;
  cantidadDespachada?: string | number;
  cantidadPendiente?: string | number;
  cantidadReservada?: string | number;
  reservasStock?: {
    idAlmacen: number;
    cantidadReservada: number;
  }[];
  observacion?: string;
  insumo?: {
    idInsumo?: number;
    codigoInterno?: string;
    nombreInsumo?: string;
    unidadMedida?: {
      nombreUnidad?: string;
      abreviatura?: string;
    };
  };
}

export interface PedidoAprobadoDespacho {
  idPedido?: number;
  numeroPedido?: string;
  codigoPedido?: string;
  tipoPedido?: string;
  prioridad?: string;
  estado?: string;
  estadoPedido?: string;
  solicitante?: {
    idUsuario?: number;
    nombreCompleto?: string;
    nombreUsuario?: string;
  } | null;
  area?: {
    idArea?: number;
    nombreArea?: string;
  } | null;
  detalles: PedidoDespachoDetalle[];
}
