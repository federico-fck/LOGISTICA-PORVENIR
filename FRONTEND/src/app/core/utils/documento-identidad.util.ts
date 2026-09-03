export interface OpcionExpedidoCi {
  codigo: string;
  departamento: string;
}

export interface DocumentoIdentidadUsuario {
  cedulaIdentidad?: string | null;
  cedula_identidad?: string | null;
  complementoCi?: string | null;
  complemento_ci?: string | null;
  expedidoCi?: string | null;
  expedido_ci?: string | null;
}

export interface DocumentoIdentidadSeparado {
  cedulaIdentidad: string;
  complementoCi: string;
  expedidoCi: string;
}

export const EXPEDIDOS_CI: OpcionExpedidoCi[] = [
  { codigo: 'LP', departamento: 'La Paz' },
  { codigo: 'CB', departamento: 'Cochabamba' },
  { codigo: 'SC', departamento: 'Santa Cruz' },
  { codigo: 'OR', departamento: 'Oruro' },
  { codigo: 'PT', departamento: 'Potosi' },
  { codigo: 'CH', departamento: 'Chuquisaca' },
  { codigo: 'TJ', departamento: 'Tarija' },
  { codigo: 'BN', departamento: 'Beni' },
  { codigo: 'PD', departamento: 'Pando' },
];

const CODIGOS_EXPEDIDO = new Set(EXPEDIDOS_CI.map((item) => item.codigo));

function texto(valor: unknown): string {
  return typeof valor === 'string' ? valor.trim() : '';
}

export function limpiarCedulaIdentidad(valor: unknown): string {
  return texto(valor).replace(/\D/g, '');
}

export function limpiarComplementoCi(valor: unknown): string {
  return texto(valor)
    .replace(/[^a-zA-Z0-9]/g, '')
    .toUpperCase()
    .slice(0, 10);
}

export function normalizarExpedidoCi(valor: unknown): string {
  const expedido = texto(valor).toUpperCase();
  return CODIGOS_EXPEDIDO.has(expedido) ? expedido : '';
}

export function obtenerDocumentoIdentidad(
  usuario?: DocumentoIdentidadUsuario | null,
): DocumentoIdentidadSeparado {
  const data = usuario as DocumentoIdentidadUsuario | null | undefined;
  const cedulaOriginal = texto(data?.cedulaIdentidad ?? data?.cedula_identidad);
  const complemento = limpiarComplementoCi(
    data?.complementoCi ?? data?.complemento_ci,
  );
  const expedido = normalizarExpedidoCi(data?.expedidoCi ?? data?.expedido_ci);

  const legado = cedulaOriginal.match(
    /^(\d+)(?:-([a-zA-Z0-9]{1,10}))?(?:\s+([a-zA-Z]{2}))?$/,
  );

  if (legado) {
    return {
      cedulaIdentidad: legado[1],
      complementoCi: complemento || limpiarComplementoCi(legado[2]),
      expedidoCi: expedido || normalizarExpedidoCi(legado[3]),
    };
  }

  return {
    cedulaIdentidad: limpiarCedulaIdentidad(cedulaOriginal),
    complementoCi: complemento,
    expedidoCi: expedido,
  };
}

export function formatearDocumentoIdentidad(
  usuario?: DocumentoIdentidadUsuario | null,
): string {
  const documento = obtenerDocumentoIdentidad(usuario);

  if (!documento.cedulaIdentidad) {
    return 'Sin documento';
  }

  const cedulaConComplemento = documento.complementoCi
    ? `${documento.cedulaIdentidad}-${documento.complementoCi}`
    : documento.cedulaIdentidad;

  return documento.expedidoCi
    ? `${cedulaConComplemento} ${documento.expedidoCi}`
    : cedulaConComplemento;
}
