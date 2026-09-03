import { Component, inject } from '@angular/core';

import { ConfirmacionAccionService } from './confirmacion-accion.service';

@Component({
  selector: 'app-confirmacion-accion',
  standalone: true,
  templateUrl: './confirmacion-accion.component.html',
  styleUrl: './confirmacion-accion.component.css',
})
export class ConfirmacionAccionComponent {
  private readonly confirmacionService = inject(ConfirmacionAccionService);

  readonly confirmacion = this.confirmacionService.confirmacion;

  cerrar() {
    this.confirmacionService.cerrar();
  }
}
