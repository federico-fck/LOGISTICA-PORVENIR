export interface OrdenCompra {
  idOrdenCompra?: number;
  id_orden_compra?: number;
  numeroOrden?: string;
  numero_orden?: string;
  fechaOrden?: string;
  fecha_orden?: string;
  fechaEmision?: string;
  fecha_emision?: string;
  fechaEstimadaEntrega?: string;
  fecha_estimada_entrega?: string;
  fechaEntregaEstimada?: string;
  fecha_entrega_estimada?: string;
  estadoOrden?: string;
  estado_orden?: string;
  fechaCreacion?: string;
  fecha_creacion?: string;
  subtotal?: string | number;
  descuento?: string | number;
  total?: string | number;
  totalFinal?: string | number;
  total_final?: string | number;
  observaciones?: string;
  proveedor?: any;
  pedido?: any;
  detalles?: any[];
}

export interface RecepcionCompra {
  idRecepcionCompra?: number;
  id_recepcion_compra?: number;
  numeroRecepcion?: string;
  numero_recepcion?: string;
  fechaRecepcion?: string;
  fecha_recepcion?: string;
  estadoRecepcion?: string;
  estado_recepcion?: string;
  fechaRealRecepcion?: string;
  fecha_real_recepcion?: string;
  fechaCreacion?: string;
  fecha_creacion?: string;
  observaciones?: string;
  ordenCompra?: any;
  orden_compra?: any;
  usuarioResponsable?: any;
  usuario_responsable?: any;
  detalles?: any[];
}

export interface ComprobanteCompra {
  idComprobanteCompra?: number;
  id_comprobante_compra?: number;
  numeroComprobante?: string;
  numero_comprobante?: string;
  tipoComprobante?: string;
  tipo_comprobante?: string;
  fechaEmision?: string;
  fecha_emision?: string;
  fechaComprobante?: string;
  fecha_comprobante?: string;
  fechaPago?: string;
  fecha_pago?: string;
  fechaCreacion?: string;
  fecha_creacion?: string;
  fechaRegistro?: string;
  fecha_registro?: string;
  montoTotal?: string | number;
  monto_total?: string | number;
  montoSubtotal?: string | number;
  monto_subtotal?: string | number;
  montoDescuento?: string | number;
  monto_descuento?: string | number;
  estadoComprobante?: string;
  estado_comprobante?: string;
  observaciones?: string;
  proveedor?: any;
  ordenCompra?: any;
  orden_compra?: any;
}
