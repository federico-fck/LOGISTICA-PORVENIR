import {
  AbstractControl,
  FormArray,
  FormGroup,
  ValidationErrors,
} from '@angular/forms';

export type FormFieldLabels = Record<string, string>;

const formulariosConValidacionSolicitada = new WeakSet<AbstractControl>();

export function marcarFormularioInvalido(
  form: AbstractControl,
  etiquetas: FormFieldLabels = {},
  titulo = 'Revise los campos del formulario',
): string {
  solicitarValidacionFormulario(form);
  form.markAllAsTouched();
  return '';
}

export function solicitarValidacionFormulario(form: AbstractControl): void {
  formulariosConValidacionSolicitada.add(raizControl(form));
}

export function validacionFormularioSolicitada(control: AbstractControl): boolean {
  const raiz = raizControl(control);

  if (raiz.pristine && raiz.untouched) {
    formulariosConValidacionSolicitada.delete(raiz);
    return false;
  }

  return formulariosConValidacionSolicitada.has(raiz);
}

export function mensajeErrorControl(
  errores: ValidationErrors | null | undefined,
): string {
  if (!errores) {
    return '';
  }

  const primerError = Object.entries(errores)[0];

  if (!primerError) {
    return '';
  }

  const [tipo, detalle] = primerError;

  switch (tipo) {
    case 'required':
    case 'passwordRequerido':
      return 'Este campo es obligatorio.';
    case 'minlength':
      return `Debe tener al menos ${detalle?.requiredLength} caracteres.`;
    case 'passwordMinLength':
      return 'Debe tener al menos 6 caracteres.';
    case 'maxlength':
      return `Debe tener maximo ${detalle?.requiredLength} caracteres.`;
    case 'min':
      return `Debe ser mayor o igual a ${detalle?.min}.`;
    case 'max':
      return `Debe ser menor o igual a ${detalle?.max}.`;
    case 'email':
    case 'correoProfesional':
      return 'Ingrese un correo valido.';
    case 'codigoAlfanumericoGuion':
    case 'documentoRespaldo':
      return 'Solo permite letras, numeros y guion.';
    case 'telefonoBolivia':
      return 'Debe tener 8 digitos y empezar con 6 o 7.';
    case 'telefonoNumericoFlexible':
      return 'Solo permite numeros.';
    case 'soloNumerosMax':
      return `Use solo numeros y maximo ${detalle?.maxLength} digitos.`;
    case 'nombrePersona':
      return 'Use solo letras y espacios.';
    case 'personaContacto':
      return 'Use solo letras, espacios y parentesis.';
    case 'usuarioSistema':
      return 'Use minusculas, numeros, punto o guion bajo.';
    case 'complementoCi':
      return 'Use 1 o 2 caracteres validos.';
    case 'maxDigits':
      return `No debe tener mas de ${detalle?.maxDigits} numeros.`;
    case 'horarioAtencionManual':
      return 'Use letras, numeros, espacios, dos puntos o guion.';
    case 'almacenesIguales':
      return 'Debe ser diferente al almacen origen.';
    case 'passwordConfirmacion':
      return 'Debe coincidir con la contrasena.';
    case 'descuentoMayorSubtotal':
      return 'No puede ser mayor al subtotal.';
    case 'seleccionInvalida':
      return 'Seleccione una opcion valida.';
    default:
      return 'Revise este dato.';
  }
}

export function mensajeFormularioInvalido(
  form: AbstractControl,
  etiquetas: FormFieldLabels = {},
  titulo = 'Revise los campos del formulario',
): string {
  const errores = erroresFormulario(form, etiquetas);

  if (!errores.length) {
    return `${titulo}.`;
  }

  return `${titulo}: ${unicos(errores).join(' | ')}`;
}

export function erroresFormulario(
  control: AbstractControl,
  etiquetas: FormFieldLabels = {},
  ruta = '',
): string[] {
  const errores: string[] = [];

  if (control instanceof FormGroup) {
    Object.entries(control.controls).forEach(([campo, hijo]) => {
      const rutaHijo = ruta ? `${ruta}.${campo}` : campo;
      errores.push(...erroresFormulario(hijo, etiquetas, rutaHijo));
    });

    if (control.errors) {
      errores.push(...mensajesDeErrores(etiquetaCampo(ruta, etiquetas), control.errors));
    }

    return errores;
  }

  if (control instanceof FormArray) {
    control.controls.forEach((hijo, indice) => {
      const rutaHijo = ruta ? `${ruta}.${indice + 1}` : String(indice + 1);
      errores.push(...erroresFormulario(hijo, etiquetas, rutaHijo));
    });

    if (control.errors) {
      errores.push(...mensajesDeErrores(etiquetaCampo(ruta, etiquetas), control.errors));
    }

    return errores;
  }

  if (!control.errors) {
    return errores;
  }

  return mensajesDeErrores(etiquetaCampo(ruta, etiquetas), control.errors);
}

export function mensajeErrorBackend(
  error: unknown,
  etiquetas: FormFieldLabels = {},
  fallback = 'No se pudo completar la operacion. Revise los datos enviados.',
): string {
  const mensajes = extraerMensajesBackend(error);

  if (!mensajes.length) {
    return fallback;
  }

  const normalizados = unicos(
    mensajes
      .filter((mensaje) => !esMensajeTecnico(mensaje))
      .map((mensaje) => normalizarMensajeBackend(mensaje, etiquetas))
      .filter((mensaje) => mensaje.trim().length > 0),
  );

  return normalizados.length
    ? `Revise los datos enviados: ${normalizados.join(' | ')}`
    : fallback;
}

function mensajesDeErrores(
  etiqueta: string,
  errores: ValidationErrors,
): string[] {
  return Object.entries(errores).map(([tipo, detalle]) => {
    switch (tipo) {
      case 'required':
        return `${etiqueta}: es obligatorio.`;
      case 'minlength':
        return `${etiqueta}: debe tener al menos ${detalle?.requiredLength} caracteres.`;
      case 'maxlength':
        return `${etiqueta}: debe tener maximo ${detalle?.requiredLength} caracteres.`;
      case 'min':
        return `${etiqueta}: debe ser mayor o igual a ${detalle?.min}.`;
      case 'max':
        return `${etiqueta}: debe ser menor o igual a ${detalle?.max}.`;
      case 'email':
      case 'correoProfesional':
        return `${etiqueta}: ingrese un correo valido.`;
      case 'codigoAlfanumericoGuion':
      case 'documentoRespaldo':
        return `${etiqueta}: solo permite letras, numeros y guion.`;
      case 'telefonoBolivia':
        return `${etiqueta}: debe tener 8 digitos y empezar con 6 o 7.`;
      case 'telefonoNumericoFlexible':
        return `${etiqueta}: solo permite numeros.`;
      case 'soloNumerosMax':
        return `${etiqueta}: solo permite numeros y maximo ${detalle?.maxLength} digitos.`;
      case 'nombrePersona':
        return `${etiqueta}: solo permite letras y espacios.`;
      case 'personaContacto':
        return `${etiqueta}: solo permite letras, espacios y parentesis.`;
      case 'usuarioSistema':
        return `${etiqueta}: use minusculas, numeros, punto o guion bajo.`;
      case 'complementoCi':
        return `${etiqueta}: use 1 o 2 caracteres validos.`;
      case 'maxDigits':
        return `${etiqueta}: no debe tener mas de ${detalle?.maxDigits} numeros.`;
      case 'horarioAtencionManual':
        return `${etiqueta}: use letras, numeros, espacios, dos puntos o guion.`;
      case 'almacenesIguales':
        return 'Almacen destino: debe ser diferente al almacen origen.';
      case 'passwordRequerido':
        return 'Contrasena: es obligatoria.';
      case 'passwordMinLength':
        return 'Contrasena: debe tener al menos 6 caracteres.';
      case 'passwordConfirmacion':
        return 'Confirmar contrasena: debe coincidir con la contrasena.';
      default:
        return `${etiqueta}: tiene un dato invalido.`;
    }
  });
}

function etiquetaCampo(ruta: string, etiquetas: FormFieldLabels): string {
  if (!ruta) {
    return etiquetas['formulario'] || 'Formulario';
  }

  return etiquetas[ruta] || etiquetas[ultimoSegmento(ruta)] || humanizarCampo(ruta);
}

function extraerMensajesBackend(error: unknown): string[] {
  const data = error as any;
  const candidatos = [
    data?.error?.message,
    data?.error?.errors,
    data?.error?.detail,
    data?.error?.details,
    data?.error?.error,
    data?.message,
  ];

  return candidatos.flatMap((valor) => normalizarMensajeCrudo(valor));
}

function normalizarMensajeCrudo(valor: unknown): string[] {
  if (!valor) {
    return [];
  }

  if (Array.isArray(valor)) {
    return valor.flatMap((item) => normalizarMensajeCrudo(item));
  }

  if (typeof valor === 'object') {
    return Object.entries(valor as Record<string, unknown>).flatMap(
      ([campo, mensajes]) => {
        const lista = normalizarMensajeCrudo(mensajes);
        return lista.length
          ? lista.map((mensaje) => `${campo}: ${mensaje}`)
          : [`${campo}: dato invalido`];
      },
    );
  }

  return [String(valor)];
}

function normalizarMensajeBackend(
  mensaje: string,
  etiquetas: FormFieldLabels,
): string {
  const texto = mensaje.trim();
  const campo = detectarCampoBackend(texto, etiquetas);

  if (!campo) {
    return traducirMensajeComun(texto);
  }

  const reemplazado = reemplazarCampo(texto, campo, etiquetas[campo]);
  const traducido = traducirMensajeComun(reemplazado, etiquetas[campo]);

  return empiezaConEtiqueta(traducido, etiquetas[campo])
    ? traducido
    : `${etiquetas[campo]}: ${traducido}`;
}

function esMensajeTecnico(mensaje: string): boolean {
  const lower = mensaje.trim().toLowerCase();
  return ['bad request', 'error', 'internal server error'].includes(lower);
}

function detectarCampoBackend(
  mensaje: string,
  etiquetas: FormFieldLabels,
): string | null {
  const lower = mensaje.toLowerCase();

  return (
    Object.keys(etiquetas).find((campo) => {
      if (campo === 'formulario') {
        return false;
      }

      return variantesCampo(campo).some((variante) =>
        lower.includes(variante.toLowerCase()),
      );
    }) || null
  );
}

function reemplazarCampo(
  mensaje: string,
  campo: string,
  etiqueta: string,
): string {
  return variantesCampo(campo).reduce((actual, variante) => {
    const regex = new RegExp(escapeRegExp(variante), 'gi');
    return actual.replace(regex, etiqueta);
  }, mensaje);
}

function traducirMensajeComun(mensaje: string, etiqueta?: string): string {
  const lower = mensaje.toLowerCase();

  if (etiqueta && /should not be empty|must not be empty|required/.test(lower)) {
    return `${etiqueta}: es obligatorio.`;
  }

  if (etiqueta && /must be an email|email must be/.test(lower)) {
    return `${etiqueta}: ingrese un correo valido.`;
  }

  if (etiqueta && /unique|duplicate|already exists|ya existe|duplicado/.test(lower)) {
    return `${etiqueta}: ya existe, use otro valor.`;
  }

  if (etiqueta && /must be a number|must be numeric|is not a number/.test(lower)) {
    return `${etiqueta}: debe ser numerico.`;
  }

  return mensaje;
}

function variantesCampo(campo: string): string[] {
  return unicos([
    campo,
    ultimoSegmento(campo),
    camelASnake(campo),
    camelASnake(ultimoSegmento(campo)),
  ]);
}

function humanizarCampo(ruta: string): string {
  const campo = ultimoSegmento(ruta);
  const texto = campo
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/[_-]+/g, ' ')
    .trim()
    .toLowerCase();

  return texto ? texto.charAt(0).toUpperCase() + texto.slice(1) : 'Campo';
}

function ultimoSegmento(ruta: string): string {
  const partes = ruta.split('.');
  return partes[partes.length - 1] || ruta;
}

function camelASnake(valor: string): string {
  return valor.replace(/([a-z])([A-Z])/g, '$1_$2').toLowerCase();
}

function empiezaConEtiqueta(mensaje: string, etiqueta: string): boolean {
  return mensaje.toLowerCase().startsWith(etiqueta.toLowerCase());
}

function escapeRegExp(valor: string): string {
  return valor.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function unicos<T>(items: T[]): T[] {
  return [...new Set(items)];
}

function raizControl(control: AbstractControl): AbstractControl {
  let actual = control;

  while (actual.parent) {
    actual = actual.parent;
  }

  return actual;
}
