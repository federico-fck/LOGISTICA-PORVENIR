import {
  AfterViewInit,
  Directive,
  DoCheck,
  ElementRef,
  OnDestroy,
  Renderer2,
  inject,
} from '@angular/core';
import { NgControl, ValidationErrors } from '@angular/forms';
import {
  mensajeErrorControl,
  validacionFormularioSolicitada,
} from './form-error-messages';

@Directive({
  selector:
    'input[formControlName], select[formControlName], textarea[formControlName], input[formControl], select[formControl], textarea[formControl]',
  standalone: true,
})
export class CampoValidacionDirective
  implements AfterViewInit, DoCheck, OnDestroy
{
  private readonly elementRef =
    inject<ElementRef<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>>(
      ElementRef,
    );
  private readonly renderer = inject(Renderer2);
  private readonly ngControl = inject(NgControl, {
    self: true,
    optional: true,
  });
  private readonly errorId = `campo-error-${Math.random().toString(36).slice(2)}`;
  private errorElement: HTMLElement | null = null;
  private lastState = '';

  ngAfterViewInit() {
    this.render();
  }

  ngDoCheck() {
    this.render();
  }

  ngOnDestroy() {
    this.removeError();
  }

  private render() {
    const control = this.ngControl?.control;

    if (!control) {
      return;
    }

    const groupErrors = this.groupErrorsForControl();
    const errors = control.errors || groupErrors;
    const validacionSolicitada = validacionFormularioSolicitada(control);
    const shouldShow =
      Boolean(errors) &&
      (control.invalid || Boolean(groupErrors)) &&
      validacionSolicitada;
    const state = JSON.stringify({
      shouldShow,
      errors,
      validacionSolicitada,
    });

    if (state === this.lastState) {
      return;
    }

    this.lastState = state;
    this.toggleInvalidState(shouldShow);

    if (!shouldShow || !errors) {
      this.removeError();
      return;
    }

    this.ensureError().textContent = mensajeErrorControl(errors);
  }

  private groupErrorsForControl(): ValidationErrors | null {
    const controlName = String(this.ngControl?.name || '');
    const parentErrors = this.ngControl?.control?.parent?.errors;

    if (!parentErrors) {
      return null;
    }

    if (parentErrors['almacenesIguales'] && controlName.includes('Destino')) {
      return { almacenesIguales: true };
    }

    return null;
  }

  private toggleInvalidState(isInvalid: boolean) {
    const host = this.elementRef.nativeElement;
    const visualHost = this.visualHost();

    if (isInvalid) {
      this.renderer.addClass(host, 'campo-formulario-invalido');
    } else {
      this.renderer.removeClass(host, 'campo-formulario-invalido');
    }

    this.renderer.setAttribute(
      host,
      'aria-invalid',
      isInvalid ? 'true' : 'false',
    );

    if (visualHost !== host) {
      if (isInvalid) {
        this.renderer.addClass(visualHost, 'campo-formulario-invalido');
      } else {
        this.renderer.removeClass(visualHost, 'campo-formulario-invalido');
      }
    }

    if (isInvalid) {
      this.renderer.setAttribute(host, 'aria-describedby', this.errorId);
      return;
    }

    this.renderer.removeAttribute(host, 'aria-describedby');
  }

  private ensureError(): HTMLElement {
    if (!this.errorElement) {
      this.errorElement = this.renderer.createElement('p') as HTMLElement;
      this.renderer.addClass(this.errorElement, 'campo-error');
      this.renderer.setAttribute(this.errorElement, 'id', this.errorId);
      this.renderer.setAttribute(this.errorElement, 'role', 'alert');
    }

    const target = this.insertionTarget();
    const parent = target.parentNode;

    if (parent && this.errorElement.parentNode !== parent) {
      this.renderer.insertBefore(parent, this.errorElement, target.nextSibling);
    }

    return this.errorElement;
  }

  private removeError() {
    if (this.errorElement?.parentNode) {
      this.renderer.removeChild(this.errorElement.parentNode, this.errorElement);
    }
  }

  private insertionTarget(): HTMLElement {
    const host = this.elementRef.nativeElement;
    const parent = host.parentElement;

    if (!parent) {
      return host;
    }

    if (parent.tagName.toLowerCase() === 'label') {
      return parent;
    }

    if (
      parent.classList.contains('relative') ||
      this.isBorderedComposite(parent)
    ) {
      return parent;
    }

    return host;
  }

  private visualHost(): HTMLElement {
    const host = this.elementRef.nativeElement;
    const parent = host.parentElement;

    return parent && this.isBorderedComposite(parent) ? parent : host;
  }

  private isBorderedComposite(element: HTMLElement): boolean {
    const classes = element.className;

    return (
      element.classList.contains('flex') &&
      typeof classes === 'string' &&
      classes.includes('border')
    );
  }
}
