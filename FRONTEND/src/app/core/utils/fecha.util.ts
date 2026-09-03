export const ZONA_HORARIA_BOLIVIA = 'America/La_Paz';

const LOCALE_BOLIVIA = 'es-BO';
const OFFSET_BOLIVIA = '-04:00';

type FechaEntrada = string | Date | null | undefined;

function convertirAFecha(fecha: FechaEntrada): Date | null {
  if (!fecha) {
    return null;
  }

  if (fecha instanceof Date) {
    return Number.isNaN(fecha.getTime()) ? null : new Date(fecha.getTime());
  }

  const valor = fecha.trim();

  if (!valor) {
    return null;
  }

  if (/^\d{4}-\d{2}-\d{2}$/.test(valor)) {
    const fechaBolivia = new Date(`${valor}T00:00:00${OFFSET_BOLIVIA}`);
    return Number.isNaN(fechaBolivia.getTime()) ? null : fechaBolivia;
  }

  if (/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,3})?)?$/.test(valor)) {
    const fechaBolivia = new Date(`${valor}${OFFSET_BOLIVIA}`);
    return Number.isNaN(fechaBolivia.getTime()) ? null : fechaBolivia;
  }

  const fechaParseada = new Date(valor);
  return Number.isNaN(fechaParseada.getTime()) ? null : fechaParseada;
}

export function formatearFechaHoraBolivia(
  fecha: FechaEntrada,
  valorVacio = 'Sin fecha',
): string {
  const fechaValida = convertirAFecha(fecha);

  if (!fechaValida) {
    return valorVacio;
  }

  return new Intl.DateTimeFormat(LOCALE_BOLIVIA, {
    timeZone: ZONA_HORARIA_BOLIVIA,
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  }).format(fechaValida);
}

export function formatearFechaBolivia(
  fecha: FechaEntrada,
  valorVacio = 'Sin fecha',
): string {
  const fechaValida = convertirAFecha(fecha);

  if (!fechaValida) {
    return valorVacio;
  }

  return new Intl.DateTimeFormat(LOCALE_BOLIVIA, {
    timeZone: ZONA_HORARIA_BOLIVIA,
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(fechaValida);
}

export function convertirDatetimeLocalParaBackend(valor: string): string {
  const limpio = valor?.trim();

  if (!limpio) {
    return '';
  }

  const fecha = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,3})?)?$/.test(
    limpio,
  )
    ? new Date(`${limpio}${OFFSET_BOLIVIA}`)
    : new Date(limpio);

  return Number.isNaN(fecha.getTime()) ? '' : fecha.toISOString();
}

export function convertirFechaBackendADatetimeLocal(
  fecha: FechaEntrada,
): string {
  const fechaValida = convertirAFecha(fecha);

  if (!fechaValida) {
    return '';
  }

  const partes = new Intl.DateTimeFormat('en-CA', {
    timeZone: ZONA_HORARIA_BOLIVIA,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(fechaValida);
  const parte = (tipo: Intl.DateTimeFormatPartTypes) =>
    partes.find((item) => item.type === tipo)?.value || '';

  return `${parte('year')}-${parte('month')}-${parte('day')}T${parte('hour')}:${parte('minute')}`;
}
