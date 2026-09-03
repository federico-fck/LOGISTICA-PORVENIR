export interface Proveedor {
  idProveedor: number;
  codigoProveedor: string;
  razonSocial: string;
  nombreComercial?: string;
  nit: string;
  rubro: string;
  tipoInsumosProvee?: string;
  personaContacto?: string;
  telefono?: string;
  celularWhatsapp?: string;
  correo?: string;
  ciudad?: string;
  estado: string;
}
