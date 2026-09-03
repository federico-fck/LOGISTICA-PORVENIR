import { TestBed } from '@angular/core/testing';
import { FormBuilder, Validators } from '@angular/forms';
import { of } from 'rxjs';
import { AlmacenesService } from '../../core/services/almacenes.service';
import { InsumosService } from '../../core/services/insumos.service';
import { InventarioDespachosService } from '../../core/services/inventario-despachos.service';
import { AuthState } from '../../core/state/auth.state';
import {
  MOTIVOS_AJUSTE_INVENTARIO,
  almacenesDiferentesValidator,
} from '../../core/forms/professional-forms';
import { InventarioDespachos } from './inventario-despachos-flujo';

describe('Inventario y Despachos - formularios', () => {
  it('pestana debe mostrar Movimientos de inventario', async () => {
    await TestBed.configureTestingModule({
      imports: [InventarioDespachos],
      providers: [
        {
          provide: InventarioDespachosService,
          useValue: {
            inventario: () => of([]),
            stockBajo: () => of([]),
            movimientos: () => of([]),
            despachos: () => of([]),
            pedidosAprobadosParaDespacho: () => of([]),
            usuariosSistema: () => of([]),
            areasSistema: () => of([]),
          },
        },
        { provide: InsumosService, useValue: { listar: () => of([]) } },
        { provide: AlmacenesService, useValue: { listar: () => of([]) } },
        {
          provide: AuthState,
          useValue: {
            usuario: () => ({ idUsuario: 1, nombreCompleto: 'Usuario Prueba' }),
            rolActual: () => 'ADMINISTRADOR',
            permisos: () => [],
          },
        },
      ],
    }).compileComponents();

    const fixture = TestBed.createComponent(InventarioDespachos);
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain(
      'Movimientos de inventario',
    );
  });

  it('ajuste sin motivo es invalido y motivo seleccionado es valido', () => {
    const fb = new FormBuilder().nonNullable;
    const form = fb.group({
      idInsumo: ['1', [Validators.required]],
      idAlmacen: ['1', [Validators.required]],
      tipoMovimiento: ['AJUSTE_POSITIVO', [Validators.required]],
      cantidad: ['1', [Validators.required, Validators.min(0.01)]],
      motivo: ['', [Validators.required]],
    });

    expect(form.valid).toBe(false);
    form.controls.motivo.setValue(MOTIVOS_AJUSTE_INVENTARIO[0]);
    expect(form.valid).toBe(true);
  });

  it('cantidades negativas son invalidas', () => {
    const fb = new FormBuilder().nonNullable;
    const form = fb.group({
      cantidad: ['-1', [Validators.required, Validators.min(0.01)]],
    });

    expect(form.valid).toBe(false);
  });

  it('almacen origen igual a destino es invalido en transferencia', () => {
    const fb = new FormBuilder().nonNullable;
    const form = fb.group(
      {
        idAlmacenOrigen: ['1', [Validators.required]],
        idAlmacenDestino: ['1', [Validators.required]],
      },
      {
        validators: [almacenesDiferentesValidator('idAlmacenOrigen', 'idAlmacenDestino')],
      },
    );

    expect(form.valid).toBe(false);
  });
});
