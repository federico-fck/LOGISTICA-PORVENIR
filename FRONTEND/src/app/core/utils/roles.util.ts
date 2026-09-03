export const ROLES_SISTEMA = {
  ADMINISTRADOR: 'ADMINISTRADOR',
  ENCARGADO_ALMACEN: 'ENCARGADO_ALMACEN',
  SUPERVISOR_MINA: 'SUPERVISOR_MINA',
  JEFE_AREA: 'JEFE_AREA',
  ENCARGADO_COMPRAS: 'ENCARGADO_COMPRAS',
  AUDITOR: 'AUDITOR',
  USUARIO_SOLICITANTE: 'USUARIO_SOLICITANTE',
} as const;

export type RolSistema = (typeof ROLES_SISTEMA)[keyof typeof ROLES_SISTEMA];

export const ROLES_OFICIALES: ReadonlyArray<{
  codigo: RolSistema;
  nombre: string;
  descripcion: string;
}> = [
  {
    codigo: ROLES_SISTEMA.ADMINISTRADOR,
    nombre: 'Administrador del sistema',
    descripcion: 'Acceso total al sistema, usuarios, seguridad, reportes y auditoria.',
  },
  {
    codigo: ROLES_SISTEMA.ENCARGADO_ALMACEN,
    nombre: 'Encargado de almacén',
    descripcion: 'Responsable operativo de almacenes, inventario, movimientos y despachos.',
  },
  {
    codigo: ROLES_SISTEMA.SUPERVISOR_MINA,
    nombre: 'Supervisor de mina',
    descripcion: 'Solicita insumos para operación minera y realiza seguimiento a pedidos.',
  },
  {
    codigo: ROLES_SISTEMA.JEFE_AREA,
    nombre: 'Jefe de área',
    descripcion: 'Responsable de revisar, aprobar, observar o rechazar pedidos del área.',
  },
  {
    codigo: ROLES_SISTEMA.ENCARGADO_COMPRAS,
    nombre: 'Encargado de compras',
    descripcion: 'Responsable de proveedores, compras, recepciones y comprobantes.',
  },
  {
    codigo: ROLES_SISTEMA.AUDITOR,
    nombre: 'Auditor',
    descripcion: 'Usuario con acceso de consulta a auditoría, trazabilidad y reportes.',
  },
  {
    codigo: ROLES_SISTEMA.USUARIO_SOLICITANTE,
    nombre: 'Usuario solicitante',
    descripcion: 'Usuario que crea pedidos de insumos y realiza seguimiento a sus solicitudes.',
  },
];

const ALIAS_ROLES: Record<string, RolSistema> = {
  ADMINISTRADOR: ROLES_SISTEMA.ADMINISTRADOR,
  ADMINISTRADOR_DEL_SISTEMA: ROLES_SISTEMA.ADMINISTRADOR,
  ADMIN: ROLES_SISTEMA.ADMINISTRADOR,
  JEFE_DE_ALMACEN: ROLES_SISTEMA.ENCARGADO_ALMACEN,
  ENCARGADO_DE_ALMACEN: ROLES_SISTEMA.ENCARGADO_ALMACEN,
  ENCARGADO_ALMACEN: ROLES_SISTEMA.ENCARGADO_ALMACEN,
  ALMACEN: ROLES_SISTEMA.ENCARGADO_ALMACEN,
  SUPERVISOR_DE_MINA: ROLES_SISTEMA.SUPERVISOR_MINA,
  SUPERVISOR_MINA: ROLES_SISTEMA.SUPERVISOR_MINA,
  JEFE_DE_AREA: ROLES_SISTEMA.JEFE_AREA,
  JEFE_AREA: ROLES_SISTEMA.JEFE_AREA,
  JEFE_DE_AREA_SOLICITANTE: ROLES_SISTEMA.JEFE_AREA,
  ENCARGADO_DE_COMPRAS: ROLES_SISTEMA.ENCARGADO_COMPRAS,
  ENCARGADO_COMPRAS: ROLES_SISTEMA.ENCARGADO_COMPRAS,
  RESPONSABLE_DE_COMPRAS: ROLES_SISTEMA.ENCARGADO_COMPRAS,
  COMPRAS: ROLES_SISTEMA.ENCARGADO_COMPRAS,
  USUARIO_SOLICITANTE: ROLES_SISTEMA.USUARIO_SOLICITANTE,
  SOLICITANTE: ROLES_SISTEMA.USUARIO_SOLICITANTE,
  AUDITOR: ROLES_SISTEMA.AUDITOR,
};

export const NOMBRES_ROL: Record<RolSistema, string> =
  ROLES_OFICIALES.reduce(
    (mapa, rol) => ({ ...mapa, [rol.codigo]: rol.nombre }),
    {} as Record<RolSistema, string>,
  );

export function normalizarRol(rol?: string | null): string {
  if (!rol) {
    return '';
  }

  const clave = rol
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');

  return ALIAS_ROLES[clave] || clave;
}

export function nombreRolDesdeCodigo(codigo?: string | null): string {
  const rolNormalizado = normalizarRol(codigo) as RolSistema;
  return NOMBRES_ROL[rolNormalizado] || codigo || 'Sin rol';
}

export function esRolOficialActivo(nombreOCodigo?: string | null): boolean {
  const rolNormalizado = normalizarRol(nombreOCodigo);
  return ROLES_OFICIALES.some((rol) => rol.codigo === rolNormalizado);
}
