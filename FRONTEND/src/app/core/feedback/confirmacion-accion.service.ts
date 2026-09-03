import { Injectable, signal } from '@angular/core';

export interface ConfirmacionAccion {
  id: number;
  titulo: string;
  mensaje: string;
}

@Injectable({
  providedIn: 'root',
})
export class ConfirmacionAccionService {
  private readonly confirmacionSignal = signal<ConfirmacionAccion | null>(null);
  private temporizador: ReturnType<typeof setTimeout> | null = null;
  private secuencia = 0;

  readonly confirmacion = this.confirmacionSignal.asReadonly();

  mostrar(mensaje = 'Accion realizada correctamente.', titulo = 'Operacion exitosa') {
    this.limpiarTemporizador();

    this.confirmacionSignal.set({
      id: ++this.secuencia,
      titulo,
      mensaje,
    });

    this.temporizador = setTimeout(() => {
      this.cerrar();
    }, 2400);
  }

  cerrar() {
    this.limpiarTemporizador();
    this.confirmacionSignal.set(null);
  }

  private limpiarTemporizador() {
    if (!this.temporizador) {
      return;
    }

    clearTimeout(this.temporizador);
    this.temporizador = null;
  }
}
