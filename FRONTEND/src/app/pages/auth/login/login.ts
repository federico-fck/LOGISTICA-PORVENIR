import { Component, inject, signal } from '@angular/core';
import {
  FormBuilder,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import {
  FormFieldLabels,
  marcarFormularioInvalido,
} from '../../../core/forms/form-error-messages';
import { CampoValidacionDirective } from '../../../core/forms/campo-validacion.directive';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ReactiveFormsModule, CampoValidacionDirective],
  templateUrl: './login.html',
  styleUrl: './login.css',
})
export class Login {
  private readonly formBuilder = inject(FormBuilder);
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);
  private readonly etiquetasFormulario: FormFieldLabels = {
    usuario: 'Usuario',
    password: 'Contrasena',
  };

  cargando = signal(false);
  error = signal('');

  mostrarUsuario = signal(true);
  mostrarPassword = signal(false);

  form = this.formBuilder.nonNullable.group({
    usuario: ['', [Validators.required]],
    password: ['', [Validators.required]],
  });

  alternarUsuario() {
    this.mostrarUsuario.update((valor) => !valor);
  }

  alternarPassword() {
    this.mostrarPassword.update((valor) => !valor);
  }

  ingresar() {
    this.error.set('');

    if (this.form.invalid) {
      this.error.set(
        marcarFormularioInvalido(
          this.form,
          this.etiquetasFormulario,
          'Revise los datos de acceso',
        ),
      );
      return;
    }

    this.cargando.set(true);

    this.authService.login(this.form.getRawValue()).subscribe({
      next: () => {
        this.cargando.set(false);
        this.router.navigate(['/dashboard']);
      },
      error: () => {
        this.cargando.set(false);
        this.error.set('Usuario o contraseña incorrectos.');
      },
    });
  }
}
