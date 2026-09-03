import {
  AbstractControl,
  FormGroup,
  ValidationErrors,
  ValidatorFn,
} from '@angular/forms';

export const CARGOS_USUARIO = [
  'Administrador',
  'Encargado de almacen',
  'Supervisor de mina',
  'Responsable de compras',
  'Auditor',
  'Jefe de area',
  'Operador logistico',
  'Auxiliar administrativo',
  'Otro',
] as const;

export const TIPOS_ALMACEN_RECOMENDADOS = [
  { valor: 'PRINCIPAL', etiqueta: 'Almacen principal' },
  { valor: 'SUPERFICIE', etiqueta: 'Almacen de superficie' },
  { valor: 'SUBTERRANEO', etiqueta: 'Almacen subterraneo' },
  { valor: 'POLVORIN', etiqueta: 'Polvorin' },
  { valor: 'SEGURIDAD_INDUSTRIAL', etiqueta: 'Almacen de seguridad industrial' },
  { valor: 'HERRAMIENTAS_REPUESTOS', etiqueta: 'Almacen de herramientas y repuestos' },
  { valor: 'EPP', etiqueta: 'Almacen de EPP' },
  { valor: 'TEMPORAL', etiqueta: 'Almacen temporal' },
  { valor: 'COMBUSTIBLE', etiqueta: 'Almacen de combustible' },
] as const;

export const HORARIOS_ALMACEN = [
  'Lunes a viernes 08:00 - 18:00',
  'Lunes a sabado 08:00 - 18:00',
  'Lunes a sabado 07:00 - 19:00',
  'Todos los dias 08:00 - 20:00',
  'Atencion 24 horas',
  'Personalizado',
] as const;

export const TIPOS_INSUMO_PROVEEDOR = [
  'EPP',
  'Herramientas',
  'Repuestos',
  'Lubricantes',
  'Combustibles',
  'Material de construccion',
  'Servicios logisticos',
  'Servicios tecnicos',
  'Otros',
] as const;

export const MOTIVOS_AJUSTE_INVENTARIO = [
  'Error de conteo en inventario fisico',
  'Insumo encontrado / sobrante',
  'Insumo danado / roto',
  'Vencimiento de producto',
  'Robo o extravio',
  'Correccion por auditoria interna',
  'Diferencia por recepcion',
  'Regularizacion de stock',
  'Otro',
] as const;

export const MOTIVOS_TRANSFERENCIA_INVENTARIO = [
  'Reabastecimiento de stock',
  'Solicitud de orden de trabajo',
  'Devolucion al almacen principal',
  'Prestamo interno entre areas',
  'Redistribucion por emergencia operativa',
  'Reubicacion por seguridad',
  'Balanceo de stock entre almacenes',
  'Otro',
] as const;

export const MOTIVOS_DEVOLUCION_INVENTARIO = [
  'Excedente de obra / sobrante',
  'Insumo defectuoso / danado',
  'Talla / medida incorrecta',
  'Cancelacion de orden de trabajo',
  'Material no utilizado en turno',
  'Error en despacho',
  'Cambio de prioridad operativa',
  'Otro',
] as const;

export const MOTIVOS_PEDIDO = [
  'Requerimiento para frente de trabajo',
  'Stock minimo de seguridad',
  'Renovacion por desgaste / EPP',
  'Emergencia / contingencia',
  'Reposicion por consumo operativo',
  'Mantenimiento programado',
  'Reparacion de equipo o instalacion',
  'Seguridad industrial',
  'Otro',
] as const;

export const TIPOS_COMPROBANTE = [
  { valor: 'FACTURA', etiqueta: 'Factura' },
  { valor: 'RECIBO', etiqueta: 'Recibo' },
  { valor: 'NOTA_VENTA', etiqueta: 'Nota de Venta' },
  { valor: 'COMPROBANTE_INTERNO', etiqueta: 'Comprobante Interno' },
] as const;

const USUARIO_PATTERN = /^[a-z0-9._]+$/;
const CODIGO_PATTERN = /^[A-Za-z0-9-]+$/;
const NOMBRE_PERSONA_PATTERN = /^[A-Za-zÀ-ÿ\s]+$/;
const PERSONA_CONTACTO_PATTERN = /^[A-Za-z\u00C0-\u00FF\s()]+$/;
const CORREO_PATTERN = /^[a-z0-9._]+@[a-z0-9._]+\.[a-z0-9._]+$/;
const DOCUMENTO_RESPALDO_PATTERN = /^[A-Za-z0-9-]*$/;
const HORARIO_ATENCION_PATTERN = /^[A-Za-z0-9\u00C0-\u00FF\s:-]+$/;

function valor(control: AbstractControl): string {
  return String(control.value ?? '').trim();
}

export function usuarioSistemaValidator(): ValidatorFn {
  return (control) => {
    const texto = valor(control);
    if (!texto) return null;
    return USUARIO_PATTERN.test(texto) ? null : { usuarioSistema: true };
  };
}

export function nombrePersonaValidator(): ValidatorFn {
  return (control) => {
    const texto = valor(control);
    if (!texto) return null;
    return NOMBRE_PERSONA_PATTERN.test(texto) ? null : { nombrePersona: true };
  };
}

export function personaContactoValidator(): ValidatorFn {
  return (control) => {
    const texto = valor(control);
    if (!texto) return null;
    return PERSONA_CONTACTO_PATTERN.test(texto)
      ? null
      : { personaContacto: true };
  };
}

export function correoProfesionalValidator(): ValidatorFn {
  return (control) => {
    const texto = valor(control);
    if (!texto) return null;
    return CORREO_PATTERN.test(texto) ? null : { correoProfesional: true };
  };
}

export function codigoAlfanumericoGuionValidator(): ValidatorFn {
  return (control) => {
    const texto = valor(control);
    if (!texto) return null;
    return CODIGO_PATTERN.test(texto) ? null : { codigoAlfanumericoGuion: true };
  };
}

export function soloNumerosMaxValidator(maxLength: number): ValidatorFn {
  return (control) => {
    const texto = valor(control);
    if (!texto) return null;
    return new RegExp(`^\\d{1,${maxLength}}$`).test(texto)
      ? null
      : { soloNumerosMax: { maxLength } };
  };
}

export function telefonoBoliviaValidator(): ValidatorFn {
  return (control) => {
    const texto = valor(control);
    if (!texto) return null;
    return /^[67]\d{7}$/.test(texto) ? null : { telefonoBolivia: true };
  };
}

export function telefonoNumericoFlexibleValidator(maxLength = 15): ValidatorFn {
  return (control) => {
    const texto = valor(control);
    if (!texto) return null;
    return new RegExp(`^\\d{1,${maxLength}}$`).test(texto)
      ? null
      : { telefonoNumericoFlexible: true };
  };
}

export function complementoCiValidator(): ValidatorFn {
  return (control) => {
    const texto = valor(control);
    if (!texto) return null;
    return /^[A-Z0-9]{1,2}$/.test(texto)
      ? null
      : { complementoCi: true };
  };
}

export function maxDigitsValidator(maxDigits: number): ValidatorFn {
  return (control) => {
    const texto = valor(control);
    if (!texto) return null;
    const digits = texto.match(/\d/g)?.length ?? 0;
    return digits <= maxDigits ? null : { maxDigits: { maxDigits } };
  };
}

export function documentoRespaldoValidator(): ValidatorFn {
  return (control) => {
    const texto = valor(control);
    if (!texto) return null;
    return DOCUMENTO_RESPALDO_PATTERN.test(texto)
      ? null
      : { documentoRespaldo: true };
  };
}

export function horarioAtencionManualValidator(): ValidatorFn {
  return (control) => {
    const texto = valor(control);
    if (!texto) return null;
    return HORARIO_ATENCION_PATTERN.test(texto)
      ? null
      : { horarioAtencionManual: true };
  };
}

export function almacenesDiferentesValidator(
  origen: string,
  destino: string,
): ValidatorFn {
  return (control) => {
    const grupo = control as FormGroup;
    const idOrigen = String(grupo.controls[origen]?.value ?? '');
    const idDestino = String(grupo.controls[destino]?.value ?? '');
    return idOrigen && idDestino && idOrigen === idDestino
      ? { almacenesIguales: true }
      : null;
  };
}

export function normalizarMinusculas(valorTexto: string): string {
  return String(valorTexto || '').trim().toLowerCase();
}

export function normalizarMayusculas(valorTexto: string): string {
  return String(valorTexto || '').trim().toUpperCase();
}

export function normalizarSoloDigitos(valorTexto: string, maxLength?: number): string {
  const limpio = String(valorTexto || '').replace(/\D/g, '');
  return maxLength ? limpio.slice(0, maxLength) : limpio;
}

export function validarArchivoRecepcion(fileName: string): boolean {
  return /\.(pdf|jpg|jpeg|png)$/i.test(fileName);
}

export function totalConDescuento(
  subtotal: number,
  descuento: number,
): number {
  return redondearMoneda(
    Math.max((Number(subtotal) || 0) - (Number(descuento) || 0), 0),
  );
}

export function formatearNumeroPedidoAnual(secuencia: number, anio: number): string {
  return `PED-${String(secuencia).padStart(4, '0')}/${anio}`;
}

function redondearMoneda(value: number): number {
  return Math.round((Number(value) + Number.EPSILON) * 100) / 100;
}

export function passwordUsuarioErrors(
  modo: 'nuevo' | 'editar',
  cambiarPassword: boolean,
  password: string,
  confirmarPassword: string,
): ValidationErrors | null {
  const pass = String(password || '').trim();
  const confirmacion = String(confirmarPassword || '').trim();

  if (modo === 'nuevo' && !pass) {
    return { passwordRequerido: true };
  }

  if (modo === 'editar' && !cambiarPassword) {
    return null;
  }

  if (cambiarPassword && !pass) {
    return { passwordRequerido: true };
  }

  if (pass && pass.length < 6) {
    return { passwordMinLength: true };
  }

  if (modo === 'nuevo' && confirmacion && pass !== confirmacion) {
    return { passwordConfirmacion: true };
  }

  if (modo === 'editar' && cambiarPassword && pass !== confirmacion) {
    return { passwordConfirmacion: true };
  }

  return null;
}
