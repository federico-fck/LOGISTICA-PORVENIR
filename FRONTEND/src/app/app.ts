import { Component, HostListener } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ConfirmacionAccionComponent } from './core/feedback/confirmacion-accion.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, ConfirmacionAccionComponent],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {
  @HostListener('document:click', ['$event'])
  manejarClickDocumento(event: MouseEvent) {
    const objetivo = event.target;

    if (!(objetivo instanceof HTMLElement)) {
      return;
    }

    const botonAcciones = objetivo.closest<HTMLElement>('.lp-actions-trigger');

    if (botonAcciones) {
      const contenedor = botonAcciones.closest<HTMLElement>('.lp-actions');

      if (!contenedor) {
        return;
      }

      const estabaAbierto = contenedor.classList.contains('is-open');
      this.cerrarMenusAcciones();

      if (estabaAbierto) {
        botonAcciones.blur();
        return;
      }

      contenedor.classList.add('is-open');
      botonAcciones.setAttribute('aria-expanded', 'true');
      this.actualizarDireccionMenu(contenedor, botonAcciones);
      return;
    }

    if (objetivo.closest('.lp-actions-item')) {
      this.cerrarMenusAcciones();
      return;
    }

    if (!objetivo.closest('.lp-actions')) {
      this.cerrarMenusAcciones();
    }
  }

  @HostListener('document:keydown.escape')
  cerrarMenusConEscape() {
    this.cerrarMenusAcciones();
  }

  private cerrarMenusAcciones() {
    document
      .querySelectorAll<HTMLElement>('.lp-actions.is-open')
      .forEach((menu) => {
        menu.classList.remove('is-open', 'is-upward');
        menu
          .querySelector<HTMLElement>('.lp-actions-trigger')
          ?.setAttribute('aria-expanded', 'false');
      });
  }

  private actualizarDireccionMenu(contenedor: HTMLElement, boton: HTMLElement) {
    const menu = contenedor.querySelector<HTMLElement>('.lp-actions-menu');

    if (!menu) {
      return;
    }

    const rect = boton.getBoundingClientRect();
    const totalOpciones = menu.querySelectorAll('.lp-actions-item').length;
    const altoMenu = Math.max(menu.scrollHeight, totalOpciones * 46 + 16, 220);
    const espacioAbajo = window.innerHeight - rect.bottom;
    const espacioArriba = rect.top;

    contenedor.classList.toggle(
      'is-upward',
      espacioAbajo < altoMenu + 16 && espacioArriba > espacioAbajo,
    );
  }
}
